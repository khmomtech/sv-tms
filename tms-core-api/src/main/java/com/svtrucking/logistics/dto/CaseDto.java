package com.svtrucking.logistics.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.svtrucking.logistics.enums.CaseCategory;
import com.svtrucking.logistics.enums.CaseStatus;
import com.svtrucking.logistics.enums.IssueSeverity;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class CaseDto {

  private Long id;
  private String code;

  @NotBlank(message = "Title is required")
  @Size(max = 300, message = "Title cannot exceed 300 characters")
  private String title;

  @Size(max = 10000, message = "Description cannot exceed 10000 characters")
  private String description;

  @NotNull(message = "Category is required")
  private CaseCategory category;

  @NotNull(message = "Severity is required")
  private IssueSeverity severity;

  private CaseStatus status;

  // Assignment
  private Long assignedToUserId;
  private String assignedToUsername;
  private String assignedTeam;

  // Related entities
  private Long driverId;
  private String driverName;
  private Long vehicleId;
  private String vehiclePlate;

  // SLA
  private LocalDateTime slaTargetAt;

  // Audit
  private LocalDateTime createdAt;
  private Long createdByUserId;
  private String createdByUsername;
  private LocalDateTime updatedAt;
  private LocalDateTime closedAt;

  // Related data counts
  private Integer incidentCount;
  private Integer taskCount;
  private Integer attachmentCount;
  private Integer timelineEntryCount;

  // Optional: included related data
  private List<IncidentDto> incidents;
  private List<CaseTaskDto> tasks;
  private List<CaseAttachmentDto> attachments;
  private List<CaseTimelineDto> timeline;
}
