package com.svtrucking.logistics.dto.requests;

import com.fasterxml.jackson.annotation.JsonAlias;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.databind.annotation.JsonDeserialize;
import com.svtrucking.logistics.config.CustomInstantDeserializer;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/** Payload sent from driver app to backend to update live GPS location. */
@Data // generates getters, setters, toString, equals, hashCode
@NoArgsConstructor // default constructor
@AllArgsConstructor // full-args constructor
@Builder // builder pattern
@JsonIgnoreProperties(ignoreUnknown = true) // ignore unexpected fields
public class DriverLocationUpdate {

  private Long driverId;
  private Double latitude;
  private Double longitude;
  private Long dispatchId;

  @JsonDeserialize(using = CustomInstantDeserializer.class)
  private java.time.Instant timestamp;

  private Integer batteryLevel;
  private String source;
  private Double speed;

  @JsonProperty("clientSpeedKmh")
  @JsonAlias({"client_speed_kmh", "clientSpeedKMH"})
  private Double clientSpeedKmh;

  private String locationName;

  /** Optional: a canonical m/s value irrespective of what the client sent. */
  public double canonicalSpeedMps() {
    if (speed != null) return speed; // assume already m/s
    if (clientSpeedKmh != null) return clientSpeedKmh / 3.6;
    return 0.0;
  }
}
