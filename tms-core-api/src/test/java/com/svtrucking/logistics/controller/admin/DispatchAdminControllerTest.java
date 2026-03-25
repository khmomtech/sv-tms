package com.svtrucking.logistics.controller.admin;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.svtrucking.logistics.dto.DispatchDto;
import com.svtrucking.logistics.service.ChangeTruckResult;
import com.svtrucking.logistics.service.DispatchService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.util.Collections;

import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

public class DispatchAdminControllerTest {

  private MockMvc mockMvc;
  private DispatchService dispatchService;

  @BeforeEach
  public void setup() {
    dispatchService = Mockito.mock(DispatchService.class);
    // create controller with mocked dependencies; other args can be null for this
    // focused test
    DispatchAdminController controller = new DispatchAdminController(
        dispatchService,
        null, // dispatchFlowAdminService
        null, // loadProofService
        null, // unloadProofService
        null, // notificationService
        null // safetyChecklistPdfService
    );
    mockMvc = MockMvcBuilders.standaloneSetup(controller).build();
  }

  @Test
  public void changeTruck_returnsWarningWhenDriverNotAssigned() throws Exception {
    Long dispatchId = 1L;
    Long vehicleId = 99L;

    DispatchDto dto = new DispatchDto();
    dto.setId(dispatchId);
    dto.setDriverId(12L);

    ChangeTruckResult result = new ChangeTruckResult(dto, false);
    // Simulate a warning produced during truck change (e.g., driver was not
    // assigned to new vehicle)
    result.getWarnings().add("driver-not-assigned-to-new-vehicle");

    when(dispatchService.changeTruck(eq(dispatchId), eq(vehicleId))).thenReturn(result);

    mockMvc
        .perform(
            put("/api/admin/dispatches/1/change-truck?vehicleId=99")
                .contentType(MediaType.APPLICATION_JSON)
                .header("Authorization", "Bearer test"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.errors.warnings").exists());
  }

  @Test
  public void assignTruckOnly_returnsOkAndIncludesDispatch() throws Exception {
    Long dispatchId = 1L;
    Long vehicleId = 99L;

    DispatchDto dto = new DispatchDto();
    dto.setId(dispatchId);
    dto.setDriverId(12L);

    when(dispatchService.assignTruckOnly(eq(dispatchId), eq(vehicleId))).thenReturn(dto);

    mockMvc
        .perform(
            post("/api/admin/dispatches/1/assign-truck?vehicleId=99")
                .contentType(MediaType.APPLICATION_JSON)
                .header("Authorization", "Bearer test"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.success").value(true))
        .andExpect(jsonPath("$.data.id").value(dispatchId.intValue()));
  }
}
