package com.svtrucking.logistics.settings.entity;

import com.svtrucking.logistics.settings.enums.SettingScope;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.Lob;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import java.time.Instant;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;
import jakarta.persistence.FetchType;
import jakarta.persistence.Index;
import jakarta.persistence.ForeignKey;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(
    name = "setting_value",
    indexes = {
      @Index(name = "idx_sv_scope", columnList = "scope, scope_ref"),
      @Index(name = "idx_sv_def", columnList = "def_id"),
      @Index(name = "idx_sv_updated_at", columnList = "updated_at")
    })
public class SettingValue {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @ManyToOne(fetch = FetchType.LAZY, optional = false)
  @JoinColumn(name = "def_id", nullable = false, foreignKey = @ForeignKey(name = "fk_sv_def"))
  private SettingDef def;

  @Builder.Default
  @Enumerated(EnumType.STRING)
  @Column(nullable = false, length = 16)
  private SettingScope scope = SettingScope.GLOBAL;

  @Column(name = "scope_ref", length = 128)
  private String scopeRef; // tenantId/siteId when scope != GLOBAL

  @Lob
  @Column(name = "value_text")
  private String valueText; // encrypted for PASSWORD type

  @Builder.Default
  @Column(nullable = false)
  private Integer version = 1;

  @Column(name = "updated_by", nullable = false, length = 128)
  private String updatedBy;

  @CreationTimestamp
  @Column(name = "created_at", nullable = false, updatable = false)
  private Instant createdAt; // not in table DDL, optional column

  @UpdateTimestamp
  @Column(name = "updated_at", nullable = false)
  private Instant updatedAt; // aligns with trigger/ON UPDATE
}
