package com.svtrucking.logistics.controller.drivers;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.svtrucking.logistics.config.TestRedisConfig;
import com.svtrucking.logistics.dto.requests.DriverCreateRequest;
import com.svtrucking.logistics.dto.requests.DriverUpdateRequest;
import com.svtrucking.logistics.enums.DriverStatus;
import com.svtrucking.logistics.enums.VehicleType;
import com.svtrucking.logistics.model.Driver;
import com.svtrucking.logistics.model.DriverDocument;
import com.svtrucking.logistics.repository.DriverDocumentRepository;
import com.svtrucking.logistics.repository.DriverRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

@SpringBootTest(
    properties = {
        "spring.autoconfigure.exclude="
            + "org.springframework.boot.autoconfigure.data.redis.RedisAutoConfiguration,"
            + "org.springframework.boot.autoconfigure.data.redis.RedisRepositoriesAutoConfiguration,"
            + "org.springframework.boot.autoconfigure.websocket.servlet.WebSocketServletAutoConfiguration"
    })
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Transactional
@Import({TestRedisConfig.class, com.svtrucking.logistics.config.TestSecurityConfig.class})
class DriverManagementLicenseIntegrationTest {

  @Autowired private MockMvc mockMvc;
  @Autowired private ObjectMapper objectMapper;
  @Autowired private DriverRepository driverRepository;
  @Autowired private DriverDocumentRepository driverDocumentRepository;

  @Test
  @WithMockUser(username = "admin", authorities = {"driver:manage", "driver:view_all"})
  void createDriverPersistsLicenseDocumentAndRejectsDuplicate() throws Exception {
    DriverCreateRequest firstRequest = baseCreateRequest("DRVLIC1001", "Alice", "Driver", "099111111");

    mockMvc.perform(post("/api/admin/drivers/add")
            .contentType(MediaType.APPLICATION_JSON)
            .content(objectMapper.writeValueAsString(firstRequest)))
        .andExpect(status().isCreated())
        .andExpect(jsonPath("$.success").value(true))
        .andExpect(jsonPath("$.data.licenseNumber").value("DRVLIC1001"));

    Driver createdDriver = driverRepository.findTopByPhone("099111111").orElseThrow();
    assertThat(driverDocumentRepository.findLicenseDocumentsByDriverId(createdDriver.getId()))
        .hasSize(1);
    assertThat(driverDocumentRepository.findLicenseDocumentsByDriverId(createdDriver.getId()).get(0).getName())
        .isEqualTo("DRVLIC1001");

    DriverCreateRequest duplicateRequest = baseCreateRequest("drvlic1001", "Bob", "Driver", "099222222");

    mockMvc.perform(post("/api/admin/drivers/add")
            .contentType(MediaType.APPLICATION_JSON)
            .content(objectMapper.writeValueAsString(duplicateRequest)))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.success").value(false))
        .andExpect(jsonPath("$.message").value(org.hamcrest.Matchers.containsString("licenseNumber")));
  }

  @Test
  @WithMockUser(username = "admin", authorities = {"driver:manage", "driver:view_all"})
  void updateDriverRejectsOtherDriversLicenseAndReadEndpointsHydrateLicense() throws Exception {
    Driver firstDriver = saveDriver("John", "One", "098100001");
    saveLicenseDocument(firstDriver, "LICONE001");

    Driver secondDriver = saveDriver("Jane", "Two", "098100002");
    saveLicenseDocument(secondDriver, "LICTWO002");

    DriverUpdateRequest duplicateUpdate = baseUpdateRequest("Jane", "Two", "LICONE001", "098100002");

    mockMvc.perform(put("/api/admin/drivers/update/{id}", secondDriver.getId())
            .contentType(MediaType.APPLICATION_JSON)
            .content(objectMapper.writeValueAsString(duplicateUpdate)))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.success").value(false))
        .andExpect(jsonPath("$.message").value(org.hamcrest.Matchers.containsString("licenseNumber")));

    DriverUpdateRequest uniqueUpdate = baseUpdateRequest("Jane", "Two", "lictwo999", "098100002");

    mockMvc.perform(put("/api/admin/drivers/update/{id}", secondDriver.getId())
            .contentType(MediaType.APPLICATION_JSON)
            .content(objectMapper.writeValueAsString(uniqueUpdate)))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.success").value(true))
        .andExpect(jsonPath("$.data.licenseNumber").value("LICTWO999"));

    assertThat(driverDocumentRepository.findLicenseDocumentsByDriverId(secondDriver.getId()))
        .hasSize(1);
    assertThat(driverDocumentRepository.findLicenseDocumentsByDriverId(secondDriver.getId()).get(0).getName())
        .isEqualTo("LICTWO999");

    mockMvc.perform(get("/api/admin/drivers/{id}", secondDriver.getId()))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.data.licenseNumber").value("LICTWO999"));

    mockMvc.perform(get("/api/admin/drivers/list")
            .param("page", "0")
            .param("size", "10"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.data.content[*].licenseNumber")
            .value(org.hamcrest.Matchers.hasItem("LICTWO999")));

    mockMvc.perform(get("/api/admin/drivers/search")
            .param("query", "Jane"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.data[0].licenseNumber").value("LICTWO999"));
  }

  private DriverCreateRequest baseCreateRequest(
      String licenseNumber, String firstName, String lastName, String phone) {
    return DriverCreateRequest.builder()
        .firstName(firstName)
        .lastName(lastName)
        .phone(phone)
        .licenseNumber(licenseNumber)
        .rating(4.5)
        .isActive(true)
        .vehicleType(VehicleType.TRUCK)
        .status(DriverStatus.ONLINE)
        .build();
  }

  private DriverUpdateRequest baseUpdateRequest(
      String firstName, String lastName, String licenseNumber, String phone) {
    return DriverUpdateRequest.builder()
        .firstName(firstName)
        .lastName(lastName)
        .phone(phone)
        .licenseNumber(licenseNumber)
        .rating(4.0)
        .isActive(true)
        .vehicleType(VehicleType.TRUCK)
        .status(DriverStatus.ONLINE)
        .build();
  }

  private Driver saveDriver(String firstName, String lastName, String phone) {
    Driver driver = new Driver();
    driver.setFirstName(firstName);
    driver.setLastName(lastName);
    driver.setPhone(phone);
    driver.setRating(4.0);
    driver.setIsActive(true);
    driver.setVehicleType(VehicleType.TRUCK);
    driver.setStatus(DriverStatus.ONLINE);
    driver.setPartner(false);
    return driverRepository.save(driver);
  }

  private void saveLicenseDocument(Driver driver, String licenseNumber) {
    DriverDocument document = new DriverDocument();
    document.setDriver(driver);
    document.setCategory("license");
    document.setName(licenseNumber);
    document.setIsRequired(Boolean.TRUE);
    driverDocumentRepository.save(document);
  }
}
