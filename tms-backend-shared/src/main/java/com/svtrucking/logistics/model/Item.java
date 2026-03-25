package com.svtrucking.logistics.model;

import com.svtrucking.logistics.enums.ItemType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import jakarta.persistence.Temporal;
import jakarta.persistence.TemporalType;
import java.util.Date;
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
@Table(name = "items")
public class Item {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @Column(name = "item_code", unique = true, length = 50)
  private String itemCode;

  @Column(name = "item_name", nullable = false, length = 255)
  private String itemName;

  @Column(name = "item_name_kh", length = 255)
  private String itemNameKh;

  @Enumerated(EnumType.STRING)
  @Column(name = "item_type", length = 100)
  private ItemType itemType;

  @Column(length = 50)
  private String size;

  @Column(length = 50)
  private String weight;

  @Column(length = 20)
  private String unit;

  @Column(nullable = false)
  private Integer quantity;

  @Column(name = "pallets", length = 255)
  private String pallets;

  @Column(name = "pallet_type", length = 100)
  private String palletType;

  @Builder.Default
  @Column(nullable = false)
  private Integer status = 1;

  @Column(name = "sort_order")
  private Integer sortOrder;

  @Temporal(TemporalType.TIMESTAMP)
  @Column(name = "created_at", updatable = false)
  private Date createdAt;

  @Temporal(TemporalType.TIMESTAMP)
  @Column(name = "updated_at")
  private Date updatedAt;

  @PrePersist
  protected void onCreate() {
    Date now = new Date();
    this.createdAt = now;
    this.updatedAt = now;
  }

  @PreUpdate
  protected void onUpdate() {
    this.updatedAt = new Date();
  }
}
