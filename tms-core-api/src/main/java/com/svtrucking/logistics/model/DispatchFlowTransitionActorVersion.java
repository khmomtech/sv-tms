package com.svtrucking.logistics.model;

import com.svtrucking.logistics.enums.DispatchFlowActorType;
import jakarta.persistence.*;
import java.time.LocalDateTime;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(
    name = "dispatch_flow_transition_actor_version",
    uniqueConstraints = {
      @UniqueConstraint(
          name = "uk_dispatch_flow_actor_version",
          columnNames = {"transition_rule_version_id", "actor_type"})
    })
@Getter
@Setter
@NoArgsConstructor
public class DispatchFlowTransitionActorVersion {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "transition_rule_version_id", nullable = false)
  private DispatchFlowTransitionRuleVersion transitionRuleVersion;

  @Enumerated(EnumType.STRING)
  @Column(name = "actor_type", nullable = false, length = 50)
  private DispatchFlowActorType actorType;

  @Column(name = "can_execute", nullable = false)
  private boolean canExecute = true;

  @Column(name = "created_at", nullable = false)
  private LocalDateTime createdAt;

  @PrePersist
  void onCreate() {
    if (createdAt == null) {
      createdAt = LocalDateTime.now();
    }
  }
}
