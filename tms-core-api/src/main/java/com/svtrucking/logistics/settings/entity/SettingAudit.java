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
    name = "setting_audit",
    indexes = {
      @Index(name = "idx_sa_def", columnList = "def_id"),
      @Index(name = "idx_sa_updated_at", columnList = "updated_at")
    })
public class SettingAudit {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @ManyToOne(fetch = FetchType.LAZY, optional = false)
  @JoinColumn(name = "def_id", nullable = false, foreignKey = @ForeignKey(name = "fk_sa_def"))
  private SettingDef def;

  @Enumerated(EnumType.STRING)
  @Column(nullable = false, length = 16)
  private SettingScope scope;

  @Column(name = "scope_ref", length = 128)
  private String scopeRef;

  @Lob
  @Column(name = "old_value")
  private String oldValue; // masked for PASSWORD in service layer

  @Lob
  @Column(name = "new_value")
  private String newValue; // masked for PASSWORD in service layer

  @Column(name = "updated_by", nullable = false, length = 128)
  private String updatedBy;

  @CreationTimestamp
  @Column(name = "updated_at", nullable = false)
  private Instant updatedAt; // DB default CURRENT_TIMESTAMP works too

  @Column(length = 256)
  private String reason;
}
