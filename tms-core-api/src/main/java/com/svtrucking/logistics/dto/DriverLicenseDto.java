package com.svtrucking.logistics.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.svtrucking.logistics.model.DriverLicense;
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
@JsonInclude(JsonInclude.Include.NON_NULL)
public class DriverLicenseDto {

  private Long id;

  private Long driverId;
  private String driverName;

  private String licenseNumber;
  private String licenseClass; // Cambodia: A1, A, B1, B, C, C1, D, E

  private LocalDate issuedDate;
  private LocalDate expiryDate;

  private String issuingAuthority;
  private String licenseImageUrl;

  private String licenseFrontImage;
  private String licenseBackImage;

  private String notes;
  private Boolean expired;

  private Boolean deleted; //  Optional for admin view

  public static DriverLicenseDto fromEntity(DriverLicense license) {
    if (license == null) return null;

    return DriverLicenseDto.builder()
        .id(license.getId())
        .driverId(license.getDriver() != null ? license.getDriver().getId() : null)
        .driverName(license.getDriver() != null ? license.getDriver().getFullName() : null)
        .licenseNumber(license.getLicenseNumber())
        .licenseClass(license.getLicenseClass()) // Read from license record (source of truth)
        .issuedDate(license.getIssuedDate())
        .expiryDate(license.getExpiryDate())
        .issuingAuthority(license.getIssuingAuthority())
        .licenseImageUrl(license.getLicenseImageUrl())
        .licenseFrontImage(license.getLicenseFrontImage())
        .licenseBackImage(license.getLicenseBackImage())
        .notes(license.getNotes())
        .expired(license.isExpired())
        .deleted(license.isDeleted())
        .build();
  }
}
