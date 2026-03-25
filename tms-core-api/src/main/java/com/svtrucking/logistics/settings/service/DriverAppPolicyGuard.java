package com.svtrucking.logistics.settings.service;

import com.svtrucking.logistics.settings.entity.SettingDef;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import java.util.stream.Collectors;
import org.springframework.stereotype.Component;

@Component
public class DriverAppPolicyGuard {

  private static final String APP_POLICIES_GROUP = "app.policies";

  private static final Set<String> ALLOWED_DRAWER_IDS =
      Set.of(
          "home",
          "my_vehicle",
          "my_id_card",
          "notifications",
          "profile",
          "report_issue_list",
          "incident_report",
          "incident_report_list",
          "safety_history",
          "maintenance",
          "trip_report",
          "daily_summary",
          "settings",
          "help");

  private static final Set<String> ALLOWED_BOTTOM_IDS =
      Set.of("home", "trips", "report", "profile", "more");

  private static final Set<String> ALLOWED_QUICK_ACTION_IDS =
      Set.of(
          "my_trips",
          "incident_report",
          "report_issue",
          "documents",
          "trip_report",
          "help_center",
          "daily_summary",
          "more");

  private static final Set<String> ALLOWED_DISPATCH_STATUSES =
      Set.of(
          "PENDING",
          "SCHEDULED",
          "ASSIGNED",
          "DRIVER_CONFIRMED",
          "ARRIVED_LOADING",
          "IN_QUEUE",
          "LOADING",
          "LOADED",
          "AT_HUB",
          "HUB_LOADING",
          "IN_TRANSIT",
          "IN_TRANSIT_BREAKDOWN",
          "PENDING_INVESTIGATION",
          "ARRIVED_UNLOADING",
          "UNLOADING",
          "UNLOADED",
          "APPROVED",
          "SAFETY_PASSED",
          "SAFETY_FAILED",
          "DELIVERED",
          "FINANCIAL_LOCKED",
          "CLOSED",
          "COMPLETED",
          "CANCELLED",
          "REJECTED");

  public void validate(SettingDef def, Object value) {
    final String groupCode = def.getGroup().getCode();
    if (!APP_POLICIES_GROUP.equalsIgnoreCase(groupCode)) {
      return;
    }

    final String key = def.getKeyCode();
    switch (key) {
      case "nav.drawer.items" -> validateDrawerItems(value);
      case "nav.bottom.items" -> validateBottomItems(value);
      case "nav.home.quick_actions" -> validateQuickActions(value);
      case "dispatch.actions.hidden_statuses", "dispatch.actions.allowed_statuses" ->
          validateDispatchStatuses(key, value);
      case "dispatch.actions.require_driver_initiated" -> validateBoolean(key, value);
      default -> {
        // No custom guard for other keys in this group.
      }
    }
  }

  private void validateDrawerItems(Object value) {
    final List<String> items = parseStringList(value);
    validateAllowList("nav.drawer.items", items, ALLOWED_DRAWER_IDS);
  }

  private void validateBottomItems(Object value) {
    final List<String> items = parseStringList(value);
    validateAllowList("nav.bottom.items", items, ALLOWED_BOTTOM_IDS);
    if (!items.isEmpty() && !items.contains("home")) {
      throw new IllegalArgumentException("nav.bottom.items must include 'home'");
    }
    if (!items.isEmpty() && !"home".equals(items.get(0))) {
      throw new IllegalArgumentException("nav.bottom.items should start with 'home'");
    }
  }

  private void validateQuickActions(Object value) {
    final List<String> items = parseStringList(value);
    validateAllowList("nav.home.quick_actions", items, ALLOWED_QUICK_ACTION_IDS);
  }

  private void validateDispatchStatuses(String key, Object value) {
    final List<String> statuses =
        parseStringList(value).stream()
            .map(v -> v.toUpperCase(Locale.ROOT))
            .collect(Collectors.toList());
    validateAllowList(key, statuses, ALLOWED_DISPATCH_STATUSES);
  }

  private void validateBoolean(String key, Object value) {
    if (value instanceof Boolean) {
      return;
    }
    final String normalized = String.valueOf(value).trim().toLowerCase(Locale.ROOT);
    if ("true".equals(normalized) || "false".equals(normalized)) {
      return;
    }
    throw new IllegalArgumentException(key + " expects boolean true/false");
  }

  private void validateAllowList(String key, List<String> values, Set<String> allowed) {
    final Set<String> seen = new LinkedHashSet<>();
    for (String item : values) {
      if (!allowed.contains(item)) {
        throw new IllegalArgumentException(
            key + " contains invalid value '" + item + "'. Allowed: " + allowed);
      }
      if (!seen.add(item)) {
        throw new IllegalArgumentException(key + " contains duplicate value '" + item + "'");
      }
    }
  }

  private List<String> parseStringList(Object raw) {
    if (raw == null) return List.of();

    if (raw instanceof List<?> list) {
      return list.stream()
          .map(e -> String.valueOf(e).trim())
          .filter(s -> !s.isEmpty())
          .collect(Collectors.toList());
    }

    final String text = String.valueOf(raw).trim();
    if (text.isEmpty()) return List.of();
    return List.of(text.split(",")).stream()
        .map(String::trim)
        .filter(s -> !s.isEmpty())
        .collect(Collectors.toList());
  }
}
