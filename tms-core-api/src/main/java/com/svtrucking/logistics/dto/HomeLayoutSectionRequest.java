package com.svtrucking.logistics.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * Request DTO for creating or updating home layout section
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class HomeLayoutSectionRequest {

    @NotBlank(message = "Section key is required")
    @Size(max = 50, message = "Section key must not exceed 50 characters")
    private String sectionKey;

    @NotBlank(message = "Section name is required")
    @Size(max = 100, message = "Section name must not exceed 100 characters")
    private String sectionName;

    @Size(max = 100, message = "Section name (Khmer) must not exceed 100 characters")
    private String sectionNameKh;

    @Size(max = 500, message = "Description must not exceed 500 characters")
    private String description;

    @Size(max = 500, message = "Description (Khmer) must not exceed 500 characters")
    private String descriptionKh;

    @NotNull(message = "Display order is required")
    private Integer displayOrder;

    @NotNull(message = "Visible flag is required")
    private Boolean visible;

    @Builder.Default
    private Boolean isMandatory = false;

    @Size(max = 50, message = "Icon must not exceed 50 characters")
    private String icon;

    @Size(max = 50, message = "Category must not exceed 50 characters")
    @Builder.Default
    private String category = "general";

    private String configJson;
}
