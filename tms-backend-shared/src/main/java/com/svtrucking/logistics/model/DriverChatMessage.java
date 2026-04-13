package com.svtrucking.logistics.model;

import jakarta.persistence.Access;
import jakarta.persistence.AccessType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.LocalDateTime;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Access(AccessType.FIELD)
@Table(name = "driver_chat_messages")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DriverChatMessage {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @Column(name = "driver_id", nullable = false)
  private Long driverId;

  @Column(name = "sender_role", length = 20, nullable = false)
  private String senderRole;

  @Column(name = "sender", length = 100)
  private String sender;

  @Column(name = "message", columnDefinition = "TEXT", nullable = false)
  private String message;

  @Enumerated(EnumType.STRING)
  @Column(name = "message_type", length = 20, nullable = false)
  private DriverChatMessageType messageType;

  @Column(name = "agora_channel_name", length = 128)
  private String agoraChannelName;

  @Column(name = "call_session_id")
  private Long callSessionId;

  @Column(name = "created_at", nullable = false)
  private LocalDateTime createdAt;

  @Column(name = "is_read", nullable = false)
  private boolean read;
}
