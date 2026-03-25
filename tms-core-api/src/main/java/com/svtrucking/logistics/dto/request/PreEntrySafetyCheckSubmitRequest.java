package com.svtrucking.logistics.dto.request;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import java.util.List;

/**
 * Request DTO for submitting pre-entry safety check.
 * Sent by field checker/safety personnel when vehicle arrives at gate.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PreEntrySafetyCheckSubmitRequest {

    @NotNull(message = "Dispatch ID is required")
    private Long dispatchId;

    @NotNull(message = "Vehicle ID is required")
    private Long vehicleId;

    @NotNull(message = "Driver ID is required")
    private Long driverId;

    private String warehouseCode;
    private String remarks;

    @NotEmpty(message = "At least one safety item must be checked")
    @Valid
    private List<SafetyItemSubmit> items;

    // Inspection documentation
    private List<String> inspectionPhotoUrls; // URLs of uploaded photos
    private String checkerSignatureUrl; // URL of checker's signature

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class SafetyItemSubmit {
        @NotNull(message = "Category is required")
        private String category; // TIRES, LIGHTS, LOAD, DOCUMENTS, WEIGHT, BRAKES, WINDSHIELD

        @NotNull(message = "Item name is required")
        private String itemName;

        @NotNull(message = "Status is required: OK, FAILED, CONDITIONAL")
        private String status;

        private String remarks;
        private String photoUrl;
    }
}
