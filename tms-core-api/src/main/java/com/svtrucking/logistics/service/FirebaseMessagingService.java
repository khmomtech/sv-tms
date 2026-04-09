package com.svtrucking.logistics.service;

import com.google.firebase.messaging.*;
import java.util.List;
import java.util.concurrent.ExecutionException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

/**
 * Firebase Cloud Messaging service with built-in retry and non-throwing
 * fallback.
 *
 * <p>
 * IMPORTANT: Neither {@code sendNotification} nor
 * {@code sendNotificationToMultipleTokens}
 * will ever throw an unchecked exception. Callers (including
 * {@code @Transactional} methods)
 * must NOT be rolled back because of a notification failure.
 *
 * <p>
 * Retry policy: up to 3 attempts with exponential back-off (1s, 2s).
 * Interrupted sends
 * do not retry. On exhaustion the error is logged only.
 */
@Slf4j
@Service
public class FirebaseMessagingService {

    private static final int MAX_ATTEMPTS = 3;
    private static final long BASE_DELAY_MS = 1_000;

    /**
     * Send a push notification to a single FCM token.
     * Returns the FCM message-id on success, {@code null} on failure (never
     * throws).
     */
    /** Returns the first 8 chars of a token for log tracing without exposing the full value. */
    private static String maskToken(String token) {
        if (token == null || token.length() < 8) return "****";
        return token.substring(0, 8) + "…";
    }

    public String sendNotification(String token, String title, String body) {
        if (token == null || token.isBlank()) {
            log.warn("FCM sendNotification skipped: token is blank (title={})", title);
            return null;
        }

        Message message = Message.builder()
                .setToken(token)
                .setNotification(Notification.builder().setTitle(title).setBody(body).build())
                .build();

        Exception lastException = null;
        for (int attempt = 1; attempt <= MAX_ATTEMPTS; attempt++) {
            try {
                String messageId = FirebaseMessaging.getInstance().sendAsync(message).get();
                log.debug("FCM sent: token={}, messageId={}", maskToken(token), messageId);
                return messageId;
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                log.warn("FCM send interrupted (will not retry): token={}, title={}", maskToken(token), title);
                return null; // never throw
            } catch (ExecutionException e) {
                lastException = e.getCause() instanceof Exception ? (Exception) e.getCause() : e;
                log.warn("FCM send attempt {}/{} failed: token={}, error={}",
                        attempt, MAX_ATTEMPTS, maskToken(token), lastException.getMessage());
                if (attempt < MAX_ATTEMPTS) {
                    sleepQuietly(BASE_DELAY_MS * attempt);
                }
            }
        }

        // All attempts exhausted — log and return null; MUST NOT throw
        log.error("FCM send failed after {} attempts: token={}, title={}, cause={}",
                MAX_ATTEMPTS, maskToken(token), title,
                lastException != null ? lastException.getMessage() : "unknown");
        return null;
    }

    /**
     * @deprecated Use {@link com.svtrucking.logistics.modules.notification.provider.PushProvider}
     *             with a {@code NotificationPayload} of {@code type = "INCOMING_CALL"} instead.
     *             This method bypasses the configurable provider abstraction and always calls
     *             FCM directly.  It is kept for backward-compatibility only.
     *
     * <p>Send a high-priority data-only FCM message to wake the driver app for an
     * incoming call even when the app is killed.
     *
     * <p>A data-only message (no {@code notification} block) is delivered to the
     * app's background handler on Android regardless of battery-saver or Doze.
     * The Flutter side stores the payload in SharedPreferences and shows a
     * heads-up local notification so the driver can answer or decline.
     *
     * @param token      driver's FCM device token
     * @param callerName display name of the caller (e.g. "Dispatch")
     * @param channelName Agora channel name (driver uses this to join)
     * @param sessionId  call session database id
     * @param driverId   driver id (for routing on Flutter side)
     */
    @Deprecated(since = "2.0", forRemoval = true)
    public String sendCallNotification(String token, String callerName,
            String channelName, Long sessionId, Long driverId) {
        if (token == null || token.isBlank()) {
            log.warn("FCM sendCallNotification skipped: blank token (channel={})", channelName);
            return null;
        }

        Message message = Message.builder()
                .setToken(token)
                // Data-only — no notification block. The Flutter background handler
                // shows a local notification so this doesn't need a system notification.
                .putData("type", "INCOMING_CALL")
                .putData("callerName", callerName != null ? callerName : "Dispatch")
                .putData("channelName", channelName != null ? channelName : "")
                .putData("sessionId", sessionId != null ? sessionId.toString() : "")
                .putData("driverId", driverId != null ? driverId.toString() : "")
                // Android: deliver immediately even in Doze / background-restricted mode
                .setAndroidConfig(
                        com.google.firebase.messaging.AndroidConfig.builder()
                                .setPriority(com.google.firebase.messaging.AndroidConfig.Priority.HIGH)
                                .build())
                // Apple Push Notification Service: content-available = 1 wakes app
                .setApnsConfig(
                        com.google.firebase.messaging.ApnsConfig.builder()
                                .putHeader("apns-priority", "10")
                                .setAps(com.google.firebase.messaging.Aps.builder()
                                        .setContentAvailable(true)
                                        .build())
                                .build())
                .build();

        Exception lastException = null;
        for (int attempt = 1; attempt <= MAX_ATTEMPTS; attempt++) {
            try {
                String messageId = FirebaseMessaging.getInstance().sendAsync(message).get();
                log.info("FCM call notification sent: channel={}, token suffix=...{}, messageId={}",
                        channelName, token.length() > 8 ? token.substring(token.length() - 8) : token,
                        messageId);
                return messageId;
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                log.warn("FCM call send interrupted: channel={}", channelName);
                return null;
            } catch (java.util.concurrent.ExecutionException e) {
                lastException = e.getCause() instanceof Exception ? (Exception) e.getCause() : e;
                log.warn("FCM call send attempt {}/{} failed: channel={}, error={}",
                        attempt, MAX_ATTEMPTS, channelName, lastException.getMessage());
                if (attempt < MAX_ATTEMPTS) sleepQuietly(BASE_DELAY_MS * attempt);
            }
        }

        log.error("FCM call notification failed after {} attempts: channel={}, cause={}",
                MAX_ATTEMPTS, channelName,
                lastException != null ? lastException.getMessage() : "unknown");
        return null;
    }

    /**
     * Send a push notification to multiple FCM tokens.
     * Silently logs failures; never throws.
     */
    public void sendNotificationToMultipleTokens(List<String> tokens, String title, String body) {
        if (tokens == null || tokens.isEmpty()) {
            return;
        }

        MulticastMessage message = MulticastMessage.builder()
                .setNotification(Notification.builder().setTitle(title).setBody(body).build())
                .addAllTokens(tokens)
                .build();

        Exception lastException = null;
        for (int attempt = 1; attempt <= MAX_ATTEMPTS; attempt++) {
            try {
                BatchResponse response = FirebaseMessaging.getInstance().sendEachForMulticastAsync(message).get();
                int failCount = response.getFailureCount();
                if (failCount > 0) {
                    log.warn("FCM multicast partial failure: {}/{} tokens failed (title={})",
                            failCount, tokens.size(), title);
                }
                return;
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                log.warn("FCM multicast interrupted (will not retry): title={}", title);
                return; // never throw
            } catch (ExecutionException e) {
                lastException = e.getCause() instanceof Exception ? (Exception) e.getCause() : e;
                log.warn("FCM multicast attempt {}/{} failed: title={}, error={}",
                        attempt, MAX_ATTEMPTS, title, lastException.getMessage());
                if (attempt < MAX_ATTEMPTS) {
                    sleepQuietly(BASE_DELAY_MS * attempt);
                }
            }
        }

        // All attempts exhausted — MUST NOT throw
        log.error("FCM multicast failed after {} attempts: title={}, cause={}",
                MAX_ATTEMPTS, title,
                lastException != null ? lastException.getMessage() : "unknown");
    }

    private static void sleepQuietly(long millis) {
        try {
            Thread.sleep(millis);
        } catch (InterruptedException ie) {
            Thread.currentThread().interrupt();
        }
    }
}
