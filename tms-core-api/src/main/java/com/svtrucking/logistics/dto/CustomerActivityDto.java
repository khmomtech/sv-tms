package com.svtrucking.logistics.dto;

import com.svtrucking.logistics.enums.ActivityType;
import com.svtrucking.logistics.model.CustomerActivity;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CustomerActivityDto {
    private Long id;
    private Long customerId;
    private ActivityType type;
    private String title;
    private String description;
    private String metadata; // JSON string
    private Long relatedEntityId;
    private String relatedEntityType;
    private String createdBy;
    private String createdByName;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    public static CustomerActivityDto fromEntity(CustomerActivity entity) {
        if (entity == null) return null;

        return CustomerActivityDto.builder()
                .id(entity.getId())
                .customerId(entity.getCustomer().getId())
                .type(entity.getType())
                .title(entity.getTitle())
                .description(entity.getDescription())
                .metadata(entity.getMetadata()) // Already String type
                .relatedEntityId(entity.getRelatedEntityId())
                .relatedEntityType(entity.getRelatedEntityType())
                .createdBy(null) // createdBy field removed from entity
                .createdByName(entity.getCreatedByName())
                .createdAt(entity.getCreatedAt())
                .updatedAt(entity.getUpdatedAt())
                .build();
    }
}
