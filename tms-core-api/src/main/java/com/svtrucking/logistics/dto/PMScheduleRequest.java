package com.svtrucking.logistics.dto;

import com.svtrucking.logistics.enums.PMTriggerType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Request DTO for PM schedule creation
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PMScheduleRequest {

    private String scheduleName;
    private String description;
    private PMTriggerType triggerType;
    private Integer triggerInterval;
    private Integer triggerIntervalDays;
    private Integer reminderBeforeKm;
    private Integer reminderBeforeDays;
    private Long taskTypeId;
}
