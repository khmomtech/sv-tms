package com.svtrucking.tms.events;

import java.time.Instant;
import java.util.Map;

public record DeliveryStatusEvent(
        String eventId,
        String sourceService,
        String originalEventId,
        String status,
        String channel,
        Instant occurredAt,
        Map<String, Object> metadata) {
}
