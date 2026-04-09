package com.svtrucking.logistics.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;
import lombok.*;

@Entity
@Table(name = "pre_entry_check_master_items", indexes = {
    @Index(name = "idx_pre_entry_master_category", columnList = "category_id")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PreEntryCheckMasterItem {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "category_id", nullable = false)
  private PreEntryCheckCategory category;

  @Column(name = "item_key", nullable = false, length = 100)
  private String itemKey;

  @Column(name = "item_label_km", nullable = false, length = 255)
  private String itemLabelKm;

  @Column(name = "check_time", length = 50)
  private String checkTime;

  @Column(name = "sort_order")
  private Integer sortOrder;

  @Column(name = "is_active")
  private Boolean isActive;

  @Column(name = "created_at")
  private LocalDateTime createdAt;

  @Column(name = "updated_at")
  private LocalDateTime updatedAt;
}
