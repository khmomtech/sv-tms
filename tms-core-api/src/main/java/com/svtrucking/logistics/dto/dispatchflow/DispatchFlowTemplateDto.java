package com.svtrucking.logistics.dto.dispatchflow;

import com.svtrucking.logistics.model.DispatchFlowTemplate;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class DispatchFlowTemplateDto {
  private Long id;
  private String code;
  private String name;
  private String description;
  private boolean active;
  private Long activePublishedVersionId;

  public static DispatchFlowTemplateDto fromEntity(DispatchFlowTemplate template) {
    return DispatchFlowTemplateDto.builder()
        .id(template.getId())
        .code(template.getCode())
        .name(template.getName())
        .description(template.getDescription())
        .active(template.isActive())
        .activePublishedVersionId(template.getActivePublishedVersionId())
        .build();
  }
}
