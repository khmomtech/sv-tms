package com.svtrucking.logistics.modules.notification.model;

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
import org.hibernate.annotations.SQLDelete;
import org.hibernate.annotations.Where;
import jakarta.persistence.Index;
import jakarta.persistence.PrePersist;

@Entity
@Table(
    name = "driver_notifications",
    indexes = {
      @Index(
          name = "idx_dn_driver_created_notdel",
          columnList = "driver_id,is_deleted,created_at,id")
    })
@SQLDelete(
    sql =
        "UPDATE driver_notifications SET is_deleted = 1, deleted_at = CURRENT_TIMESTAMP WHERE id = ?")
@Where(clause = "is_deleted = 0") // auto-hide soft-deleted rows in normal queries
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Getter
@Setter
public class DriverNotification {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @Column(name = "driver_id")
  private Long driverId; // null for topic-based broadcast

  private String title;
  private String message;

  private String type; // info, urgent, weather, system, etc.
  private String topic; // e.g., zone-phnompenh, all-drivers
  private String referenceId; // dispatchId, vehicleId, etc.
  private String actionUrl; // deep link or navigation
  private String severity; // low, medium, high
  private String sender; // system, admin, dispatcher, etc.

  @Builder.Default
  @Column(name = "is_read", nullable = false)
  private boolean isRead = false;

  // ---- soft delete fields ----
  @Builder.Default
  @Column(name = "is_deleted", nullable = false)
  private boolean isDeleted = false;

  @Column(name = "deleted_at")
  private LocalDateTime deletedAt;

  // ---- timestamps ----
  @Column(name = "sent_at", nullable = false)
  private LocalDateTime sentAt;

  @Column(name = "created_at", nullable = false, updatable = false)
  private LocalDateTime createdAt;

  @PrePersist
  protected void onCreate() {
    LocalDateTime now = LocalDateTime.now();
    if (createdAt == null) createdAt = now;
    if (sentAt == null) sentAt = now;
  }
}
