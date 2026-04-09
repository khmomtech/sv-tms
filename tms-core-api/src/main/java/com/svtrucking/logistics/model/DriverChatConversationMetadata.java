package com.svtrucking.logistics.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import java.time.LocalDateTime;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * Tracks admin-level state (archived, resolved) for each driver chat conversation.
 * Created lazily the first time an admin takes an action on the conversation.
 */
@Entity
@Table(name = "driver_chat_conversation_metadata")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DriverChatConversationMetadata {

  /** Same as driverId in DriverChatMessage — one row per conversation. */
  @Id
  @Column(name = "driver_id", nullable = false)
  private Long driverId;

  @Column(name = "archived_by_admin", nullable = false)
  @Builder.Default
  private boolean archivedByAdmin = false;

  @Column(name = "resolved_by_admin", nullable = false)
  @Builder.Default
  private boolean resolvedByAdmin = false;

  @Column(name = "updated_at", nullable = false)
  private LocalDateTime updatedAt;

  @PrePersist
  @PreUpdate
  protected void onUpdate() {
    updatedAt = LocalDateTime.now();
  }
}
