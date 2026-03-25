package com.svtrucking.logistics.dto;

import java.time.LocalDateTime;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class NotificationDTO {
  private Long id;
  private String title;
  private String body;
  private boolean isRead;
  private LocalDateTime createdAt;
}
