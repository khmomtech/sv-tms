package com.svtrucking.message.service;

import com.svtrucking.message.model.MessageDeliveryAttempt;
import com.svtrucking.message.repository.MessageDeliveryAttemptRepository;
import com.svtrucking.tms.events.DeliveryStatusEvent;
import com.svtrucking.tms.events.EventTopics;
import com.svtrucking.tms.events.NotificationEvent;
import java.time.Instant;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;

@Service
public class NotificationEventConsumer {

    private static final Logger LOG = LoggerFactory.getLogger(NotificationEventConsumer.class);

    private final MessageDeliveryAttemptRepository attemptRepository;
    private final KafkaTemplate<String, DeliveryStatusEvent> deliveryStatusKafkaTemplate;

    public NotificationEventConsumer(
            MessageDeliveryAttemptRepository attemptRepository,
            KafkaTemplate<String, DeliveryStatusEvent> deliveryStatusKafkaTemplate) {
        this.attemptRepository = attemptRepository;
        this.deliveryStatusKafkaTemplate = deliveryStatusKafkaTemplate;
    }

    @KafkaListener(
            topics = EventTopics.NOTIFICATION_EVENTS,
            containerFactory = "notificationEventKafkaListenerContainerFactory")
    public void consume(NotificationEvent event) {
        MessageDeliveryAttempt attempt = new MessageDeliveryAttempt();
        attempt.setEventId(event.eventId());
        attempt.setChannel(event.channel() == null || event.channel().isBlank() ? "push" : event.channel());
        attempt.setStatus("ACCEPTED");
        attempt.setOccurredAt(event.occurredAt() == null ? Instant.now() : event.occurredAt());
        attempt.setSummary(buildSummary(event));
        attemptRepository.save(attempt);

        DeliveryStatusEvent statusEvent = new DeliveryStatusEvent(
                "delivery-" + event.eventId(),
                "tms-message-api",
                event.eventId(),
                "ACCEPTED",
                attempt.getChannel(),
                Instant.now(),
                Map.of("title", nullSafe(event.title()), "notificationType", nullSafe(event.notificationType())));
        deliveryStatusKafkaTemplate.send(EventTopics.DELIVERY_STATUS_EVENTS, event.eventId(), statusEvent);
        LOG.info("Accepted notification event {}", event.eventId());
    }

    private String buildSummary(NotificationEvent event) {
        return "%s:%s".formatted(nullSafe(event.title()), nullSafe(event.body()));
    }

    private String nullSafe(String value) {
        return value == null ? "" : value;
    }
}
