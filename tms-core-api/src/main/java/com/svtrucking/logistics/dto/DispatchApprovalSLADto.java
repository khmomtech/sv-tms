package com.svtrucking.logistics.dto;

import com.svtrucking.logistics.model.DispatchApprovalSLA;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * DTO for DispatchApprovalSLA tracking.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DispatchApprovalSLADto {

    private Long id;
    private Long dispatchId;
    private String status;
    private LocalDateTime deliveredAt;
    private LocalDateTime approvalSubmittedAt;
    private LocalDateTime approvedAt;
    private Integer slaTargetMinutes;
    private Integer actualMinutes;
    private String slaStatus;
    private Boolean isBreach;

    public static DispatchApprovalSLADto from(DispatchApprovalSLA entity) {
        if (entity == null)
            return null;

        entity.calculateActualMinutes();

        return DispatchApprovalSLADto.builder()
                .id(entity.getId())
                .dispatchId(entity.getDispatch() != null ? entity.getDispatch().getId() : null)
                .status(entity.getStatus() != null ? entity.getStatus().getValue() : null)
                .deliveredAt(entity.getDeliveredAt())
                .approvalSubmittedAt(entity.getApprovalSubmittedAt())
                .approvedAt(entity.getApprovedAt())
                .slaTargetMinutes(entity.getSlaTargetMinutes())
                .actualMinutes(entity.getActualMinutes())
                .slaStatus(entity.getSlaStatus() != null ? entity.getSlaStatus().getDescription() : null)
                .isBreach(entity.isSLABreached())
                .build();
    }
}
