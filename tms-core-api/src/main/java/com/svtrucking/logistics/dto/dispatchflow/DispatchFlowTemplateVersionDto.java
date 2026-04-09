package com.svtrucking.logistics.dto.dispatchflow;

import com.svtrucking.logistics.enums.DispatchFlowVersionStatus;
import com.svtrucking.logistics.model.DispatchFlowTemplateVersion;
import java.time.LocalDateTime;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class DispatchFlowTemplateVersionDto {
  private Long id;
  private Long templateId;
  private Integer versionNo;
  private String versionLabel;
  private DispatchFlowVersionStatus status;
  private boolean activePublished;
  private LocalDateTime publishedAt;
  private String notes;

  public static DispatchFlowTemplateVersionDto fromEntity(DispatchFlowTemplateVersion entity) {
    return DispatchFlowTemplateVersionDto.builder()
        .id(entity.getId())
        .templateId(entity.getTemplate().getId())
        .versionNo(entity.getVersionNo())
        .versionLabel(entity.getVersionLabel())
        .status(entity.getStatus())
        .activePublished(entity.isActivePublished())
        .publishedAt(entity.getPublishedAt())
        .notes(entity.getNotes())
        .build();
  }
}
