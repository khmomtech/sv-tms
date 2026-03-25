package com.svtrucking.logistics.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class SafetyMasterImportResultDto {
  private String detectedFormat;
  private int categoriesInserted;
  private int itemsInserted;
  private int categoriesCreated;
  private int categoriesUpdated;
  private int itemsCreated;
  private int itemsUpdated;
  private int itemsSkipped;
  private java.util.List<String> warnings;
  private String message;
}
