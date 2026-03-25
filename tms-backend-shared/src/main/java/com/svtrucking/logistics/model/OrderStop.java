package com.svtrucking.logistics.model;

import com.svtrucking.logistics.enums.StopType;
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
import jakarta.persistence.Table;
import java.time.LocalDateTime;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "order_stops")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class OrderStop {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @Enumerated(EnumType.STRING)
  @Column(nullable = false, length = 10)
  private StopType type;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "transport_order_id", nullable = false)
  private TransportOrder transportOrder;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "address_id", nullable = false)
  private CustomerAddress address;

  @Column(name = "sequence_order", nullable = false)
  private Integer sequence;

  @Column(name = "eta")
  private LocalDateTime eta;

  @Column(name = "arrival_time")
  private LocalDateTime arrivalTime;

  @Column(name = "departure_time")
  private LocalDateTime departureTime;

  @Column(name = "remarks", length = 500)
  private String remarks;

  @Column(name = "proof_image_url")
  private String proofImageUrl;

  @Column(name = "confirmed_by")
  private String confirmedBy;

  @Column(name = "contact_phone")
  private String contactPhone;

  @Column(name = "contact_name")
  private String contactName;
}
