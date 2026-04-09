package com.svtrucking.logistics.dto;

import com.svtrucking.logistics.model.MaintenanceTaskType;
import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MaintenanceTaskTypeDto {

  private Long id;

  @NotBlank(message = "Name is required")
  private String name;

  private String description;

  public static MaintenanceTaskTypeDto fromEntity(MaintenanceTaskType entity) {
    return MaintenanceTaskTypeDto.builder()
        .id(entity.getId())
        .name(entity.getName())
        .description(entity.getDescription())
        .build();
  }

  public static MaintenanceTaskType toEntity(MaintenanceTaskTypeDto dto) {
    return MaintenanceTaskType.builder()
        .id(dto.getId())
        .name(dto.getName())
        .description(dto.getDescription())
        .build();
  }
}
