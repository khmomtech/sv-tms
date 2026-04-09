package com.svtrucking.logistics.dto.requests;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.svtrucking.logistics.enums.DriverStatus;
import com.svtrucking.logistics.enums.VehicleType;
import jakarta.validation.Valid;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import java.time.LocalDate;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import com.svtrucking.logistics.dto.RegisterRequest;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@JsonIgnoreProperties(ignoreUnknown = true) // <- ignore unexpected fields like "id"
public class DriverCreateRequest {

  @Valid private RegisterRequest user;

  @NotBlank private String firstName;
  @NotBlank private String lastName;

  private String name; // optional display name
  private String licenseNumber;

  @NotBlank private String phone;

  @DecimalMin("0.0")
  @DecimalMax("5.0")
  private Double rating;

  private Boolean isActive;
  private String zone;

  private VehicleType vehicleType;
  private DriverStatus status;

  private LocalDate idCardExpiry;

  private Double latitude;
  private Double longitude;

  private String deviceToken;
  private String profilePicture;
  private Long driverGroupId;

  // jackson will expose this as "partner" by default because of boolean getter naming,
  // but let's be explicit to avoid confusion between "isPartner" vs "partner"
  @JsonProperty("partner")
  private boolean isPartner;

  private String partnerCompany;

  private Long employeeId;
  private Long assignedVehicleId;
}
