package com.svtrucking.logistics.dto;

import com.svtrucking.logistics.enums.DispatchStatus;
import com.svtrucking.logistics.enums.DispatchStatusChangeSource;
import com.svtrucking.logistics.model.DispatchStatusHistory;
import java.time.LocalDateTime;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DispatchStatusHistoryDto {
  private DispatchStatus status;
  private LocalDateTime updatedAt;
  private String updatedBy;
  private Long actorUserId;
  private String actorRolesSnapshot;
  private DispatchStatusChangeSource source;
  private String overrideReason;
  private String remarks;

  public static DispatchStatusHistoryDto fromEntity(DispatchStatusHistory entity) {
    if (entity == null) return null;

    return DispatchStatusHistoryDto.builder()
        .status(entity.getStatus())
        .updatedAt(entity.getUpdatedAt())
        .updatedBy(entity.getUpdatedBy())
        .actorUserId(entity.getActorUserId())
        .actorRolesSnapshot(entity.getActorRolesSnapshot())
        .source(entity.getSource())
        .overrideReason(entity.getOverrideReason())
        .remarks(entity.getRemarks())
        .build();
  }
}
