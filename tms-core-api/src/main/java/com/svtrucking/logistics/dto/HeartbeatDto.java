package com.svtrucking.logistics.dto;

import com.fasterxml.jackson.annotation.JsonAlias;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
//  Ignore unknown fields so client can evolve without breaking
@JsonIgnoreProperties(ignoreUnknown = true)
public class HeartbeatDto {

  // Accept multiple JSON keys ("ts" or "timestamp")
  @JsonAlias({"ts", "timestamp"})
  private Long epochMs; // epoch millis from client

  @NotBlank private String netType; // WIFI / 4G / 5G / NONE

  @Min(0)
  @Max(100)
  private Integer battery; // 0–100 %

  private Boolean gpsOn; // Use wrapper Boolean for "null" vs false

  private String appVersion;
}
