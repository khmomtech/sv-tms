package com.svtrucking.logistics.modules.notification.controller;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.modules.notification.model.NotificationChannel;
import com.svtrucking.logistics.modules.notification.model.NotificationSetting;
import com.svtrucking.logistics.modules.notification.service.NotificationSettingService;
import java.util.List;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/admin/notification-settings")
@CrossOrigin(origins = "*")
public class NotificationSettingsController {

  private final NotificationSettingService settingService;

  public NotificationSettingsController(NotificationSettingService settingService) {
    this.settingService = settingService;
  }

  @GetMapping
  @PreAuthorize("hasAnyRole('ADMIN','SUPER_ADMIN','SYSTEM_ADMIN','OPS_MANAGER')")
  public ResponseEntity<ApiResponse<List<NotificationSetting>>> list() {
    List<NotificationSetting> rows = settingService.listAll();
    return ResponseEntity.ok(ApiResponse.ok("Notification settings loaded", rows));
  }

  @PutMapping("/{channel}")
  @PreAuthorize("hasAnyRole('ADMIN','SUPER_ADMIN','SYSTEM_ADMIN','OPS_MANAGER')")
  public ResponseEntity<ApiResponse<NotificationSetting>> update(
      @PathVariable String channel, @RequestBody NotificationSetting payload) {
    NotificationChannel parsed;
    try {
      parsed = NotificationChannel.valueOf(channel.toUpperCase());
    } catch (IllegalArgumentException e) {
      return ResponseEntity.badRequest()
          .body(ApiResponse.fail("Invalid channel: " + channel));
    }

    NotificationSetting saved = settingService.updateByChannel(parsed, payload);
    return ResponseEntity.ok(ApiResponse.ok("Notification setting updated", saved));
  }
}
