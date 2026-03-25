package com.svtrucking.logistics.model;

import com.fasterxml.jackson.annotation.JsonBackReference;
import com.fasterxml.jackson.annotation.JsonManagedReference;
import com.svtrucking.logistics.enums.ShipmentStatus;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToMany;
import jakarta.persistence.Table;
import java.time.LocalDateTime;
import java.util.List;
import lombok.Getter;
import lombok.Setter;
import jakarta.persistence.CascadeType;
import jakarta.persistence.PrePersist;

@Getter
@Setter
@Entity
@Table(name = "shipments")
public class Shipment {
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @ManyToOne
  @JoinColumn(name = "order_id", nullable = false)
  @JsonBackReference
  private Order order;

  private String trackingNumber;
  private LocalDateTime estimatedDeliveryDate;
  private LocalDateTime actualDeliveryDate;

  @Enumerated(EnumType.STRING)
  private ShipmentStatus shipmentStatus;

  private String assignedVehicle;
  private String assignedDriver;

  private String proofOfDelivery; // Image URL, Signature URL

  @OneToMany(mappedBy = "shipment", cascade = CascadeType.ALL, orphanRemoval = true)
  @JsonManagedReference
  private List<LoadingAddress> loadingAddresses;

  @OneToMany(mappedBy = "shipment", cascade = CascadeType.ALL, orphanRemoval = true)
  @JsonManagedReference
  private List<DropAddress> dropAddresses;

  @PrePersist
  protected void onCreate() {
    this.estimatedDeliveryDate = LocalDateTime.now().plusDays(2); // Default 2 days
  }
}
