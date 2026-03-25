package com.svtrucking.logistics.auth.controller;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.dto.DeviceRegisterDto;
import com.svtrucking.logistics.dto.requests.DeviceApprovalRequest;
import com.svtrucking.logistics.enums.DeviceStatus;
import com.svtrucking.logistics.service.DeviceRegistrationService;
import com.svtrucking.logistics.service.LocalizedMessageService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnWebApplication;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/driver/device")
@RequiredArgsConstructor
@Slf4j
@ConditionalOnWebApplication(type = ConditionalOnWebApplication.Type.SERVLET)
public class DeviceAuthMobileController {

  private final DeviceRegistrationService deviceService;
  private final LocalizedMessageService messages;

  @PostMapping("/register")
  public ApiResponse<DeviceStatus> registerDevice(@RequestBody DeviceRegisterDto dto) {
    DeviceStatus status = deviceService.registerOrVerifyDevice(dto);
    return new ApiResponse<>(true, messages.get("api.device.registered"), status);
  }

  @PostMapping("/request-approval")
  public ResponseEntity<ApiResponse<Void>> requestApproval(
      @Valid @RequestBody DeviceApprovalRequest request) {
    try {
      deviceService.requestApprovalViaLogin(request);
      return ResponseEntity.ok(
          new ApiResponse<>(true, messages.get("api.device.approval_requested"), null));
    } catch (IllegalArgumentException ex) {
      log.warn("Validation error: {}", ex.getMessage());
      return ResponseEntity.badRequest()
          .body(
              new ApiResponse<>(
                  false, messages.get("api.device.validation_failed", ex.getMessage()), null));
    } catch (org.springframework.security.authentication.BadCredentialsException ex) {
      log.warn("Authentication failed: {}", ex.getMessage());
      return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
          .body(new ApiResponse<>(false, messages.get("api.device.invalid_credentials"), null));
    } catch (RuntimeException ex) {
      log.error("Unexpected error during device approval", ex);
      return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
          .body(new ApiResponse<>(false, messages.get("api.device.server_error"), null));
    }
  }
}
