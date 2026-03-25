package com.svtrucking.logistics.infrastructure.security;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class SecuritySurfaceTest {

  @Autowired private MockMvc mvc;

  @Test
  void actuatorHealth_isPublic() throws Exception {
    mvc.perform(get("/actuator/health")).andExpect(status().isOk());
  }

  @Test
  void safetyEndpoints_requireAuthentication() throws Exception {
    // With anonymous auth present, request reaches method security (@PreAuthorize) and is denied.
    mvc.perform(get("/api/admin/safety-checks")).andExpect(status().isForbidden());
  }

  @Test
  void nonSafetyEndpoints_areDisabled() throws Exception {
    mvc.perform(get("/api/admin/users")).andExpect(status().isForbidden());
  }

  @Test
  void removedPreLoadingEndpoints_areNotFound() throws Exception {
    mvc.perform(get("/api/pre-loading-safety/latest/1")).andExpect(status().isNotFound());
  }
}
