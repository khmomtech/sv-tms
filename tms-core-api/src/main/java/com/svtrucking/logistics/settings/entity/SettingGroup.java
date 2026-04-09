package com.svtrucking.logistics.settings.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import jakarta.persistence.UniqueConstraint;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(
    name = "setting_group",
    uniqueConstraints =
        @UniqueConstraint(
            name = "uq_setting_group_code",
            columnNames = {"code"}))
public class SettingGroup {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @Column(nullable = false, length = 128)
  private String code; // e.g., "security.auth"

  @Column(nullable = false, length = 128)
  private String name; // display name

  @Column(length = 512)
  private String description;
}
