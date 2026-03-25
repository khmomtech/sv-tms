package com.svtrucking.logistics.safety.api.driver;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.dto.SafetyCheckAttachmentDto;
import com.svtrucking.logistics.dto.SafetyCheckDto;
import com.svtrucking.logistics.infrastructure.security.AuthenticatedUserUtil;
import com.svtrucking.logistics.safety.service.SafetyCheckReadPlatformService;
import com.svtrucking.logistics.safety.service.SafetyCheckWritePlatformService;
import java.time.LocalDate;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/driver/safety-checks")
@RequiredArgsConstructor
public class DriverSafetyCheckController {

  private final SafetyCheckReadPlatformService safetyChecksRead;
  private final SafetyCheckWritePlatformService safetyChecksWrite;
  private final AuthenticatedUserUtil authUtil;

  @GetMapping("/today")
  @PreAuthorize("hasAnyAuthority('ROLE_DRIVER','ROLE_ADMIN','ROLE_SUPERADMIN')")
  public ResponseEntity<ApiResponse<SafetyCheckDto>> getToday(@RequestParam Long vehicleId) {
    Long driverId = authUtil.getCurrentDriverId();
    SafetyCheckDto dto = safetyChecksRead.getToday(driverId, vehicleId);
    return ResponseEntity.ok(new ApiResponse<>(true, "Fetched today safety check", dto));
  }

  @PostMapping("/draft")
  @PreAuthorize("hasAnyAuthority('ROLE_DRIVER','ROLE_ADMIN','ROLE_SUPERADMIN')")
  public ResponseEntity<ApiResponse<SafetyCheckDto>> saveDraft(
      @RequestBody SafetyCheckDto payload) {
    Long driverId = authUtil.getCurrentDriverId();
    Long actorId = authUtil.getCurrentUserId();
    String actorRole = authUtil.getCurrentUser().getRoles().stream().findFirst().map(r -> r.getName().name()).orElse(null);

    SafetyCheckDto dto = safetyChecksWrite.saveDraft(payload, driverId, actorId, actorRole);
    return ResponseEntity.ok(new ApiResponse<>(true, "Draft saved", dto));
  }

  @PostMapping(
      value = "/{id}/attachments",
      consumes = MediaType.MULTIPART_FORM_DATA_VALUE,
      produces = MediaType.APPLICATION_JSON_VALUE)
  @PreAuthorize("hasAnyAuthority('ROLE_DRIVER','ROLE_ADMIN','ROLE_SUPERADMIN')")
  public ResponseEntity<ApiResponse<SafetyCheckAttachmentDto>> addAttachment(
      @PathVariable Long id,
      @RequestParam("file") MultipartFile file,
      @RequestParam(name = "itemId", required = false) Long itemId) {
    Long driverId = authUtil.getCurrentDriverId();
    Long actorId = authUtil.getCurrentUserId();
    String actorRole = authUtil.getCurrentUser().getRoles().stream().findFirst().map(r -> r.getName().name()).orElse(null);

    SafetyCheckAttachmentDto dto =
        safetyChecksWrite.addAttachment(id, itemId, file, actorId, actorRole, driverId);
    return ResponseEntity.ok(new ApiResponse<>(true, "Attachment uploaded", dto));
  }

  @PostMapping("/{id}/submit")
  @PreAuthorize("hasAnyAuthority('ROLE_DRIVER','ROLE_ADMIN','ROLE_SUPERADMIN')")
  public ResponseEntity<ApiResponse<SafetyCheckDto>> submit(@PathVariable Long id) {
    Long driverId = authUtil.getCurrentDriverId();
    Long actorId = authUtil.getCurrentUserId();
    String actorRole = authUtil.getCurrentUser().getRoles().stream().findFirst().map(r -> r.getName().name()).orElse(null);

    SafetyCheckDto dto = safetyChecksWrite.submit(id, driverId, actorId, actorRole);
    return ResponseEntity.ok(new ApiResponse<>(true, "Submitted", dto));
  }

  @GetMapping
  @PreAuthorize("hasAnyAuthority('ROLE_DRIVER','ROLE_ADMIN','ROLE_SUPERADMIN')")
  public ResponseEntity<ApiResponse<List<SafetyCheckDto>>> getHistory(
      @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
      @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
    Long driverId = authUtil.getCurrentDriverId();
    List<SafetyCheckDto> list = safetyChecksRead.getHistory(driverId, from, to);
    return ResponseEntity.ok(new ApiResponse<>(true, "History", list));
  }
}
