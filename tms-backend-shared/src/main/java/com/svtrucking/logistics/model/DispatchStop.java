package com.svtrucking.logistics.model;

import jakarta.persistence.Entity;
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

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@Entity
@Table(name = "dispatch_stops")
public class DispatchStop {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  private Integer stopSequence;
  private String locationName;
  private String address;
  private String coordinates;
  private LocalDateTime arrivalTime;
  private LocalDateTime departureTime;
  private Boolean isCompleted = false;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "dispatch_id", nullable = false)
  private Dispatch dispatch;
}
