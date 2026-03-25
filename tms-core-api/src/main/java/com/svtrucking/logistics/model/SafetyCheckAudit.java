package com.svtrucking.logistics.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
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
    name = "safety_check_audit",
    indexes = {
      @Index(name = "idx_safety_check_audit_check", columnList = "safety_check_id"),
      @Index(name = "idx_safety_check_audit_actor", columnList = "actor_id"),
      @Index(name = "idx_safety_check_audit_action", columnList = "action")
    })
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SafetyCheckAudit {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "safety_check_id", nullable = false)
  private SafetyCheck safetyCheck;

  @Column(nullable = false, length = 50)
  private String action;

  @Column(name = "actor_id")
  private Long actorId;

  @Column(name = "actor_role", length = 50)
  private String actorRole;

  @Column(length = 1000)
  private String message;

  @Column(name = "created_at")
  private LocalDateTime createdAt;

  @PrePersist
  protected void onCreate() {
    if (createdAt == null) {
      createdAt = LocalDateTime.now();
    }
  }
}
