package com.svtrucking.logistics.service;

import com.svtrucking.logistics.dto.CustomerActivityDto;
import com.svtrucking.logistics.dto.CustomerHealthScoreDto;
import com.svtrucking.logistics.dto.CustomerInsightsDto;
import com.svtrucking.logistics.enums.ActivityType;
import com.svtrucking.logistics.model.Customer;
import com.svtrucking.logistics.model.CustomerActivity;
import com.svtrucking.logistics.repository.CustomerActivityRepository;
import com.svtrucking.logistics.repository.CustomerRepository;
import com.svtrucking.logistics.repository.TransportOrderRepository;
import com.svtrucking.logistics.security.AuthenticatedUserUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
public class CustomerActivityService {

    private final CustomerActivityRepository activityRepository;
    private final CustomerRepository customerRepository;
    private final TransportOrderRepository orderRepository;
    private final AuthenticatedUserUtil authenticatedUserUtil;

    @Transactional(readOnly = true)
    public Page<CustomerActivityDto> getActivities(Long customerId, Pageable pageable) {
        return activityRepository.findByCustomerIdOrderByCreatedAtDesc(customerId, pageable)
                .map(CustomerActivityDto::fromEntity);
    }

    @Transactional
    public CustomerActivityDto createActivity(Long customerId, ActivityType type, String title, 
                                             String description, String metadata,
                                             Long relatedEntityId, String relatedEntityType) {
        Customer customer = customerRepository.findById(customerId)
                .orElseThrow(() -> new RuntimeException("Customer not found"));

        String currentUser = authenticatedUserUtil.getCurrentUser().getUsername();

        CustomerActivity activity = CustomerActivity.builder()
                .customer(customer)
                .type(type)
                .title(title)
                .description(description)
                .metadata(metadata)
                .relatedEntityId(relatedEntityId)
                .relatedEntityType(relatedEntityType)
                .createdByName(currentUser)
                .build();

        activity = activityRepository.save(activity);
        return CustomerActivityDto.fromEntity(activity);
    }

    @Transactional
    public void deleteActivity(Long customerId, Long activityId) {
        activityRepository.deleteById(activityId);
    }

    @Transactional
    public void logOrderActivity(Long customerId, Long orderId, ActivityType type, String title) {
        createActivity(customerId, type, title, null, null, orderId, "ORDER");
    }

    @Transactional(readOnly = true)
    public CustomerInsightsDto getInsights(Long customerId) {
        Customer customer = customerRepository.findById(customerId)
                .orElseThrow(() -> new RuntimeException("Customer not found"));

        LocalDate now = LocalDate.now();
        LocalDate monthStart = now.withDayOfMonth(1);
        LocalDate lastMonthStart = monthStart.minusMonths(1);
        LocalDate lastMonthEnd = monthStart.minusDays(1);

        // Calculate metrics
        Integer totalOrders = customer.getTotalOrders() != null ? customer.getTotalOrders() : 0;
        BigDecimal totalRevenue = customer.getTotalRevenue() != null ? customer.getTotalRevenue() : BigDecimal.ZERO;
        BigDecimal avgOrderValue = totalOrders > 0 
            ? totalRevenue.divide(BigDecimal.valueOf(totalOrders), 2, RoundingMode.HALF_UP)
            : BigDecimal.ZERO;

        // Monthly revenue (mock - should query from orders)
        BigDecimal revenueThisMonth = BigDecimal.ZERO;
        BigDecimal revenueLastMonth = BigDecimal.ZERO;
        
        Double revenueGrowth = 0.0;
        if (revenueLastMonth.compareTo(BigDecimal.ZERO) > 0) {
            revenueGrowth = revenueThisMonth.subtract(revenueLastMonth)
                    .divide(revenueLastMonth, 4, RoundingMode.HALF_UP)
                    .multiply(BigDecimal.valueOf(100))
                    .doubleValue();
        }

        // Order frequency
        Integer orderFrequencyDays = 0;
        if (customer.getFirstOrderDate() != null && totalOrders > 1) {
            long daysBetween = ChronoUnit.DAYS.between(customer.getFirstOrderDate(), LocalDate.now());
            orderFrequencyDays = (int) (daysBetween / totalOrders);
        }

        return CustomerInsightsDto.builder()
                .customerId(customerId)
                .totalOrders(totalOrders)
                .totalRevenue(totalRevenue)
                .averageOrderValue(avgOrderValue)
                .lastOrderDate(customer.getLastOrderDate())
                .firstOrderDate(customer.getFirstOrderDate())
                .orderFrequencyDays(orderFrequencyDays)
                .lifetimeValue(totalRevenue)
                .revenueThisMonth(revenueThisMonth)
                .revenueLastMonth(revenueLastMonth)
                .revenueGrowthPercent(revenueGrowth)
                .ordersThisMonth(0)
                .ordersLastMonth(0)
                .topProducts(new ArrayList<>())
                .preferredPaymentTerms(customer.getPaymentTerms())
                .healthScore(calculateHealthScore(customer))
                .build();
    }

    @Transactional(readOnly = true)
    public CustomerHealthScoreDto getHealthScore(Long customerId) {
        Customer customer = customerRepository.findById(customerId)
                .orElseThrow(() -> new RuntimeException("Customer not found"));

        return calculateHealthScore(customer);
    }

    private CustomerHealthScoreDto calculateHealthScore(Customer customer) {
        // Calculate individual factors (0-100 scale)
        int orderFrequency = calculateOrderFrequencyScore(customer);
        int revenueGrowth = calculateRevenueGrowthScore(customer);
        int paymentPunctuality = 100; // Default to perfect score (implement actual logic)
        int engagementLevel = calculateEngagementScore(customer);
        int recency = calculateRecencyScore(customer);

        // Weighted average
        int totalScore = (int) ((orderFrequency * 0.25) + 
                               (revenueGrowth * 0.25) + 
                               (paymentPunctuality * 0.20) + 
                               (engagementLevel * 0.15) + 
                               (recency * 0.15));

        CustomerHealthScoreDto.FactorsDto factors = CustomerHealthScoreDto.FactorsDto.builder()
                .orderFrequency(orderFrequency)
                .revenueGrowth(revenueGrowth)
                .paymentPunctuality(paymentPunctuality)
                .engagementLevel(engagementLevel)
                .recency(recency)
                .build();

        List<String> recommendations = generateRecommendations(totalScore, factors);

        return CustomerHealthScoreDto.builder()
                .customerId(customer.getId())
                .score(totalScore)
                .status(CustomerHealthScoreDto.calculateStatus(totalScore))
                .factors(factors)
                .lastCalculated(LocalDateTime.now())
                .recommendations(recommendations)
                .build();
    }

    private int calculateOrderFrequencyScore(Customer customer) {
        Integer totalOrders = customer.getTotalOrders();
        if (totalOrders == null || totalOrders == 0) return 0;
        
        // More orders = better score
        if (totalOrders >= 50) return 100;
        if (totalOrders >= 25) return 80;
        if (totalOrders >= 10) return 60;
        if (totalOrders >= 5) return 40;
        return 20;
    }

    private int calculateRevenueGrowthScore(Customer customer) {
        // Simplified - should compare month-over-month
        BigDecimal totalRevenue = customer.getTotalRevenue();
        if (totalRevenue == null || totalRevenue.compareTo(BigDecimal.ZERO) == 0) return 0;
        
        // More revenue = better score
        if (totalRevenue.compareTo(BigDecimal.valueOf(100000)) >= 0) return 100;
        if (totalRevenue.compareTo(BigDecimal.valueOf(50000)) >= 0) return 80;
        if (totalRevenue.compareTo(BigDecimal.valueOf(20000)) >= 0) return 60;
        if (totalRevenue.compareTo(BigDecimal.valueOf(10000)) >= 0) return 40;
        return 20;
    }

    private int calculateEngagementScore(Customer customer) {
        long activityCount = activityRepository.countByCustomerId(customer.getId());
        
        if (activityCount >= 20) return 100;
        if (activityCount >= 10) return 80;
        if (activityCount >= 5) return 60;
        if (activityCount >= 2) return 40;
        return 20;
    }

    private int calculateRecencyScore(Customer customer) {
        LocalDate lastOrderDate = customer.getLastOrderDate();
        if (lastOrderDate == null) return 0;
        
        long daysSinceLastOrder = ChronoUnit.DAYS.between(lastOrderDate, LocalDate.now());
        
        if (daysSinceLastOrder <= 7) return 100;
        if (daysSinceLastOrder <= 30) return 80;
        if (daysSinceLastOrder <= 60) return 60;
        if (daysSinceLastOrder <= 90) return 40;
        return 20;
    }

    private List<String> generateRecommendations(int score, CustomerHealthScoreDto.FactorsDto factors) {
        List<String> recommendations = new ArrayList<>();
        
        if (factors.getRecency() < 60) {
            recommendations.add("Customer hasn't ordered recently - consider reaching out");
        }
        if (factors.getOrderFrequency() < 50) {
            recommendations.add("Low order frequency - offer loyalty incentives");
        }
        if (factors.getRevenueGrowth() < 50) {
            recommendations.add("Revenue potential - suggest upselling opportunities");
        }
        if (factors.getEngagementLevel() < 50) {
            recommendations.add("Limited engagement - schedule check-in call");
        }
        if (score < 40) {
            recommendations.add("At-risk customer - immediate attention required");
        }
        
        return recommendations;
    }
}
