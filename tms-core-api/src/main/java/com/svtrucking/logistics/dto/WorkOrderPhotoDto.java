package com.svtrucking.logistics.dto;

import com.svtrucking.logistics.enums.PhotoType;
import com.svtrucking.logistics.model.WorkOrderPhoto;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class WorkOrderPhotoDto {

  private Long id;

  @NotNull(message = "Work order ID is required")
  private Long workOrderId;

  private Long taskId;

  @NotBlank(message = "Photo URL is required")
  @Size(max = 500, message = "Photo URL cannot exceed 500 characters")
  private String photoUrl;

  @NotNull(message = "Photo type is required")
  private PhotoType photoType;

  @Size(max = 500, message = "Description cannot exceed 500 characters")
  private String description;

  private LocalDateTime uploadedAt;

  private Long uploadedById;

  private String uploadedByName;

  public static WorkOrderPhotoDto fromEntity(WorkOrderPhoto entity) {
    if (entity == null) return null;

    return WorkOrderPhotoDto.builder()
        .id(entity.getId())
        .workOrderId(entity.getWorkOrder() != null ? entity.getWorkOrder().getId() : null)
        .taskId(entity.getTask() != null ? entity.getTask().getId() : null)
        .photoUrl(entity.getPhotoUrl())
        .photoType(entity.getPhotoType())
        .description(entity.getDescription())
        .uploadedAt(entity.getUploadedAt())
        .uploadedById(entity.getUploadedBy() != null ? entity.getUploadedBy().getId() : null)
        .uploadedByName(entity.getUploadedBy() != null ? entity.getUploadedBy().getUsername() : null)
        .build();
  }
}
