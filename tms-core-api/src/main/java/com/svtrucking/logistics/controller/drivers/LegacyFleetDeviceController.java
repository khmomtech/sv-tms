package com.svtrucking.logistics.controller.drivers;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.dto.requests.DeviceTokenRequest;
import com.svtrucking.logistics.service.DriverService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

/**
 * Legacy compatibility controller to support older frontend paths under `/fleet/drivers`.
 */
@RestController
@RequestMapping("/fleet/drivers")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
@Slf4j
public class LegacyFleetDeviceController {

  private final DriverService driverService;

  @PostMapping("/devices")
  public ResponseEntity<ApiResponse<String>> updateDeviceToken(@RequestBody DeviceTokenRequest req) {
    try {
      driverService.updateDeviceToken(req.getDriverId(), req.getDeviceToken());
      return ResponseEntity.ok(ApiResponse.success("Token updated"));
    } catch (Exception e) {
      log.error("Failed to update device token for driver {}: {}", req.getDriverId(), e.getMessage(), e);
      return ResponseEntity.badRequest().body(ApiResponse.fail("Failed to update device token: " + e.getMessage()));
    }
  }

  @GetMapping("/devices/{driverId}")
  public ResponseEntity<ApiResponse<String>> getDeviceToken(@PathVariable Long driverId) {
    try {
      String token = driverService.getDeviceToken(driverId);
      return ResponseEntity.ok(ApiResponse.ok("Token fetched", token));
    } catch (Exception e) {
      log.error("Failed to fetch device token for driver {}: {}", driverId, e.getMessage(), e);
      return ResponseEntity.status(404).body(ApiResponse.fail("Driver not found"));
    }
  }
}
