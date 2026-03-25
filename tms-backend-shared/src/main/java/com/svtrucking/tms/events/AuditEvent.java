package com.svtrucking.tms.events;

import java.time.Instant;
import java.util.Map;

public record AuditEvent(
        String eventId,
        String sourceService,
        String eventType,
        String subjectType,
        String subjectId,
        String actor,
        Instant occurredAt,
        Map<String, Object> metadata) {
}
