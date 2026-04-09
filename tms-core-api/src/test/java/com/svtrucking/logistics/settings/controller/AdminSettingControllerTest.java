package com.svtrucking.logistics.settings.controller;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.svtrucking.logistics.exception.GlobalExceptionHandler;
import com.svtrucking.logistics.settings.dto.SettingReadResponse;
import com.svtrucking.logistics.settings.dto.SettingWriteRequest;
import com.svtrucking.logistics.settings.service.SettingImportExportService;
import com.svtrucking.logistics.settings.service.SettingService;
import com.svtrucking.logistics.settings.repository.SettingAuditRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

@ExtendWith(MockitoExtension.class)
class AdminSettingControllerTest {

  private MockMvc mockMvc;

    @Mock private SettingService settingService;
    @Mock private SettingImportExportService importExportService;
    @Mock private SettingAuditRepository auditRepository;

    private final ObjectMapper objectMapper = new ObjectMapper();

    @BeforeEach
    void setUp() {
        AdminSettingController controller = new AdminSettingController(settingService, importExportService, auditRepository);
        mockMvc =
                MockMvcBuilders.standaloneSetup(controller)
                        .setControllerAdvice(new GlobalExceptionHandler())
                        .build();
    }

  @Test
  void upsert_returnsOk_whenPayloadIsValid() throws Exception {
    SettingWriteRequest req =
        new SettingWriteRequest(
            "app.policies",
            "nav.bottom.items",
            "GLOBAL",
            null,
            "home,trips,report,profile,more",
            "Set safe bottom nav");

    SettingReadResponse response =
        new SettingReadResponse(
            "app.policies",
            "nav.bottom.items",
            "STRING",
            "home,trips,report,profile,more",
            "GLOBAL",
            null,
            2,
            "superadmin",
            "2026-03-11T11:00:00Z");

    when(settingService.upsert(any(SettingWriteRequest.class), eq("system"))).thenReturn(response);

    mockMvc
        .perform(
            post("/api/admin/settings/value")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(req)))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.groupCode").value("app.policies"))
        .andExpect(jsonPath("$.keyCode").value("nav.bottom.items"))
        .andExpect(jsonPath("$.scope").value("GLOBAL"));
  }

  @Test
  void upsert_returnsBadRequest_whenDynamicPolicyIsInvalid() throws Exception {
    SettingWriteRequest req =
        new SettingWriteRequest(
            "app.policies",
            "nav.bottom.items",
            "GLOBAL",
            null,
            "trips,home,profile",
            "Bad order for testing");

    when(settingService.upsert(any(SettingWriteRequest.class), eq("system")))
        .thenThrow(new IllegalArgumentException("nav.bottom.items should start with 'home'"));

    mockMvc
        .perform(
            post("/api/admin/settings/value")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(req)))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.error").value("Bad Request"))
        .andExpect(jsonPath("$.message").value("nav.bottom.items should start with 'home'"));
  }
}
