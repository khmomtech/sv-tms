package com.svtrucking.logistics.dto;

import com.fasterxml.jackson.annotation.JsonAlias;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import java.time.LocalDate;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.extern.jackson.Jacksonized;

@Data
@Builder
@Jacksonized
@NoArgsConstructor
@AllArgsConstructor
@JsonIgnoreProperties(ignoreUnknown = true)
public class VehicleDocumentRequest {
  private Long vehicleId;
  private String documentType;
  private String documentUrl;
  @JsonAlias({"docNumber"})
  private String documentNumber;
  private LocalDate issueDate;
  private LocalDate expiryDate;
  private Boolean approved;
  private String notes;
}
