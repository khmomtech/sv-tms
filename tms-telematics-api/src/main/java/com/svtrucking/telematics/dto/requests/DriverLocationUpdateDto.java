package com.svtrucking.telematics.dto.requests;

import com.fasterxml.jackson.annotation.*;
import com.fasterxml.jackson.databind.annotation.JsonDeserialize;
import com.svtrucking.telematics.config.CustomInstantDeserializer;
import jakarta.validation.constraints.*;
import java.time.Instant;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
@JsonIgnoreProperties(ignoreUnknown = true)
public class DriverLocationUpdateDto {

    @NotNull
    private Long driverId;

    private Long dispatchId;
    private String pointId;
    @PositiveOrZero
    private Long seq;
    private String sessionId;
    private String source;
    private String appVersion;

    @PositiveOrZero
    @JsonProperty("version")
    @JsonAlias({ "appVersionCode", "build" })
    private Integer version;

    @JsonProperty("netType")
    @JsonAlias({ "net_type" })
    private String netType;

    @JsonProperty("locationSource")
    @JsonAlias({ "location_source" })
    private String locationSource;

    private Boolean gpsOn;
    private String vehiclePlate;

    @NotNull
    @DecimalMin("-90.0")
    @DecimalMax("90.0")
    private Double latitude;

    @NotNull
    @DecimalMin("-180.0")
    @DecimalMax("180.0")
    private Double longitude;

    @PositiveOrZero
    @Max(360)
    @JsonAlias({ "bearing", "headingDeg" })
    private Double heading;

    @PositiveOrZero
    @JsonProperty("accuracyMeters")
    @JsonAlias({ "accuracy", "accuracy_meters" })
    private Double accuracyMeters;

    @PositiveOrZero
    private Double speed;

    @PositiveOrZero
    @JsonAlias({ "clientSpeedKmh", "client_speed_kmh", "speedKmh" })
    private Double clientSpeedKmh;

    @JsonDeserialize(using = CustomInstantDeserializer.class)
    private Instant timestamp;

    @Positive
    @JsonAlias({ "clientTime", "timestampEpochMs", "client_time" })
    private Long clientTime;

    @JsonSetter("clientTime")
    public void setClientTime(Object raw) {
        this.clientTime = parseClientTime(raw);
    }

    @JsonSetter("timestampEpochMs")
    public void setTimestampEpochMs(Object raw) {
        this.clientTime = parseClientTime(raw);
    }

    @JsonSetter("client_time")
    public void setClient_time(Object raw) {
        this.clientTime = parseClientTime(raw);
    }

    @Min(-1)
    @Max(100)
    private Integer batteryLevel;

    private String locationName;

    public long effectiveEpochMillisOr(long fallbackNow) {
        if (clientTime != null)
            return clientTime;
        if (timestamp != null)
            return timestamp.toEpochMilli();
        return fallbackNow;
    }

    public double canonicalSpeedMps() {
        if (speed != null)
            return speed;
        if (clientSpeedKmh != null)
            return clientSpeedKmh / 3.6;
        return 0.0;
    }

    private Long parseClientTime(Object raw) {
        if (raw == null)
            return null;
        try {
            if (raw instanceof Number n)
                return n.longValue();
            if (raw instanceof String s) {
                String text = s.trim();
                if (text.isEmpty())
                    return null;
                try {
                    return Long.parseLong(text);
                } catch (NumberFormatException ignored) {
                }
                try {
                    return Instant.parse(text).toEpochMilli();
                } catch (Exception ignored) {
                }
                if (text.contains(".")) {
                    String[] parts = text.split("\\.");
                    if (parts.length == 2) {
                        String frac = parts[1].replaceAll("Z$", "");
                        if (frac.length() > 3)
                            frac = frac.substring(0, 3);
                        try {
                            return Instant.parse(parts[0] + "." + frac + "Z").toEpochMilli();
                        } catch (Exception ignored) {
                        }
                    }
                }
            }
        } catch (Exception ignored) {
        }
        return null;
    }

    @AssertTrue(message = "latitude must be finite")
    @JsonIgnore
    public boolean isLatitudeFinite() {
        return latitude == null || (!latitude.isNaN() && !latitude.isInfinite());
    }

    @AssertTrue(message = "longitude must be finite")
    @JsonIgnore
    public boolean isLongitudeFinite() {
        return longitude == null || (!longitude.isNaN() && !longitude.isInfinite());
    }
}
