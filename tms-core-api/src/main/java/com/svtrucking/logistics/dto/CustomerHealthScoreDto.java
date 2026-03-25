package com.svtrucking.logistics.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CustomerHealthScoreDto {
    private Long customerId;
    private Integer score; // 0-100
    private HealthStatus status;
    private FactorsDto factors;
    private LocalDateTime lastCalculated;
    private List<String> recommendations;

    public enum HealthStatus {
        EXCELLENT,  // 80-100
        GOOD,       // 60-79
        FAIR,       // 40-59
        POOR,       // 20-39
        AT_RISK     // 0-19
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class FactorsDto {
        private Integer orderFrequency;     // 0-100
        private Integer revenueGrowth;      // 0-100
        private Integer paymentPunctuality; // 0-100
        private Integer engagementLevel;    // 0-100
        private Integer recency;            // 0-100
    }

    public static HealthStatus calculateStatus(int score) {
        if (score >= 80) return HealthStatus.EXCELLENT;
        if (score >= 60) return HealthStatus.GOOD;
        if (score >= 40) return HealthStatus.FAIR;
        if (score >= 20) return HealthStatus.POOR;
        return HealthStatus.AT_RISK;
    }
}
