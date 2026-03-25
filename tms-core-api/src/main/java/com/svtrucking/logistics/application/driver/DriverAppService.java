package com.svtrucking.logistics.application.driver;

import com.svtrucking.logistics.domain.driver.DriverAccessGuard;
import com.svtrucking.logistics.dto.DriverDto;
import com.svtrucking.logistics.dto.requests.DriverCreateRequest;
import com.svtrucking.logistics.dto.requests.DriverUpdateRequest;
import com.svtrucking.logistics.model.Driver;
import com.svtrucking.logistics.service.DriverService;
import com.svtrucking.logistics.support.audit.AuditedAction;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Application layer for driver operations. Applies access control, audit logging and delegates to
 * the underlying domain/service layer.
 */
@Service
@RequiredArgsConstructor
@Transactional
public class DriverAppService {

  private final DriverService driverService;
  private final DriverAccessGuard driverAccessGuard;

  @AuditedAction("driver.create")
  public DriverDto createDriver(DriverCreateRequest request) {
    driverAccessGuard.assertCanManageDrivers();
    Driver saved = driverService.createDriverFromRequest(request);
    return DriverDto.fromEntity(saved, false, false);
  }

  @Transactional(readOnly = true)
  public Page<DriverDto> listDrivers(Pageable pageable) {
    driverAccessGuard.assertCanViewAllDrivers();
    return driverService.getAllListDrivers(pageable);
  }

  @Transactional(readOnly = true)
  public DriverDto getDriver(Long id) {
    driverAccessGuard.assertCanViewDriver(id);
    Driver driver = driverService.getDriverById(id);
    return DriverDto.fromEntity(driver, true, true);
  }

  @AuditedAction("driver.update")
  public DriverDto updateDriver(Long id, DriverUpdateRequest request) {
    driverAccessGuard.assertCanManageDrivers();
    Driver updated = driverService.updateDriverFromRequest(id, request);
    return DriverDto.fromEntity(updated, false, false);
  }

  @AuditedAction("driver.delete")
  public void deleteDriver(Long id) {
    driverAccessGuard.assertCanManageDrivers();
    driverService.deleteDriver(id);
  }

  @Transactional(readOnly = true)
  public List<DriverDto> quickSearch(String query) {
    driverAccessGuard.assertCanViewAllDrivers();
    return driverService.searchDrivers(query);
  }
}
