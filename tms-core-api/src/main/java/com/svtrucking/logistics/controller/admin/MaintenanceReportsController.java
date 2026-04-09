package com.svtrucking.logistics.controller.admin;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.security.PermissionNames;
import com.svtrucking.logistics.service.MaintenanceReportingService;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/admin/maintenance")
@RequiredArgsConstructor
public class MaintenanceReportsController {

  private final MaintenanceReportingService reportingService;

  @GetMapping("/dashboard")
  @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.MAINTENANCE_READ + "')")
  public ResponseEntity<ApiResponse<Map<String, Object>>> dashboard() {
    return ResponseEntity.ok(
        new ApiResponse<>(true, "Maintenance dashboard", reportingService.getDashboardKpis(), null, Instant.now()));
  }

  @GetMapping("/vehicles/{vehicleId}/history")
  @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.MAINTENANCE_RECORD_READ + "')")
  public ResponseEntity<ApiResponse<Map<String, Object>>> vehicleHistory(
      @PathVariable Long vehicleId, Pageable pageable) {
    return ResponseEntity.ok(
        new ApiResponse<>(true, "Vehicle maintenance history", reportingService.getVehicleHistory(vehicleId, pageable), null, Instant.now()));
  }

  @GetMapping("/reports/cost-per-vehicle")
  @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.REPORT_READ + "')")
  public ResponseEntity<ApiResponse<List<Map<String, Object>>>> costPerVehicle(
      @RequestParam(defaultValue = "20") int limit) {
    return ResponseEntity.ok(
        new ApiResponse<>(true, "Cost per vehicle", reportingService.getCostPerVehicle(limit), null, Instant.now()));
  }
}

