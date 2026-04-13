package com.svtrucking.logistics.model;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.svtrucking.logistics.enums.OrderOrigin;
import com.svtrucking.logistics.enums.OrderStatus;
import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToMany;
import jakarta.persistence.OneToOne;
import jakarta.persistence.PostLoad;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import jakarta.persistence.Transient;
import jakarta.persistence.Version;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.EqualsAndHashCode;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.ToString;
import org.hibernate.annotations.CreationTimestamp;

@JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "transport_orders")
@ToString(onlyExplicitlyIncluded = true)
@EqualsAndHashCode(onlyExplicitlyIncluded = true)
public class TransportOrder {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  @EqualsAndHashCode.Include
  @ToString.Include
  private Long id;

  @Version private int version;

  @Column(name = "order_reference", unique = true, nullable = false, length = 100)
  @ToString.Include
  private String orderReference;

  @ManyToOne(fetch = FetchType.LAZY, optional = false)
  @JoinColumn(name = "customer_id", nullable = false)
  private Customer customer;

  @Column(name = "bill_to")
  private String billTo;

  @Column(name = "order_date")
  private LocalDate orderDate;

  @Column(name = "delivery_date")
  private LocalDate deliveryDate;

  @Column(name = "shipment_type", length = 20)
  private String shipmentType;

  @Column(name = "courier_assigned", length = 50)
  private String courierAssigned;

  @Column(name = "trip_no", length = 50)
  private String tripNo;

  @Column(name = "truck_number", length = 50)
  private String truckNumber;

  @Column(name = "truck_trip_count")
  private Integer truckTripCount;

  @Enumerated(EnumType.STRING)
  @Column(length = 50)
  private OrderStatus status;

  @Enumerated(EnumType.STRING)
  @Column(name = "origin", length = 50)
  private OrderOrigin origin;

  @Column(name = "source_reference", length = 128)
  private String sourceReference;

  @Column(name = "requires_driver")
  private Boolean requiresDriver;

  @ManyToOne(fetch = FetchType.LAZY, optional = false)
  @JoinColumn(name = "created_by", nullable = false)
  private User createdBy;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "seller_id")
  private Employee seller;

  @Builder.Default
  @OneToMany(mappedBy = "transportOrder", cascade = CascadeType.ALL, orphanRemoval = true)
  @ToString.Exclude
  @EqualsAndHashCode.Exclude
  private List<OrderItem> items = new ArrayList<>();

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "pickup_address_id")
  private CustomerAddress pickupAddress;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "drop_address_id")
  private CustomerAddress dropAddress;

  @Transient private List<CustomerAddress> pickupAddresses;

  @Transient private List<CustomerAddress> dropAddresses;

  @Builder.Default
  @OneToMany(mappedBy = "transportOrder", cascade = CascadeType.ALL, orphanRemoval = true)
  private List<Dispatch> dispatches = new ArrayList<>();

  @OneToOne(mappedBy = "transportOrder", cascade = CascadeType.ALL, orphanRemoval = true)
  private Invoice invoice;

  @Builder.Default
  @OneToMany(mappedBy = "transportOrder", cascade = CascadeType.ALL, orphanRemoval = true)
  @ToString.Exclude
  @EqualsAndHashCode.Exclude
  private List<OrderStop> stops = new ArrayList<>();

  @Column(name = "remark", length = 255)
  private String remark;

  @Column(name = "financial_locked_flag", nullable = false)
  private Boolean financialLockedFlag = Boolean.FALSE;

  @CreationTimestamp
  @Column(name = "created_at", nullable = false, updatable = false)
  private LocalDateTime createdAt;

  @PostLoad
  @PrePersist
  private void ensureDefaults() {
    // version is a primitive int — always initialized, no null check needed
    if (this.requiresDriver == null) {
      this.requiresDriver = Boolean.TRUE;
    }
    if (this.origin == null) {
      this.origin = OrderOrigin.BOOKING;
    }
    if (this.financialLockedFlag == null) {
      this.financialLockedFlag = Boolean.FALSE;
    }
  }

  @PreUpdate
  private void ensureDefaultsOnUpdate() {
    // version is a primitive int — always initialized, no null check needed
    if (this.requiresDriver == null) {
      this.requiresDriver = Boolean.TRUE;
    }
    if (this.origin == null) {
      this.origin = OrderOrigin.BOOKING;
    }
    if (this.financialLockedFlag == null) {
      this.financialLockedFlag = Boolean.FALSE;
    }
  }
}
