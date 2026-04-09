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
public class CreateNotificationRequest {
  private Long driverId; // Optional for direct notification
  private String title;
  private String message;
  private String type;
  private String topic; // Optional for broadcast-style
  private String referenceId;
  private String actionUrl; // For linking to dispatch or feature
  private String actionLabel; //  New field: e.g. "View"
  private String severity; // low, medium, high
  private String sender; // system, dispatcher, admin, etc.
}
