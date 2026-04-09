package com.svtrucking.logistics.dto;

import com.svtrucking.logistics.model.DispatchApprovalHistory;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * DTO for DispatchApprovalHistory audit records.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DispatchApprovalHistoryDto {

    private Long id;
    private Long dispatchId;
    private String fromStatus;
    private String toStatus;
    private String action;
    private String approvalRemarks;
    private UserSimpleDto reviewedBy;
    private LocalDateTime createdAt;

    public static DispatchApprovalHistoryDto from(DispatchApprovalHistory entity) {
        if (entity == null)
            return null;

        return DispatchApprovalHistoryDto.builder()
                .id(entity.getId())
                .dispatchId(entity.getDispatch() != null ? entity.getDispatch().getId() : null)
                .fromStatus(entity.getFromStatus().getValue())
                .toStatus(entity.getToStatus().getValue())
                .action(entity.getAction().name())
                .approvalRemarks(entity.getApprovalRemarks())
                .reviewedBy(entity.getReviewedBy() != null ? UserSimpleDto.fromEntity(entity.getReviewedBy()) : null)
                .createdAt(entity.getCreatedAt())
                .build();
    }
}
