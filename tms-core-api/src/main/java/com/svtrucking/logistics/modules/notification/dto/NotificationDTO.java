package com.svtrucking.logistics.modules.notification.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import java.time.LocalDateTime;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class NotificationDTO {
  private Long id;
  private String title;
  private String body;
  private String type;
  private String topic;
  private String referenceId;
  private String actionUrl; // Consider renaming to "targetUrl" for consistency
  private String actionLabel; // Add this field
  private String severity;
  private String sender;
  private boolean isRead;
  private LocalDateTime sentAt;
  private LocalDateTime createdAt;
}
