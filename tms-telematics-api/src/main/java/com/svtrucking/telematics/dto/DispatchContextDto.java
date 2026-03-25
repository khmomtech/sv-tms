package com.svtrucking.telematics.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Dispatch context DTO fetched from tms-backend's internal endpoint
 * GET /api/internal/telematics/dispatch/by-reference?ref={orderRef}
 * and cached in DispatchContextCacheService with a 30s Caffeine TTL.
 */
@Data
@NoArgsConstructor
@JsonIgnoreProperties(ignoreUnknown = true)
public class DispatchContextDto {

    private String orderReference;
    private String orderStatus;
    private String shipmentType;
    private LocalDate orderDate;
    private LocalDate deliveryDate;
    private String customerName;
    private String billTo;

    private Long dispatchId;
    private String routeCode;
    private String trackingNo;
    private String dispatchStatus;
    private LocalDateTime estimatedArrival;
    private LocalDateTime startTime;
    private String fromLocation;
    private String toLocation;

    private Long driverId;
    private String driverName;
    private String driverPhone;
    private String vehiclePlate;

    private List<StopDto> stops;

    private boolean hasProofOfDelivery;
    private LocalDateTime deliveredAt;
    private List<StatusHistoryDto> statusHistory;
    private ProofOfDeliveryDto proofOfDelivery;

    @Data
    @NoArgsConstructor
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class StopDto {
        private String type;
        private Integer sequence;
        private String eta;
        private LocalDateTime arrivalTime;
        private LocalDateTime departureTime;
        private String remarks;
        private String proofImageUrl;
        private String confirmedBy;
        private String contactPhone;
        private AddressDto address;
    }

    @Data
    @NoArgsConstructor
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class AddressDto {
        private String name;
        private String address;
        private String city;
        private String country;
        private String postcode;
        private Double latitude;
        private Double longitude;
    }

    @Data
    @NoArgsConstructor
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class StatusHistoryDto {
        private String status;
        private LocalDateTime timestamp;
        private String notes;
        private String updatedBy;
        private String source;
    }

    @Data
    @NoArgsConstructor
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class ProofOfDeliveryDto {
        private Long id;
        private Long dispatchId;
        private String remarks;
        private String address;
        private Double latitude;
        private Double longitude;
        private List<String> proofImagePaths;
        private String signaturePath;
        private LocalDateTime submittedAt;
        private Boolean availableForDownload;
        private Boolean delivered;
    }
}
