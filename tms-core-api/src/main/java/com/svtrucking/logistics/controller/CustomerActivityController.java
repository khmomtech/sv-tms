package com.svtrucking.logistics.controller;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.dto.CustomerActivityDto;
import com.svtrucking.logistics.dto.CustomerHealthScoreDto;
import com.svtrucking.logistics.dto.CustomerInsightsDto;
import com.svtrucking.logistics.enums.ActivityType;
import com.svtrucking.logistics.service.CustomerActivityService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

@RestController
@RequestMapping("/api/admin/customers")
@RequiredArgsConstructor
@Tag(name = "Customer Activities", description = "Customer activity timeline and insights")
@PreAuthorize("hasAnyRole('ADMIN', 'DISPATCHER')")
public class CustomerActivityController {

    private final CustomerActivityService activityService;

    @GetMapping("/{customerId}/activities")
    @Operation(summary = "Get customer activity timeline")
    public ResponseEntity<ApiResponse<Page<CustomerActivityDto>>> getActivities(
            @PathVariable Long customerId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        
        Page<CustomerActivityDto> activities = activityService.getActivities(
                customerId, 
                PageRequest.of(page, size)
        );
        return ResponseEntity.ok(ApiResponse.success("Customer activities retrieved successfully", activities));
    }

    @PostMapping("/{customerId}/activities")
    @Operation(summary = "Create customer activity")
    public ResponseEntity<ApiResponse<CustomerActivityDto>> createActivity(
            @PathVariable Long customerId,
            @Valid @RequestBody CreateActivityRequest request) {
        
        CustomerActivityDto activity = activityService.createActivity(
                customerId,
                request.getType(),
                request.getTitle(),
                request.getDescription(),
                request.getMetadata(),
                request.getRelatedEntityId(),
                request.getRelatedEntityType()
        );
        return ResponseEntity.ok(ApiResponse.success("Activity created successfully", activity));
    }

    @DeleteMapping("/{customerId}/activities/{activityId}")
    @Operation(summary = "Delete customer activity")
    public ResponseEntity<ApiResponse<Void>> deleteActivity(
            @PathVariable Long customerId,
            @PathVariable Long activityId) {
        
        activityService.deleteActivity(customerId, activityId);
        return ResponseEntity.ok(ApiResponse.success(null));
    }

    @GetMapping("/{customerId}/health-score")
    @Operation(summary = "Get customer health score")
    public ResponseEntity<ApiResponse<CustomerHealthScoreDto>> getHealthScore(
            @PathVariable Long customerId) {
        
        CustomerHealthScoreDto healthScore = activityService.getHealthScore(customerId);
        return ResponseEntity.ok(ApiResponse.success("Health score retrieved successfully", healthScore));
    }

    @GetMapping("/{customerId}/insights")
    @Operation(summary = "Get customer insights and analytics")
    public ResponseEntity<ApiResponse<CustomerInsightsDto>> getInsights(
            @PathVariable Long customerId) {
        
        CustomerInsightsDto insights = activityService.getInsights(customerId);
        return ResponseEntity.ok(ApiResponse.success("Customer insights retrieved successfully", insights));
    }

    @Data
    public static class CreateActivityRequest {
        @NotNull
        private ActivityType type;

        @NotBlank
        private String title;

        private String description;
        private String metadata; // JSON string
        private Long relatedEntityId;
        private String relatedEntityType;
    }
}
