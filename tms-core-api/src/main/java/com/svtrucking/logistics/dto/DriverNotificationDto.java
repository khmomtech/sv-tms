package com.svtrucking.logistics.dto;

import com.svtrucking.logistics.modules.notification.model.DriverNotification;
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
public class DriverNotificationDto {
  private Long id;
  private String title;
  private String message;
  private boolean read;
  private LocalDateTime sentAt;
  private LocalDateTime createdAt;

  public static DriverNotificationDto fromEntity(DriverNotification entity) {
    return DriverNotificationDto.builder()
        .id(entity.getId())
        .title(entity.getTitle())
        .message(entity.getMessage())
        .read(entity.isRead())
        .sentAt(entity.getSentAt())
        .createdAt(entity.getCreatedAt())
        .build();
  }
}
