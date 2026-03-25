package com.svtrucking.logistics.safety.api.admin;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.dto.SafetyCheckDto;
import com.svtrucking.logistics.enums.DailySafetyCheckStatus;
import com.svtrucking.logistics.enums.SafetyRiskLevel;
import com.svtrucking.logistics.infrastructure.security.AuthenticatedUserUtil;
import com.svtrucking.logistics.safety.service.SafetyCheckReadPlatformService;
import com.svtrucking.logistics.safety.service.SafetyCheckWritePlatformService;
import java.time.LocalDate;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/admin/safety-checks")
@RequiredArgsConstructor
public class AdminSafetyCheckController {

  private final SafetyCheckReadPlatformService safetyChecksRead;
  private final SafetyCheckWritePlatformService safetyChecksWrite;
  private final AuthenticatedUserUtil authUtil;

  public record ApproveRequest(SafetyRiskLevel riskOverride) {}

  public record RejectRequest(String reason) {}

  @GetMapping
  @PreAuthorize("hasAnyAuthority('ROLE_ADMIN','ROLE_SUPERADMIN','ROLE_SAFETY','all_functions')")
  public ResponseEntity<ApiResponse<Page<SafetyCheckDto>>> list(
      @RequestParam(required = false) String search,
      @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
      @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to,
      @RequestParam(required = false) DailySafetyCheckStatus status,
      @RequestParam(required = false) SafetyRiskLevel risk,
      @RequestParam(defaultValue = "0") int page,
      @RequestParam(defaultValue = "20") int size) {
    Pageable pageable = PageRequest.of(page, size, Sort.by("checkDate").descending());
    Page<SafetyCheckDto> data =
        safetyChecksRead.getAdminList(search, from, to, status, risk, pageable);
    return ResponseEntity.ok(new ApiResponse<>(true, "Safety checks", data));
  }

  @GetMapping("/export/csv")
  @PreAuthorize("hasAnyAuthority('ROLE_ADMIN','ROLE_SUPERADMIN','ROLE_SAFETY','all_functions')")
  public ResponseEntity<byte[]> exportCsv(
      @RequestParam(required = false) String search,
      @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
      @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to,
      @RequestParam(required = false) DailySafetyCheckStatus status,
      @RequestParam(required = false) SafetyRiskLevel risk) {
    byte[] csv = safetyChecksRead.exportAdminCsv(search, from, to, status, risk);
    return ResponseEntity.ok()
        .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"safety_checks.csv\"")
        .contentType(MediaType.parseMediaType("text/csv"))
        .body(csv);
  }

  @GetMapping("/export/xlsx")
  @PreAuthorize("hasAnyAuthority('ROLE_ADMIN','ROLE_SUPERADMIN','ROLE_SAFETY','all_functions')")
  public ResponseEntity<byte[]> exportExcel(
      @RequestParam(required = false) String search,
      @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
      @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to,
      @RequestParam(required = false) DailySafetyCheckStatus status,
      @RequestParam(required = false) SafetyRiskLevel risk) {
    byte[] excel = safetyChecksRead.exportAdminExcel(search, from, to, status, risk);
    return ResponseEntity.ok()
        .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"safety_checks.xlsx\"")
        .contentType(
            MediaType.parseMediaType(
                "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"))
        .body(excel);
  }

  @GetMapping("/{id}")
  @PreAuthorize("hasAnyAuthority('ROLE_ADMIN','ROLE_SUPERADMIN','ROLE_SAFETY','all_functions')")
  public ResponseEntity<ApiResponse<SafetyCheckDto>> getById(@PathVariable Long id) {
    SafetyCheckDto dto = safetyChecksRead.getAdminDetail(id);
    return ResponseEntity.ok(new ApiResponse<>(true, "Safety check detail", dto));
  }

  @PostMapping("/{id}/approve")
  @PreAuthorize("hasAnyAuthority('ROLE_ADMIN','ROLE_SUPERADMIN','ROLE_SAFETY','all_functions')")
  public ResponseEntity<ApiResponse<SafetyCheckDto>> approve(
      @PathVariable Long id, @RequestBody(required = false) ApproveRequest body) {
    Long actorId = authUtil.getCurrentUserId();
    String actorRole = authUtil.getCurrentUser().getRoles().stream().findFirst().map(r -> r.getName().name()).orElse(null);
    SafetyRiskLevel override = body != null ? body.riskOverride() : null;
    SafetyCheckDto dto = safetyChecksWrite.approve(id, actorId, actorRole, override);
    return ResponseEntity.ok(new ApiResponse<>(true, "Approved", dto));
  }

  @PostMapping("/{id}/reject")
  @PreAuthorize("hasAnyAuthority('ROLE_ADMIN','ROLE_SUPERADMIN','ROLE_SAFETY','all_functions')")
  public ResponseEntity<ApiResponse<SafetyCheckDto>> reject(
      @PathVariable Long id, @RequestBody RejectRequest body) {
    Long actorId = authUtil.getCurrentUserId();
    String actorRole = authUtil.getCurrentUser().getRoles().stream().findFirst().map(r -> r.getName().name()).orElse(null);
    SafetyCheckDto dto = safetyChecksWrite.reject(id, actorId, actorRole, body != null ? body.reason() : null);
    return ResponseEntity.ok(new ApiResponse<>(true, "Rejected", dto));
  }
}
