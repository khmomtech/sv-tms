package com.svtrucking.logistics.safety.domain;

import com.svtrucking.logistics.enums.SafetyItemResult;
import com.svtrucking.logistics.enums.SafetySeverity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import java.time.LocalDateTime;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(
    name = "safety_check_items",
    indexes = {
      @Index(name = "idx_safety_check_items_check", columnList = "safety_check_id"),
      @Index(name = "idx_safety_check_items_category", columnList = "category"),
      @Index(name = "idx_safety_check_items_key", columnList = "item_key")
    })
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SafetyCheckItem {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "safety_check_id", nullable = false)
  private SafetyCheck safetyCheck;

  @Column(nullable = false, length = 50)
  private String category;

  @Column(name = "item_key", nullable = false, length = 100)
  private String itemKey;

  @Column(name = "item_label_km", length = 255)
  private String itemLabelKm;

  @Enumerated(EnumType.STRING)
  @Column(name = "result", length = 32)
  private SafetyItemResult result;

  @Enumerated(EnumType.STRING)
  @Column(name = "severity", length = 32)
  private SafetySeverity severity;

  @Column(length = 1000)
  private String remark;

  @Column(name = "created_at")
  private LocalDateTime createdAt;

  @PrePersist
  protected void onCreate() {
    if (createdAt == null) {
      createdAt = LocalDateTime.now();
    }
  }
}

