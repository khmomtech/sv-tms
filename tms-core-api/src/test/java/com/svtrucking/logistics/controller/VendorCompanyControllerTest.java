package com.svtrucking.logistics.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.svtrucking.logistics.enums.PartnershipType;
import com.svtrucking.logistics.model.PartnerCompany;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.jdbc.Sql;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
import static org.hamcrest.Matchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Transactional
@Sql(scripts = {"classpath:cleanup.sql", "classpath:import.sql"}, executionPhase = Sql.ExecutionPhase.BEFORE_TEST_METHOD)
class VendorCompanyControllerTest {

  @Autowired
  private MockMvc mockMvc;

  @Autowired
  private ObjectMapper objectMapper;

  private PartnerCompany basePartner(String code, String license) {
    return PartnerCompany.builder()
        .companyCode(code)
        .companyName("Controller Vendor " + code)
        .businessLicense(license)
        .contactPerson("Bob")
        .email(code.toLowerCase() + "@example.com")
        .phone("+1555111" + code.substring(code.length() - 3))
        .address("456 Avenue")
        .partnershipType(PartnershipType.DRIVER_FLEET)
        .build();
  }

  @Test
  @WithMockUser(username = "superadmin", roles = {"SUPERADMIN"})
  @DisplayName("license exists endpoint returns false then true after creation (case insensitive)")
  void licenseExistsEndpoint_flow() throws Exception {
    // Use timestamp-based unique values to avoid conflicts
    String timestamp = String.valueOf(System.currentTimeMillis());
    String uniqueLicense = "TEST-LIC-" + timestamp;
    String uniqueCompanyCode = "PART-" + timestamp;
    
    // Initial should be false
    mockMvc.perform(get("/api/vendors/license/" + uniqueLicense + "/exists"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.data", is(false)));

    // Create vendor with unique code and license
    PartnerCompany vendor = basePartner(uniqueCompanyCode, uniqueLicense);
    mockMvc.perform(post("/api/vendors")
            .contentType(MediaType.APPLICATION_JSON)
            .content(objectMapper.writeValueAsString(vendor)))
        .andExpect(status().isCreated())
        .andExpect(jsonPath("$.data.companyCode", is(uniqueCompanyCode)));

    // License exists with different case
    mockMvc.perform(get("/api/vendors/license/" + uniqueLicense.toLowerCase() + "/exists"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.data", is(true)));
  }
}
