package com.svtrucking.logistics.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * Request DTO for vehicle maintenance policy setup
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MaintenancePolicyRequest {

    private List<PMScheduleRequest> schedules;
}