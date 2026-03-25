package com.svtrucking.logistics.modules.notification.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.LocalDateTime;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

// =========================
//  Topic Entity (Optional)
// =========================
@Entity
@Table(name = "notification_topics")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class NotificationTopic {
  @Id @GeneratedValue private Long id;

  @Column(unique = true, nullable = false)
  private String name; // e.g., zone-phnompenh

  private String description;
  private boolean systemDefined;
  private String accessLevel; // admin, driver, dispatcher
  private String createdBy;

  private LocalDateTime createdAt = LocalDateTime.now();
}
