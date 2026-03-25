package com.svtrucking.logistics.controller.admin;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.svtrucking.logistics.dto.DispatchDto;
import com.svtrucking.logistics.dto.response.DispatchActionMetadata;
import com.svtrucking.logistics.dto.response.DispatchStatusUpdateResponse;
import com.svtrucking.logistics.enums.DispatchStatus;
import com.svtrucking.logistics.modules.notification.service.DriverNotificationService;
import com.svtrucking.logistics.service.DispatchService;
import com.svtrucking.logistics.service.SafetyChecklistPdfService;
import org.hamcrest.Matchers;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.Mockito;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@ExtendWith(MockitoExtension.class)
public class DispatchAdminControllerIT {

  private MockMvc mockMvc;

  @Mock private SafetyChecklistPdfService safetyChecklistPdfService;
  @Mock private DispatchService dispatchService;
  @Mock private DriverNotificationService notificationService;
  @Mock private com.svtrucking.logistics.service.LoadProofService loadProofService;
  @Mock private com.svtrucking.logistics.service.UnloadProofService unloadProofService;
  @Mock private com.svtrucking.logistics.service.AuditTrailService auditTrailService;
  @Mock private com.svtrucking.logistics.security.JwtUtil jwtUtil;
  @Mock private io.micrometer.core.instrument.MeterRegistry meterRegistry;
  @Mock private org.springframework.core.env.Environment environment;

  @InjectMocks private com.svtrucking.logistics.controller.admin.DispatchAdminController controller;

  private ObjectMapper objectMapper = new ObjectMapper();

  @BeforeEach
  void setup() {
    mockMvc = MockMvcBuilders.standaloneSetup(controller).build();
  }

  @Test
  void getSafetyPdf_returnsPdf() throws Exception {
    byte[] pdf = "dummypdf".getBytes();
    Mockito.when(safetyChecklistPdfService.generate(123L)).thenReturn(pdf);

    mockMvc
        .perform(get("/api/admin/dispatches/123/safety-pdf"))
        .andExpect(status().isOk())
        .andExpect(content().contentType(MediaType.APPLICATION_PDF))
        .andExpect(header().string("Content-Disposition", Matchers.containsString("preloading-safety-123.pdf")))
        .andExpect(content().bytes(pdf));
  }

  @Test
  void messageDriver_sendsNotification() throws Exception {
    DispatchDto dto = new DispatchDto();
    dto.setId(123L);
    dto.setDriverId(456L);
    Mockito.when(dispatchService.getDispatchById(123L)).thenReturn(dto);

    String body = objectMapper.writeValueAsString(java.util.Map.of("title", "Hi", "message", "Hello driver"));

    mockMvc
        .perform(post("/api/admin/dispatches/123/message-driver").contentType(MediaType.APPLICATION_JSON).content(body))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.success").value(true));

    Mockito.verify(notificationService, Mockito.times(1)).sendNotification(Mockito.any());
  }

  @Test
  void getAvailableActions_returnsPayload() throws Exception {
    DispatchActionMetadata action = DispatchActionMetadata.builder()
        .targetStatus(DispatchStatus.SAFETY_PASSED)
        .actionLabel("get_ticket")
        .actionType(DispatchActionMetadata.ActionType.OPERATION)
        .driverInitiated(true)
        .priority(1)
        .build();

    DispatchStatusUpdateResponse response = DispatchStatusUpdateResponse.builder()
        .dispatchId(123L)
        .currentStatus(DispatchStatus.ARRIVED_LOADING)
        .availableActions(java.util.List.of(action))
        .canPerformActions(true)
        .build();

    Mockito.when(dispatchService.getAvailableActionsForDispatchAdmin(123L)).thenReturn(response);

    mockMvc
        .perform(get("/api/admin/dispatches/123/available-actions"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.success").value(true))
        .andExpect(jsonPath("$.data.dispatchId").value(123))
        .andExpect(jsonPath("$.data.currentStatus").value("ARRIVED_LOADING"))
        .andExpect(jsonPath("$.data.availableActions[0].targetStatus").value("SAFETY_PASSED"));
  }
}
