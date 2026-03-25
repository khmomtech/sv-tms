package com.svtrucking.logistics.dto.requests;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import java.util.ArrayList;
import java.util.List;
import lombok.Data;

@Data
public class PublicSafetyCheckRequest {
  @NotBlank
  private String vehiclePlate;

  private String driverName;

  private String driverPhone;

  private String shift;
  private String notes;
  private Double gpsLat;
  private Double gpsLng;

  @Valid
  @NotEmpty
  private List<PublicSafetyCheckItemRequest> items = new ArrayList<>();
}
