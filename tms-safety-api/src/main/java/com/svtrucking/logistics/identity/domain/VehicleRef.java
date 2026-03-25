package com.svtrucking.logistics.identity.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(
    name = "vehicles",
    indexes = {@Index(name = "idx_vehicle_plate", columnList = "license_plate")})
@Getter
@Setter
@NoArgsConstructor
public class VehicleRef {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @Column(name = "license_plate", nullable = false, unique = true, length = 20)
  private String licensePlate;
}

