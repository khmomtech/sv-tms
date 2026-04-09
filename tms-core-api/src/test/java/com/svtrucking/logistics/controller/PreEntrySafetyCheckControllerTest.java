package com.svtrucking.logistics.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.svtrucking.logistics.dto.PreEntrySafetyCheckDto;
import com.svtrucking.logistics.dto.request.PreEntrySafetyCheckSubmitRequest;
import com.svtrucking.logistics.dto.request.SafetyConditionalOverrideRequest;
import com.svtrucking.logistics.exception.GlobalExceptionHandler;
import com.svtrucking.logistics.exception.InvalidDispatchDataException;
import com.svtrucking.logistics.service.PreEntrySafetyCheckService;
import java.util.List;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class PreEntrySafetyCheckControllerTest {

  private MockMvc mockMvc;
  private PreEntrySafetyCheckService preEntrySafetyCheckService;
  private final ObjectMapper objectMapper = new ObjectMapper();

  @BeforeEach
  void setup() {
    preEntrySafetyCheckService = Mockito.mock(PreEntrySafetyCheckService.class);
    PreEntrySafetyCheckController controller = new PreEntrySafetyCheckController(preEntrySafetyCheckService);

    mockMvc = MockMvcBuilders.standaloneSetup(controller)
        .setControllerAdvice(new GlobalExceptionHandler())
        .build();
  }

  @Test
  void submitSafetyCheck_returnsOk() throws Exception {
    PreEntrySafetyCheckDto dto = PreEntrySafetyCheckDto.builder()
        .id(21L)
        .dispatchId(100L)
        .status("PASSED")
        .build();

    when(preEntrySafetyCheckService.submitSafetyCheck(any(PreEntrySafetyCheckSubmitRequest.class)))
        .thenReturn(dto);

    String body = objectMapper.writeValueAsString(PreEntrySafetyCheckSubmitRequest.builder()
        .dispatchId(100L)
        .vehicleId(200L)
        .driverId(300L)
        .warehouseCode("W1")
        .remarks("gate check")
        .items(List.of(
            PreEntrySafetyCheckSubmitRequest.SafetyItemSubmit.builder()
                .category("TIRES")
                .itemName("Front left")
                .status("OK")
                .build()))
        .build());

    mockMvc.perform(post("/api/admin/pre-entry-safety/submit")
            .contentType(MediaType.APPLICATION_JSON)
            .content(body))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.id").value(21))
        .andExpect(jsonPath("$.dispatchId").value(100))
        .andExpect(jsonPath("$.status").value("PASSED"));
  }

  @Test
  void submitSafetyCheck_returnsBadRequestWhenServiceRejects() throws Exception {
    when(preEntrySafetyCheckService.submitSafetyCheck(any(PreEntrySafetyCheckSubmitRequest.class)))
        .thenThrow(new InvalidDispatchDataException("dispatchId", "already exists"));

    String body = objectMapper.writeValueAsString(PreEntrySafetyCheckSubmitRequest.builder()
        .dispatchId(100L)
        .vehicleId(200L)
        .driverId(300L)
        .items(List.of(
            PreEntrySafetyCheckSubmitRequest.SafetyItemSubmit.builder()
                .category("TIRES")
                .itemName("Front left")
                .status("OK")
                .build()))
        .build());

    mockMvc.perform(post("/api/admin/pre-entry-safety/submit")
            .contentType(MediaType.APPLICATION_JSON)
            .content(body))
        .andExpect(status().isBadRequest());
  }

  @Test
  void approveConditionalOverride_setsPathVariableIntoRequestAndReturnsOk() throws Exception {
    PreEntrySafetyCheckDto dto = PreEntrySafetyCheckDto.builder()
        .id(22L)
        .dispatchId(101L)
        .status("PASSED")
        .build();

    when(preEntrySafetyCheckService.approveConditionalOverride(any(SafetyConditionalOverrideRequest.class)))
        .thenReturn(dto);

    String body = objectMapper.writeValueAsString(SafetyConditionalOverrideRequest.builder()
        .safetyCheckId(55L)
        .decision("APPROVED")
        .remarks("Supervisor approved")
        .build());

    mockMvc.perform(post("/api/admin/pre-entry-safety/55/override")
            .contentType(MediaType.APPLICATION_JSON)
            .content(body))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.id").value(22))
        .andExpect(jsonPath("$.status").value("PASSED"));

    verify(preEntrySafetyCheckService).approveConditionalOverride(any(SafetyConditionalOverrideRequest.class));
  }

  @Test
  void getByDispatchId_returnsPayload() throws Exception {
    PreEntrySafetyCheckDto dto = PreEntrySafetyCheckDto.builder()
        .id(23L)
        .dispatchId(102L)
        .status("CONDITIONAL")
        .build();

    when(preEntrySafetyCheckService.getByDispatchId(102L)).thenReturn(dto);

    mockMvc.perform(get("/api/admin/pre-entry-safety/dispatch/102"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.id").value(23))
        .andExpect(jsonPath("$.dispatchId").value(102))
        .andExpect(jsonPath("$.status").value("CONDITIONAL"));
  }

  @Test
  void getPendingConditionalOverrides_returnsList() throws Exception {
    PreEntrySafetyCheckDto dto = PreEntrySafetyCheckDto.builder()
        .id(24L)
        .dispatchId(103L)
        .status("CONDITIONAL")
        .build();

    when(preEntrySafetyCheckService.getPendingConditionalOverrides()).thenReturn(List.of(dto));

    mockMvc.perform(get("/api/admin/pre-entry-safety/pending-overrides"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$[0].id").value(24))
        .andExpect(jsonPath("$[0].dispatchId").value(103));
  }

  @Test
  void uploadPreEntryPhoto_returnsWrappedUrl() throws Exception {
    MockMultipartFile file = new MockMultipartFile(
        "file",
        "gate.jpg",
        MediaType.IMAGE_JPEG_VALUE,
        "fake-image".getBytes());

    when(preEntrySafetyCheckService.uploadInspectionPhoto(any())).thenReturn("/uploads/pre-entry-safety/gate.jpg");

    mockMvc.perform(multipart("/api/admin/pre-entry-safety/photos/upload")
            .file(file))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.success").value(true))
        .andExpect(jsonPath("$.data.url").value("/uploads/pre-entry-safety/gate.jpg"));
  }

  @Test
  void list_returnsFilteredRows() throws Exception {
    PreEntrySafetyCheckDto dto = PreEntrySafetyCheckDto.builder()
        .id(25L)
        .dispatchId(104L)
        .status("PASSED")
        .build();

    when(preEntrySafetyCheckService.listSafetyChecks(any(), any(), any(), any(), any())).thenReturn(List.of(dto));

    mockMvc.perform(get("/api/admin/pre-entry-safety")
            .param("status", "PASSED")
            .param("warehouseCode", "KHB")
            .param("fromDate", "2026-03-01")
            .param("toDate", "2026-03-31"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$[0].id").value(25))
        .andExpect(jsonPath("$[0].dispatchId").value(104));
  }

  @Test
  void getById_returnsPayload() throws Exception {
    PreEntrySafetyCheckDto dto = PreEntrySafetyCheckDto.builder()
        .id(30L)
        .dispatchId(105L)
        .status("FAILED")
        .build();

    when(preEntrySafetyCheckService.getById(30L)).thenReturn(dto);

    mockMvc.perform(get("/api/admin/pre-entry-safety/30"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.id").value(30))
        .andExpect(jsonPath("$.dispatchId").value(105))
        .andExpect(jsonPath("$.status").value("FAILED"));
  }

  @Test
  void updateSafetyCheck_returnsUpdatedPayload() throws Exception {
    PreEntrySafetyCheckDto dto = PreEntrySafetyCheckDto.builder()
        .id(40L)
        .dispatchId(100L)
        .status("CONDITIONAL")
        .build();

    when(preEntrySafetyCheckService.updateSafetyCheck(eq(40L), any(PreEntrySafetyCheckSubmitRequest.class)))
        .thenReturn(dto);

    String body = objectMapper.writeValueAsString(PreEntrySafetyCheckSubmitRequest.builder()
        .dispatchId(100L)
        .vehicleId(200L)
        .driverId(300L)
        .warehouseCode("KHB")
        .remarks("updated")
        .items(List.of(
            PreEntrySafetyCheckSubmitRequest.SafetyItemSubmit.builder()
                .category("TIRES")
                .itemName("Front left")
                .status("CONDITIONAL")
                .build()))
        .build());

    mockMvc.perform(put("/api/admin/pre-entry-safety/40")
            .contentType(MediaType.APPLICATION_JSON)
            .content(body))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.id").value(40))
        .andExpect(jsonPath("$.status").value("CONDITIONAL"));
  }

  @Test
  void deleteSafetyCheck_returnsNoContent() throws Exception {
    mockMvc.perform(delete("/api/admin/pre-entry-safety/88"))
        .andExpect(status().isNoContent());

    verify(preEntrySafetyCheckService).deleteSafetyCheck(88L);
  }
}
