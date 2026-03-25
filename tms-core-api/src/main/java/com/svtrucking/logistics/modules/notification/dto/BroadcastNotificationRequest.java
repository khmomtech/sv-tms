package com.svtrucking.logistics.modules.notification.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
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
public class BroadcastNotificationRequest {
  private String topic;
  private String title;
  private String message;
  private String type;
  private String referenceId;
  private String actionUrl;
  private String severity;
  private String sender;
}
