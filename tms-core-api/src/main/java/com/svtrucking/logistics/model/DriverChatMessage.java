package com.svtrucking.logistics.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Access;
import jakarta.persistence.AccessType;
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
 * Represents a chat message (or call signal) between a driver and the dispatch/support team.
 *
 * <p>Call-signal messages (CALL_REQUEST, CALL_ACCEPTED, CALL_DECLINED, CALL_ENDED) carry
 * {@link #agoraChannelName} so both parties know which Agora channel to join.
 * TYPING messages are broadcast via STOMP only — they are never saved to the database.
 */
@Entity
@Access(AccessType.FIELD)
@Table(name = "driver_chat_messages")
@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class DriverChatMessage {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @Column(nullable = false)
  private Long driverId;

  @Column(nullable = false)
  private String senderRole;

  private String sender;

  @Column(nullable = false, columnDefinition = "TEXT")
  private String message;

  @Column(nullable = false)
  private LocalDateTime createdAt;

  @Enumerated(EnumType.STRING)
  @Column(name = "message_type", nullable = false)
  @Builder.Default
  private DriverChatMessageType messageType = DriverChatMessageType.TEXT;

  @Column(name = "is_read", nullable = false)
  private boolean read;

  // ── Agora call fields ────────────────────────────────────────────────────

  /**
   * Agora channel name for CALL_REQUEST / CALL_ACCEPTED messages.
   * Both driver and admin must join this channel to establish audio/video.
   */
  @Column(name = "agora_channel_name", length = 128)
  private String agoraChannelName;

  /**
   * Links this message to the {@link CallSession} row that backs the call.
   */
  @Column(name = "call_session_id")
  private Long callSessionId;

  @PrePersist
  protected void onCreate() {
    if (createdAt == null) {
      createdAt = LocalDateTime.now();
    }
  }
}
