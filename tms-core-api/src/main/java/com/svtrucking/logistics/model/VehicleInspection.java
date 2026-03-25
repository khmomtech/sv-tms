package com.svtrucking.logistics.model;

import com.svtrucking.logistics.enums.InspectionStatus;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import java.util.Date;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
@Table(name = "vehicle_inspections")
public class VehicleInspection {
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @ManyToOne
  @JoinColumn(name = "vehicle_id")
  private Vehicle vehicle;

  private String inspectionType; // "Pre-Trip" or "Post-Trip"
  private Date inspectionDate;
  private boolean brakesChecked;
  private boolean tiresChecked;
  private boolean oilChecked;
  private boolean lightsChecked;
  private boolean engineChecked;
  private String comments;
  private String photoUrl; // Link to image proof

  @Enumerated(EnumType.STRING)
  private InspectionStatus status; // PASS, FAIL, REQUIRES_SERVICE
}
