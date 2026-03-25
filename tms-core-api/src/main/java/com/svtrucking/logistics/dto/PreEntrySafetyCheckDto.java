package com.svtrucking.logistics.dto;

import com.svtrucking.logistics.model.PreEntrySafetyCheck;
import com.svtrucking.logistics.model.PreEntrySafetyItem.SafetyItemStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.ArrayList;
import java.util.stream.Collectors;

/**
 * DTO for PreEntrySafetyCheck with detailed item breakdown.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PreEntrySafetyCheckDto {

    private Long id;
    private Long dispatchId;
    private Long vehicleId;
    private String vehicleNumber;
    private Long driverId;
    private String driverName;
    private String warehouseCode;
    private String status;
    private LocalDate checkDate;
    private String remarks;
    private UserSimpleDto checkedBy;
    private LocalDateTime checkedAt;
    private String checkerSignaturePath;
    private List<String> inspectionPhotos;
    private UserSimpleDto overrideApprovedBy;
    private LocalDateTime overrideApprovedAt;
    private String overrideRemarks;
    private List<PreEntrySafetyItemDto> items;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    // Summary fields
    private Integer totalItems;
    private Integer passedItems;
    private Integer failedItems;
    private Integer conditionalItems;
    private String dispatchStatusAfterCheck;
    private Boolean autoTransitionApplied;
    private String transitionMessage;

    public static PreEntrySafetyCheckDto from(PreEntrySafetyCheck entity) {
        if (entity == null)
            return null;

        List<PreEntrySafetyItemDto> itemDtos = entity.getItems() != null
                ? entity.getItems().stream().map(PreEntrySafetyItemDto::from).collect(Collectors.toList())
                : List.of();
        long passed = entity.getItems() != null
                ? entity.getItems().stream().filter(i -> i.getStatus() == SafetyItemStatus.OK).count()
                : 0;
        long failed = entity.getItems() != null
                ? entity.getItems().stream().filter(i -> i.getStatus() == SafetyItemStatus.FAILED).count()
                : 0;
        long conditional = entity.getItems() != null
                ? entity.getItems().stream().filter(i -> i.getStatus() == SafetyItemStatus.CONDITIONAL).count()
                : 0;

        return PreEntrySafetyCheckDto.builder()
                .id(entity.getId())
                .dispatchId(entity.getDispatch() != null ? entity.getDispatch().getId() : null)
                .vehicleId(entity.getVehicle() != null ? entity.getVehicle().getId() : null)
                .vehicleNumber(entity.getVehicle() != null ? entity.getVehicle().getLicensePlate() : null)
                .driverId(entity.getDriver() != null ? entity.getDriver().getId() : null)
                .driverName(entity.getDriver() != null
                        ? entity.getDriver().getFirstName() + " " + entity.getDriver().getLastName()
                        : null)
                .warehouseCode(entity.getWarehouseCode())
                .status(entity.getStatus() != null ? entity.getStatus().getValue() : null)
                .checkDate(entity.getCheckDate())
                .remarks(entity.getRemarks())
                .checkedBy(entity.getCheckedBy() != null ? UserSimpleDto.fromEntity(entity.getCheckedBy()) : null)
                .checkedAt(entity.getCheckedAt())
                .checkerSignaturePath(entity.getCheckerSignaturePath())
                // Materialize lazy element collection to a plain list before leaving transaction scope.
                .inspectionPhotos(entity.getInspectionPhotos() != null ? new ArrayList<>(entity.getInspectionPhotos()) : List.of())
                .overrideApprovedBy(
                        entity.getOverrideApprovedBy() != null ? UserSimpleDto.fromEntity(entity.getOverrideApprovedBy())
                                : null)
                .overrideApprovedAt(entity.getOverrideApprovedAt())
                .overrideRemarks(entity.getOverrideRemarks())
                .items(itemDtos)
                .totalItems(itemDtos.size())
                .passedItems((int) passed)
                .failedItems((int) failed)
                .conditionalItems((int) conditional)
                .createdAt(entity.getCreatedAt())
                .updatedAt(entity.getUpdatedAt())
                .build();
    }

    public static PreEntrySafetyCheckDto fromSummary(PreEntrySafetyCheck entity) {
        if (entity == null) {
            return null;
        }

        return PreEntrySafetyCheckDto.builder()
                .id(entity.getId())
                .dispatchId(entity.getDispatch() != null ? entity.getDispatch().getId() : null)
                .vehicleId(entity.getVehicle() != null ? entity.getVehicle().getId() : null)
                .vehicleNumber(entity.getVehicle() != null ? entity.getVehicle().getLicensePlate() : null)
                .driverId(entity.getDriver() != null ? entity.getDriver().getId() : null)
                .driverName(buildDriverName(entity))
                .warehouseCode(entity.getWarehouseCode())
                .status(entity.getStatus() != null ? entity.getStatus().getValue() : null)
                .checkDate(entity.getCheckDate())
                .createdAt(entity.getCreatedAt())
                .updatedAt(entity.getUpdatedAt())
                .build();
    }

    private static String buildDriverName(PreEntrySafetyCheck entity) {
        if (entity.getDriver() == null) {
            return null;
        }
        String first = entity.getDriver().getFirstName() == null ? "" : entity.getDriver().getFirstName().trim();
        String last = entity.getDriver().getLastName() == null ? "" : entity.getDriver().getLastName().trim();
        String fullName = (first + " " + last).trim();
        return fullName.isEmpty() ? null : fullName;
    }
}
