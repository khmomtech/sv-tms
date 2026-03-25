package com.svtrucking.logistics.modules.notification.queue;

import com.svtrucking.logistics.modules.notification.provider.PushProvider;
import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class NotificationQueueConsumerTest {

  private NotificationQueueService queueService;
  private PushProvider pushProvider;
  private NotificationQueueConsumer consumer;

  @BeforeEach
  void setUp() {
    queueService = mock(NotificationQueueService.class);
    pushProvider = mock(PushProvider.class);
    consumer = new NotificationQueueConsumer(queueService, pushProvider);

    // default to allow retries
    ReflectionTestUtils.setField(consumer, "maxAttempts", 5);
  }

  @Test
  void run_whenQueueEmpty_doesNothing() {
    when(queueService.poll()).thenReturn(null);

    consumer.run();

    verify(queueService).poll();
    verify(pushProvider, times(0)).send(any());
  }

  @Test
  void run_whenPayloadReachedMaxAttempts_dropsPayload() {
    NotificationPayload payload = NotificationPayload.builder().attemptCount(5).build();
    when(queueService.poll()).thenReturn(payload);

    consumer.run();

    verify(pushProvider, times(0)).send(any());
  }

  @Test
  void run_whenSendSucceeds_doesNotRequeue() {
    NotificationPayload payload = NotificationPayload.builder().attemptCount(0).build();
    when(queueService.poll()).thenReturn(payload);
    when(pushProvider.send(payload)).thenReturn(true);

    consumer.run();

    verify(queueService, times(0)).enqueue(any());
  }

  @Test
  void run_whenSendFails_requeuesWithIncrementedAttemptCount() {
    NotificationPayload payload = NotificationPayload.builder().attemptCount(0).build();
    when(queueService.poll()).thenReturn(payload);
    when(pushProvider.send(payload)).thenReturn(false);

    consumer.run();

    verify(queueService).enqueue(payload);
    // should now have incremented attempt count
    assert payload.getAttemptCount() == 1;
  }

  @Test
  void run_recordsMetricsWhenRegistryPresent() {
    NotificationPayload payload = NotificationPayload.builder().attemptCount(0).build();
    when(queueService.poll()).thenReturn(payload);
    when(pushProvider.send(payload)).thenReturn(true);

    // Provide an actual registry so counters/gauges are created
    SimpleMeterRegistry registry = new SimpleMeterRegistry();
    ReflectionTestUtils.setField(consumer, "meterRegistry", registry);
    ReflectionTestUtils.setField(consumer, "maxAttempts", 5);

    consumer.run();

    // Since push succeeded, the success counter should be incremented
    assert registry.get("notification.queue.success").counter().count() == 1.0;
  }
}
