package com.svtrucking.logistics.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import jakarta.validation.constraints.NotBlank;
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
public class CaseAttachmentDto {

  private Long id;
  private Long caseId;

  @NotBlank(message = "File name is required")
  private String fileName;

  private String filePath;
  private String downloadUrl;
  private Long fileSize;
  private String mimeType;

  @Size(max = 1000, message = "Description cannot exceed 1000 characters")
  private String description;

  private LocalDateTime uploadedAt;
  private Long uploadedByUserId;
  private String uploadedByUsername;
}
