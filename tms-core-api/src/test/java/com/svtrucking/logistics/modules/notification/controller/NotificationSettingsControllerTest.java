package com.svtrucking.logistics.modules.notification.controller;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.svtrucking.logistics.modules.notification.model.NotificationChannel;
import com.svtrucking.logistics.modules.notification.model.NotificationSetting;
import com.svtrucking.logistics.modules.notification.service.NotificationSettingService;
import java.util.List;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import static org.mockito.Mockito.mock;

class NotificationSettingsControllerTest {

  private MockMvc mockMvc;
  private NotificationSettingService settingService;
  private ObjectMapper objectMapper;

  @BeforeEach
  void setUp() {
    settingService = mock(NotificationSettingService.class);
    NotificationSettingsController controller = new NotificationSettingsController(settingService);
    mockMvc = MockMvcBuilders.standaloneSetup(controller).build();
    objectMapper = new ObjectMapper();
  }

  @Test
  void list_returnsSettings() throws Exception {
    NotificationSetting setting = NotificationSetting.builder()
        .id(1L)
        .channel(NotificationChannel.EMAIL)
        .enabled(true)
        .thresholdDays(1)
        .thresholdKm(100)
        .recipientsJson("[\"admin@example.com\"]")
        .build();

    when(settingService.listAll()).thenReturn(List.of(setting));

    mockMvc.perform(get("/api/admin/notification-settings").contentType(MediaType.APPLICATION_JSON))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.success").value(true))
        .andExpect(jsonPath("$.data[0].channel").value("EMAIL"));
  }

  @Test
  void update_validChannel_updatesAndReturnsSetting() throws Exception {
    NotificationSetting payload = NotificationSetting.builder()
        .enabled(true)
        .thresholdDays(2)
        .thresholdKm(50)
        .recipientsJson("[\"ops@example.com\"]")
        .build();

    NotificationSetting saved = NotificationSetting.builder()
        .id(2L)
        .channel(NotificationChannel.IN_APP)
        .enabled(true)
        .thresholdDays(2)
        .thresholdKm(50)
        .recipientsJson("[\"ops@example.com\"]")
        .build();

    when(settingService.updateByChannel(eq(NotificationChannel.IN_APP), any(NotificationSetting.class))).thenReturn(saved);

    mockMvc.perform(put("/api/admin/notification-settings/in_app")
            .contentType(MediaType.APPLICATION_JSON)
            .content(objectMapper.writeValueAsString(payload)))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.success").value(true))
        .andExpect(jsonPath("$.data.channel").value("IN_APP"));
  }

  @Test
  void update_invalidChannel_returnsBadRequest() throws Exception {
    NotificationSetting payload = NotificationSetting.builder().enabled(false).build();

    mockMvc.perform(put("/api/admin/notification-settings/unknown")
            .contentType(MediaType.APPLICATION_JSON)
            .content(objectMapper.writeValueAsString(payload)))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.success").value(false));
  }
}
