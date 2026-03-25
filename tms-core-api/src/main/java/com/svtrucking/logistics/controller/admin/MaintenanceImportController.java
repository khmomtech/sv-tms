package com.svtrucking.logistics.controller.admin;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.security.PermissionNames;
import com.svtrucking.logistics.service.MaintenanceImportService;
import java.time.Instant;
import java.util.Map;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/admin/maintenance/import")
@RequiredArgsConstructor
public class MaintenanceImportController {

  private final MaintenanceImportService importService;

  @PostMapping(value = "/excel", consumes = "multipart/form-data")
  @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.MAINTENANCE_READ + "')")
  public ResponseEntity<ApiResponse<Map<String, Object>>> importExcel(
      @RequestParam("file") MultipartFile file, Authentication authentication) {
    String username = null;
    if (authentication != null && authentication.getPrincipal() instanceof org.springframework.security.core.userdetails.UserDetails ud) {
      username = ud.getUsername();
    } else if (authentication != null && authentication.getPrincipal() instanceof String s) {
      username = s;
    }
    Map<String, Object> res = importService.importWorkbook(file, username);
    return ResponseEntity.ok(new ApiResponse<>(true, "Maintenance import completed", res, null, Instant.now()));
  }
}

