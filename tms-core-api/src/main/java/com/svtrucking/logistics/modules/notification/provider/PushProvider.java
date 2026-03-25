package com.svtrucking.logistics.modules.notification.provider;

import com.svtrucking.logistics.modules.notification.queue.NotificationPayload;

public interface PushProvider {
  /**
   * Sends the given notification payload.
   *
   * @return true if send succeeded; false if it should be retried.
   */
  boolean send(NotificationPayload payload);
}
