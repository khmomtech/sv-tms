package com.svtrucking.logistics.controller;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.model.UserSetting;
import com.svtrucking.logistics.security.AuthenticatedUserUtil;
import com.svtrucking.logistics.service.UserSettingService;
import java.util.List;
import java.util.Map;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@Slf4j
@RestController
@RequiredArgsConstructor
@RequestMapping("/api/user-settings")
@CrossOrigin(origins = "*")
public class UserSettingController {

  private final UserSettingService userSettingService;
  private final AuthenticatedUserUtil authenticatedUserUtil;

  /** 🔹 Get all settings for the authenticated user */
  @GetMapping
  public ResponseEntity<ApiResponse<List<UserSetting>>> getSettings() {
    Long userId = authenticatedUserUtil.getCurrentUser().getId();
    log.info("Fetching settings for user ID: {}", userId);
    List<UserSetting> settings = userSettingService.getSettingsByUserId(userId);
    return ResponseEntity.ok(new ApiResponse<>(true, "Settings retrieved", settings));
  }

  /** 🔹 Get a specific setting by key */
  @GetMapping("/key/{key}")
  public ResponseEntity<ApiResponse<UserSetting>> getUserSettingByKey(@PathVariable String key) {
    Long userId = authenticatedUserUtil.getCurrentUser().getId();
    log.info("Fetching setting for user {} with key '{}'", userId, key);
    return userSettingService
        .getSettingByUserIdAndKey(userId, key)
        .map(setting -> ResponseEntity.ok(new ApiResponse<>(true, "Setting found", setting)))
        .orElseGet(() -> ResponseEntity.ok(new ApiResponse<>(false, "Setting not found", null)));
  }

  /** 🔹 Update or create user setting */
  @PostMapping("/update")
  public ResponseEntity<ApiResponse<UserSetting>> updateUserSetting(
      @RequestBody Map<String, String> payload) {

    String key = payload.get("key");
    String value = payload.get("value");

    if (key == null || value == null) {
      log.warn("Missing key or value in setting update payload: {}", payload);
      return ResponseEntity.badRequest()
          .body(new ApiResponse<>(false, "Missing key or value", null));
    }

    Long userId = authenticatedUserUtil.getCurrentUser().getId();
    log.info("Updating setting for user {}: {} = {}", userId, key, value);

    UserSetting updatedSetting = userSettingService.updateSetting(userId, key, value);
    return ResponseEntity.ok(new ApiResponse<>(true, "Setting updated", updatedSetting));
  }
}
