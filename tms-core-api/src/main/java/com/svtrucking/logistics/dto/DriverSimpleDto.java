package com.svtrucking.logistics.dto;

import com.svtrucking.logistics.model.Driver;
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
public class DriverSimpleDto {
  private Long id;
  private String fullName;
  private String phone;

  public static DriverSimpleDto fromEntity(Driver driver) {
    if (driver == null) return null;
    return DriverSimpleDto.builder()
        .id(driver.getId())
        .fullName(driver.getFullName())
        .phone(driver.getPhone())
        .build();
  }
}
