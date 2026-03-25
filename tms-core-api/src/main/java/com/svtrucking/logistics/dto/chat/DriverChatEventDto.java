package com.svtrucking.logistics.dto.chat;

import com.svtrucking.logistics.model.DriverChatMessage;

public record DriverChatEventDto(
    String eventType,
    Long driverId,
    DriverChatMessage message,
    DriverChatConversationSummaryDto conversation) {}
