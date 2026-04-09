package com.svtrucking.logistics.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
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
@JsonInclude(JsonInclude.Include.NON_NULL)
public class TaskAttachmentDto {

  private Long id;

  @NotNull(message = "Task ID is required")
  private Long taskId;

  @NotBlank(message = "File name is required")
  @Size(max = 255, message = "File name cannot exceed 255 characters")
  private String fileName;

  @NotBlank(message = "File URL is required")
  @Size(max = 500, message = "File URL cannot exceed 500 characters")
  private String fileUrl;

  @Size(max = 100, message = "MIME type cannot exceed 100 characters")
  private String mimeType;

  private Long fileSizeBytes;

  private Long uploadedById;
  private String uploadedByUsername;
  private String uploadedByName;

  private LocalDateTime uploadedAt;

  @Size(max = 500, message = "Description cannot exceed 500 characters")
  private String description;

  // Computed
  private String fileSizeFormatted; // e.g., "1.5 MB"
}
