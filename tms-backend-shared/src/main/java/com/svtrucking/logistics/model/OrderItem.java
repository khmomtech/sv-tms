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
@Entity
@Table(name = "order_items")
public class OrderItem {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @ManyToOne(fetch = FetchType.LAZY, optional = false)
  @JoinColumn(name = "item_id", nullable = false)
  private Item item;

  @Column(nullable = false)
  private double quantity;

  @Column(nullable = false)
  private String unitOfMeasurement;

  @Column(nullable = false)
  private double palletType;

  private String dimensions;
  private double weight;

  @Column(name = "from_destination")
  private String fromDestination;

  @Column(name = "to_destination")
  private String toDestination;

  private String warehouse;
  private String department;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "order_id", nullable = false)
  private TransportOrder transportOrder;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "pickup_address_id")
  private CustomerAddress pickupAddress;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "drop_address_id")
  private CustomerAddress dropAddress;
}
