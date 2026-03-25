package com.svtrucking.logistics.identity.api;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.dto.DeviceRegisterDto;
import com.svtrucking.logistics.enums.DeviceStatus;
import com.svtrucking.logistics.identity.device.DeviceRegistrationService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Public endpoints used by driver apps to register a device and request approval.
 *
 * <p>These are intentionally permit-all at the filter chain because the driver may not have a
 * usable token until the device is approved.
 */
@RestController
@RequestMapping("/api/driver/device")
@RequiredArgsConstructor
public class DriverDeviceController {

  private final DeviceRegistrationService deviceRegistrationService;

  @PostMapping("/register")
  public ResponseEntity<ApiResponse<DeviceStatus>> register(@Valid @RequestBody DeviceRegisterDto body) {
    DeviceStatus status = deviceRegistrationService.registerOrVerifyDevice(body);
    return ResponseEntity.ok(ApiResponse.success("Device registered", status));
  }

  @PostMapping("/request-approval")
  public ResponseEntity<ApiResponse<String>> requestApproval(@Valid @RequestBody DeviceRegisterDto body) {
    deviceRegistrationService.requestDeviceApproval(body);
    return ResponseEntity.ok(ApiResponse.success("Approval requested"));
  }
}

