package com.svtrucking.logistics.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.svtrucking.logistics.dto.DispatchApprovalHistoryDto;
import com.svtrucking.logistics.dto.DispatchApprovalSLADto;
import com.svtrucking.logistics.dto.DispatchDto;
import com.svtrucking.logistics.dto.request.DispatchApprovalRequest;
import com.svtrucking.logistics.exception.GlobalExceptionHandler;
import com.svtrucking.logistics.exception.InvalidDispatchDataException;
import com.svtrucking.logistics.service.DispatchApprovalService;
import java.time.LocalDateTime;
import java.util.List;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class DispatchApprovalControllerTest {

  private MockMvc mockMvc;
  private DispatchApprovalService dispatchApprovalService;
  private final ObjectMapper objectMapper = new ObjectMapper();

  @BeforeEach
  void setup() {
    dispatchApprovalService = Mockito.mock(DispatchApprovalService.class);
    DispatchApprovalController controller = new DispatchApprovalController(dispatchApprovalService);

    mockMvc = MockMvcBuilders.standaloneSetup(controller)
        .setControllerAdvice(new GlobalExceptionHandler())
        .build();
  }

  @Test
  void approveDispatchClosure_returnsOk() throws Exception {
    DispatchDto dto = new DispatchDto();
    dto.setId(11L);

    when(dispatchApprovalService.approveDispatchClosure(eq(11L), any(DispatchApprovalRequest.class)))
        .thenReturn(dto);

    String body = objectMapper.writeValueAsString(DispatchApprovalRequest.builder()
        .dispatchId(11L)
        .action("APPROVED")
        .remarks("ok")
        .podPhotosReviewed(true)
        .build());

    mockMvc.perform(post("/api/admin/dispatch-approval/11/approve")
            .contentType(MediaType.APPLICATION_JSON)
            .content(body))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.id").value(11));
  }

  @Test
  void rejectDispatchClosure_returnsBadRequestOnValidationError() throws Exception {
    when(dispatchApprovalService.rejectApproval(eq(12L), any(DispatchApprovalRequest.class)))
        .thenThrow(new InvalidDispatchDataException("remarks", "required"));

    String body = objectMapper.writeValueAsString(DispatchApprovalRequest.builder()
        .dispatchId(12L)
        .action("REJECTED")
        .remarks("")
        .build());

    mockMvc.perform(post("/api/admin/dispatch-approval/12/reject")
            .contentType(MediaType.APPLICATION_JSON)
            .content(body))
        .andExpect(status().isBadRequest());
  }

  @Test
  void getPendingClosures_returnsList() throws Exception {
    DispatchApprovalHistoryDto dto = DispatchApprovalHistoryDto.builder()
        .dispatchId(13L)
        .action("PENDING")
        .toStatus("PENDING_APPROVAL")
        .createdAt(LocalDateTime.now())
        .build();

    when(dispatchApprovalService.getPendingClosures()).thenReturn(List.of(dto));

    mockMvc.perform(get("/api/admin/dispatch-approval/pending"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$[0].dispatchId").value(13))
        .andExpect(jsonPath("$[0].action").value("PENDING"));
  }

  @Test
  void getSlaInfo_returnsPayload() throws Exception {
    DispatchApprovalSLADto slaDto = DispatchApprovalSLADto.builder()
        .dispatchId(14L)
        .slaTargetMinutes(120)
        .actualMinutes(45)
        .isBreach(false)
        .build();

    when(dispatchApprovalService.getSLAInfo(14L)).thenReturn(slaDto);

    mockMvc.perform(get("/api/admin/dispatch-approval/14/sla"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.dispatchId").value(14))
        .andExpect(jsonPath("$.slaTargetMinutes").value(120))
        .andExpect(jsonPath("$.isBreach").value(false));
  }
}
