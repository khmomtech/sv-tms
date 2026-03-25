package com.svtrucking.logistics.modules.notification.queue;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.Instant;

/**
 * Payload stored in the notification queue.
 *
 * <p>For regular push notifications use {@code title}, {@code message}, {@code type},
 * and {@code topic} (FCM device token or FCM topic name).
 *
 * <p>For {@code type = "INCOMING_CALL"} additionally set {@code callerName},
 * {@code channelName}, and {@code sessionId}.  The provider implementations route
 * these as data-only, high-priority messages so the driver app can show a
 * heads-up incoming-call notification even when the app is killed.
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class NotificationPayload {
  private Long driverId;
  private String title;
  private String message;
  private String type;
  /** FCM device token (for single-device sends) or FCM topic (for broadcast). */
  private String topic;
  private String referenceId;
  private String actionUrl;
  private String actionLabel;
  private String severity;
  private String sender;
  private Instant createdAt;
  private int attemptCount;

  // ── Call-specific fields (used when type = "INCOMING_CALL") ─────────────
  /** Display name of the caller shown to the driver (e.g. "Dispatch"). */
  private String callerName;
  /** Agora channel name the driver must join to answer the call. */
  private String channelName;
  /** Database ID of the CallSession entity (for accept/decline routing). */
  private Long sessionId;
}
