package com.svtrucking.logistics.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.svtrucking.logistics.model.Vehicle;
import com.svtrucking.logistics.model.Driver;
import com.svtrucking.logistics.repository.VehicleRepository;
import com.svtrucking.logistics.repository.DriverRepository;
import com.svtrucking.logistics.service.AuditRecordService;
import java.math.BigDecimal;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;
import jakarta.transaction.Transactional;
import org.junit.jupiter.api.Test;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc(addFilters = false)
@Transactional
public class VehicleControllerIntegrationTest {

    @Test
    @WithMockUser(username = "superadmin", authorities = { "all_functions" })
    public void updateVehicle_withAssignedDriverNull_shouldSucceed() throws Exception {
        // Create initial vehicle
        Map<String, Object> payload = new HashMap<>();
        payload.put("licensePlate", "TEST-INT-789");
        payload.put("model", "ModelZ");
        payload.put("manufacturer", "MakeZ");
        payload.put("type", "TRUCK");
        payload.put("status", "AVAILABLE");
        payload.put("mileage", 0);
        payload.put("fuelConsumption", 0);
        payload.put("maxWeight", 100.00);
        payload.put("maxVolume", 2.5);
        payload.put("year", 2026);
        payload.put("truckSize", "SMALL_VAN");

        String json = objectMapper.writeValueAsString(payload);
        mockMvc.perform(post("/api/admin/vehicles").contentType(MediaType.APPLICATION_JSON).content(json))
                .andExpect(status().isCreated());

        Optional<Vehicle> created = vehicleRepository.findByLicensePlate("TEST-INT-789");
        assertTrue(created.isPresent(), "Vehicle should be persisted");
        Long id = created.get().getId();

        // Update with assignedDriver: null
        Map<String, Object> update = new HashMap<>();
        update.put("licensePlate", "TEST-INT-789");
        update.put("model", "ModelZ-Updated");
        update.put("assignedDriver", null);

        String updateJson = objectMapper.writeValueAsString(update);
        mockMvc.perform(put("/api/admin/vehicles/" + id).contentType(MediaType.APPLICATION_JSON).content(updateJson))
                .andExpect(status().isOk());
    }

    @Test
    @WithMockUser(username = "superadmin", authorities = { "all_functions" })
    public void updateVehicle_withAssignedDriverObject_shouldSucceed() throws Exception {
        // Create initial vehicle
        Map<String, Object> payload = new HashMap<>();
        payload.put("licensePlate", "TEST-INT-790");
        payload.put("model", "ModelA");
        payload.put("manufacturer", "MakeA");
        payload.put("type", "TRUCK");
        payload.put("status", "AVAILABLE");
        payload.put("mileage", 0);
        payload.put("fuelConsumption", 0);
        payload.put("maxWeight", 100.00);
        payload.put("maxVolume", 2.5);
        payload.put("year", 2026);
        payload.put("truckSize", "SMALL_VAN");

        String json = objectMapper.writeValueAsString(payload);
        mockMvc.perform(post("/api/admin/vehicles").contentType(MediaType.APPLICATION_JSON).content(json))
                .andExpect(status().isCreated());

        Optional<Vehicle> created = vehicleRepository.findByLicensePlate("TEST-INT-790");
        assertTrue(created.isPresent(), "Vehicle should be persisted");
        Long id = created.get().getId();

        // Create and save a real driver
        Driver testDriver = new Driver();
        testDriver.setFirstName("Test");
        testDriver.setLastName("Driver");
        testDriver.setPhone("+85512345678");
        testDriver.setLicenseNumber("DL-TEST-001");
        testDriver = driverRepository.save(testDriver);

        // Use the real driver ID in the update payload
        Map<String, Object> driver = new HashMap<>();
        driver.put("id", testDriver.getId());
        driver.put("fullName", testDriver.getFirstName() + " " + testDriver.getLastName());
        driver.put("phone", testDriver.getPhone());

        Map<String, Object> update = new HashMap<>();
        update.put("licensePlate", "TEST-INT-790");
        update.put("model", "ModelA-Updated");
        update.put("assignedDriver", driver);

        String updateJson = objectMapper.writeValueAsString(update);
        mockMvc.perform(put("/api/admin/vehicles/" + id).contentType(MediaType.APPLICATION_JSON).content(updateJson))
                .andExpect(status().isOk());
    }

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private VehicleRepository vehicleRepository;

    @Autowired
    private DriverRepository driverRepository;

    @org.springframework.boot.test.mock.mockito.MockBean
    private AuditRecordService auditRecordService;

    @Test
    @WithMockUser(username = "superadmin", authorities = { "all_functions" })
    public void createVehicle_withMaxWeightAndVolume_persists() throws Exception {
        Map<String, Object> payload = new HashMap<>();
        payload.put("licensePlate", "TEST-INT-123");
        payload.put("model", "ModelX");
        payload.put("manufacturer", "Make");
        payload.put("type", "TRUCK");
        payload.put("status", "AVAILABLE");
        payload.put("mileage", 0);
        payload.put("fuelConsumption", 0);
        payload.put("maxWeight", 1000.00);
        payload.put("maxVolume", 12.5);
        payload.put("year", 2026);
        payload.put("truckSize", "SMALL_VAN");

        String json = objectMapper.writeValueAsString(payload);

        mockMvc
                .perform(post("/api/admin/vehicles").contentType(MediaType.APPLICATION_JSON).content(json))
                .andExpect(status().isCreated());

        Optional<Vehicle> created = vehicleRepository.findByLicensePlate("TEST-INT-123");
        assertTrue(created.isPresent(), "Vehicle should be persisted");
        // Use compareTo to avoid scale differences
        assertTrue(created.get().getMaxWeight().compareTo(new BigDecimal("1000.00")) == 0);
        assertTrue(created.get().getMaxVolume().compareTo(new BigDecimal("12.50")) == 0);
    }

    @Test
    @WithMockUser(username = "superadmin", authorities = { "all_functions" })
    public void updateVehicle_changesPersistedFields() throws Exception {
        // create initial vehicle
        Map<String, Object> payload = new HashMap<>();
        payload.put("licensePlate", "TEST-INT-456");
        payload.put("model", "ModelY");
        payload.put("manufacturer", "MakeY");
        payload.put("type", "TRUCK");
        payload.put("status", "AVAILABLE");
        payload.put("mileage", 10);
        payload.put("fuelConsumption", 1);
        payload.put("maxWeight", 500.00);
        payload.put("maxVolume", 6.5);
        payload.put("year", 2025);
        payload.put("truckSize", "SMALL_VAN");

        String json = objectMapper.writeValueAsString(payload);

        mockMvc
                .perform(post("/api/admin/vehicles").contentType(MediaType.APPLICATION_JSON).content(json))
                .andExpect(status().isCreated());

        Optional<Vehicle> created = vehicleRepository.findByLicensePlate("TEST-INT-456");
        assertTrue(created.isPresent(), "Vehicle should be persisted");

        Long id = created.get().getId();

        // prepare update
        Map<String, Object> update = new HashMap<>();
        update.put("licensePlate", "TEST-INT-456");
        update.put("model", "ModelY-Updated");
        update.put("maxWeight", 750.00);
        update.put("maxVolume", 9.25);

        String updateJson = objectMapper.writeValueAsString(update);

        mockMvc
                .perform(put("/api/admin/vehicles/" + id).contentType(MediaType.APPLICATION_JSON).content(updateJson))
                .andExpect(status().isOk());

        Optional<Vehicle> updated = vehicleRepository.findById(id);
        assertTrue(updated.isPresent(), "Updated vehicle should exist");
        assertTrue(updated.get().getMaxWeight().compareTo(new BigDecimal("750.00")) == 0);
        assertTrue(updated.get().getMaxVolume().compareTo(new BigDecimal("9.25")) == 0);
    }
}
