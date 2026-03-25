package com.svtrucking.tms.events;

import java.time.Instant;
import java.util.Map;

public record DispatchEvent(
        String eventId,
        String sourceService,
        String eventType,
        Long dispatchId,
        Long driverId,
        Instant occurredAt,
        Map<String, Object> metadata) {
}
