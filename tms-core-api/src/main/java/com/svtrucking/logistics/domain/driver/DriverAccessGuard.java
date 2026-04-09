package com.svtrucking.logistics.domain.driver;

import com.svtrucking.logistics.security.AuthenticatedUserUtil;
import com.svtrucking.logistics.security.AuthorizationService;
import com.svtrucking.logistics.security.PermissionNames;
import java.util.Objects;
import java.util.Optional;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Component;

/** Performs coarse and row-level access control around driver resources. */
@Component
@RequiredArgsConstructor
public class DriverAccessGuard {

  private final AuthorizationService authorizationService;
  private final AuthenticatedUserUtil authenticatedUserUtil;
  public void assertCanViewDriver(Long driverId) {
    if (authorizationService.hasPermission(PermissionNames.DRIVER_VIEW_ALL)
        || authorizationService.hasPermission(PermissionNames.DRIVER_MANAGE)) {
      return;
    }
    Optional<Long> currentDriverId = currentDriverId();
    if (currentDriverId.isPresent() && Objects.equals(currentDriverId.get(), driverId)) {
      return;
    }
    throw new AccessDeniedException("You are not allowed to view this driver");
  }

  public void assertCanManageDrivers() {
    if (!authorizationService.hasPermission(PermissionNames.DRIVER_MANAGE)) {
      throw new AccessDeniedException("You are not allowed to manage drivers");
    }
  }

  public void assertCanViewAllDrivers() {
    if (authorizationService.hasPermission(PermissionNames.DRIVER_VIEW_ALL)
        || authorizationService.hasPermission(PermissionNames.DRIVER_MANAGE)) {
      return;
    }
    throw new AccessDeniedException("You are not allowed to view driver lists");
  }

  public void assertCanManageAccount(Long driverId) {
    if (authorizationService.hasPermission(PermissionNames.DRIVER_ACCOUNT_MANAGE)
        || authorizationService.hasPermission(PermissionNames.DRIVER_MANAGE)) {
      return;
    }
    Optional<Long> currentDriverId = currentDriverId();
    if (currentDriverId.isPresent() && Objects.equals(currentDriverId.get(), driverId)) {
      return;
    }
    throw new AccessDeniedException("You are not allowed to manage this driver account");
  }

  private Optional<Long> currentDriverId() {
    try {
      return Optional.ofNullable(authenticatedUserUtil.getCurrentDriverId());
    } catch (RuntimeException ex) {
      return Optional.empty();
    }
  }
}
