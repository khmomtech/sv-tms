package com.svtrucking.logistics.dto.requests;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.svtrucking.logistics.enums.DriverStatus;
import com.svtrucking.logistics.enums.VehicleType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.LocalDate;
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
@JsonIgnoreProperties(ignoreUnknown = true)
public class DriverUpdateRequest {

  private String name;

  @NotBlank
  @Size(max = 100)
  private String firstName;

  @NotBlank
  @Size(max = 100)
  private String lastName;

  @Size(max = 50)
  private String licenseNumber;

  @NotBlank
  @Size(max = 20)
  private String phone;

  @NotNull private Double rating;

  @NotNull private Boolean isActive;

  private String zone;

  @NotNull private VehicleType vehicleType;

  @NotNull private DriverStatus status;

  private LocalDate idCardExpiry;

  private String profilePicture;
  private Double latitude;
  private Double longitude;
  private String deviceToken;
  private Long driverGroupId;

  private Boolean isPartner;
  private String partnerCompany;

  private Long employeeId;
  private Long vehicleId;
}
