package com.svtrucking.logistics.dto;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class RuntimeInfoDto {
  private String serviceName;
  private String version;
  private String buildTime;
  private String gitSha;
  private String workflowSchemaVersion;
  private String migrationVersion;
}
