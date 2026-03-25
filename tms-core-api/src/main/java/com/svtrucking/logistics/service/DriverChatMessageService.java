package com.svtrucking.logistics.service;

import com.svtrucking.logistics.dto.chat.DriverChatConversationSummaryDto;
import com.svtrucking.logistics.dto.chat.DriverChatEventDto;
import com.svtrucking.logistics.model.CallSession;
import com.svtrucking.logistics.model.Driver;
import com.svtrucking.logistics.model.DriverChatMessage;
import com.svtrucking.logistics.model.DriverChatMessageType;
import com.svtrucking.logistics.modules.notification.provider.PushProvider;
import com.svtrucking.logistics.modules.notification.queue.NotificationPayload;
import com.svtrucking.logistics.modules.notification.queue.NotificationQueueService;
import com.svtrucking.logistics.settings.event.SettingChangedEvent;
import com.svtrucking.logistics.model.DriverChatConversationMetadata;
import com.svtrucking.logistics.repository.CallSessionRepository;
import com.svtrucking.logistics.repository.DriverChatConversationMetadataRepository;
import com.svtrucking.logistics.repository.DriverChatMessageRepository;
import com.svtrucking.logistics.repository.DriverRepository;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.event.EventListener;
import org.springframework.core.annotation.Order;
import org.springframework.data.domain.Sort;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Slf4j
public class DriverChatMessageService {

  private final DriverChatMessageRepository repository;
  private final DriverRepository driverRepository;
  private final CallSessionRepository callSessionRepository;
  private final DriverChatConversationMetadataRepository metadataRepository;
  private final SimpMessagingTemplate messagingTemplate;
  private final AgoraTokenService agoraTokenService;
  private final PushProvider pushProvider;

  // Queue is optional — absent when Redis is not configured
  @Autowired(required = false)
  private NotificationQueueService notificationQueueService;

  private static final String TOPIC_DRIVER = "/topic/driver-chat/";
  private static final String TOPIC_ADMIN  = "/topic/admin-driver-chat";

  // ─── Message queries ────────────────────────────────────────────────────

  @Transactional(readOnly = true)
  public List<DriverChatMessage> listForDriver(Long driverId) {
    return repository.findByDriverId(
        driverId, Sort.by(Sort.Direction.ASC, "createdAt"));
  }

  @Transactional(readOnly = true)
  public List<DriverChatMessage> listForDriver(Long driverId, int page, int size) {
    if (page < 0) page = 0;
    if (size <= 0) size = 30;
    if (size > 100) size = 100;
    return repository
        .findByDriverId(driverId,
            org.springframework.data.domain.PageRequest.of(
                page, size, Sort.by(Sort.Direction.ASC, "createdAt")))
        .getContent();
  }

  @Transactional(readOnly = true)
  public List<DriverChatConversationSummaryDto> listConversationSummaries() {
    List<DriverChatConversationSummaryDto> summaries = new ArrayList<>();
    for (Long driverId : repository.findDriverIdsOrderedByLatestMessage()) {
      repository.findFirstByDriverIdOrderByCreatedAtDesc(driverId)
          .ifPresent(last -> summaries.add(buildSummary(driverId, last)));
    }
    return summaries;
  }

  // ─── Send messages ──────────────────────────────────────────────────────

  @Transactional
  public DriverChatMessage sendMessageToDriver(
      Long driverId, String senderRole, String sender, String message) {
    return sendMessageToDriver(
        driverId, senderRole, sender, message, DriverChatMessageType.TEXT);
  }

  @Transactional
  public DriverChatMessage sendMessageToDriver(
      Long driverId, String senderRole, String sender,
      String message, DriverChatMessageType messageType) {
    return sendMessageToDriver(
        driverId, senderRole, sender, message, messageType, null, null);
  }

  @Transactional
  public DriverChatMessage sendMessageToDriver(
      Long driverId, String senderRole, String sender,
      String message, DriverChatMessageType messageType,
      String agoraChannelName, Long callSessionId) {

    DriverChatMessage entity = DriverChatMessage.builder()
        .driverId(driverId)
        .senderRole(senderRole)
        .sender(sender)
        .message(message)
        .messageType(messageType)
        .createdAt(LocalDateTime.now())
        .read(false)
        .agoraChannelName(agoraChannelName)
        .callSessionId(callSessionId)
        .build();

    DriverChatMessage saved = repository.save(entity);
    broadcast("MESSAGE_CREATED", driverId, saved);
    return saved;
  }

  // ─── Mark read ──────────────────────────────────────────────────────────

  @Transactional
  public DriverChatMessage markAsRead(Long messageId) {
    DriverChatMessage updated = repository.findById(messageId)
        .map(msg -> {
          msg.setRead(true);
          return repository.save(msg);
        })
        .orElseThrow(
            () -> new IllegalArgumentException("Message not found: " + messageId));
    broadcast("MESSAGE_READ", updated.getDriverId(), updated);
    return updated;
  }

  @Transactional
  public int markDriverMessagesReadByAdmin(Long driverId) {
    int updated = repository.markConversationAsReadBySenderRole(driverId, "DRIVER");
    if (updated > 0) {
      broadcast("CONVERSATION_READ", driverId,
          repository.findFirstByDriverIdOrderByCreatedAtDesc(driverId).orElse(null));
    }
    return updated;
  }

  // ─── Typing indicator ───────────────────────────────────────────────────

  /**
   * Broadcast an ephemeral TYPING frame via STOMP — no DB write.
   */
  public void broadcastTyping(Long driverId, String senderRole) {
    // Build a transient (non-persisted) message for the STOMP frame.
    DriverChatMessage typing = DriverChatMessage.builder()
        .driverId(driverId)
        .senderRole(senderRole)
        .sender(senderRole)
        .message("")
        .messageType(DriverChatMessageType.TYPING)
        .createdAt(LocalDateTime.now())
        .read(true)
        .build();

    DriverChatEventDto event = new DriverChatEventDto("TYPING", driverId, typing, null);
    messagingTemplate.convertAndSend(TOPIC_DRIVER + driverId, event);
    messagingTemplate.convertAndSend(TOPIC_ADMIN, event);
  }

  // ─── Call session management ─────────────────────────────────────────────

  /**
   * Create a new call session and broadcast CALL_REQUEST with Agora token details.
   *
   * @param driverId     ID of the driver in the call
   * @param senderRole   "DRIVER" or "ADMIN"
   * @param sender       Username of initiator
   * @return Token response DTO carrying appId, agoraToken, channelName, uid
   */
  @Transactional
  public CallTokenResponse createCallSession(
      Long driverId, String senderRole, String sender) {

    // One active session at a time per driver.
    List<CallSession> existing = callSessionRepository.findActiveByDriverId(driverId);
    if (!existing.isEmpty()) {
      log.warn("[Call] Driver {} already has an active call session", driverId);
      CallSession active = existing.get(0);
      String token = agoraTokenService.generateRtcToken(active.getChannelName(), 0);
      return new CallTokenResponse(
          agoraTokenService.getAppId(), token, active.getChannelName(), 0, active.getId());
    }

    // Generate a unique channel name for this call.
    String channelName = "call-" + driverId + "-" + UUID.randomUUID().toString().substring(0, 8);
    String agoraToken = agoraTokenService.generateRtcToken(channelName, 0);

    CallSession session = CallSession.builder()
        .driverId(driverId)
        .adminUsername("ADMIN".equals(senderRole) ? sender : null)
        .channelName(channelName)
        .status(CallSession.Status.RINGING)
        .startedAt(LocalDateTime.now())
        .build();
    CallSession saved = callSessionRepository.save(session);

    // Send CALL_REQUEST message so the driver's STOMP subscription fires.
    sendMessageToDriver(
        driverId, senderRole, sender,
        "📞 " + ("DRIVER".equals(senderRole) ? "Call request from driver" : "Incoming call from support"),
        DriverChatMessageType.CALL_REQUEST,
        channelName,
        saved.getId());

    // ── Push notification for background/killed-app wakeup ──────────────────
    // When the admin starts the call the driver's app may be killed or backgrounded;
    // STOMP won't be running.  Route through the configured PushProvider so the
    // delivery channel (FCM direct, Kafka, none) is controlled by
    // notification.push.provider in application.properties.
    if ("ADMIN".equals(senderRole)) {
      Driver driver = driverRepository.findById(driverId).orElse(null);
      if (driver != null && driver.getDeviceToken() != null && !driver.getDeviceToken().isBlank()) {
        sendCallPushNotification(driver.getDeviceToken(), sender, channelName, saved.getId(), driverId);
      } else {
        log.warn("[Call] Driver {} has no device token; skipping call push notification", driverId);
      }
    }

    return new CallTokenResponse(
        agoraTokenService.getAppId(), agoraToken, channelName, 0, saved.getId());
  }

  /**
   * Called when a driver/admin accepts a call. Transitions session → ACTIVE.
   */
  @Transactional
  public CallTokenResponse acceptCallSession(Long driverId, String senderRole, String sender) {
    List<CallSession> active = callSessionRepository.findActiveByDriverId(driverId);
    if (active.isEmpty()) {
      throw new IllegalStateException("No active call session for driver " + driverId);
    }

    CallSession session = active.get(0);
    session.setStatus(CallSession.Status.ACTIVE);
    session.setAnsweredAt(LocalDateTime.now());
    callSessionRepository.save(session);

    String token = agoraTokenService.generateRtcToken(session.getChannelName(), 0);

    sendMessageToDriver(
        driverId, senderRole, sender,
        "📞 Call accepted",
        DriverChatMessageType.CALL_ACCEPTED,
        session.getChannelName(),
        session.getId());

    return new CallTokenResponse(
        agoraTokenService.getAppId(), token, session.getChannelName(), 0, session.getId());
  }

  /**
   * Called when either party hangs up. Transitions session → ENDED.
   */
  @Transactional
  public void endCallSession(Long driverId, String senderRole, String sender) {
    List<CallSession> active = callSessionRepository.findActiveByDriverId(driverId);
    active.forEach(session -> {
      session.setStatus(CallSession.Status.ENDED);
      session.setEndedAt(LocalDateTime.now());
      if (session.getAnsweredAt() != null) {
        session.setDurationSeconds(
            (int) ChronoUnit.SECONDS.between(session.getAnsweredAt(), session.getEndedAt()));
      }
      callSessionRepository.save(session);

      sendMessageToDriver(
          driverId, senderRole, sender,
          "📞 Call ended",
          DriverChatMessageType.CALL_ENDED,
          session.getChannelName(),
          session.getId());
    });
  }

  /**
   * Called when the driver declines an incoming call.
   */
  @Transactional
  public void declineCallSession(Long driverId, String senderRole, String sender) {
    List<CallSession> active = callSessionRepository.findActiveByDriverId(driverId);
    active.forEach(session -> {
      session.setStatus(CallSession.Status.DECLINED);
      session.setEndedAt(LocalDateTime.now());
      callSessionRepository.save(session);

      sendMessageToDriver(
          driverId, senderRole, sender,
          "📞 Call declined",
          DriverChatMessageType.CALL_DECLINED,
          session.getChannelName(),
          session.getId());
    });
  }

  // ─── Token-only endpoint (driver fetches token without creating session) ───

  /**
   * Fetch an Agora token for the driver's current active session.
   * Used by the driver app when joining a channel that was created by support.
   */
  @Transactional(readOnly = true)
  public CallTokenResponse fetchTokenForActiveSession(Long driverId) {
    List<CallSession> active = callSessionRepository.findActiveByDriverId(driverId);
    if (active.isEmpty()) {
      throw new IllegalStateException("No active call session for driver " + driverId);
    }
    CallSession session = active.get(0);
    String token = agoraTokenService.generateRtcToken(session.getChannelName(), 0);
    return new CallTokenResponse(
        agoraTokenService.getAppId(), token, session.getChannelName(), 0, session.getId());
  }

  // ─── Conversation summary ───────────────────────────────────────────────

  private DriverChatConversationSummaryDto buildSummary(
      Long driverId, DriverChatMessage last) {
    Driver driver = driverRepository.findById(driverId).orElse(null);
    String driverName = driver != null
        ? (!driver.getFullName().isBlank() ? driver.getFullName() : driver.getName())
        : "Driver #" + driverId;
    String phone = driver != null ? driver.getPhone() : null;
    String employeeName = (driver != null && driver.getEmployee() != null)
        ? ((driver.getEmployee().getFirstName() != null
                ? driver.getEmployee().getFirstName() : "")
            + " "
            + (driver.getEmployee().getLastName() != null
                ? driver.getEmployee().getLastName() : "")).trim()
        : null;
    long unread = repository.countByDriverIdAndReadFalseAndSenderRoleIgnoreCase(driverId, "DRIVER");
    long total  = repository.countByDriverId(driverId);
    DriverChatConversationMetadata meta = metadataRepository.findById(driverId).orElse(null);
    boolean archived  = meta != null && meta.isArchivedByAdmin();
    boolean resolved  = meta != null && meta.isResolvedByAdmin();
    return new DriverChatConversationSummaryDto(
        driverId, driverName, phone, employeeName,
        last.getMessage(), last.getSenderRole(), last.getCreatedAt(),
        unread, total, archived, resolved);
  }

  // ─── Archive / resolve conversation ─────────────────────────────────────

  @Transactional
  public void setArchived(Long driverId, boolean archived) {
    DriverChatConversationMetadata meta = metadataRepository.findById(driverId)
        .orElseGet(() -> DriverChatConversationMetadata.builder().driverId(driverId).build());
    meta.setArchivedByAdmin(archived);
    metadataRepository.save(meta);
  }

  @Transactional
  public void setResolved(Long driverId, boolean resolved) {
    DriverChatConversationMetadata meta = metadataRepository.findById(driverId)
        .orElseGet(() -> DriverChatConversationMetadata.builder().driverId(driverId).build());
    meta.setResolvedByAdmin(resolved);
    metadataRepository.save(meta);
  }

  // ─── STOMP broadcast ────────────────────────────────────────────────────

  private void broadcast(String eventType, Long driverId, DriverChatMessage message) {
    DriverChatConversationSummaryDto summary =
        repository.findFirstByDriverIdOrderByCreatedAtDesc(driverId)
            .map(last -> buildSummary(driverId, last))
            .orElse(null);
    DriverChatEventDto event = new DriverChatEventDto(eventType, driverId, message, summary);
    messagingTemplate.convertAndSend(TOPIC_DRIVER + driverId, event);
    messagingTemplate.convertAndSend(TOPIC_ADMIN, event);
  }

  // ─── Push notification helper ─────────────────────────────────────────────

  /**
   * Routes a call push notification through the configured {@link PushProvider}.
   *
   * <p>If the Redis notification queue is available the payload is enqueued for
   * async delivery (better throughput, built-in retry).  Otherwise it is sent
   * synchronously via {@code pushProvider.send()}.
   */
  private void sendCallPushNotification(
      String deviceToken, String callerName, String channelName,
      Long sessionId, Long driverId) {

    NotificationPayload payload = NotificationPayload.builder()
        .driverId(driverId)
        .type("INCOMING_CALL")
        .topic(deviceToken)       // FCM device token (or Kafka routing key when provider=kafka)
        .callerName(callerName)
        .channelName(channelName)
        .sessionId(sessionId)
        .title("📞 Incoming call")
        .message("Call from " + (callerName != null && !callerName.isBlank() ? callerName : "Dispatch"))
        .sender(callerName)
        .attemptCount(0)
        .build();

    // Prefer queue for async / retry semantics; fall back to synchronous send.
    // isEnabled() re-reads from SettingService on each call so live changes apply immediately.
    if (notificationQueueService != null && notificationQueueService.isEnabled()) {
      boolean queued = notificationQueueService.enqueue(payload);
      if (queued) {
        log.info("[Call] Call push notification queued: channel={}, driverId={}", channelName, driverId);
        return;
      }
      log.warn("[Call] Queue enqueue failed; falling back to direct send: channel={}", channelName);
    }

    boolean sent = pushProvider.send(payload);
    if (sent) {
      log.info("[Call] Call push notification sent directly: channel={}, driverId={}", channelName, driverId);
    } else {
      log.warn("[Call] Call push notification failed: channel={}, driverId={}", channelName, driverId);
    }
  }

  // ─── Inner DTO ──────────────────────────────────────────────────────────

  public record CallTokenResponse(
      String appId,
      String agoraToken,
      String channelName,
      int uid,
      Long sessionId) {}
}
