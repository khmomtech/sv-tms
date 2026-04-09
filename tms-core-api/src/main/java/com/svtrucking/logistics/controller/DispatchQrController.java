package com.svtrucking.logistics.controller;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.service.DispatchQrService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/dispatches")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class DispatchQrController {

  private static final String QR_READ_AUTH =
      "hasAnyAuthority('ROLE_SAFETY','ROLE_LOADING','ROLE_DISPATCH_MONITOR','ROLE_ADMIN','ROLE_SUPERADMIN','dispatch:view','dispatch:read','dispatch:monitor','all_functions')";

  private final DispatchQrService qrService;

  @GetMapping(value = "/{id}/qr", produces = MediaType.APPLICATION_JSON_VALUE)
  @PreAuthorize(QR_READ_AUTH)
  public ResponseEntity<ApiResponse<String>> payload(@PathVariable Long id) {
    String payload = qrService.buildPayload(id);
    return ResponseEntity.ok(new ApiResponse<>(true, "QR payload", payload));
  }

  @GetMapping(value = "/{id}/qr.png", produces = MediaType.IMAGE_PNG_VALUE)
  @PreAuthorize(QR_READ_AUTH)
  public ResponseEntity<byte[]> payloadPng(
      @PathVariable Long id, @RequestParam(defaultValue = "320") int size) {
    int dimension = Math.max(180, Math.min(size, 800));
    byte[] png = qrService.buildPng(id, dimension);
    return ResponseEntity.ok()
        .header(
            HttpHeaders.CONTENT_DISPOSITION, "inline; filename=dispatch-" + id + "-qr.png")
        .body(png);
  }
}
