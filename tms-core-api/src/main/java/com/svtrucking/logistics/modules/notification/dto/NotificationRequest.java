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
public class NotificationRequest {

  private Long driverId; // For direct-to-driver notification
  private String topic; // For topic-based broadcast

  private String title;
  private String message;
  private String type; // e.g. system, dispatch-update, weather, etc.
  private String referenceId; // e.g. dispatchId or related resource
  private String actionUrl; // Deep-link or navigation URL
  private String severity; // low, medium, high
  private String sender; // admin, dispatcher, system, etc.
}
