package com.svtrucking.logistics.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import java.time.LocalDateTime;
import lombok.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class SafetyCheckAuditDto {
  private Long id;
  private String action;
  private Long actorId;
  private String actorRole;
  private String message;
  private LocalDateTime createdAt;
}
