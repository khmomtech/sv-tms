package com.svtrucking.logistics.dto;

import com.svtrucking.logistics.model.PreEntrySafetyItem;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * DTO for PreEntrySafetyItem (individual safety checklist items).
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PreEntrySafetyItemDto {

    private Long id;
    private Long safetyCheckId;
    private String categoryCode;
    private String category;
    private String itemName;
    private String statusCode;
    private String status;
    private String remarks;
    private String photoPath;
    private LocalDateTime createdAt;

    public static PreEntrySafetyItemDto from(PreEntrySafetyItem entity) {
        if (entity == null)
            return null;

        return PreEntrySafetyItemDto.builder()
                .id(entity.getId())
                .safetyCheckId(entity.getSafetyCheck() != null ? entity.getSafetyCheck().getId() : null)
                .categoryCode(entity.getCategory() != null ? entity.getCategory().name() : null)
                .category(entity.getCategory() != null ? entity.getCategory().getDisplayName() : null)
                .itemName(entity.getItemName())
                .statusCode(entity.getStatus() != null ? entity.getStatus().name() : null)
                .status(entity.getStatus() != null ? entity.getStatus().getDescription() : null)
                .remarks(entity.getRemarks())
                .photoPath(entity.getPhotoPath())
                .createdAt(entity.getCreatedAt())
                .build();
    }
}
