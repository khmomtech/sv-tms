package com.svtrucking.logistics.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.svtrucking.logistics.enums.CaseTaskStatus;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class CaseTaskDto {

  private Long id;
  private Long caseId;
  private String caseCode;

  @NotBlank(message = "Title is required")
  @Size(max = 200, message = "Title cannot exceed 200 characters")
  private String title;

  @Size(max = 5000, message = "Description cannot exceed 5000 characters")
  private String description;

  private CaseTaskStatus status;

  private Long ownerUserId;
  private String ownerUsername;

  private LocalDateTime dueAt;
  private LocalDateTime createdAt;
  private Long createdByUserId;
  private String createdByUsername;

  private LocalDateTime completedAt;
  private Long completedByUserId;
  private String completedByUsername;

  // Computed fields
  private Boolean isOverdue;
}
