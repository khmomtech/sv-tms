package com.svtrucking.logistics.driverapp.controller;

import com.svtrucking.logistics.security.AuthenticatedUserUtil;
import com.svtrucking.logistics.settings.dto.SettingReadResponse;
import com.svtrucking.logistics.settings.service.SettingService;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/driver-app")
@RequiredArgsConstructor
public class DriverAppBootstrapController {

  private final AuthenticatedUserUtil authenticatedUserUtil;
  private final SettingService settingService;

  @GetMapping("/bootstrap")
  public Map<String, Object> bootstrap(Authentication authentication) {
    Map<String, Object> root = new LinkedHashMap<>();
    Map<String, Object> user = new LinkedHashMap<>();
    user.put("id", authenticatedUserUtil.getCurrentUserId());
    user.put(
        "roles",
        authentication == null
            ? List.of()
            : authentication.getAuthorities().stream().map(GrantedAuthority::getAuthority).toList());
    user.put("derivedSegments", List.of());

    root.put("user", user);
    root.put("screens", resolveBooleanGroup("app.screens", Map.of()));
    root.put("features", resolveBooleanGroup("app.features", defaultFeatures()));
    root.put("policies", resolvePolicies());
    root.put(
        "meta",
        Map.of(
            "generatedAt", Instant.now().toString(),
            "resolutionTraceVersion", "driver-app-api-default"));
    return root;
  }

  private Map<String, Object> resolveBooleanGroup(
      String groupCode, Map<String, Object> defaults) {
    Map<String, Object> resolved = new LinkedHashMap<>(defaults);
    for (SettingReadResponse row : settingService.listGroupValues(groupCode, "GLOBAL", null, false)) {
      resolved.put(row.keyCode(), coerceBoolean(row.value()));
    }
    return resolved;
  }

  private Map<String, Object> resolvePolicies() {
    Map<String, Object> resolved = new LinkedHashMap<>(defaultPolicies());
    for (SettingReadResponse row : settingService.listGroupValues("app.policies", "GLOBAL", null, false)) {
      resolved.put(row.keyCode(), row.value());
    }
    return resolved;
  }

  private Map<String, Object> defaultPolicies() {
    Map<String, Object> defaults = new LinkedHashMap<>();
    defaults.put("dashboard.refresh_sec", 60);
    defaults.put(
        "nav.home.quick_actions",
        List.of("my_trips", "incident_report", "report_issue", "documents", "trip_report", "help_center"));
    defaults.put("driver.home.defer_bootstrap_refresh", true);
    defaults.put("driver.home.lazy_load_enabled", true);
    defaults.put("driver.home.quick_actions_always_visible", true);
    defaults.put("driver.home.connect_ws_in_background", true);
    defaults.put("auth.device_approval_required", false);
    defaults.put("auth.login_requires_tracking_session", false);
    defaults.put("auth.auto_approve_latest_login_device", true);
    defaults.put("auth.review_login_button_enabled", false);
    return defaults;
  }

  private Map<String, Object> defaultFeatures() {
    Map<String, Object> defaults = new LinkedHashMap<>();
    defaults.put("driver.chat.enabled", true);
    defaults.put("driver.incident_report.enabled", true);
    defaults.put("driver.telematics_ui_enabled", true);
    defaults.put("incident_report.enabled", true);
    defaults.put("location_tracking.enabled", true);
    defaults.put("notifications.enabled", true);
    defaults.put("safety_check.enabled", true);
    return defaults;
  }

  private boolean coerceBoolean(Object raw) {
    if (raw instanceof Boolean value) {
      return value;
    }
    String normalized = String.valueOf(raw).trim();
    return "1".equals(normalized) || "true".equalsIgnoreCase(normalized);
  }
}
