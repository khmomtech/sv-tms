package com.svtrucking.logistics.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.svtrucking.logistics.enums.SafetyItemResult;
import com.svtrucking.logistics.enums.SafetySeverity;
import java.time.LocalDateTime;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class SafetyCheckItemDto {
  private Long id;
  private String category;
  private String categoryLabelKm;
  private String itemKey;
  private String itemLabelKm;
  private SafetyItemResult result;
  private SafetySeverity severity;
  private String remark;
  private LocalDateTime createdAt;
}
