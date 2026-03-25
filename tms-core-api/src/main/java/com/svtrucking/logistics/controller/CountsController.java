package com.svtrucking.logistics.controller;

import com.svtrucking.logistics.repository.DriverRepository;
import com.svtrucking.logistics.repository.VehicleRepository;
import com.svtrucking.logistics.repository.MaintenanceTaskRepository;
import java.util.Map;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Lightweight endpoints returning simple counts used by the admin UI sidebar.
 * These are intentionally small and return {"count": <number>} so the frontend
 * can consume them without dealing with ApiResponse wrappers.
 */
@RestController
@CrossOrigin(origins = "*")
public class CountsController {

  private final DriverRepository driverRepository;
  private final VehicleRepository vehicleRepository;
  private final MaintenanceTaskRepository maintenanceTaskRepository;

  public CountsController(
      DriverRepository driverRepository,
      VehicleRepository vehicleRepository,
      MaintenanceTaskRepository maintenanceTaskRepository) {
    this.driverRepository = driverRepository;
    this.vehicleRepository = vehicleRepository;
    this.maintenanceTaskRepository = maintenanceTaskRepository;
  }

  @GetMapping({"/api/drivers/count", "/api/public/counts/drivers"})
  public ResponseEntity<Map<String, Long>> driversCount() {
    long c = driverRepository.count();
    return ResponseEntity.ok(Map.of("count", c));
  }

  @GetMapping({"/api/vehicles/count", "/api/public/counts/vehicles"})
  public ResponseEntity<Map<String, Long>> vehiclesCount() {
    long c = vehicleRepository.count();
    return ResponseEntity.ok(Map.of("count", c));
  }

  @GetMapping({"/api/maintenance/work-orders/count", "/api/public/counts/work-orders"})
  public ResponseEntity<Map<String, Long>> workOrdersCount() {
    long c = maintenanceTaskRepository.count();
    return ResponseEntity.ok(Map.of("count", c));
  }
}
