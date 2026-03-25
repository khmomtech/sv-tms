package com.svtrucking.logistics.controller.drivers;

import com.svtrucking.logistics.dto.AppVersionDto;
import com.svtrucking.logistics.model.AppVersion;
import com.svtrucking.logistics.service.AppVersionService;
import java.time.ZoneId;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/public/app-version")
public class PublicAppVersionController {

  private final AppVersionService appVersionService;

  public PublicAppVersionController(AppVersionService appVersionService) {
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
}
