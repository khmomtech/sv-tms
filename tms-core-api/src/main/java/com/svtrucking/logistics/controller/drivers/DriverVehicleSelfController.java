package com.svtrucking.logistics.controller.drivers;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.exception.DriverNotFoundException;
import com.svtrucking.logistics.model.Driver;
import com.svtrucking.logistics.model.Vehicle;
import com.svtrucking.logistics.model.VehicleDriver;
import com.svtrucking.logistics.repository.DriverRepository;
import com.svtrucking.logistics.repository.VehicleDriverRepository;
import com.svtrucking.logistics.security.AuthenticatedUserUtil;
import java.util.LinkedHashMap;
import java.util.Map;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequestMapping("/api/driver")
@RequiredArgsConstructor
@Slf4j
public class DriverVehicleSelfController {

  private final AuthenticatedUserUtil authUtil;
  private final DriverRepository driverRepository;
  private final VehicleDriverRepository vehicleDriverRepository;

  @GetMapping({"/my-vehicle", "/me/vehicle"})
  @PreAuthorize("hasAnyAuthority('ROLE_DRIVER','ROLE_ADMIN','ROLE_SUPERADMIN')")
  public ResponseEntity<ApiResponse<Map<String, Object>>> getMyVehicle() {
    try {
      Long driverId = currentDriverIdOrThrow();
      Driver driver = findDriverOrThrow(driverId);
      VehicleDriver assignment = vehicleDriverRepository.findActiveByDriverId(driverId).orElse(null);
      Vehicle vehicle = assignment != null ? assignment.getVehicle() : driver.getCurrentAssignedVehicle();
      if (vehicle == null) {
        return ResponseEntity.ok(ApiResponse.success("No vehicle assigned", null));
      }

      Map<String, Object> payload = new LinkedHashMap<>();
      payload.put("id", vehicle.getId());
      payload.put("licensePlate", vehicle.getLicensePlate());
      payload.put("plate", vehicle.getLicensePlate());
      payload.put("vehiclePlate", vehicle.getLicensePlate());
      payload.put("type", vehicle.getType());
      payload.put("status", vehicle.getStatus());
      payload.put("model", vehicle.getModel());
      payload.put("manufacturer", vehicle.getManufacturer());
      payload.put("vin", vehicle.getVin());
      payload.put("yearMade", vehicle.getYearMade());
      payload.put("truckSize", vehicle.getTruckSize());
      payload.put("fuelConsumption", vehicle.getFuelConsumption());
      return ResponseEntity.ok(ApiResponse.success("Vehicle retrieved", payload));
    } catch (DriverNotFoundException e) {
      log.warn("Current driver vehicle lookup target not found: {}", e.getMessage());
      return ResponseEntity.status(HttpStatus.NOT_FOUND)
          .body(ApiResponse.fail("Driver profile not found"));
    } catch (ResponseStatusException e) {
      log.warn("Current driver vehicle lookup rejected: {}", e.getReason());
      return ResponseEntity.status(e.getStatusCode())
          .body(ApiResponse.fail(e.getReason() != null ? e.getReason() : "Forbidden"));
    } catch (Exception e) {
      log.error("Failed to load current driver vehicle: {}", e.getMessage(), e);
      return ResponseEntity.badRequest()
          .body(ApiResponse.fail("Failed to load vehicle"));
    }
  }

  private Long currentDriverIdOrThrow() {
    try {
      return authUtil.getCurrentDriverId();
    } catch (Exception ex) {
      throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Current user is not linked to a driver");
    }
  }

  private Driver findDriverOrThrow(Long driverId) {
    return driverRepository.findById(driverId)
        .orElseThrow(() -> new DriverNotFoundException("Driver not found: " + driverId));
  }
}
