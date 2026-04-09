package com.svtrucking.logistics.modules.notification.model;

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

// =========================
//  AdminNotification Entity
// =========================
@Entity
@Table(name = "admin_notifications")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AdminNotification {
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  private String title;
  private String message;
  private String type; // e.g., system, user-feedback
  private String topic; // optional
  private String referenceId;
  private String severity;
  private String sender;

  private String actionUrl; // e.g., "/orders/123"
  private String actionLabel; // e.g., "View Order"

  private boolean isRead = false;
  private LocalDateTime createdAt = LocalDateTime.now();
}
