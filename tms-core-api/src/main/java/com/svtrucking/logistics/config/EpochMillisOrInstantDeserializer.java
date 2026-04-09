package com.svtrucking.logistics.config;

import com.fasterxml.jackson.core.JsonParser;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.JsonToken;
import com.fasterxml.jackson.databind.DeserializationContext;
import com.fasterxml.jackson.databind.deser.std.StdDeserializer;
import java.io.IOException;
import java.time.Instant;
import java.time.format.DateTimeParseException;

/**
 * Accepts either epoch milliseconds (number/string) or ISO-8601 timestamps and returns epoch ms.
 * Handles long fractional seconds by truncating to milliseconds.
 */
public class EpochMillisOrInstantDeserializer extends StdDeserializer<Long> {

  public EpochMillisOrInstantDeserializer() {
    super(Long.class);
  }

  @Override
  public Long deserialize(JsonParser p, DeserializationContext ctxt)
      throws IOException, JsonProcessingException {

    // Numeric epoch millis
    if (p.currentToken() == JsonToken.VALUE_NUMBER_INT) {
      return p.getLongValue();
    }

    String text = p.getValueAsString();
    if (text == null) return null;
    text = text.trim();
    if (text.isEmpty()) return null;

    // Numeric value encoded as string
    try {
      return Long.parseLong(text);
    } catch (NumberFormatException ignored) {
      // Fall through to ISO parsing
    }

    // ISO string with possible long fractional seconds (e.g., 2025-12-15T03:01:59.012579Z)
    try {
      return parseIso(text).toEpochMilli();
    } catch (Exception e) {
      throw ctxt.weirdStringException(
          text, Long.class, "Expected epoch millis or ISO-8601 timestamp");
    }
  }

  private Instant parseIso(String raw) {
    try {
      return Instant.parse(raw);
    } catch (DateTimeParseException e) {
      String text = raw;
      if (text.contains(".")) {
        String[] parts = text.split("\\.");
        if (parts.length == 2) {
          String fractional = parts[1].replaceAll("Z$", "");
          if (fractional.length() > 3) {
            fractional = fractional.substring(0, 3);
          }
          text = parts[0] + "." + fractional + "Z";
        }
      }
      return Instant.parse(text);
    }
  }
}
