package com.svtrucking.logistics.security;

import com.svtrucking.logistics.model.User;
import com.svtrucking.logistics.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;

import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@TestPropertySource(properties = {
    "management.endpoints.web.exposure.include=*",
    "test.security.enabled=false",
    "app.driver.skip-device-check=false",
    "app.driver.login-bypass=false",
    "app.reviewer.bypass=false"
})
public class SecurityHardeningIntegrationTest {

  @Autowired private MockMvc mvc;
  @Autowired private UserRepository userRepository;
  @Autowired private PasswordEncoder passwordEncoder;

  @Test
  public void actuator_health_isPublic() throws Exception {
    mvc.perform(get("/actuator/health"))
        .andExpect(status().isOk());
  }

  @Test
  public void actuator_env_isNotPublic() throws Exception {
    mvc.perform(get("/actuator/env"))
        .andExpect(result -> {
          int s = result.getResponse().getStatus();
          assertTrue(s == 401 || s == 403, "expected 401/403 but was " + s);
        });
  }

  @Test
  public void debug_endpoints_areNotPublic() throws Exception {
    mvc.perform(get("/api/debug/anything"))
        .andExpect(result -> {
          int s = result.getResponse().getStatus();
          assertTrue(s == 401 || s == 403, "expected 401/403 but was " + s);
        });
  }

  @Test
  public void driver_login_requires_device_id_by_default() throws Exception {
    User u = new User();
    u.setUsername("driver1");
    u.setEmail("driver1@test.local");
    u.setPassword(passwordEncoder.encode("test-pass"));
    u.setEnabled(true);
    u.setAccountNonLocked(true);
    u.setAccountNonExpired(true);
    u.setCredentialsNonExpired(true);
    userRepository.save(u);

    mvc.perform(post("/api/auth/driver/login")
            .contentType(MediaType.APPLICATION_JSON)
            .content("{\"username\":\"driver1\",\"password\":\"test-pass\"}"))
        .andExpect(status().isBadRequest());
  }
}
