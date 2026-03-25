package com.svtrucking.logistics.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "parts_master")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PartsMaster {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @Column(unique = true, nullable = false, length = 50)
  private String partCode;

  @Column(nullable = false, length = 200)
  private String partName;

  @Column(columnDefinition = "TEXT")
  private String description;

  @Column(length = 100)
  private String category;

  @Column(length = 200)
  private String manufacturer;

  @Column(length = 200)
  private String supplierName;

  @Column(length = 200)
  private String supplierContact;

  @Column(precision = 10, scale = 2)
  private BigDecimal referenceCost;

  public BigDecimal getUnitPrice() {
    return referenceCost;
  }

  public void setUnitPrice(BigDecimal price) {
    this.referenceCost = price;
  }

  public String getUnit() {
    return "EA";
  }

  public void setUnit(String unit) {}

  public String getSupplier() {
    return supplierName;
  }

  public void setSupplier(String supplier) {
    this.supplierName = supplier;
  }

  @Column(columnDefinition = "TEXT")
  private String notes;

  @Builder.Default
  private Boolean active = true;

  @Column(nullable = false)
  @Builder.Default
  private LocalDateTime createdAt = LocalDateTime.now();

  private LocalDateTime updatedAt;

  @Column(nullable = false)
  @Builder.Default
  private Boolean isDeleted = false;

  @PrePersist
  protected void onCreate() {
    if (createdAt == null) {
      createdAt = LocalDateTime.now();
    }
  }

  @PreUpdate
  protected void onUpdate() {
    updatedAt = LocalDateTime.now();
  }
}
