package com.svtrucking.logistics.dto;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import com.svtrucking.logistics.dto.requests.DriverLocationUpdateDto;
import java.time.Instant;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class DriverLocationUpdateDtoTest {

  private ObjectMapper mapper;

  @BeforeEach
  void setup() {
    mapper = new ObjectMapper();
    mapper.registerModule(new JavaTimeModule());
  }

  @Test
  void parsesIsoClientTimeWithLongFractionalSeconds() throws Exception {
    String iso = "2025-12-15T03:25:35.576319Z";
    String json =
        """
        {
          "driverId": 1,
          "latitude": 11.1,
          "longitude": 104.9,
          "clientTime": "%s"
        }
        """.formatted(iso);

    DriverLocationUpdateDto dto = mapper.readValue(json, DriverLocationUpdateDto.class);

    assertThat(dto.getClientTime()).isEqualTo(Instant.parse("2025-12-15T03:25:35.576Z").toEpochMilli());
    assertThat(dto.effectiveEpochMillisOr(0)).isEqualTo(dto.getClientTime());
  }

  @Test
  void parsesNumericClientTime() throws Exception {
    long now = System.currentTimeMillis();
    String json =
        """
        {
          "driverId": 1,
          "latitude": 11.1,
          "longitude": 104.9,
          "clientTime": %d
        }
        """.formatted(now);

    DriverLocationUpdateDto dto = mapper.readValue(json, DriverLocationUpdateDto.class);

    assertThat(dto.getClientTime()).isEqualTo(now);
    assertThat(dto.effectiveEpochMillisOr(0)).isEqualTo(now);
  }

  @Test
  void fallsBackToTimestampWhenClientTimeMissing() throws Exception {
    String json =
        """
        {
          "driverId": 1,
          "latitude": 11.1,
          "longitude": 104.9,
          "timestamp": "2025-12-15T03:25:35.012Z"
        }
        """;

    DriverLocationUpdateDto dto = mapper.readValue(json, DriverLocationUpdateDto.class);

    assertThat(dto.getClientTime()).isNull();
    assertThat(dto.effectiveEpochMillisOr(0))
        .isEqualTo(Instant.parse("2025-12-15T03:25:35.012Z").toEpochMilli());
  }
}
