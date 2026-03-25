package com.svtrucking.logistics.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.LocalDateTime;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "refresh_tokens")
public class RefreshToken {
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @Column(name = "token", nullable = false, unique = true)
  private String token;

  @Column(name = "user_id")
  private Long userId;

  @Column(name = "issued_at")
  private LocalDateTime issuedAt;

  @Column(name = "expires_at")
  private LocalDateTime expiresAt;

  @Column(name = "revoked")
  private Boolean revoked;

  @Column(name = "device_info")
  private String deviceInfo;
}
