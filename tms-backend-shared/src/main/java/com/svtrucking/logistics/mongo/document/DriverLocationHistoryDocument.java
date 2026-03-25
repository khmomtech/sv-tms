package com.svtrucking.logistics.mongo.document;

import java.time.Instant;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import org.springframework.data.mongodb.core.mapping.Field;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = DriverLocationHistoryDocument.COLLECTION)
public class DriverLocationHistoryDocument {
  public static final String COLLECTION = "driver_location_history";

  @Id private String id;

  private Long driverId;
  private Long dispatchId;
  private Double latitude;
  private Double longitude;
  private Double accuracyMeters;
  private Double heading;
  private Double speed;
  private Double clientSpeedKmh;
  private String locationName;
  private String locationSource;
  private String netType;
  private String source;
  private Integer batteryLevel;
  private Long appVersionCode;
  private Boolean isOnline;
  private Instant eventTime;
  private Instant timestamp;

  @CreatedDate
  @Field("createdAt")
  private Instant createdAt;
}
