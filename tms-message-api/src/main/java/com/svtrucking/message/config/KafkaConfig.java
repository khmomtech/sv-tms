package com.svtrucking.message.config;

import com.svtrucking.tms.events.DeliveryStatusEvent;
import com.svtrucking.tms.events.NotificationEvent;
import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.common.serialization.StringDeserializer;
import org.apache.kafka.common.serialization.StringSerializer;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.kafka.annotation.EnableKafka;
import org.springframework.kafka.config.ConcurrentKafkaListenerContainerFactory;
import org.springframework.kafka.core.ConsumerFactory;
import org.springframework.kafka.core.DefaultKafkaConsumerFactory;
import org.springframework.kafka.core.DefaultKafkaProducerFactory;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.core.ProducerFactory;
import org.springframework.kafka.listener.CommonErrorHandler;
import org.springframework.kafka.listener.DeadLetterPublishingRecoverer;
import org.springframework.kafka.listener.DefaultErrorHandler;
import org.springframework.kafka.support.serializer.JsonDeserializer;
import org.springframework.kafka.support.serializer.JsonSerializer;
import org.springframework.util.backoff.FixedBackOff;

import java.util.HashMap;
import java.util.Map;

@Configuration
@EnableKafka
public class KafkaConfig {

    // -------------------------------------------------------------------------
    // Consumer factory & listener — notification.events
    // -------------------------------------------------------------------------

    @Bean
    ConsumerFactory<String, NotificationEvent> notificationEventConsumerFactory(
            @Value("${spring.kafka.bootstrap-servers}") String bootstrapServers) {
        Map<String, Object> props = new HashMap<>();
        props.put(ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrapServers);
        props.put(ConsumerConfig.GROUP_ID_CONFIG, "tms-message-api");
        props.put(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class);
        props.put(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, JsonDeserializer.class);
        props.put(JsonDeserializer.TRUSTED_PACKAGES, "com.svtrucking.tms.events");

        // Restart from earliest unprocessed offset if this consumer group has
        // no committed offset yet (e.g. first deploy or after a DLT recovery).
        props.put(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG, "earliest");

        // Disable auto-commit so offsets are committed only after the listener
        // method returns without error. Spring Kafka manages commit timing.
        props.put(ConsumerConfig.ENABLE_AUTO_COMMIT_CONFIG, false);

        return new DefaultKafkaConsumerFactory<>(
                props,
                new StringDeserializer(),
                new JsonDeserializer<>(NotificationEvent.class, false));
    }

    /**
     * Listener factory with a Dead Letter Topic (DLT) error handler.
     *
     * On failure the handler retries the message up to 3 times with a 1-second
     * pause between attempts (FixedBackOff). If all retries are exhausted the
     * message is forwarded to "notification.events.DLT" for manual inspection
     * instead of being silently dropped or endlessly blocking the partition.
     */
    @Bean
    ConcurrentKafkaListenerContainerFactory<String, NotificationEvent>
    notificationEventKafkaListenerContainerFactory(
            ConsumerFactory<String, NotificationEvent> notificationEventConsumerFactory,
            KafkaTemplate<String, DeliveryStatusEvent> deliveryStatusKafkaTemplate) {

        ConcurrentKafkaListenerContainerFactory<String, NotificationEvent> factory =
                new ConcurrentKafkaListenerContainerFactory<>();
        factory.setConsumerFactory(notificationEventConsumerFactory);

        // DeadLetterPublishingRecoverer routes failed messages to
        // "<original-topic>.DLT" on the same broker cluster.
        DeadLetterPublishingRecoverer recoverer =
                new DeadLetterPublishingRecoverer(deliveryStatusKafkaTemplate);

        // Retry 3 times, wait 1 second between each attempt, then send to DLT.
        CommonErrorHandler errorHandler =
                new DefaultErrorHandler(recoverer, new FixedBackOff(1_000L, 3));

        factory.setCommonErrorHandler(errorHandler);
        return factory;
    }

    // -------------------------------------------------------------------------
    // Producer factory & template — message.delivery-status.events
    // -------------------------------------------------------------------------

    @Bean
    ProducerFactory<String, DeliveryStatusEvent> deliveryStatusProducerFactory(
            @Value("${spring.kafka.bootstrap-servers}") String bootstrapServers) {
        Map<String, Object> props = new HashMap<>();
        props.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrapServers);
        props.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, StringSerializer.class);
        props.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, JsonSerializer.class);

        // Wait for ALL in-sync replicas to acknowledge before returning success.
        // Combined with min.insync.replicas=2 on the broker, this guarantees the
        // message is durable across at least 2 brokers before we move on.
        props.put(ProducerConfig.ACKS_CONFIG, "all");

        // Retry up to 5 times on transient broker failures or leader elections.
        props.put(ProducerConfig.RETRIES_CONFIG, 5);

        // Idempotent producer: Kafka deduplicates messages server-side using a
        // per-producer sequence number, preventing duplicates during retries.
        // Requires acks=all and max.in.flight.requests.per.connection <= 5.
        props.put(ProducerConfig.ENABLE_IDEMPOTENCE_CONFIG, true);

        // Must be <= 5 when idempotence is enabled; preserves message ordering.
        props.put(ProducerConfig.MAX_IN_FLIGHT_REQUESTS_PER_CONNECTION, 5);

        // Total budget for all retries; 120 s covers a full broker restart.
        props.put(ProducerConfig.DELIVERY_TIMEOUT_MS_CONFIG, 120_000);

        return new DefaultKafkaProducerFactory<>(props);
    }

    @Bean
    KafkaTemplate<String, DeliveryStatusEvent> deliveryStatusKafkaTemplate(
            ProducerFactory<String, DeliveryStatusEvent> deliveryStatusProducerFactory) {
        return new KafkaTemplate<>(deliveryStatusProducerFactory);
    }
}
