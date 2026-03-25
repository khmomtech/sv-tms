package com.svtrucking.logistics.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
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
public class SafetyCheckMasterItemDto {
  private Long id;
  private Long categoryId;
  private String categoryCode;
  private String categoryNameKm;
  private String itemKey;
  private String itemLabelKm;
  private String checkTime;
  private Integer sortOrder;
  private Boolean isActive;
  private LocalDateTime createdAt;
  private LocalDateTime updatedAt;
}
