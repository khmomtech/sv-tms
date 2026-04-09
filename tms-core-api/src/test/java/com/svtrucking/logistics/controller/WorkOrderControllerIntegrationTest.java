package com.svtrucking.logistics.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.svtrucking.logistics.config.TestRedisConfig;
import com.svtrucking.logistics.dto.WorkOrderDto;
import com.svtrucking.logistics.enums.Priority;
import com.svtrucking.logistics.enums.WorkOrderStatus;
import com.svtrucking.logistics.enums.WorkOrderType;
import com.svtrucking.logistics.model.*;
import com.svtrucking.logistics.repository.*;
import org.junit.jupiter.api.BeforeEach;
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

import java.time.LocalDateTime;

import static org.hamcrest.Matchers.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Import({TestRedisConfig.class, com.svtrucking.logistics.config.TestSecurityConfig.class})
@Transactional
class WorkOrderControllerIntegrationTest {

  @Autowired private MockMvc mockMvc;
  @Autowired private ObjectMapper objectMapper;
  @Autowired private WorkOrderRepository workOrderRepository;
  @Autowired private VehicleRepository vehicleRepository;
  @Autowired private UserRepository userRepository;

  private Vehicle testVehicle;
  private User testUser;
  private User managerUser;
  private int woCounter = 1;

  @BeforeEach
  void setUp() {
    workOrderRepository.deleteAll();

    testUser =
        userRepository
            .findByUsername("admin")
            .orElseGet(
                () -> {
                  User user = new User();
                  user.setUsername("admin");
                  user.setPassword("password");
                  user.setEmail("admin@test.com");
                  return userRepository.save(user);
                });

    managerUser =
        userRepository
            .findByUsername("manager")
            .orElseGet(
                () -> {
                  User user = new User();
                  user.setUsername("manager");
                  user.setPassword("password");
                  user.setEmail("manager@test.com");
                  return userRepository.save(user);
                });

    testVehicle =
        vehicleRepository
            .findByLicensePlate("TEST-002")
            .orElseGet(
                () ->
                    vehicleRepository.save(
                        Vehicle.builder()
                            .licensePlate("TEST-002")
                            .manufacturer("Honda")
                            .model("Accord")
                            .yearMade(2021)
                            .mileage(java.math.BigDecimal.valueOf(15000))
                            .status(com.svtrucking.logistics.enums.VehicleStatus.AVAILABLE)
                            .type(com.svtrucking.logistics.enums.VehicleType.TRUCK)
                            .build()));
  }

  /**
   * Helper method to generate unique WO numbers for test data
   */
  private String generateTestWoNumber() {
    int year = java.time.LocalDateTime.now().getYear();
    return String.format("WO-%d-%05d", year, woCounter++);
  }

  @Test
  @WithMockUser(username = "admin", roles = {"ADMIN"})
  void createWorkOrder_WithValidData_ShouldReturnCreated() throws Exception {
    WorkOrderDto dto =
        WorkOrderDto.builder()
            .title("Engine Repair")
            .description("Repair engine issue")
            .vehicleId(testVehicle.getId())
            .type(WorkOrderType.PREVENTIVE)
            .priority(Priority.HIGH)
            .estimatedCost(500.0)
            .build();

    mockMvc
        .perform(
            post("/api/admin/work-orders")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(dto)))
        .andExpect(status().isCreated())
        .andExpect(jsonPath("$.title", is("Engine Repair")))
        .andExpect(jsonPath("$.type", is("PREVENTIVE")))
        .andExpect(jsonPath("$.priority", is("HIGH")))
        .andExpect(jsonPath("$.status", is("OPEN")))
        .andExpect(jsonPath("$.woNumber", notNullValue()));
  }

  @Test
  @WithMockUser(username = "technician", roles = {"TECHNICIAN"})
  void getWorkOrder_WhenExists_ShouldReturnWorkOrder() throws Exception {
    WorkOrder workOrder =
        workOrderRepository.save(
            WorkOrder.builder()
                .woNumber(generateTestWoNumber())
                .title("Brake Service")
                .description("Replace brake pads")
                .vehicle(testVehicle)
                .type(WorkOrderType.PREVENTIVE)
                .priority(Priority.NORMAL)
                .status(WorkOrderStatus.OPEN)
                .scheduledDate(LocalDateTime.now())
                .createdBy(testUser)
                .build());

    mockMvc
        .perform(get("/api/admin/work-orders/" + workOrder.getId()))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.id", is(workOrder.getId().intValue())))
        .andExpect(jsonPath("$.title", is("Brake Service")))
        .andExpect(jsonPath("$.type", is("PREVENTIVE")));
  }

  @Test
  @WithMockUser(username = "admin", roles = {"ADMIN"})
  void updateWorkOrderStatus_ShouldReturnUpdated() throws Exception {
    WorkOrder workOrder =
        workOrderRepository.save(
            WorkOrder.builder()
                .woNumber(generateTestWoNumber())
                .title("Oil Change")
                .vehicle(testVehicle)
                .type(WorkOrderType.PREVENTIVE)
                .priority(Priority.LOW)
                .status(WorkOrderStatus.OPEN)
                .createdBy(testUser)
                .build());

    mockMvc
        .perform(
            patch("/api/admin/work-orders/" + workOrder.getId() + "/status")
                .param("status", "IN_PROGRESS"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.status", is("IN_PROGRESS")));
  }

  @Test
  @WithMockUser(username = "manager", roles = {"MANAGER"})
  void approveWorkOrder_WithManagerRole_ShouldReturnOk() throws Exception {
    WorkOrder workOrder =
        workOrderRepository.save(
            WorkOrder.builder()
                .woNumber(generateTestWoNumber())
                .title("Transmission Repair")
                .vehicle(testVehicle)
                .type(WorkOrderType.REPAIR)
                .priority(Priority.URGENT)
                .status(WorkOrderStatus.OPEN)
                .actualCost(java.math.BigDecimal.valueOf(1200.0))
                .createdBy(testUser)
                .build());

    mockMvc
        .perform(post("/api/admin/work-orders/" + workOrder.getId() + "/approve"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.status", is("OPEN")))
        .andExpect(jsonPath("$.approved", is(true)))
        .andExpect(jsonPath("$.approvedBy", notNullValue()));
  }

  @Test
  @WithMockUser(username = "admin", roles = {"ADMIN"})
  void deleteWorkOrder_ShouldReturnNoContent() throws Exception {
    WorkOrder workOrder =
        workOrderRepository.save(
            WorkOrder.builder()
                .woNumber(generateTestWoNumber())
                .title("Test Work Order")
                .vehicle(testVehicle)
                .type(WorkOrderType.PREVENTIVE)
                .priority(Priority.LOW)
                .status(WorkOrderStatus.OPEN)
                .createdBy(testUser)
                .build());

    mockMvc
        .perform(delete("/api/admin/work-orders/" + workOrder.getId()))
        .andExpect(status().isNoContent());
  }

  @Test
  @WithMockUser(username = "driver", roles = {"DRIVER"})
  void createWorkOrder_WithDriverRole_ShouldReturnForbidden() throws Exception {
    WorkOrderDto dto =
        WorkOrderDto.builder()
            .title("Unauthorized Work Order")
            .vehicleId(testVehicle.getId())
            .type(WorkOrderType.REPAIR)
            .priority(Priority.HIGH)
            .build();

    mockMvc
        .perform(
            post("/api/admin/work-orders")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(dto)))
        .andExpect(status().isForbidden());
  }
}
