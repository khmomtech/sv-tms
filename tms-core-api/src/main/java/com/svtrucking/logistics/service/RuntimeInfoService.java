package com.svtrucking.logistics.service;

import com.svtrucking.logistics.dto.RuntimeInfoDto;
import java.util.Arrays;
import lombok.RequiredArgsConstructor;
import org.flywaydb.core.Flyway;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class RuntimeInfoService {

  private final ObjectProvider<Flyway> flywayProvider;

  @Value("${spring.application.name:${APP_NAME:sv-tms-service}}")
  private String serviceName;

  @Value("${app.build.version:${APP_BUILD_VERSION:dev}}")
  private String version;

  @Value("${app.build.time:${APP_BUILD_TIME:unknown}}")
  private String buildTime;

  @Value("${app.git.sha:${APP_GIT_SHA:unknown}}")
  private String gitSha;

  @Value("${app.workflow.schema.version:${APP_WORKFLOW_SCHEMA_VERSION:2026-03}}")
  private String workflowSchemaVersion;

  public RuntimeInfoDto getRuntimeInfo() {
    String migrationVersion = "unknown";
    Flyway flyway = flywayProvider.getIfAvailable();
    if (flyway != null) {
      var current = flyway.info().current();
      if (current != null && current.getVersion() != null) {
        migrationVersion = current.getVersion().getVersion();
      } else {
        var all = flyway.info().all();
        if (all != null && all.length > 0) {
          migrationVersion =
              Arrays.stream(all)
                  .filter(info -> info.getVersion() != null)
                  .reduce((first, second) -> second)
                  .map(info -> info.getVersion().getVersion())
                  .orElse(migrationVersion);
        }
      }
    }

    return RuntimeInfoDto.builder()
        .serviceName(serviceName)
        .version(version)
        .buildTime(buildTime)
        .gitSha(gitSha)
        .workflowSchemaVersion(workflowSchemaVersion)
        .migrationVersion(migrationVersion)
        .build();
  }
}
