package com.svtrucking.logistics.dto;

import com.svtrucking.logistics.enums.LoadingDocumentType;
import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Builder
public class LoadingDocumentDto {
  private Long id;
  private LoadingDocumentType documentType;
  private String fileName;
  private String fileUrl;
  private String mimeType;
  private LocalDateTime uploadedAt;
}
