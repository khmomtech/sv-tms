package com.svtrucking.logistics.dto;

import com.svtrucking.logistics.model.DriverIssuePhoto;
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
public class DriverIssuePhotoDto {

  private Long id;

  @NotNull(message = "Issue ID is required")
  private Long issueId;

  @NotBlank
  @Size(max = 500, message = "Photo URL cannot exceed 500 characters")
  private String photoUrl;

  private LocalDateTime uploadedAt;

  public static DriverIssuePhotoDto fromEntity(DriverIssuePhoto entity) {
    if (entity == null) return null;

    return DriverIssuePhotoDto.builder()
        .id(entity.getId())
        .issueId(entity.getDriverIssue() != null ? entity.getDriverIssue().getId() : null)
        .photoUrl(entity.getPhotoUrl())
        .uploadedAt(entity.getUploadedAt())
        .build();
  }
}
