package com.svtrucking.logistics.modules.notification.service;

import com.svtrucking.logistics.model.Driver;
import com.svtrucking.logistics.messaging.CoreEventPublisher;
import com.svtrucking.logistics.modules.notification.dto.BroadcastNotificationRequest;
import com.svtrucking.logistics.modules.notification.dto.CreateNotificationRequest;
import com.svtrucking.logistics.modules.notification.dto.NotificationDTO;
import com.svtrucking.logistics.modules.notification.model.DriverNotification;
import com.svtrucking.logistics.modules.notification.provider.PushProvider;
import com.svtrucking.logistics.modules.notification.queue.NotificationPayload;
import com.svtrucking.logistics.modules.notification.queue.NotificationQueueService;
import com.svtrucking.logistics.modules.notification.repository.DriverNotificationRepository;
import com.svtrucking.logistics.repository.DriverRepository;
import com.svtrucking.tms.events.NotificationEvent;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import java.time.Instant;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Slf4j
@Service
@RequiredArgsConstructor
public class DriverNotificationService {

  private final DriverNotificationRepository notificationRepository;
  private final DriverRepository driverRepository;
  private final CoreEventPublisher eventPublisher;
  private final SimpMessagingTemplate messagingTemplate;
  private final PushProvider pushProvider;

  // Queue is optional; if Redis isn't configured, we fall back to direct send.
  @Autowired(required = false)
  private NotificationQueueService queueService;

  @Value("${notification.queue.enabled:true}")
  private boolean notificationQueueEnabled;

  @Value("${notification.queue.fallback-to-fcm:true}")
  private boolean notificationQueueFallbackToFcm;

  /** Send to a single driver (queue + persist row). */
  public NotificationDispatchResult sendNotification(CreateNotificationRequest req) {
    Long driverId = req.getDriverId();
    String title =
        Optional.ofNullable(req.getTitle()).filter(s -> !s.isBlank()).orElse("SV Trucking");
    String body =
        Optional.ofNullable(req.getMessage())
            .filter(s -> !s.isBlank())
            .orElse("You have a new update.");
    LocalDateTime now = LocalDateTime.now();

    // Persist notification (soft-delete friendly via entity annotations)
    DriverNotification entity = new DriverNotification();
    entity.setDriverId(driverId);
    entity.setTitle(title);
    entity.setMessage(body);
    entity.setType(req.getType());
    entity.setTopic(req.getTopic());
    entity.setReferenceId(req.getReferenceId());
    entity.setSender(req.getSender());
    entity.setSentAt(now);
    entity.setCreatedAt(now);
    // isRead stays default false
    notificationRepository.save(entity);
    boolean persisted = entity.getId() != null;

    // 🛰 WebSocket push for active driver app sessions
    boolean websocketDelivered = false;
    if (driverId != null) {
      try {
        messagingTemplate.convertAndSend(
            "/topic/driver-notification/" + driverId,
            convertToDTO(entity));
        websocketDelivered = true;
      } catch (Exception e) {
        log.warn("WebSocket push failed for driver {}: {}", driverId, e.getMessage(), e);
      }
    }

    boolean eventPublished = false;
    try {
      publishNotificationEvent(
          entity.getDriverId(),
          title,
          body,
          req.getType(),
          req.getReferenceId(),
          req.getTopic(),
          req.getSender());
      eventPublished = true;
    } catch (Exception e) {
      log.warn("Notification event publish failed for driver {}: {}", driverId, e.getMessage(), e);
    }

    // Enqueue for delivery (MQ-first). If queue is unavailable, optionally fall back to FCM.
    boolean queued = false;
    if (notificationQueueEnabled) {
      NotificationPayload payload = NotificationPayload.builder()
          .driverId(driverId)
          .title(title)
          .message(body)
          .type(req.getType())
          .topic((driverId != null) ? resolveDriverToken(driverId) : req.getTopic())
          .referenceId(req.getReferenceId())
          .actionUrl(req.getActionUrl())
          .actionLabel(req.getActionLabel())
          .severity(req.getSeverity())
          .sender(req.getSender())
          .attemptCount(0)
          .build();

      if (queueService == null) {
        log.warn("Notification queue is enabled but NotificationQueueService is unavailable; using fallback delivery");
      } else {
        queued = queueService.enqueue(payload);
      }

      if (queued) {
        return new NotificationDispatchResult(
            persisted,
            websocketDelivered,
            eventPublished,
            true,
            false);
      }
      log.warn("Notification queue enqueue failed; falling back to direct send (FCM) for driver={}", driverId);
    }

    boolean pushDelivered = false;
    if (notificationQueueFallbackToFcm) {
      pushDelivered = sendDirectToFcm(driverId, title, body, req);
    }

    return new NotificationDispatchResult(
        persisted,
        websocketDelivered,
        eventPublished,
        queued,
        pushDelivered);
  }

  /**
   * Fallback direct send when the Redis queue is unavailable.
   * Delegates to the configured {@link PushProvider} so the delivery channel
   * (FCM, Kafka, none) respects {@code notification.push.provider}.
   */
  private boolean sendDirectToFcm(Long driverId, String title, String body, CreateNotificationRequest req) {
    if (driverId == null) {
      return false;
    }

    String token = resolveDriverToken(driverId);
    if (token == null || token.isBlank()) {
      log.warn("[Notify] No device token for driver {}; skipping fallback send", driverId);
      return false;
    }

    NotificationPayload payload = NotificationPayload.builder()
        .driverId(driverId)
        .title(title)
        .message(body)
        .type(req.getType())
        .topic(token)
        .referenceId(req.getReferenceId())
        .actionUrl(req.getActionUrl())
        .actionLabel(req.getActionLabel())
        .severity(req.getSeverity())
        .sender(req.getSender())
        .attemptCount(0)
        .build();

    boolean sent = pushProvider.send(payload);
    if (!sent) {
      log.warn("[Notify] Fallback direct send failed for driver={}, type={}", driverId, req.getType());
    }
    return sent;
  }

  private String resolveDriverToken(Long driverId) {
    return driverRepository.findById(driverId).map(Driver::getDeviceToken).orElse(null);
  }

  /** Broadcast to a topic (queued for delivery, persisted). */
  public void broadcastToTopic(BroadcastNotificationRequest req) {
    String title =
        Optional.ofNullable(req.getTitle()).filter(s -> !s.isBlank()).orElse("SV Trucking");
    String body =
        Optional.ofNullable(req.getMessage())
            .filter(s -> !s.isBlank())
            .orElse("You have a new update.");
    LocalDateTime now = LocalDateTime.now();

    if (req.getTopic() == null || req.getTopic().isBlank()) {
      throw new IllegalArgumentException("Topic is required for broadcast");
    }

    DriverNotification saved = new DriverNotification();
    saved.setDriverId(null); // broadcast
    saved.setTitle(title);
    saved.setMessage(body);
    saved.setType(req.getType());
    saved.setTopic(req.getTopic());
    saved.setReferenceId(req.getReferenceId());
    saved.setSender(req.getSender());
    saved.setSentAt(now);
    saved.setCreatedAt(now);
    notificationRepository.save(saved);

    // 🛰 WebSocket broadcast for all driver app sessions
    try {
      messagingTemplate.convertAndSend("/topic/driver-notification/all", convertToDTO(saved));
    } catch (Exception e) {
      log.warn("WebSocket broadcast to all drivers failed: {}", e.getMessage(), e);
    }

    publishNotificationEvent(
        null,
        title,
        body,
        req.getType(),
        req.getReferenceId(),
        req.getTopic(),
        req.getSender());

    if (notificationQueueEnabled) {
      NotificationPayload payload = NotificationPayload.builder()
          .title(title)
          .message(body)
          .type(req.getType())
          .topic(req.getTopic())
          .referenceId(req.getReferenceId())
          .actionUrl(req.getActionUrl())
          .severity(req.getSeverity())
          .sender(req.getSender())
          .attemptCount(0)
          .build();

      boolean queued = queueService.enqueue(payload);
      if (queued) {
        return;
      }
      log.warn("Notification queue enqueue failed; falling back to direct send to topic {}", req.getTopic());
    }

    if (notificationQueueFallbackToFcm) {
      sendDirectBroadcastToFcm(req.getTopic(), title, body, req);
    }
  }

  /**
   * Fallback broadcast send when the Redis queue is unavailable.
   * Delegates to the configured {@link PushProvider} so FCM topic vs Kafka
   * routing respects {@code notification.push.provider}.
   */
  private void sendDirectBroadcastToFcm(
      String topic, String title, String body, BroadcastNotificationRequest req) {
    NotificationPayload payload = NotificationPayload.builder()
        .title(title)
        .message(body)
        .type(req.getType())
        .topic(topic)
        .referenceId(req.getReferenceId())
        .actionUrl(req.getActionUrl())
        .severity(req.getSeverity())
        .sender(req.getSender())
        .attemptCount(0)
        .build();

    boolean sent = pushProvider.send(payload);
    if (!sent) {
      log.warn("[Notify] Fallback broadcast send failed: topic={}, type={}", topic, req.getType());
    }
  }

  // =========================
  // Listing & Ordering
  // =========================

  /** Legacy: Paged notifications, newest first (kept for compatibility). */
  @Transactional(readOnly = true)
  public Page<DriverNotification> getNotificationsNewestFirst(Long driverId, int page, int size) {
    int p = Math.max(page, 0);
    int s = Math.min(Math.max(size, 1), 100);
    //  must filter isDeleted = false
    return notificationRepository.findNewestAliveByDriverId(driverId, PageRequest.of(p, s));
  }

  /** Preferred: Paged notifications with Unread first → Newest next. */
  @Transactional(readOnly = true)
  public Page<DriverNotification> getNotificationsUnreadFirst(Long driverId, int page, int size) {
    int p = Math.max(page, 0);
    int s = Math.min(Math.max(size, 1), 100);
    return notificationRepository.listForDriverUnreadFirst(driverId, PageRequest.of(p, s));
  }

  /** Unread only (newest within unread). */
  @Transactional(readOnly = true)
  public Page<DriverNotification> getUnreadNotifications(Long driverId, int page, int size) {
    int p = Math.max(page, 0);
    int s = Math.min(Math.max(size, 1), 100);
    return notificationRepository.listUnreadForDriver(driverId, PageRequest.of(p, s));
  }

  /** New notifications since timestamp (useful for polling or lastSeenAt). */
  @Transactional(readOnly = true)
  public Page<DriverNotification> getNewSince(
      Long driverId, LocalDateTime since, int page, int size) {
    int p = Math.max(page, 0);
    int s = Math.min(Math.max(size, 1), 100);
    return notificationRepository.listNewSince(driverId, since, PageRequest.of(p, s));
  }

  // =========================
  // Read / Delete / Counts
  // =========================

  /** Mark a single notification as read (scoped by driver for safety). */
  @Transactional
  public void markAsRead(Long id, Long driverId) {
    int updated = notificationRepository.markAsReadByIdAndDriver(id, driverId);
    if (updated == 0) {
      // Fallback: either not found, belongs to another driver, or already read
      DriverNotification n =
          notificationRepository
              .findById(id)
              .orElseThrow(() -> new RuntimeException("Notification not found: id=" + id));
      if (!n.isRead()) {
        // only allow if driver matches (avoid cross-account marking)
        if (n.getDriverId() != null && !n.getDriverId().equals(driverId)) {
          throw new RuntimeException(
              "Forbidden: notification does not belong to driver " + driverId);
        }
        n.setRead(true);
        notificationRepository.save(n);
      }
    }
  }

  /** Bulk mark all as read for a driver. */
  @Transactional
  public int markAllAsReadByDriver(Long driverId) {
    return notificationRepository.markAllAsReadByDriver(driverId);
  }

  /** Soft delete one (handled by @SQLDelete if present). */
  @Transactional
  public void deleteNotification(Long id, Long driverId) {
    // Optional guard: ensure ownership before delete
    DriverNotification n =
        notificationRepository
            .findById(id)
            .orElseThrow(() -> new RuntimeException("Notification not found: id=" + id));
    if (n.getDriverId() != null && !n.getDriverId().equals(driverId)) {
      throw new RuntimeException("Forbidden: notification does not belong to driver " + driverId);
    }
    notificationRepository.deleteById(id);
  }

  /** Soft delete all notifications for a driver (custom bulk soft delete). */
  @Transactional
  public int deleteAllNotificationsForDriver(Long driverId) {
    return notificationRepository.deleteByDriverId(driverId);
  }

  /** 🔥 NEW: Soft delete only READ notifications for a driver. */
  @Transactional
  public int deleteReadNotificationsForDriver(Long driverId) {
    // Repository should implement: int deleteReadByDriverId(Long driverId);
    return notificationRepository.deleteReadByDriverId(driverId);
  }

  /** 🔥 NEW: Bulk delete by IDs for a driver, with ownership guard. */
  @Transactional
  public int deleteBatchForDriver(Long driverId, List<Long> ids) {
    if (ids == null || ids.isEmpty()) return 0;

    // Optional strong guard: ensure all belong to the same driver before deleting
    List<Long> notOwned = notificationRepository.findIdsNotOwnedByDriver(driverId, ids);
    if (!notOwned.isEmpty()) {
      throw new RuntimeException(
          "Forbidden: some notifications do not belong to driver " + driverId);
    }

    // Repository should implement: int deleteByDriverIdAndIdIn(Long driverId, List<Long> ids);
    return notificationRepository.deleteByDriverIdAndIdIn(driverId, ids);
  }

  /** Count unread for badge display. */
  @Transactional(readOnly = true)
  public long countUnread(Long driverId) {
    return notificationRepository.countByDriverIdAndIsReadFalse(driverId);
  }

  private void publishNotificationEvent(
      Long driverId,
      String title,
      String body,
      String type,
      String referenceId,
      String channel,
      String sender) {
    NotificationEvent event =
        new NotificationEvent(
            UUID.randomUUID().toString(),
            "tms-core-api",
            type,
            null,
            driverId,
            title,
            body,
            channel,
            Instant.now(),
            Map.of(
                "referenceId", referenceId == null ? "" : referenceId,
                "sender", sender == null ? "" : sender));
    eventPublisher.publishNotification(driverId == null ? "broadcast" : String.valueOf(driverId), event);
  }

  // =========================
  // DTO helpers
  // =========================

  public NotificationDTO convertToDTO(DriverNotification n) {
    return NotificationDTO.builder()
        .id(n.getId())
        .title(n.getTitle())
        .body(n.getMessage())
        .type(n.getType())
        .topic(n.getTopic())
        .referenceId(n.getReferenceId())
        .isRead(n.isRead())
        .createdAt(n.getCreatedAt())
        .build();
  }

  public List<NotificationDTO> convertToDTOList(List<DriverNotification> notifications) {
    return notifications.stream().map(this::convertToDTO).collect(Collectors.toList());
  }

  /**
   * Get driver by ID.
   */
  public Optional<Driver> getDriverById(Long driverId) {
    return driverRepository.findById(driverId);
  }
}
