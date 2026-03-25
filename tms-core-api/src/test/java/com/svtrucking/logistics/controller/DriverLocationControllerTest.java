package com.svtrucking.logistics.controller;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.svtrucking.logistics.dto.requests.DriverLocationUpdateDto;
import com.svtrucking.logistics.service.DriverTrackingSessionService;
import com.svtrucking.logistics.service.LocationIngestService;
import java.time.Instant;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import com.svtrucking.logistics.config.TestRedisConfig;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.doThrow;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.http.HttpStatus;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Import(TestRedisConfig.class)
public class DriverLocationControllerTest {

  @Autowired private MockMvc mockMvc;

  @Autowired private ObjectMapper objectMapper;

  @MockBean private LocationIngestService locationIngestService;
  @MockBean private DriverTrackingSessionService trackingSessionService;

  @Test
  @WithMockUser(
      username = "admin",
      roles = {"ADMIN"})
  public void testUpdateDriverLocationViaRest() throws Exception {
    // Create a location update request
    DriverLocationUpdateDto locationUpdate = new DriverLocationUpdateDto();
    locationUpdate.setDriverId(1L);
    locationUpdate.setLatitude(11.6268899);
    locationUpdate.setLongitude(104.8917588);
    locationUpdate.setClientTime(Instant.parse("2024-01-01T00:00:00Z").toEpochMilli());
    locationUpdate.setTimestamp(null);

    doNothing().when(trackingSessionService).validateLocationWriteOrThrow("test-token", 1L, null);

    // Convert to JSON
    String json = objectMapper.writeValueAsString(locationUpdate);

    // Send POST request to update location
    mockMvc
        .perform(
            post("/api/driver/location/update")
                .header("Authorization", "Bearer test-token")
                .contentType(MediaType.APPLICATION_JSON)
                .content(json))
        .andExpect(status().isOk());
  }

  @Test
  @WithMockUser(
      username = "admin",
      roles = {"ADMIN"})
  public void testUpdateDriverLocationViaRest_ReturnsUnauthorizedOnTrackingFailure() throws Exception {
    DriverLocationUpdateDto locationUpdate = new DriverLocationUpdateDto();
    locationUpdate.setDriverId(1L);
    locationUpdate.setLatitude(11.6268899);
    locationUpdate.setLongitude(104.8917588);
    locationUpdate.setClientTime(Instant.parse("2024-01-01T00:00:00Z").toEpochMilli());

    doThrow(new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Tracking token missing"))
        .when(trackingSessionService)
        .validateLocationWriteOrThrow("bad-token", 1L, null);

    String json = objectMapper.writeValueAsString(locationUpdate);

    mockMvc
        .perform(
            post("/api/driver/location/update")
                .header("Authorization", "Bearer bad-token")
                .contentType(MediaType.APPLICATION_JSON)
                .content(json))
        .andExpect(status().isUnauthorized());
  }
}
