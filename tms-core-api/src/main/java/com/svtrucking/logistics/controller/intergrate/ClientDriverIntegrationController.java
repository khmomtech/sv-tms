package com.svtrucking.logistics.controller.intergrate;

import com.svtrucking.logistics.dto.DriverDto;
import com.svtrucking.logistics.enums.DriverStatus;
import com.svtrucking.logistics.enums.VehicleType;
import com.svtrucking.logistics.service.DriverService;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/integrations/drivers")
@RequiredArgsConstructor
public class ClientDriverIntegrationController {

  private final DriverService driverService;

  /**
   * 🔍 Search drivers by filters Example: GET
   * /api/v1/integrations/drivers/search?keyword=Ben&truckType=TRUCK&status=ONLINE&licensePlate=PP-001
   */
  @GetMapping("/search")
  public ResponseEntity<List<DriverDto>> searchDrivers(
      @RequestParam(required = false) String keyword,
      @RequestParam(required = false) VehicleType truckType,
      @RequestParam(required = false) DriverStatus status,
      @RequestParam(required = false) String zone,
      @RequestParam(required = false) String licensePlate,
      @RequestParam(defaultValue = "false") boolean includeLocationHistory) {

    List<DriverDto> results =
        driverService.searchDrivers(
            keyword, truckType, status, zone, licensePlate, includeLocationHistory);
    return ResponseEntity.ok(results);
  }

  /**
   * 📌 Get driver detail by ID Example: GET
   * /api/v1/integrations/drivers/1?includeLocationHistory=true
   */
  @GetMapping("/{id}")
  public ResponseEntity<DriverDto> getDriverById(
      @PathVariable Long id, @RequestParam(defaultValue = "false") boolean includeLocationHistory) {
    DriverDto driver = driverService.getDriverById(id, includeLocationHistory);
    return ResponseEntity.ok(driver);
  }
}
