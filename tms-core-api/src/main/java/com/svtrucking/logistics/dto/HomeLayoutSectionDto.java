package com.svtrucking.logistics.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.svtrucking.logistics.entity.HomeLayoutSection;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;

/**
 * DTO for home screen layout section
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class HomeLayoutSectionDto {

    private Long id;
    private String sectionKey;
    private String sectionName;
    private String sectionNameKh;
    private String description;
    private String descriptionKh;
    private Integer displayOrder;
    private Boolean visible;
    private Boolean isMandatory;
    private String icon;
    private String category;
    private String configJson;
    private String createdBy;
    private LocalDateTime createdAt;
    private String updatedBy;
    private LocalDateTime updatedAt;

    /**
     * Convert entity to DTO
     */
    public static HomeLayoutSectionDto fromEntity(HomeLayoutSection entity) {
        if (entity == null) {
            return null;
        }

        return HomeLayoutSectionDto.builder()
                .id(entity.getId())
                .sectionKey(entity.getSectionKey())
                .sectionName(entity.getSectionName())
                .sectionNameKh(entity.getSectionNameKh())
                .description(entity.getDescription())
                .descriptionKh(entity.getDescriptionKh())
                .displayOrder(entity.getDisplayOrder())
                .visible(entity.getVisible())
                .isMandatory(entity.getIsMandatory())
                .icon(entity.getIcon())
                .category(entity.getCategory())
                .configJson(entity.getConfigJson())
                .createdBy(entity.getCreatedBy())
                .createdAt(entity.getCreatedAt())
                .updatedBy(entity.getUpdatedBy())
                .updatedAt(entity.getUpdatedAt())
                .build();
    }

    /**
     * Convert DTO to entity
     */
    public static HomeLayoutSection toEntity(HomeLayoutSectionDto dto) {
        if (dto == null) {
            return null;
        }

        return HomeLayoutSection.builder()
                .id(dto.getId())
                .sectionKey(dto.getSectionKey())
                .sectionName(dto.getSectionName())
                .sectionNameKh(dto.getSectionNameKh())
                .description(dto.getDescription())
                .descriptionKh(dto.getDescriptionKh())
                .displayOrder(dto.getDisplayOrder())
                .visible(dto.getVisible())
                .isMandatory(dto.getIsMandatory())
                .icon(dto.getIcon())
                .category(dto.getCategory())
                .configJson(dto.getConfigJson())
                .createdBy(dto.getCreatedBy())
                .updatedBy(dto.getUpdatedBy())
                .build();
    }

    /**
     * Minimal DTO for driver app (only necessary fields)
     */
    public static HomeLayoutSectionDto toDriverDto(HomeLayoutSection entity) {
        if (entity == null) {
            return null;
        }

        return HomeLayoutSectionDto.builder()
                .sectionKey(entity.getSectionKey())
                .displayOrder(entity.getDisplayOrder())
                .visible(entity.getVisible())
                .configJson(entity.getConfigJson())
                .build();
    }
}
