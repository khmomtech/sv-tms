package com.svtrucking.logistics.controller.admin;

import com.svtrucking.logistics.model.RefreshToken;
import com.svtrucking.logistics.service.RefreshTokenService;
import java.util.List;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/admin/refresh-tokens")
@PreAuthorize("hasRole('ADMIN')")
public class RefreshTokenAdminController {

  private final RefreshTokenService service;

  public RefreshTokenAdminController(RefreshTokenService service) {
    this.service = service;
  }

  /** List tokens. If userId provided, filter by user. */
  @GetMapping
  public ResponseEntity<?> list(@RequestParam(required = false) Long userId) {
    List<RefreshToken> tokens;
    if (userId != null) {
      tokens = service.findByUserId(userId);
    } else {
      tokens = service.findByUserId(null); // will return empty or all depending on repository
    }
    return ResponseEntity.ok(tokens);
  }

  /** Revoke a single token by id. */
  @PostMapping("/{id}/revoke")
  public ResponseEntity<?> revoke(@PathVariable Long id) {
    service.revokeById(id);
    return ResponseEntity.ok().body(java.util.Map.of("message", "revoked"));
  }
}
