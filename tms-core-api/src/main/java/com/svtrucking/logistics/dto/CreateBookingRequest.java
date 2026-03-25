package com.svtrucking.logistics.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import java.math.BigDecimal;
import java.time.LocalDate;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@JsonIgnoreProperties(ignoreUnknown = true)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CreateBookingRequest {
  private Long customerId;
  private BookingAddressDto pickupAddress;
  private BookingAddressDto deliveryAddress;
  private String serviceType;
  private LocalDate pickupDate;
  private LocalDate deliveryDate;
  private String paymentType;
  private String truckType;
  private Integer capacity;
  private Double totalWeightTons;
  private Double totalVolumeCbm;
  private Integer palletCount;
  private String specialHandlingNotes;
  private Boolean requiresInsurance;
  private BigDecimal estimatedCost;
  private String notes;
}
