package com.svtrucking.tms.events;

import java.time.Instant;
import java.util.Map;

public record DriverEvent(
        String eventId,
        String sourceService,
        String eventType,
        Long driverId,
        String actor,
        Instant occurredAt,
        Map<String, Object> metadata) {
}
