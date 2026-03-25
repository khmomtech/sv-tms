package com.svtrucking.logistics.controller.drivers;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.model.Driver;
import com.svtrucking.logistics.model.VehicleDriver;
import com.svtrucking.logistics.repository.DriverRepository;
import com.svtrucking.logistics.repository.VehicleDriverRepository;
import com.svtrucking.logistics.security.AuthenticatedUserUtil;
import java.util.List;
import java.util.Optional;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/driver/portal")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
public class DriverPortalController {

  private final AuthenticatedUserUtil authUtil;
  private final DriverRepository driverRepository;
  private final VehicleDriverRepository vehicleDriverRepository;

  public record DriverOption(Long id, String name, String phone) {}

  public record VehicleOption(Long id, String plate) {}

  public record DriverPortalContext(DriverOption driver, List<VehicleOption> vehicles) {}

  @GetMapping("/context")
  @PreAuthorize("hasAnyAuthority('ROLE_DRIVER')")
  public ResponseEntity<ApiResponse<DriverPortalContext>> context() {
    Long driverId = authUtil.getCurrentDriverId();
    Driver driver =
        driverRepository
            .findById(driverId)
            .orElseThrow(() -> new RuntimeException("Driver not found"));

    String name =
        driver.getName() != null && !driver.getName().isBlank()
            ? driver.getName()
            : String.join(
                " ",
                Optional.ofNullable(driver.getFirstName()).orElse(""),
                Optional.ofNullable(driver.getLastName()).orElse(""))
                .trim();
    DriverOption driverOption = new DriverOption(driver.getId(), name, driver.getPhone());

    List<VehicleOption> vehicles =
        vehicleDriverRepository.findActiveByDriverId(driverId).stream()
            .map(VehicleDriver::getVehicle)
            .filter(v -> v != null)
            .map(v -> new VehicleOption(v.getId(), v.getLicensePlate()))
            .toList();

    DriverPortalContext context = new DriverPortalContext(driverOption, vehicles);
    return ResponseEntity.ok(ApiResponse.success("Driver portal context", context));
  }
}
