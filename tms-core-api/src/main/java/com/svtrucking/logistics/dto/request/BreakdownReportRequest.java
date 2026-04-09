package com.svtrucking.logistics.dto.request;

import jakarta.validation.constraints.NotBlank;
import java.time.LocalDateTime;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Request DTO for a driver reporting a vehicle breakdown mid-transit.
 * Transitions dispatch from IN_TRANSIT → IN_TRANSIT_BREAKDOWN.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class BreakdownReportRequest {

    @NotBlank(message = "Breakdown location is required")
    private String location;

    @NotBlank(message = "Breakdown description is required")
    private String description;

    /** GPS latitude at time of breakdown. */
    private Double lat;

    /** GPS longitude at time of breakdown. */
    private Double lng;

    /** Optional estimate of when transit can resume. */
    private LocalDateTime estimatedResumeTime;
}
