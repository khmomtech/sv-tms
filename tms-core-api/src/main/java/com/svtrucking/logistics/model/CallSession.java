package com.svtrucking.logistics.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import java.time.LocalDateTime;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * Tracks an Agora voice/video call session between a driver and a support agent.
 *
 * <p>Lifecycle:
 * <pre>
 *   RINGING  →  ACTIVE   (driver answered)
 *   RINGING  →  DECLINED (driver declined or timed out)
 *   ACTIVE   →  ENDED    (either party hung up)
 * </pre>
 */
@Entity
@Table(name = "call_sessions")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CallSession {

  public enum Status { RINGING, ACTIVE, ENDED, DECLINED, MISSED }

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  /** Driver participant. */
  @Column(name = "driver_id", nullable = false)
  private Long driverId;

  /** Support/admin who initiated or joined the call (nullable for driver-initiated). */
  @Column(name = "admin_username", length = 100)
  private String adminUsername;

  /** Agora channel name — unique per session, shared by both parties. */
  @Column(name = "channel_name", nullable = false, length = 128, unique = true)
  private String channelName;

  @Enumerated(EnumType.STRING)
  @Column(name = "status", nullable = false, length = 20)
  @Builder.Default
  private Status status = Status.RINGING;

  @Column(name = "started_at", nullable = false)
  private LocalDateTime startedAt;

  @Column(name = "answered_at")
  private LocalDateTime answeredAt;

  @Column(name = "ended_at")
  private LocalDateTime endedAt;

  /** Duration in seconds — populated when status transitions to ENDED. */
  @Column(name = "duration_seconds")
  private Integer durationSeconds;

  @PrePersist
  protected void onCreate() {
    if (startedAt == null) startedAt = LocalDateTime.now();
  }
}
