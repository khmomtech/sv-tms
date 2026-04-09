package com.svtrucking.logistics.dto;

import com.svtrucking.logistics.enums.CaseTaskStatus;
import jakarta.validation.constraints.NotBlank;
import java.time.LocalDateTime;

public record CaseTaskRequest(
    @NotBlank String title,
    String description,
    CaseTaskStatus status,
    Long ownerUserId,
    LocalDateTime dueAt) {}

