package com.svtrucking.logistics.dto;

import com.svtrucking.logistics.model.VehicleDocument;
import java.time.LocalDateTime;
import java.util.Date;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class VehicleDocumentDto {

  private Long id;
  private Long vehicleId;
  private String vehicleName;
  private String licensePlate;
  private String documentType;
  private String documentUrl;
  private String documentName;
  private String docNumber;
  private String notes;
  private Date issueDate;
  private Date expiryDate;
  private Boolean approved;
  private LocalDateTime updatedAt;
  private String updatedBy;

  public static VehicleDocumentDto fromEntity(VehicleDocument doc) {
    if (doc == null) return null;

    // Avoid lazy-loading too much data while still providing useful context
    String vehicleName = null;
    String licensePlate = null;
    Long vehicleId = null;
    if (doc.getVehicle() != null) {
      vehicleId = doc.getVehicle().getId();
      licensePlate = doc.getVehicle().getLicensePlate();
      vehicleName = doc.getVehicle().getManufacturer() + " " + doc.getVehicle().getModel();
    }

    return VehicleDocumentDto.builder()
        .id(doc.getId())
        .vehicleId(vehicleId)
        .vehicleName(vehicleName)
        .licensePlate(licensePlate)
        .documentType(doc.getDocumentType() != null ? doc.getDocumentType().name() : null)
        .documentUrl(doc.getDocumentUrl())
        .documentName(null)
        .docNumber(doc.getDocumentNumber())
        .notes(doc.getNotes())
        .issueDate(doc.getIssueDate())
        .expiryDate(doc.getExpiryDate())
        .approved(doc.isApproved())
        .updatedAt(doc.getUpdatedAt())
        .updatedBy(doc.getUpdatedBy())
        .build();
  }
}
