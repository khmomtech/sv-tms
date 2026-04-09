package com.svtrucking.logistics.model;

import com.svtrucking.logistics.enums.DispatchFlowActorType;
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
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import java.time.LocalDateTime;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(
    name = "dispatch_flow_transition_actor",
    uniqueConstraints = {
      @UniqueConstraint(
          name = "uk_dispatch_flow_actor",
          columnNames = {"transition_rule_id", "actor_type"})
    })
@Getter
@Setter
@NoArgsConstructor
public class DispatchFlowTransitionActor {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "transition_rule_id", nullable = false)
  private DispatchFlowTransitionRule transitionRule;

  @Enumerated(EnumType.STRING)
  @Column(name = "actor_type", nullable = false, length = 50)
  private DispatchFlowActorType actorType;

  @Column(name = "can_execute", nullable = false)
  private boolean canExecute = true;

  @Column(name = "created_at", nullable = false)
  private LocalDateTime createdAt;

  @Column(name = "updated_at", nullable = false)
  private LocalDateTime updatedAt;

  @PrePersist
  void onCreate() {
    LocalDateTime now = LocalDateTime.now();
    if (createdAt == null) {
      createdAt = now;
    }
    if (updatedAt == null) {
      updatedAt = now;
    }
  }

  @PreUpdate
  void onUpdate() {
    updatedAt = LocalDateTime.now();
  }
}
