package com.svtrucking.logistics.controller;

import java.time.Instant;
import java.util.Map;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class BuildInfoController {

  // Bump this marker when verifying deployed backend updates.
  private static final String BUILD_MARKER = "sv-tms-maintenance-2026-02-03-1";

  @GetMapping("/api/health/build")
  public ResponseEntity<Map<String, Object>> buildInfo() {
    return ResponseEntity.ok(
        Map.of(
            "service", "sv-tms-backend",
            "buildMarker", BUILD_MARKER,
            "timestamp", Instant.now().toString()));
  }
}
