package com.svtrucking.logistics.controller;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.dto.SafetyEligibilityDto;
import com.svtrucking.logistics.service.SafetyCheckService;
import java.time.LocalDate;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/dispatch")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
public class DispatchSafetyEligibilityController {

  private final SafetyCheckService safetyCheckService;

  @GetMapping("/safety-eligibility")
  @PreAuthorize(
      "hasAnyAuthority('ROLE_ADMIN','ROLE_SUPERADMIN','ROLE_DISPATCH_MONITOR','ROLE_SAFETY','ROLE_DRIVER','all_functions')")
  public ResponseEntity<ApiResponse<SafetyEligibilityDto>> eligibility(
      @RequestParam Long driverId,
      @RequestParam Long vehicleId,
      @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
    SafetyEligibilityDto dto = safetyCheckService.checkEligibility(driverId, vehicleId, date);
    return ResponseEntity.ok(new ApiResponse<>(true, "Safety eligibility", dto));
  }
}
