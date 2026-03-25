// src/main/java/com/svtrucking/logistics/dto/PresenceHeartbeatDto.java
package com.svtrucking.logistics.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@JsonIgnoreProperties(ignoreUnknown = true)
public class PresenceHeartbeatDto {

  @NotNull
  @JsonProperty("driverId")
  private Long driverId;

  @JsonProperty("device") // e.g. "native" | "flutter"
  private String device;

  @JsonProperty("battery") // 0..100
  private Integer battery;

  @JsonProperty("gpsEnabled")
  private Boolean gpsEnabled;

  @JsonProperty("ts") // client epoch ms; optional
  private Long ts;

  @JsonProperty("reason") // e.g. "periodic" | "service-start" | "network-recovered"
  private String reason;
}
