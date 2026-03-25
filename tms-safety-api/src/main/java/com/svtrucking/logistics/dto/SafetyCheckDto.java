package com.svtrucking.logistics.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.svtrucking.logistics.enums.DailySafetyCheckStatus;
import com.svtrucking.logistics.enums.SafetyRiskLevel;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import lombok.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class SafetyCheckDto {
  private Long id;
  private LocalDate checkDate;
  private String shift;
  private Long driverId;
  private String driverName;
  private Long vehicleId;
  private String vehiclePlate;
  private DailySafetyCheckStatus status;
  private SafetyRiskLevel riskLevel;
  private SafetyRiskLevel riskOverride;
  private LocalDateTime submittedAt;
  private LocalDateTime approvedAt;
  private Long approvedBy;
  private String approvedByName;
  private String rejectReason;
  private String notes;
  private Double gpsLat;
  private Double gpsLng;
  private LocalDateTime createdAt;
  private LocalDateTime updatedAt;

  @Builder.Default
  private List<SafetyCheckItemDto> items = new ArrayList<>();

  @Builder.Default
  private List<SafetyCheckAttachmentDto> attachments = new ArrayList<>();

  @Builder.Default
  private List<SafetyCheckAuditDto> audits = new ArrayList<>();
}
