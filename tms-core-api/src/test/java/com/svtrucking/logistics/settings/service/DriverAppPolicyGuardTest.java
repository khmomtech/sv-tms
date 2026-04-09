package com.svtrucking.logistics.settings.service;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.svtrucking.logistics.settings.entity.SettingDef;
import com.svtrucking.logistics.settings.entity.SettingGroup;
import com.svtrucking.logistics.settings.enums.SettingType;
import java.util.List;
import org.junit.jupiter.api.Test;

class DriverAppPolicyGuardTest {

  private final DriverAppPolicyGuard guard = new DriverAppPolicyGuard();

  @Test
  void shouldAcceptValidDrawerItemsCsv() {
    assertDoesNotThrow(
        () ->
            guard.validate(
                setting("app.policies", "nav.drawer.items", SettingType.STRING),
                "home,my_vehicle,settings,help"));
  }

  @Test
  void shouldRejectInvalidDrawerItems() {
    assertThrows(
        IllegalArgumentException.class,
        () ->
            guard.validate(
                setting("app.policies", "nav.drawer.items", SettingType.STRING),
                "home,invalid_item,help"));
  }

  @Test
  void shouldRequireBottomNavToStartWithHome() {
    assertThrows(
        IllegalArgumentException.class,
        () ->
            guard.validate(
                setting("app.policies", "nav.bottom.items", SettingType.STRING),
                "trips,home,profile"));
  }

  @Test
  void shouldAcceptQuickActionsAsListValue() {
    assertDoesNotThrow(
        () ->
            guard.validate(
                setting("app.policies", "nav.home.quick_actions", SettingType.STRING),
                List.of("my_trips", "documents", "trip_report")));
  }

  @Test
  void shouldRejectUnknownDispatchStatus() {
    assertThrows(
        IllegalArgumentException.class,
        () ->
            guard.validate(
                setting("app.policies", "dispatch.actions.hidden_statuses", SettingType.STRING),
                "ARRIVED_LOADING,UNKNOWN_STATUS"));
  }

  @Test
  void shouldAcceptBooleanLikeValuesForRequireDriverInitiated() {
    assertDoesNotThrow(
        () ->
            guard.validate(
                setting(
                    "app.policies",
                    "dispatch.actions.require_driver_initiated",
                    SettingType.BOOLEAN),
                true));
    assertDoesNotThrow(
        () ->
            guard.validate(
                setting(
                    "app.policies",
                    "dispatch.actions.require_driver_initiated",
                    SettingType.BOOLEAN),
                "false"));
  }

  @Test
  void shouldSkipNonPolicyGroups() {
    assertDoesNotThrow(
        () ->
            guard.validate(
                setting("security.auth", "jwt.expMinutes", SettingType.NUMBER),
                60));
  }

  private SettingDef setting(String groupCode, String keyCode, SettingType type) {
    final SettingGroup group = new SettingGroup();
    group.setCode(groupCode);

    final SettingDef def = new SettingDef();
    def.setGroup(group);
    def.setKeyCode(keyCode);
    def.setType(type);
    def.setRequired(false);
    return def;
  }
}
