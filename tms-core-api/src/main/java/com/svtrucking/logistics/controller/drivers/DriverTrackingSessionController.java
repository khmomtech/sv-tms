package com.svtrucking.logistics.controller.drivers;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.dto.requests.TrackingSessionStartRequest;
import com.svtrucking.logistics.dto.responses.TrackingSessionResponse;
import com.svtrucking.logistics.service.DriverTrackingSessionService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/driver/tracking/session")
@RequiredArgsConstructor
@Slf4j
public class DriverTrackingSessionController {

  private final DriverTrackingSessionService trackingSessionService;

  @PostMapping("/start")
  public ResponseEntity<ApiResponse<TrackingSessionResponse>> start(
      Authentication authentication, @Valid @RequestBody TrackingSessionStartRequest request) {
    String username = authentication.getName();
    TrackingSessionResponse response = trackingSessionService.startSession(username, request);
    return ResponseEntity.ok(ApiResponse.success("Tracking session started", response));
  }

  @PostMapping("/refresh")
  public ResponseEntity<ApiResponse<TrackingSessionResponse>> refresh(
      @RequestHeader(value = "Authorization", required = false) String authorization) {
    String token = DriverTrackingSessionService.extractBearerToken(authorization);
    TrackingSessionResponse response = trackingSessionService.refreshSession(token);
    return ResponseEntity.ok(ApiResponse.success("Tracking session refreshed", response));
  }

  @PostMapping("/stop")
  public ResponseEntity<ApiResponse<String>> stop(
      @RequestHeader(value = "Authorization", required = false) String authorization) {
    String token = DriverTrackingSessionService.extractBearerToken(authorization);
    trackingSessionService.stopSession(token);
    return ResponseEntity.ok(ApiResponse.success("Tracking session stopped"));
  }
}
