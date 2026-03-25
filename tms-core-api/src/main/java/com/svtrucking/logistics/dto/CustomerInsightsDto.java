package com.svtrucking.logistics.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CustomerInsightsDto {
    private Long customerId;
    private Integer totalOrders;
    private BigDecimal totalRevenue;
    private BigDecimal averageOrderValue;
    private LocalDate lastOrderDate;
    private LocalDate firstOrderDate;
    private Integer orderFrequencyDays;
    private BigDecimal lifetimeValue;
    private BigDecimal revenueThisMonth;
    private BigDecimal revenueLastMonth;
    private Double revenueGrowthPercent;
    private Integer ordersThisMonth;
    private Integer ordersLastMonth;
    private List<String> topProducts;
    private String preferredPaymentTerms;
    private CustomerHealthScoreDto healthScore;
}
