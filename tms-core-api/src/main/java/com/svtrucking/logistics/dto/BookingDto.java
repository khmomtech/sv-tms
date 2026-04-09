package com.svtrucking.logistics.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.svtrucking.logistics.model.Booking;
import com.svtrucking.logistics.model.Customer;
import com.svtrucking.logistics.model.CustomerAddress;
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
public class BookingDto {
  private Long id;
  private Long customerId;
  private String customerName;
  private String customerPhone;
  private CustomerAddressDto pickupAddress;
  private CustomerAddressDto deliveryAddress;
  private String serviceType;
  private String paymentType;
  private LocalDate pickupDate;
  private LocalDate deliveryDate;
  private String truckType;
  private Integer capacity;
  private BigDecimal estimatedCost;
  private Double totalWeightTons;
  private Double totalVolumeCbm;
  private Integer palletCount;
  private String specialHandlingNotes;
  private Boolean requiresInsurance;
  private String notes;
  private String status;

  public static BookingDto fromEntity(Booking b) {
    if (b == null) return null;
    BookingDto dto = new BookingDto();
    dto.setId(b.getId());
    dto.setCustomerId(b.getCustomer() != null ? b.getCustomer().getId() : null);
    dto.setCustomerName(b.getCustomer() != null ? b.getCustomer().getName() : null);
    dto.setCustomerPhone(b.getCustomer() != null ? b.getCustomer().getPhone() : null);
    dto.setPickupAddress(CustomerAddressDto.fromEntity(b.getPickupAddress()));
    dto.setDeliveryAddress(CustomerAddressDto.fromEntity(b.getDeliveryAddress()));
    dto.setServiceType(b.getServiceType());
    dto.setPaymentType(b.getPaymentType());
    dto.setPickupDate(b.getPickupDate());
    dto.setDeliveryDate(b.getDeliveryDate());
    dto.setTruckType(b.getTruckType());
    dto.setCapacity(b.getCapacity());
    dto.setEstimatedCost(b.getEstimatedCost());
    dto.setTotalWeightTons(b.getTotalWeightTons());
    dto.setTotalVolumeCbm(b.getTotalVolumeCbm());
    dto.setPalletCount(b.getPalletCount());
    dto.setSpecialHandlingNotes(b.getSpecialHandlingNotes());
    dto.setRequiresInsurance(b.getRequiresInsurance());
    dto.setNotes(b.getNotes());
    dto.setStatus(b.getStatus());
    return dto;
  }

  public Booking toEntity() {
    Booking b = new Booking();
    if (this.customerId != null) {
      Customer c = new Customer();
      c.setId(this.customerId);
      b.setCustomer(c);
    }
    CustomerAddress pickup = this.pickupAddress != null ? this.pickupAddress.toEntity() : null;
    CustomerAddress drop = this.deliveryAddress != null ? this.deliveryAddress.toEntity() : null;
    b.setPickupAddress(pickup);
    b.setDeliveryAddress(drop);
    b.setServiceType(this.serviceType);
    b.setPaymentType(this.paymentType);
    b.setPickupDate(this.pickupDate);
    b.setDeliveryDate(this.deliveryDate);
    b.setTruckType(this.truckType);
    b.setCapacity(this.capacity);
    b.setEstimatedCost(this.estimatedCost);
    b.setTotalWeightTons(this.totalWeightTons);
    b.setTotalVolumeCbm(this.totalVolumeCbm);
    b.setPalletCount(this.palletCount);
    b.setSpecialHandlingNotes(this.specialHandlingNotes);
    b.setRequiresInsurance(this.requiresInsurance);
    b.setNotes(this.notes);
    return b;
  }
}
