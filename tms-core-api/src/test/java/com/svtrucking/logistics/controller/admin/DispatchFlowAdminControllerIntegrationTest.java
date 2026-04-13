package com.svtrucking.logistics.controller.admin;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.svtrucking.logistics.dto.dispatchflow.DispatchFlowTemplateUpsertRequest;
import com.svtrucking.logistics.repository.DispatchFlowTemplateRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;

@SpringBootTest
@AutoConfigureMockMvc
class DispatchFlowAdminControllerIntegrationTest {

  @Autowired
  private MockMvc mockMvc;

  @Autowired
  private ObjectMapper objectMapper;

  @Autowired
  private DispatchFlowTemplateRepository templateRepository;

  @Test
  @WithMockUser(username = "superadmin", authorities = {"dispatch:flow:manage"})
  void createTemplate_returnsPersistedId_andAppearsInList() throws Exception {
    String code = "IT_TEMP_TEMPLATE";
    templateRepository.findByCodeIgnoreCase(code).ifPresent(templateRepository::delete);

    DispatchFlowTemplateUpsertRequest request = new DispatchFlowTemplateUpsertRequest();
    request.setCode(code);
    request.setName("Integration Temp Template");
    request.setDescription("Created by integration test");
    request.setActive(true);

    mockMvc.perform(post("/api/admin/dispatch-flow/templates")
            .contentType(MediaType.APPLICATION_JSON)
            .content(objectMapper.writeValueAsString(request)))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.success").value(true))
        .andExpect(jsonPath("$.data.id").isNumber())
        .andExpect(jsonPath("$.data.code").value(code))
        .andExpect(jsonPath("$.data.name").value("Integration Temp Template"));

    mockMvc.perform(get("/api/admin/dispatch-flow/templates"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.data[?(@.code=='IT_TEMP_TEMPLATE')]").isNotEmpty());

    templateRepository.findByCodeIgnoreCase(code).ifPresent(templateRepository::delete);
  }
}
