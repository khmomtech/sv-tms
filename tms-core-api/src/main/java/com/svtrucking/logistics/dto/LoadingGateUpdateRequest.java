package com.svtrucking.logistics.dto;

import lombok.Data;

@Data
public class LoadingGateUpdateRequest {
  private String bay;
  private Integer queuePosition;
  private String remarks;
}
