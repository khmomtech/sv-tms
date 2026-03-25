package com.svtrucking.telematics.dto;

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

    @JsonProperty("device")
    private String device;

    @JsonProperty("battery")
    private Integer battery;

    @JsonProperty("gpsEnabled")
    private Boolean gpsEnabled;

    @JsonProperty("ts")
    private Long ts;

    @JsonProperty("reason")
    private String reason;
}
