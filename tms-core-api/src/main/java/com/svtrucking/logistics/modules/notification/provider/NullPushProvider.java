package com.svtrucking.logistics.modules.notification.provider;

import com.svtrucking.logistics.modules.notification.queue.NotificationPayload;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

/**
 * No-op push provider — logs the payload and discards it.
 *
 * <p>Useful in local development, test environments, or when push notifications
 * are intentionally disabled without breaking the application context.
 *
 * <p>Activate via {@code application.properties}:
 * <pre>
 *   notification.push.provider=none
 * </pre>
 */
// Always registered — acts as the safe fallback when Firebase/Kafka are unavailable,
// and as the active provider when notification.push.provider=none.
@Component
@Slf4j
public class NullPushProvider implements PushProvider {

  @Override
  public boolean send(NotificationPayload payload) {
    log.info("[NullProvider] Push notification suppressed (provider=none): type={}, driverId={}, title={}",
        payload.getType(), payload.getDriverId(), payload.getTitle());
    return true; // returning true so the queue consumer doesn't re-enqueue
  }
}
