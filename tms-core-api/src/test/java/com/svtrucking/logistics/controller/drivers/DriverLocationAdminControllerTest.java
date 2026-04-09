package com.svtrucking.logistics.controller.drivers;

import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.svtrucking.logistics.dto.LiveDriverDto;
import com.svtrucking.logistics.dto.LocationHistoryDto;
import com.svtrucking.logistics.service.DriverLocationService;
import com.svtrucking.logistics.service.DriverOperationsDiagnosticsService;
import com.svtrucking.logistics.service.DriverTrackingSessionService;
import com.svtrucking.logistics.service.LiveDriverQueryService;
import com.svtrucking.logistics.service.LocationIngestService;
import com.svtrucking.logistics.service.TelematicsProxyService;
import java.time.LocalDateTime;
import java.util.List;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.ResponseEntity;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

class DriverLocationAdminControllerTest {

  private MockMvc mockMvc;
  private DriverLocationService driverLocationService;
  private LiveDriverQueryService liveDriverQueryService;
  private LocationIngestService locationIngestService;
  private TelematicsProxyService telematicsProxyService;
  private DriverOperationsDiagnosticsService driverOperationsDiagnosticsService;
  private DriverTrackingSessionService driverTrackingSessionService;

  @BeforeEach
  void setUp() {
    driverLocationService = org.mockito.Mockito.mock(DriverLocationService.class);
    liveDriverQueryService = org.mockito.Mockito.mock(LiveDriverQueryService.class);
    locationIngestService = org.mockito.Mockito.mock(LocationIngestService.class);
    telematicsProxyService = org.mockito.Mockito.mock(TelematicsProxyService.class);
    driverOperationsDiagnosticsService =
        org.mockito.Mockito.mock(DriverOperationsDiagnosticsService.class);
    driverTrackingSessionService = org.mockito.Mockito.mock(DriverTrackingSessionService.class);

    DriverLocationAdminController controller =
        new DriverLocationAdminController(
            driverLocationService,
            liveDriverQueryService,
            locationIngestService,
            telematicsProxyService,
            driverOperationsDiagnosticsService,
            driverTrackingSessionService);

    mockMvc = MockMvcBuilders.standaloneSetup(controller).build();
  }

  @Test
  void liveDrivers_forwardsToTelematicsWhenProxyEnabled() throws Exception {
    when(telematicsProxyService.isForwardingEnabled()).thenReturn(true);
    when(telematicsProxyService.forwardGetObject(
            "/api/admin/telematics/live-drivers?online=true&onlineSeconds=120",
            "Bearer admin-token"))
        .thenReturn(
            ResponseEntity.ok(
                List.of(
                    LiveDriverDto.builder()
                        .driverId(17L)
                        .driverName("Proxy Driver")
                        .latitude(11.55)
                        .longitude(104.92)
                        .build())));

    mockMvc
        .perform(
            get("/api/admin/drivers/live-drivers")
                .header("Authorization", "Bearer admin-token"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.success").value(true))
        .andExpect(jsonPath("$.data[0].driverId").value(17))
        .andExpect(jsonPath("$.data[0].driverName").value("Proxy Driver"));
  }

  @Test
  void latestLocation_forwardsToTelematicsWhenProxyEnabled() throws Exception {
    when(telematicsProxyService.isForwardingEnabled()).thenReturn(true);
    when(telematicsProxyService.forwardGetObject(
            "/api/admin/telematics/driver/17/location",
            "Bearer admin-token"))
        .thenReturn(
            ResponseEntity.ok(
                LiveDriverDto.builder()
                    .driverId(17L)
                    .driverName("Latest Proxy Driver")
                    .latitude(11.56)
                    .longitude(104.93)
                    .build()));

    mockMvc
        .perform(
            get("/api/admin/drivers/17/latest-location")
                .header("Authorization", "Bearer admin-token"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.success").value(true))
        .andExpect(jsonPath("$.data.driverId").value(17))
        .andExpect(jsonPath("$.data.driverName").value("Latest Proxy Driver"));
  }

  @Test
  void locationHistory_forwardsToTelematicsWhenProxyEnabled() throws Exception {
    when(telematicsProxyService.isForwardingEnabled()).thenReturn(true);
    when(telematicsProxyService.forwardGetObject(
            "/api/admin/telematics/driver/17/history",
            "Bearer admin-token"))
        .thenReturn(
            ResponseEntity.ok(
                List.of(
                    LocationHistoryDto.builder()
                        .driverId(17L)
                        .latitude(11.57)
                        .longitude(104.94)
                        .timestamp(LocalDateTime.of(2026, 3, 13, 10, 0))
                        .build())));

    mockMvc
        .perform(
            get("/api/admin/drivers/17/location-history")
                .header("Authorization", "Bearer admin-token"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.success").value(true))
        .andExpect(jsonPath("$.data[0].driverId").value(17))
        .andExpect(jsonPath("$.data[0].latitude").value(11.57));
  }

  @Test
  void revokeTrackingSessions_returnsRevokedCount() throws Exception {
    when(driverTrackingSessionService.revokeActiveSessionsForDriver(17L)).thenReturn(2);

    mockMvc
        .perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post(
            "/api/admin/drivers/17/tracking-session/revoke"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.success").value(true))
        .andExpect(jsonPath("$.data.driverId").value(17))
        .andExpect(jsonPath("$.data.revokedSessions").value(2));
  }
}
