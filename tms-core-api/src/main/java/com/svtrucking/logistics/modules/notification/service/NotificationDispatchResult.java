package com.svtrucking.logistics.modules.notification.service;

public record NotificationDispatchResult(
    boolean persisted,
    boolean websocketDelivered,
    boolean eventPublished,
    boolean queued,
    boolean pushDelivered) {

  public boolean hasLiveDelivery() {
    return websocketDelivered || queued || pushDelivered;
  }

  public boolean hasRecordedDelivery() {
    return persisted || eventPublished;
  }
}
