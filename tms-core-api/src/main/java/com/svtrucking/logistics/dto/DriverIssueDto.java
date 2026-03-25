package com.svtrucking.logistics.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.svtrucking.logistics.enums.IssueStatus;
import com.svtrucking.logistics.enums.IssueSeverity;
import com.svtrucking.logistics.model.DriverIssue;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class DriverIssueDto {

  private Long id;

  @NotNull(message = "Driver ID is required")
  private Long driverId;

  private String driverName;

  @NotNull(message = "Vehicle ID is required")
  private Long vehicleId;

  private String vehiclePlate;

  @NotBlank(message = "Title is required")
  @Size(max = 200, message = "Title cannot exceed 200 characters")
  private String title;

  @NotBlank(message = "Description is required")
  @Size(max = 2000, message = "Description cannot exceed 2000 characters")
  private String description;

  @NotNull(message = "Severity is required")
  private IssueSeverity severity;

  private IssueStatus status;

  private String location;

  private Double currentKm;

  private List<String> photoUrls;

  private List<DriverIssuePhotoDto> photos;

  private Long workOrderId;

  private Long assignedToId;

  private String assignedToName;

  private LocalDateTime reportedAt;

  private LocalDateTime resolvedAt;

  @Size(max = 1000, message = "Resolution notes cannot exceed 1000 characters")
  private String resolutionNotes;

  // Legacy fields for backward compatibility
  private LocalDateTime createdAt;
  private List<String> images;
  private Long dispatchId;
  private String orderReference;

  // Mapper methods
  public static DriverIssueDto fromEntity(DriverIssue entity) {
    if (entity == null) return null;

    List<String> imageUrls =
        entity.getImages() == null ? null : new java.util.ArrayList<>(entity.getImages());

    return DriverIssueDto.builder()
        .id(entity.getId())
        .driverId(entity.getDriver() != null ? entity.getDriver().getId() : null)
        .driverName(
            entity.getDriver() != null
                ? entity.getDriver().getFirstName() + " " + entity.getDriver().getLastName()
                : null)
        .vehicleId(entity.getVehicle() != null ? entity.getVehicle().getId() : null)
        .vehiclePlate(entity.getVehicle() != null ? entity.getVehicle().getLicensePlate() : null)
        .title(entity.getTitle())
        .description(entity.getDescription())
        .severity(entity.getSeverity())
        .status(entity.getStatus())
        .location(entity.getLocation())
        .currentKm(entity.getCurrentKm())
        .photoUrls(imageUrls)
        .photos(
            entity.getPhotos() != null
                ? entity.getPhotos().stream()
                    .map(DriverIssuePhotoDto::fromEntity)
                    .collect(Collectors.toList())
                : null)
        .workOrderId(entity.getWorkOrder() != null ? entity.getWorkOrder().getId() : null)
        .assignedToId(entity.getAssignedTo() != null ? entity.getAssignedTo().getId() : null)
        .assignedToName(
            entity.getAssignedTo() != null ? entity.getAssignedTo().getUsername() : null)
        .reportedAt(entity.getReportedAt())
        .resolvedAt(entity.getResolvedAt())
        .resolutionNotes(entity.getResolutionNotes())
        // Legacy compatibility
        .createdAt(entity.getCreatedAt())
        .images(imageUrls)
        .build();
  }
}
