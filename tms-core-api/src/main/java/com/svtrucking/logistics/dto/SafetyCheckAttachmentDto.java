package com.svtrucking.logistics.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import java.time.LocalDateTime;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class SafetyCheckAttachmentDto {
  private Long id;
  private Long itemId;
  private String fileUrl;
  private String fileName;
  private String mimeType;
  private Long uploadedById;
  private String uploadedByName;
  private LocalDateTime createdAt;
}
