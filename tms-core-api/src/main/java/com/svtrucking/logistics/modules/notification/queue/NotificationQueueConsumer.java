package com.svtrucking.logistics.modules.notification.queue;

import com.svtrucking.logistics.modules.notification.provider.PushProvider;
import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Tags;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnBean;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/**
 * Consumer that drains the notification queue and forwards payloads to the configured PushProvider.
 */
@Component
@ConditionalOnBean(NotificationQueueService.class)
@org.springframework.boot.autoconfigure.condition.ConditionalOnProperty(prefix = "notification.queue", name = "enabled", havingValue = "true", matchIfMissing = true)
@Slf4j
@RequiredArgsConstructor
public class NotificationQueueConsumer {

  private final NotificationQueueService queueService;
  private final PushProvider pushProvider;

  @Autowired(required = false)
  private MeterRegistry meterRegistry;

  @Value("${notification.queue.max-attempts:5}")
  private int maxAttempts;

  @Scheduled(fixedDelayString = "${notification.queue.poll-interval-ms:3000}")
  public void run() {
    if (meterRegistry != null) {
      meterRegistry.gauge("notification.queue.depth", queueService.queueDepth());
    }

    NotificationPayload payload = queueService.poll();
    if (payload == null) {
      return;
    }

    if (payload.getAttemptCount() >= maxAttempts) {
      log.warn("Dropping notification payload after {} attempts: {}", payload.getAttemptCount(), payload);
      if (meterRegistry != null) {
        meterRegistry.counter("notification.queue.drop").increment();
      }
      return;
    }

    boolean success = pushProvider.send(payload);
    if (success) {
      if (meterRegistry != null) {
        meterRegistry.counter("notification.queue.success").increment();
      }
      return;
    }

    if (meterRegistry != null) {
      meterRegistry.counter("notification.queue.retry").increment();
    }
    payload.setAttemptCount(payload.getAttemptCount() + 1);
    log.info("Re-queueing notification (attempt {}): {}", payload.getAttemptCount(), payload);
    queueService.enqueue(payload);
  }
}
