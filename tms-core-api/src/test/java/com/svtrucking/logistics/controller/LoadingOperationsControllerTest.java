package com.svtrucking.logistics.controller;

import com.svtrucking.logistics.dto.LoadingDocumentDto;
import com.svtrucking.logistics.enums.LoadingDocumentType;
import com.svtrucking.logistics.service.LoadingWorkflowService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class LoadingOperationsControllerTest {

  private MockMvc mockMvc;
  private LoadingWorkflowService loadingWorkflowService;

  @BeforeEach
  void setup() {
    loadingWorkflowService = Mockito.mock(LoadingWorkflowService.class);
    LoadingOperationsController controller = new LoadingOperationsController(loadingWorkflowService);
    mockMvc = MockMvcBuilders.standaloneSetup(controller).build();
  }

  @Test
  void uploadDocument_returnsBadRequestForInvalidDocumentType() throws Exception {
    MockMultipartFile file =
        new MockMultipartFile("file", "proof.jpg", "image/jpeg", "fake".getBytes());

    mockMvc.perform(
            multipart("/api/loading-ops/sessions/9/documents")
                .file(file)
                .param("documentType", "NOT_A_REAL_TYPE"))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.success").value(false))
        .andExpect(jsonPath("$.message").value("Invalid documentType: NOT_A_REAL_TYPE"));
  }

  @Test
  void uploadDocument_defaultsToOtherTypeWhenMissingTypeParam() throws Exception {
    MockMultipartFile file =
        new MockMultipartFile("file", "proof.jpg", "image/jpeg", "fake".getBytes());

    Mockito.when(loadingWorkflowService.uploadDocument(eq(9L), eq(LoadingDocumentType.OTHER), any()))
        .thenReturn(LoadingDocumentDto.builder().id(1L).build());

    mockMvc.perform(multipart("/api/loading-ops/sessions/9/documents").file(file))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.success").value(true));
  }
}
