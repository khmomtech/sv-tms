package com.svtrucking.logistics.modules.notification.provider;

import com.google.firebase.messaging.AndroidConfig;
import com.google.firebase.messaging.AndroidNotification;
import com.google.firebase.messaging.ApnsConfig;
import com.google.firebase.messaging.Aps;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.Message;
import com.svtrucking.logistics.modules.notification.queue.NotificationPayload;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

/**
 * Push provider implementation using Firebase Cloud Messaging (FCM).
 *
 * <p>Activated when {@code notification.push.provider=fcm} (the default).
 *
 * <p>Handles two delivery modes:
 * <ul>
 *   <li><b>Regular</b> – notification + data payload routed to the appropriate Android channel.</li>
 *   <li><b>INCOMING_CALL</b> – data-only, {@code Priority.HIGH} (Android) + {@code apns-priority:10}
 *       (iOS) so the driver app background handler wakes up and shows a heads-up call notification
 *       even when the app is killed.</li>
 * </ul>
 *
 * <p>Switch providers via {@code application.properties}:
 * <pre>
 *   notification.push.provider=fcm    # Firebase (default)
 *   notification.push.provider=kafka  # Publish to Kafka topic; a consumer forwards to FCM
 *   notification.push.provider=none   # No-op / logging only
 * </pre>
 */
// Registered whenever Firebase Admin SDK is on the classpath and configured.
// DynamicPushProvider selects this at runtime when provider=fcm.
@Component
@org.springframework.boot.autoconfigure.condition.ConditionalOnBean(com.google.firebase.FirebaseApp.class)
@Slf4j
public class FirebasePushProvider implements PushProvider {

  private static final String ANDROID_ALERTS_CHANNEL_ID   = "sv_driver_alerts";
  private static final String ANDROID_UPDATES_CHANNEL_ID  = "sv_driver_notifications";
  private static final String ANDROID_CALL_CHANNEL_ID     = "sv_driver_call";

  @Override
  public boolean send(NotificationPayload payload) {
    try {
      if ("INCOMING_CALL".equalsIgnoreCase(payload.getType())) {
        return sendCallNotification(payload);
      }
      return sendRegularNotification(payload);
    } catch (Exception e) {
      log.warn("[FCM] send failed for payload type={}: {}", payload.getType(), e.getMessage(), e);
      return false;
    }
  }

  // ── Regular notification ──────────────────────────────────────────────────

  private boolean sendRegularNotification(NotificationPayload payload) throws Exception {
    String title = payload.getTitle() != null ? payload.getTitle() : "SV Trucking";
    String body  = payload.getMessage() != null ? payload.getMessage() : "You have a new update.";

    boolean isForceOpen = "FORCE_OPEN".equalsIgnoreCase(payload.getType());

    AndroidConfig androidConfig = isForceOpen
        ? AndroidConfig.builder()
            .setTtl(15 * 60 * 1000L)
            .setCollapseKey("force-open")
            .setPriority(AndroidConfig.Priority.HIGH)
            .build()
        : AndroidConfig.builder()
            .setTtl(3600 * 1000L)
            .setCollapseKey("driver-alerts")
            .setPriority(AndroidConfig.Priority.HIGH)
            .setNotification(
                AndroidNotification.builder()
                    .setTitle(title)
                    .setBody(body)
                    .setChannelId(channelForType(payload.getType()))
                    .setSound("default")
                    .build())
            .build();

    Message.Builder builder = Message.builder().setAndroidConfig(androidConfig);
    resolveDestination(builder, payload);
    applyCommonData(builder, title, body, payload);

    String messageId = FirebaseMessaging.getInstance().send(builder.build());
    log.info("[FCM] Regular notification sent: type={}, messageId={}", payload.getType(), messageId);
    return true;
  }

  // ── Incoming-call data-only notification ─────────────────────────────────

  /**
   * Sends a data-only, maximum-priority FCM message so the Flutter background
   * isolate can show a heads-up call notification even when the app is killed.
   */
  private boolean sendCallNotification(NotificationPayload payload) throws Exception {
    if (payload.getTopic() == null || payload.getTopic().isBlank()) {
      log.warn("[FCM] sendCallNotification skipped: missing device token (channelName={})",
          payload.getChannelName());
      return false;
    }

    String callerName  = payload.getCallerName()  != null ? payload.getCallerName()  : "Dispatch";
    String channelName = payload.getChannelName() != null ? payload.getChannelName() : "";
    String sessionId   = payload.getSessionId()   != null ? payload.getSessionId().toString() : "";
    String driverId    = payload.getDriverId()    != null ? payload.getDriverId().toString()  : "";

    Message message = Message.builder()
        .setToken(payload.getTopic())
        // Data-only — no notification block; background handler shows local heads-up
        .putData("type",        "INCOMING_CALL")
        .putData("callerName",  callerName)
        .putData("channelName", channelName)
        .putData("sessionId",   sessionId)
        .putData("driverId",    driverId)
        // Android: wake app from Doze/killed state
        .setAndroidConfig(
            AndroidConfig.builder()
                .setPriority(AndroidConfig.Priority.HIGH)
                .setTtl(60 * 1000L)  // 60 s — calls expire quickly
                .build())
        // iOS: background wakeup via content-available
        .setApnsConfig(
            ApnsConfig.builder()
                .putHeader("apns-priority", "10")
                .setAps(Aps.builder()
                    .setContentAvailable(true)
                    .build())
                .build())
        .build();

    String messageId = FirebaseMessaging.getInstance().send(message);
    log.info("[FCM] Call notification sent: channel={}, token=...{}, messageId={}",
        channelName,
        payload.getTopic().length() > 8
            ? payload.getTopic().substring(payload.getTopic().length() - 8)
            : payload.getTopic(),
        messageId);
    return true;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  private void resolveDestination(Message.Builder builder, NotificationPayload payload) {
    if (payload.getTopic() == null || payload.getTopic().isBlank()) {
      log.warn("[FCM] No destination token/topic for payload: {}", payload);
      throw new IllegalArgumentException("Missing FCM token or topic");
    }
    // If the topic looks like a driver device token (long, no '/') treat as token; else FCM topic.
    String dest = payload.getTopic();
    if (dest.contains("/") || dest.startsWith("driver-") || dest.startsWith("sv-")) {
      builder.setTopic(dest);
    } else {
      builder.setToken(dest);
    }
  }

  private void applyCommonData(Message.Builder b, String title, String body, NotificationPayload payload) {
    b.putData("title",       title)
     .putData("body",        body)
     .putData("type",        safe(payload.getType()))
     .putData("referenceId", safe(payload.getReferenceId()))
     .putData("priority",    "high")
     .putData("route",       routeForType(payload.getType()))
     .putData("msg_id",      java.util.UUID.randomUUID().toString())
     .putData("force_native","0");
    if ("FORCE_OPEN".equalsIgnoreCase(payload.getType())) {
      b.putData("action", "FORCE_OPEN").putData("force_native", "1");
    }
  }

  private String safe(String s) {
    return s == null ? "" : s.trim();
  }

  private String routeForType(String type) {
    if (type == null) return "/notifications";
    return switch (type.toLowerCase()) {
      case "dispatch"      -> "/dispatchDetail";
      case "issue"         -> "/report-issue-list";
      case "incoming_call" -> "/incoming-call";
      default              -> "/notifications";
    };
  }

  private String channelForType(String type) {
    if (type == null) return ANDROID_UPDATES_CHANNEL_ID;
    return switch (type.toLowerCase()) {
      case "dispatch", "issue", "alert" -> ANDROID_ALERTS_CHANNEL_ID;
      case "incoming_call"              -> ANDROID_CALL_CHANNEL_ID;
      default                           -> ANDROID_UPDATES_CHANNEL_ID;
    };
  }
}
