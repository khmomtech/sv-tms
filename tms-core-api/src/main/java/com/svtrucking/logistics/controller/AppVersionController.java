package com.svtrucking.logistics.controller;

import com.svtrucking.logistics.dto.AppVersionDto;
import com.svtrucking.logistics.model.AppVersion;
import com.svtrucking.logistics.service.AppVersionService;
import java.time.ZoneId;
import java.util.List;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/admin/app-versions")
public class AppVersionController {

  private final AppVersionService appVersionService;

  public AppVersionController(AppVersionService appVersionService) {
    this.appVersionService = appVersionService;
  }

  @GetMapping("/latest")
  public ResponseEntity<AppVersionDto> getLatestVersion() {
    AppVersion latest = appVersionService.getLatestVersion();
    if (latest == null) {
      return ResponseEntity.notFound().build();
    }
    return ResponseEntity.ok(AppVersionDto.fromEntity(latest, ZoneId.systemDefault()));
  }

  @GetMapping
  public ResponseEntity<List<AppVersionDto>> getAllVersions() {
    List<AppVersionDto> versions = appVersionService.getAllVersions().stream()
        .map(v -> AppVersionDto.fromEntity(v, ZoneId.systemDefault()))
        .toList();
    return ResponseEntity.ok(versions);
  }

  @PostMapping
  public ResponseEntity<AppVersionDto> saveAppVersion(@RequestBody AppVersion appVersion) {
    AppVersion saved = appVersionService.saveAppVersion(appVersion);
    return ResponseEntity.ok(AppVersionDto.fromEntity(saved, ZoneId.systemDefault()));
  }
}
