package com.svtrucking.logistics.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.time.LocalDate;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "bookings")
@Getter
@Setter
public class Booking {
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "customer_id")
  private Customer customer;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "pickup_address_id")
  private CustomerAddress pickupAddress;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "delivery_address_id")
  private CustomerAddress deliveryAddress;

  @Column(name = "service_type")
  private String serviceType; // e.g., FTL/LTL

  @Column(name = "payment_type")
  private String paymentType; // e.g., COD/INVOICE

  @Column(name = "pickup_date")
  private LocalDate pickupDate;

  @Column(name = "delivery_date")
  private LocalDate deliveryDate;

  @Column(name = "truck_type")
  private String truckType;

  @Column(name = "capacity")
  private Integer capacity;

  @Column(name = "estimated_cost")
  private BigDecimal estimatedCost;

  @Column(name = "total_weight_tons")
  private Double totalWeightTons;

  @Column(name = "total_volume_cbm")
  private Double totalVolumeCbm;

  @Column(name = "pallet_count")
  private Integer palletCount;

  @Column(name = "special_handling_notes", length = 2000)
  private String specialHandlingNotes;

  @Column(name = "requires_insurance")
  private Boolean requiresInsurance;

  @Column(name = "notes", length = 2000)
  private String notes;

  @Column(name = "status")
  private String status = "NEW";
}
