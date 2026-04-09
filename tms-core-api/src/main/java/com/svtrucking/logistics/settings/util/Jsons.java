package com.svtrucking.logistics.settings.util;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;

public class Jsons {
  private static final ObjectMapper MAPPER = new ObjectMapper();

  public static String toJson(Object value) {
    try {
      return MAPPER.writeValueAsString(value);
    } catch (JsonProcessingException e) {
      throw new IllegalArgumentException("Invalid JSON value", e);
    }
  }

  public static <T> T fromJson(String s, Class<T> type) {
    try {
      return MAPPER.readValue(s, type);
    } catch (Exception e) {
      throw new IllegalArgumentException("Cannot parse JSON", e);
    }
  }
}
