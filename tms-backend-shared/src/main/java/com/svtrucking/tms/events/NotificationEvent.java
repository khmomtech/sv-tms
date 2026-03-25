package com.svtrucking.tms.events;

import java.time.Instant;
import java.util.Map;

public record NotificationEvent(
        String eventId,
        String sourceService,
        String notificationType,
        Long userId,
        Long driverId,
        String title,
        String body,
        String channel,
        Instant occurredAt,
        Map<String, Object> metadata) {
}
