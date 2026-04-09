package com.svtrucking.logistics.dto;

import com.svtrucking.logistics.model.FailureCode;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class FailureCodeDto {

  private Long id;
  private String code;
  private String description;
  private String category;
  private Boolean active;

  public static FailureCodeDto fromEntity(FailureCode entity) {
    if (entity == null) return null;
    return FailureCodeDto.builder()
        .id(entity.getId())
        .code(entity.getCode())
        .description(entity.getDescription())
        .category(entity.getCategory())
        .active(entity.getActive())
        .build();
  }
}
