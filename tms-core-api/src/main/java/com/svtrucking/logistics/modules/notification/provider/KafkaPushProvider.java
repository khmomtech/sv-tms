package com.svtrucking.logistics.modules.notification.provider;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.svtrucking.logistics.modules.notification.queue.NotificationPayload;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.support.SendResult;
import org.springframework.stereotype.Component;

import java.util.concurrent.CompletableFuture;

/**
 * Push provider that publishes notification payloads to a Kafka topic.
 *
 * <p>A downstream consumer (e.g. a dedicated notification-worker service) reads the
 * topic and forwards to the actual push gateway (FCM, APNS, etc.).  This decouples
 * notification sending from the API request lifecycle and improves resilience when
 * Firebase is temporarily unreachable.
 *
 * <p>Activate via {@code application.properties}:
 * <pre>
 *   notification.push.provider=kafka
 *   notification.kafka.topic=notifications.push      # default
 *   notification.kafka.call-topic=notifications.call # optional: separate topic for calls
 * </pre>
 *
 * <p>The payload is serialised as JSON by the configured {@link KafkaTemplate}.
 * Ensure your Kafka producer config uses {@code JsonSerializer} for the value serialiser,
 * or configure {@code spring.kafka.producer.value-serializer} accordingly.
 */
// Registered whenever spring-kafka is on the classpath and a KafkaTemplate is configured.
// DynamicPushProvider selects this at runtime when provider=kafka.
@Component
@org.springframework.boot.autoconfigure.condition.ConditionalOnBean(KafkaTemplate.class)
@Slf4j
@RequiredArgsConstructor
public class KafkaPushProvider implements PushProvider {

  // Use the same KafkaTemplate<String, Object> bean that CoreEventPublisher uses.
  // Spring Kafka auto-configuration creates exactly one template; parameterising
  // it as <String, NotificationPayload> would require a separate @Bean definition.
  private final KafkaTemplate<String, Object> kafkaTemplate;
  private final ObjectMapper objectMapper;

  /** Default Kafka topic for regular push notifications. */
  @Value("${notification.kafka.topic:notifications.push}")
  private String notificationTopic;

  /**
   * Optional separate Kafka topic for time-critical incoming-call events.
   * Defaults to the same as {@code notificationTopic} when not set.
   */
  @Value("${notification.kafka.call-topic:${notification.kafka.topic:notifications.push}}")
  private String callTopic;

  @Override
  public boolean send(NotificationPayload payload) {
    boolean isCall = "INCOMING_CALL".equalsIgnoreCase(payload.getType());
    String topic   = isCall ? callTopic : notificationTopic;

    // Use driverId as Kafka message key for partition affinity (all messages for a
    // given driver land on the same partition, preserving order).
    String key = payload.getDriverId() != null
        ? payload.getDriverId().toString()
        : "broadcast";

    try {
      CompletableFuture<SendResult<String, Object>> future =
          kafkaTemplate.send(topic, key, payload);

      // Async ack — we return true optimistically and let Kafka handle retries.
      // The consumer side is responsible for delivery guarantees.
      future.whenComplete((result, ex) -> {
        if (ex != null) {
          log.warn("[Kafka] Push notification publish failed: topic={}, key={}, type={}, error={}",
              topic, key, payload.getType(), ex.getMessage());
        } else {
          log.debug("[Kafka] Push notification published: topic={}, partition={}, offset={}, type={}",
              topic,
              result.getRecordMetadata().partition(),
              result.getRecordMetadata().offset(),
              payload.getType());
        }
      });

      log.info("[Kafka] Enqueued {} notification: topic={}, key={}",
          payload.getType(), topic, key);
      return true;

    } catch (Exception e) {
      log.error("[Kafka] Failed to send payload to Kafka: topic={}, type={}, error={}",
          topic, payload.getType(), e.getMessage(), e);
      return false;
    }
  }
}
