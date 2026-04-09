package com.svtrucking.logistics.settings.service;

import com.svtrucking.logistics.settings.entity.SettingDef;
import com.svtrucking.logistics.settings.util.Jsons;

public class SettingTypeCoercion {
  public static void validate(SettingDef def, Object value) {
    if (def.isRequired() && value == null) {
      throw new IllegalArgumentException("Value required for setting: " + def.getKeyCode());
    }
    if (value == null) return; // no further checks
    switch (def.getType()) {
      case NUMBER -> {
        long l = asLong(value);
        if (def.getMinValue() != null && l < def.getMinValue())
          throw new IllegalArgumentException("Value < min for " + def.getKeyCode());
        if (def.getMaxValue() != null && l > def.getMaxValue())
          throw new IllegalArgumentException("Value > max for " + def.getKeyCode());
      }
      case STRING, URL, EMAIL -> {
        String s = String.valueOf(value);
        if (def.getRegexPattern() != null && !s.matches(def.getRegexPattern()))
          throw new IllegalArgumentException(
              "Value does not match pattern for " + def.getKeyCode());
      }
      case BOOLEAN, LIST, MAP, JSON, PASSWORD -> {}
    }
  }

  public static String serialize(SettingDef def, Object value) {
    if (value == null) return null;
    return switch (def.getType()) {
      case STRING, URL, EMAIL, PASSWORD -> String.valueOf(value);
      case NUMBER -> String.valueOf(asLong(value));
      case BOOLEAN -> String.valueOf(asBoolean(value));
      case JSON, MAP, LIST -> Jsons.toJson(value);
    };
  }

  public static Object coerceForRead(SettingDef def, String stored) {
    if (stored == null) return null;
    return switch (def.getType()) {
      case STRING, URL, EMAIL, PASSWORD -> stored;
      case NUMBER -> Long.parseLong(stored);
      case BOOLEAN -> Boolean.parseBoolean(stored);
      case JSON, MAP, LIST -> Jsons.fromJson(stored, Object.class);
    };
  }

  private static long asLong(Object v) {
    if (v instanceof Number n) return n.longValue();
    return Long.parseLong(v.toString());
  }

  private static boolean asBoolean(Object v) {
    if (v instanceof Boolean b) return b;
    return Boolean.parseBoolean(v.toString());
  }
}
