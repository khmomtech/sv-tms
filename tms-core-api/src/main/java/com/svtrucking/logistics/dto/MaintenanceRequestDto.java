package com.svtrucking.logistics.dto;

import com.svtrucking.logistics.enums.MaintenanceRequestStatus;
import com.svtrucking.logistics.enums.MaintenanceRequestType;
import com.svtrucking.logistics.enums.Priority;
import com.svtrucking.logistics.model.MaintenanceRequest;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.LocalDateTime;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MaintenanceRequestDto {

  private Long id;
  private String mrNumber;

  @NotNull(message = "Vehicle ID is required")
  private Long vehicleId;

  private String vehiclePlate;

  @NotBlank(message = "Title is required")
  @Size(max = 200, message = "Title cannot exceed 200 characters")
  private String title;

  @Size(max = 5000, message = "Description cannot exceed 5000 characters")
  private String description;

  private Priority priority;
  private MaintenanceRequestStatus status;
  private MaintenanceRequestType requestType;
  private Long failureCodeId;
  private String failureCode;
  private String failureCodeDescription;

  private LocalDateTime requestedAt;
  private LocalDateTime approvedAt;
  private LocalDateTime rejectedAt;

  private String approvalRemarks;
  private String rejectionReason;

  private Long createdById;
  private String createdByName;
  private Long approvedById;
  private String approvedByName;
  private Long rejectedById;
  private String rejectedByName;

  // Related Work Order (if created)
  private Long workOrderId;
  private String workOrderNumber;
  private com.svtrucking.logistics.enums.WorkOrderStatus workOrderStatus;

  public static MaintenanceRequestDto fromEntity(MaintenanceRequest mr) {
    if (mr == null) return null;
    return MaintenanceRequestDto.builder()
        .id(mr.getId())
        .mrNumber(mr.getMrNumber())
        .vehicleId(mr.getVehicle() != null ? mr.getVehicle().getId() : null)
        .vehiclePlate(mr.getVehicle() != null ? mr.getVehicle().getLicensePlate() : null)
        .title(mr.getTitle())
        .description(mr.getDescription())
        .priority(mr.getPriority())
        .status(mr.getStatus())
        .requestType(mr.getRequestType())
        .failureCodeId(mr.getFailureCode() != null ? mr.getFailureCode().getId() : null)
        .failureCode(mr.getFailureCode() != null ? mr.getFailureCode().getCode() : null)
        .failureCodeDescription(mr.getFailureCode() != null ? mr.getFailureCode().getDescription() : null)
        .requestedAt(mr.getRequestedAt())
        .approvedAt(mr.getApprovedAt())
        .rejectedAt(mr.getRejectedAt())
        .approvalRemarks(mr.getApprovalRemarks())
        .rejectionReason(mr.getRejectionReason())
        .createdById(mr.getCreatedBy() != null ? mr.getCreatedBy().getId() : null)
        .createdByName(mr.getCreatedBy() != null ? mr.getCreatedBy().getUsername() : null)
        .approvedById(mr.getApprovedBy() != null ? mr.getApprovedBy().getId() : null)
        .approvedByName(mr.getApprovedBy() != null ? mr.getApprovedBy().getUsername() : null)
        .rejectedById(mr.getRejectedBy() != null ? mr.getRejectedBy().getId() : null)
        .rejectedByName(mr.getRejectedBy() != null ? mr.getRejectedBy().getUsername() : null)
        .build();
  }
}
