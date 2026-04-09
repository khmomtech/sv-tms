package com.svtrucking.logistics.settings.entity;

import com.svtrucking.logistics.settings.enums.SettingType;
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
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import jakarta.persistence.FetchType;
import jakarta.persistence.UniqueConstraint;
import jakarta.persistence.ForeignKey;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(
    name = "setting_def",
    uniqueConstraints =
        @UniqueConstraint(
            name = "uq_group_key",
            columnNames = {"group_id", "key_code"}))
public class SettingDef {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @ManyToOne(fetch = FetchType.LAZY, optional = false)
  @JoinColumn(name = "group_id", nullable = false, foreignKey = @ForeignKey(name = "fk_sd_group"))
  private SettingGroup group;

  @Column(name = "key_code", nullable = false, length = 128)
  private String keyCode; // e.g., "jwt.expMinutes"

  @Column(nullable = false, length = 128)
  private String label; // human label

  @Column(length = 512)
  private String description; // help text

  @Enumerated(EnumType.STRING)
  @Column(nullable = false, length = 16)
  private SettingType type; // STRING / NUMBER / BOOLEAN / ...

  @Column(nullable = false)
  private boolean required = false;

  @Lob
  @Column(name = "default_value")
  private String defaultValue; // stored as text/JSON string

  @Column(name = "min_value")
  private Long minValue;

  @Column(name = "max_value")
  private Long maxValue;

  @Column(name = "regex_pattern", length = 256)
  private String regexPattern;

  @Column(name = "requires_restart", nullable = false)
  private boolean requiresRestart = false;
}
