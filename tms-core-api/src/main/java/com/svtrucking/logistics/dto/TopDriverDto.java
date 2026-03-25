package com.svtrucking.logistics.dto;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class TopDriverDto {
  private String name;
  private Long deliveries;
}
