package com.svtrucking.logistics.controller.drivers;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.svtrucking.logistics.config.TestRedisConfig;
import com.svtrucking.logistics.dto.requests.TrackingSessionStartRequest;
import com.svtrucking.logistics.dto.responses.TrackingSessionResponse;
import com.svtrucking.logistics.service.DriverTrackingSessionService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Import(TestRedisConfig.class)
class DriverTrackingSessionControllerTest {

  @Autowired private MockMvc mockMvc;
  @Autowired private ObjectMapper objectMapper;

  @MockBean private DriverTrackingSessionService trackingSessionService;

  @Test
  @WithMockUser(username = "testdriver", roles = {"DRIVER"})
  void startTrackingSession_returnsResponsePayload() throws Exception {
    TrackingSessionResponse response =
        TrackingSessionResponse.builder()
            .sessionId("sess-123")
            .trackingToken("trk-abc")
            .scope("LOCATION_WRITE TRACKING_WS")
            .expiresAtEpochMs(1772700000000L)
            .build();

    when(trackingSessionService.startSession(eq("testdriver"), any(TrackingSessionStartRequest.class)))
        .thenReturn(response);

    TrackingSessionStartRequest request = new TrackingSessionStartRequest();
    request.setDeviceId("ios-device-1");
    request.setPlatform("ios");
    request.setAppVersion("1.0.0");
    String body = objectMapper.writeValueAsString(request);

    mockMvc
        .perform(
            post("/api/driver/tracking/session/start")
                .contentType(MediaType.APPLICATION_JSON)
                .content(body))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.success").value(true))
        .andExpect(jsonPath("$.data.sessionId").value("sess-123"))
        .andExpect(jsonPath("$.data.trackingToken").value("trk-abc"))
        .andExpect(jsonPath("$.data.scope").value("LOCATION_WRITE TRACKING_WS"));
  }

  @Test
  @WithMockUser(username = "testdriver", roles = {"DRIVER"})
  void refreshTrackingSession_forwardsBearerToken() throws Exception {
    TrackingSessionResponse response =
        TrackingSessionResponse.builder()
            .sessionId("sess-123")
            .trackingToken("trk-new")
            .scope("LOCATION_WRITE TRACKING_WS")
            .expiresAtEpochMs(1772701111000L)
            .build();
    when(trackingSessionService.refreshSession("trk-old")).thenReturn(response);

    mockMvc
        .perform(
            post("/api/driver/tracking/session/refresh")
                .header("Authorization", "Bearer trk-old"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.success").value(true))
        .andExpect(jsonPath("$.data.trackingToken").value("trk-new"));

    verify(trackingSessionService).refreshSession("trk-old");
  }

  @Test
  @WithMockUser(username = "testdriver", roles = {"DRIVER"})
  void stopTrackingSession_forwardsBearerToken() throws Exception {
    mockMvc
        .perform(
            post("/api/driver/tracking/session/stop")
                .header("Authorization", "Bearer trk-old"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.success").value(true));

    verify(trackingSessionService).stopSession("trk-old");
  }
}
