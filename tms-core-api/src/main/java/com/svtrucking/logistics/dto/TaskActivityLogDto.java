package com.svtrucking.logistics.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class TaskActivityLogDto {

  private Long id;
  private Long taskId;
  private String action; // CREATED, STATUS_CHANGED, ASSIGNED, COMMENTED, etc.
  private String message;
  private Long userId;
  private String username;
  private String userFullName;
  private LocalDateTime createdAt;

  @Builder.Default
  private Map<String, Object> metadata = new HashMap<>();
}
