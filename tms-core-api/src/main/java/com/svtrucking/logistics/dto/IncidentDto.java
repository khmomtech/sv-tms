package com.svtrucking.logistics.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.svtrucking.logistics.enums.IncidentGroup;
import com.svtrucking.logistics.enums.IncidentSource;
import com.svtrucking.logistics.enums.IncidentStatus;
import com.svtrucking.logistics.enums.IncidentType;
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
public class IncidentDto {

  private Long id;
  private String code;

  @NotNull(message = "Incident group is required")
  private IncidentGroup incidentGroup;

  @NotNull(message = "Incident type is required")
  private IncidentType incidentType;

  @NotBlank(message = "Title is required")
  @Size(max = 200, message = "Title cannot exceed 200 characters")
  private String title;

  @Size(max = 5000, message = "Description cannot exceed 5000 characters")
  private String description;

  @NotNull(message = "Severity is required")
  private IssueSeverity severity;

  private IncidentStatus incidentStatus;
  private IncidentSource source;

  // Related entities
  private Long driverId;
  private String driverName;
  private Long vehicleId;
  private String vehiclePlate;
  private Long tripId;
  private String tripReference;

  // Location
  private String locationText;
  private Double locationLat;
  private Double locationLng;

  // Reporting
  private Long reportedByUserId;
  private String reportedByUsername;
  private LocalDateTime reportedAt;

  // SLA
  private LocalDateTime slaDueAt;

  // Assignment
  private Long assignedToId;
  private String assignedToName;

  // Attachments
  private List<String> photoUrls;
  private List<DriverIssuePhotoDto> photos;
  private Integer photoCount; // Computed field

  // Resolution
  private String resolutionNotes;
  private LocalDateTime resolvedAt;

  // Audit
  private LocalDateTime createdAt;
  private LocalDateTime updatedAt;

  // Case linking
  private Boolean linkedToCase;
  private Long caseId;
  private String caseCode;
}
