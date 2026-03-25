package com.svtrucking.logistics.dto.chat;

import java.time.LocalDateTime;

public record DriverChatConversationSummaryDto(
    Long driverId,
    String driverName,
    String phone,
    String employeeName,
    String latestMessage,
    String latestSenderRole,
    LocalDateTime latestMessageAt,
    long unreadDriverMessageCount,
    long totalMessageCount,
    boolean archivedByAdmin,
    boolean resolvedByAdmin) {}
