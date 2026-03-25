package com.svtrucking.logistics.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.svtrucking.logistics.dto.*;
import com.svtrucking.logistics.enums.*;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import com.svtrucking.logistics.config.TestRedisConfig;
import com.svtrucking.logistics.config.TestSecurityConfig;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Date;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.*;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.anonymous;

/**
 * Integration test for Vehicle Master Setup workflow
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Import({TestRedisConfig.class, TestSecurityConfig.class})
@Transactional
class VehicleSetupIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    @WithMockUser(roles = "ADMIN")
    void setupVehicle_CompleteWorkflow_ShouldCreateActiveVehicle() throws Exception {
        // Given
        VehicleSetupRequest request = createCompleteSetupRequest();

        // When & Then
        String expectedLicensePlate = request.getLicensePlate();
        mockMvc.perform(post("/api/admin/vehicles/setup")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request))
                .with(csrf()))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.licensePlate").value(expectedLicensePlate))
                .andExpect(jsonPath("$.data.status").value("AVAILABLE"))
                .andExpect(jsonPath("$.data.ownership").value("OWNED"))
                .andExpect(jsonPath("$.message").value("Vehicle setup completed successfully"));
    }

    @Test
    @WithMockUser(roles = "ADMIN")
    void setupVehicle_MissingDocuments_ShouldFail() throws Exception {
        // Given
        VehicleSetupRequest request = createSetupRequestWithoutDocuments();

        // When & Then
        mockMvc.perform(post("/api/admin/vehicles/setup")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request))
                .with(csrf()))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.message").value("❌ Vehicle setup failed"));
    }

    @Test
    @WithMockUser(roles = "ADMIN")
    void checkVehicleReadyStatus_ActiveVehicle_ShouldReturnTrue() throws Exception {
        // First create a vehicle
        VehicleSetupRequest setupRequest = createCompleteSetupRequest();
        String setupResponse = mockMvc.perform(post("/api/admin/vehicles/setup")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(setupRequest))
                .with(csrf()))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();

        // Parse the response to get the created vehicle
        VehicleDto createdVehicle = objectMapper.readValue(
                objectMapper.readTree(setupResponse).get("data").toString(),
                VehicleDto.class);

        // Then check ready status
        mockMvc.perform(get("/api/admin/vehicles/{vehicleId}/ready-status", createdVehicle.getId())
                .with(csrf()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data").value(true));
    }

    @Test
    void setupVehicle_Unauthorized_ShouldFail() throws Exception {
        // Given
        VehicleSetupRequest request = createCompleteSetupRequest();

        // When & Then
        mockMvc.perform(post("/api/admin/vehicles/setup")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request))
                .with(anonymous()))
            .andExpect(result -> {
                int status = result.getResponse().getStatus();
                assertTrue(status == 401 || status == 403, "Expected 401/403 but was " + status);
            });
    }

    private VehicleSetupRequest createCompleteSetupRequest() {
        String unique = UUID.randomUUID().toString().replace("-", "").substring(0, 6).toUpperCase();
        String licensePlate = "TEST-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();
        return VehicleSetupRequest.builder()
                .licensePlate(licensePlate)
                .vin("1HGCM82633A" + unique)
                .model("F-150")
                .manufacturer("Ford")
                .yearMade(2023)
                .type(VehicleType.TRUCK)
                .ownership(VehicleOwnership.OWNED)
                .truckSize(TruckSize.MEDIUM_TRUCK)
                .maxWeight(BigDecimal.valueOf(5000))
                .maxVolume(BigDecimal.valueOf(100))
                .fuelConsumption(BigDecimal.valueOf(12.5))
                .mileage(BigDecimal.valueOf(10000))
                .qtyPalletsCapacity(20)
                .assignedZone("Zone A")
                .requiredLicenseClass("C")
                .gpsDeviceId("GPS-TEST-001")
                .remarks("Integration test vehicle")
                .documents(createRequiredDocuments(unique))
                .maintenancePolicy(createMaintenancePolicy())
                .build();
    }

    private VehicleSetupRequest createSetupRequestWithoutDocuments() {
        return VehicleSetupRequest.builder()
                .licensePlate("TEST-002")
                .vin("1HGCM82633A123457")
                .model("F-150")
                .manufacturer("Ford")
                .yearMade(2023)
                .type(VehicleType.TRUCK)
                .ownership(VehicleOwnership.OWNED)
                .truckSize(TruckSize.MEDIUM_TRUCK)
                .maxWeight(BigDecimal.valueOf(5000))
                .maxVolume(BigDecimal.valueOf(100))
                .fuelConsumption(BigDecimal.valueOf(12.5))
                .mileage(BigDecimal.valueOf(10000))
                .qtyPalletsCapacity(20)
                .assignedZone("Zone A")
                .requiredLicenseClass("C")
                .remarks("Test vehicle without documents")
                .build();
    }

    private List<VehicleDocumentRequest> createRequiredDocuments(String unique) {
        LocalDate futureDate = LocalDate.now().plusYears(1);

        return List.of(
                VehicleDocumentRequest.builder()
                        .documentType("REGISTRATION")
                        .documentNumber("REG-" + unique)
                        .expiryDate(futureDate)
                        .documentUrl("/uploads/docs/reg-test-" + unique + ".pdf")
                        .build(),
                VehicleDocumentRequest.builder()
                        .documentType("INSURANCE")
                        .documentNumber("INS-" + unique)
                        .expiryDate(futureDate)
                        .documentUrl("/uploads/docs/ins-test-" + unique + ".pdf")
                        .build(),
                VehicleDocumentRequest.builder()
                        .documentType("INSPECTION")
                        .documentNumber("INSP-" + unique)
                        .expiryDate(futureDate)
                        .documentUrl("/uploads/docs/insp-test-" + unique + ".pdf")
                        .build()
        );
    }

    private MaintenancePolicyRequest createMaintenancePolicy() {
        return MaintenancePolicyRequest.builder()
                .schedules(List.of())
                .build();
    }
}
