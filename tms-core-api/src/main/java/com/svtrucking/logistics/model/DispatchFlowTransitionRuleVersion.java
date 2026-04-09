package com.svtrucking.logistics.model;

import com.svtrucking.logistics.enums.DispatchStatus;
import jakarta.persistence.*;
import java.time.LocalDateTime;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(
    name = "dispatch_flow_transition_rule_version",
    uniqueConstraints = {
      @UniqueConstraint(
          name = "uk_dispatch_flow_rule_version",
          columnNames = {"template_version_id", "from_status", "to_status"})
    })
@Getter
@Setter
@NoArgsConstructor
public class DispatchFlowTransitionRuleVersion {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "template_version_id", nullable = false)
  private DispatchFlowTemplateVersion templateVersion;

  @Column(name = "source_rule_id")
  private Long sourceRuleId;

  @Enumerated(EnumType.STRING)
  @Column(name = "from_status", nullable = false, length = 50)
  private DispatchStatus fromStatus;

  @Enumerated(EnumType.STRING)
  @Column(name = "to_status", nullable = false, length = 50)
  private DispatchStatus toStatus;

  @Column(name = "enabled", nullable = false)
  private boolean enabled = true;

  @Column(name = "priority", nullable = false)
  private int priority = 100;

  @Column(name = "requires_confirmation", nullable = false)
  private boolean requiresConfirmation = false;

  @Column(name = "requires_input", nullable = false)
  private boolean requiresInput = false;

  @Column(name = "validation_message", length = 255)
  private String validationMessage;

  @Column(name = "metadata_json", columnDefinition = "json")
  private String metadataJson;

  @Column(name = "created_at", nullable = false)
  private LocalDateTime createdAt;

  @PrePersist
  void onCreate() {
    if (createdAt == null) {
      createdAt = LocalDateTime.now();
    }
  }
}
