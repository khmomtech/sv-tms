package com.svtrucking.logistics.controller.drivers;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.svtrucking.logistics.dto.request.UpdateDispatchStatusRequest;
import com.svtrucking.logistics.dto.response.DispatchActionMetadata;
import com.svtrucking.logistics.dto.response.DispatchStatusUpdateResponse;
import com.svtrucking.logistics.enums.DispatchStatus;
import com.svtrucking.logistics.exception.InvalidDispatchDataException;
import com.svtrucking.logistics.modules.notification.service.DriverNotificationService;
import com.svtrucking.logistics.security.AuthenticatedUserUtil;
import com.svtrucking.logistics.service.DispatchService;
import com.svtrucking.logistics.service.LoadProofService;
import com.svtrucking.logistics.service.UnloadProofService;
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

import java.time.LocalDateTime;
import java.util.List;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@ExtendWith(MockitoExtension.class)
class DriverDispatchControllerIT {

    private final ObjectMapper objectMapper = new ObjectMapper();
    private MockMvc mockMvc;

    @Mock
    private DispatchService dispatchService;
    @Mock
    private LoadProofService loadProofService;
    @Mock
    private UnloadProofService unloadProofService;
    @Mock
    private DriverNotificationService notificationService;
    @Mock
    private AuthenticatedUserUtil authUtil;

    @InjectMocks
    private DriverDispatchController controller;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.standaloneSetup(controller).build();
    }

    @Test
    void patchStatus_returnsOk_whenValid() throws Exception {
        DispatchStatusUpdateResponse response = DispatchStatusUpdateResponse.builder()
                .dispatchId(10L)
                .previousStatus(DispatchStatus.DRIVER_CONFIRMED)
                .currentStatus(DispatchStatus.ARRIVED_LOADING)
                .updatedAt(LocalDateTime.now())
                .availableActions(List.of())
                .canPerformActions(true)
                .build();
        Mockito.when(dispatchService.updateDispatchStatusWithResponse(
                        Mockito.eq(10L),
                        Mockito.eq(DispatchStatus.ARRIVED_LOADING),
                        Mockito.isNull(),
                        Mockito.isNull()))
                .thenReturn(response);

        UpdateDispatchStatusRequest body = UpdateDispatchStatusRequest.builder()
                .status(DispatchStatus.ARRIVED_LOADING)
                .build();

        mockMvc.perform(patch("/api/driver/dispatches/10/status")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(body)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.dispatchId").value(10))
                .andExpect(jsonPath("$.data.currentStatus").value("ARRIVED_LOADING"));
    }

    @Test
    void patchStatusCompatibilityPath_routesToSameHandler() throws Exception {
        DispatchStatusUpdateResponse response = DispatchStatusUpdateResponse.builder()
                .dispatchId(11L)
                .previousStatus(DispatchStatus.DRIVER_CONFIRMED)
                .currentStatus(DispatchStatus.ARRIVED_LOADING)
                .updatedAt(LocalDateTime.now())
                .availableActions(List.of())
                .canPerformActions(true)
                .build();
        Mockito.when(dispatchService.updateDispatchStatusWithResponse(
                        Mockito.eq(11L),
                        Mockito.eq(DispatchStatus.ARRIVED_LOADING),
                        Mockito.isNull(),
                        Mockito.isNull()))
                .thenReturn(response);

        UpdateDispatchStatusRequest body = UpdateDispatchStatusRequest.builder()
                .status(DispatchStatus.ARRIVED_LOADING)
                .build();

        mockMvc.perform(patch("/api/driver/dispatches/11")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(body)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.dispatchId").value(11))
                .andExpect(jsonPath("$.data.currentStatus").value("ARRIVED_LOADING"));
    }

    @Test
    void patchStatus_returnsBadRequest_whenInvalidTransition() throws Exception {
        Mockito.when(dispatchService.updateDispatchStatusWithResponse(
                        Mockito.eq(10L),
                        Mockito.eq(DispatchStatus.IN_TRANSIT),
                        Mockito.isNull(),
                        Mockito.isNull()))
                .thenThrow(new InvalidDispatchDataException(
                        "status",
                        "Invalid status transition from DRIVER_CONFIRMED to IN_TRANSIT",
                        "POL_REQUIRED",
                        "POL",
                        "LOAD_PROOF"));

        UpdateDispatchStatusRequest body = UpdateDispatchStatusRequest.builder()
                .status(DispatchStatus.IN_TRANSIT)
                .build();

        mockMvc.perform(patch("/api/driver/dispatches/10/status")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(body)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.errors.status").value("Invalid status transition from DRIVER_CONFIRMED to IN_TRANSIT"))
                .andExpect(jsonPath("$.errors.code").value("POL_REQUIRED"))
                .andExpect(jsonPath("$.errors.requiredInput").value("POL"))
                .andExpect(jsonPath("$.errors.nextAllowedAction").value("LOAD_PROOF"));
    }

    @Test
    void patchStatus_returnsForbidden_whenDriverNotOwner() throws Exception {
        Mockito.when(dispatchService.updateDispatchStatusWithResponse(
                        Mockito.eq(10L),
                        Mockito.eq(DispatchStatus.ARRIVED_LOADING),
                        Mockito.isNull(),
                        Mockito.isNull()))
                .thenThrow(new SecurityException("This dispatch is assigned to a different driver"));

        UpdateDispatchStatusRequest body = UpdateDispatchStatusRequest.builder()
                .status(DispatchStatus.ARRIVED_LOADING)
                .build();

        mockMvc.perform(patch("/api/driver/dispatches/10/status")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(body)))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.message").value("This dispatch is assigned to a different driver"));
    }

    @Test
    void getAvailableActions_returnsActionMetadata() throws Exception {
        DispatchActionMetadata action = DispatchActionMetadata.builder()
                .targetStatus(DispatchStatus.ARRIVED_LOADING)
                .actionLabel("arrive_at_loading")
                .actionType(DispatchActionMetadata.ActionType.ARRIVAL)
                .iconName("location_on")
                .buttonColor("#FF9800")
                .driverInitiated(true)
                .requiredInput("POL")
                .inputRouteHint("LOAD_PROOF")
                .blockedCode("POL_REQUIRED")
                .priority(5)
                .build();
        DispatchStatusUpdateResponse response = DispatchStatusUpdateResponse.builder()
                .dispatchId(10L)
                .currentStatus(DispatchStatus.DRIVER_CONFIRMED)
                .availableActions(List.of(action))
                .canPerformActions(true)
                .updatedAt(LocalDateTime.now())
                .build();
        Mockito.when(dispatchService.getAvailableActionsForDispatch(10L)).thenReturn(response);

        mockMvc.perform(get("/api/driver/dispatches/10/available-actions"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.availableActions[0].targetStatus").value("ARRIVED_LOADING"))
                .andExpect(jsonPath("$.data.availableActions[0].actionLabel").value("arrive_at_loading"))
                .andExpect(jsonPath("$.data.availableActions[0].actionType").value("ARRIVAL"))
                .andExpect(jsonPath("$.data.availableActions[0].requiredInput").value("POL"))
                .andExpect(jsonPath("$.data.availableActions[0].inputRouteHint").value("LOAD_PROOF"))
                .andExpect(jsonPath("$.data.availableActions[0].blockedCode").value("POL_REQUIRED"));
    }
}
