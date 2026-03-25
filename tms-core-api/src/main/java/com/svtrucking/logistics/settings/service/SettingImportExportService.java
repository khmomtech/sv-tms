package com.svtrucking.logistics.settings.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.svtrucking.logistics.settings.dto.SettingWriteRequest;
import java.util.ArrayList;
import java.util.List;
import org.springframework.stereotype.Service;

@Service
public class SettingImportExportService {

  private final ObjectMapper om = new ObjectMapper();

  /**
   * Parse a flat settings JSON object into write requests. Input example: { "system.core": {
   * "appName": "SV TMS" }, "security.auth": { "jwt.expMinutes": 60 } }
   */
  public List<SettingWriteRequest> parseFlatJson(
      byte[] bytes, String scope, String scopeRef, boolean includeSecrets) {
    try {
      JsonNode root = om.readTree(bytes);
      List<SettingWriteRequest> out = new ArrayList<>();
      root.fields()
          .forEachRemaining(
              group -> {
                String groupCode = group.getKey();
                group
                    .getValue()
                    .fields()
                    .forEachRemaining(
                        entry -> {
                          String keyCode = entry.getKey();
                          Object value = om.convertValue(entry.getValue(), Object.class);
                          out.add(
                              new SettingWriteRequest(
                                  groupCode, keyCode, scope, scopeRef, value, "Import file"));
                        });
              });
      return out;
    } catch (Exception e) {
      throw new IllegalArgumentException("Invalid settings JSON", e);
    }
  }
}
