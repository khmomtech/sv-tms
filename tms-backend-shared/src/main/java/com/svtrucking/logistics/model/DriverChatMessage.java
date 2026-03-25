package com.svtrucking.logistics.model;

import jakarta.persistence.Access;
import jakarta.persistence.AccessType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
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

/**
 * Simple chat/message entity used for driver <-> admin messages.
 */
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

  /** Driver who owns/receives this message. */
  @Column(name = "driver_id", nullable = false)
  private Long driverId;

  /** Role that created the message ("ADMIN" or "DRIVER"). */
  @Column(name = "sender_role", length = 20, nullable = false)
  private String senderRole;

  /** Username or identifier of sender. */
  @Column(name = "sender", length = 100)
  private String sender;

  @Column(name = "message", columnDefinition = "TEXT", nullable = false)
  private String message;

  @Column(name = "created_at", nullable = false)
  private LocalDateTime createdAt;

  @Column(name = "is_read", nullable = false)
  private boolean read;
}
