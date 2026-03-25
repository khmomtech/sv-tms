package com.svtrucking.logistics.identity.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
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
@Table(
    name = "refresh_tokens",
    indexes = {
      @Index(name = "idx_refresh_token_user", columnList = "user_id"),
      @Index(name = "idx_refresh_token_expires_at", columnList = "expires_at")
    })
public class RefreshToken {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @Column(name = "token", nullable = false, unique = true, length = 512)
  private String token;

  @Column(name = "user_id", nullable = false)
  private Long userId;

  @Column(name = "issued_at")
  private LocalDateTime issuedAt;

  @Column(name = "expires_at")
  private LocalDateTime expiresAt;

  @Column(name = "revoked")
  private Boolean revoked;

  @Column(name = "device_info", length = 255)
  private String deviceInfo;
}

