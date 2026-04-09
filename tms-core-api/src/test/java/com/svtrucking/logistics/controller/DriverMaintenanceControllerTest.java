package com.svtrucking.logistics.controller;

import com.svtrucking.logistics.dto.MaintenanceRequestDto;
import com.svtrucking.logistics.model.VehicleDriver;
import com.svtrucking.logistics.model.Vehicle;
import com.svtrucking.logistics.repository.MaintenanceTaskRepository;
import com.svtrucking.logistics.repository.VehicleDriverRepository;
import com.svtrucking.logistics.security.AuthenticatedUserUtil;
import com.svtrucking.logistics.service.MaintenanceRequestService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.util.Collections;
import java.util.Optional;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Unit tests for {@link DriverMaintenanceController} using standalone MockMvc.
 *
 * Security annotations (@PreAuthorize) are bypassed so tests focus on the
 * controller's own authorization logic (driver/vehicle resolution) and HTTP
 * status mapping.
 */
class DriverMaintenanceControllerTest {

        private MockMvc mockMvc;
        private AuthenticatedUserUtil authUtil;
        private VehicleDriverRepository vehicleDriverRepository;
        private MaintenanceTaskRepository maintenanceTaskRepository;
        private MaintenanceRequestService maintenanceRequestService;

        @BeforeEach
        void setUp() {
                authUtil = mock(AuthenticatedUserUtil.class);
                vehicleDriverRepository = mock(VehicleDriverRepository.class);
                maintenanceTaskRepository = mock(MaintenanceTaskRepository.class);
                maintenanceRequestService = mock(MaintenanceRequestService.class);

                DriverMaintenanceController controller = new DriverMaintenanceController(
                                authUtil, vehicleDriverRepository, maintenanceTaskRepository,
                                maintenanceRequestService);

                mockMvc = MockMvcBuilders.standaloneSetup(controller).build();
        }

        // ── GET /api/driver/maintenance/my-vehicle/tasks ─────────────────────────

        @Test
        void getTasks_whenNotADriver_returnsForbidden() throws Exception {
                when(authUtil.getCurrentDriverId()).thenThrow(new RuntimeException("not a driver"));

                mockMvc.perform(get("/api/driver/maintenance/my-vehicle/tasks"))
                                .andExpect(status().isForbidden());
        }

        @Test
        void getTasks_whenNoVehicleAssigned_returnsOkWithEmptyList() throws Exception {
                when(authUtil.getCurrentDriverId()).thenReturn(42L);
                when(vehicleDriverRepository.findActiveByDriverId(42L)).thenReturn(Optional.empty());

                mockMvc.perform(get("/api/driver/maintenance/my-vehicle/tasks"))
                                .andExpect(status().isOk())
                                .andExpect(jsonPath("$.success").value(true));
        }

        @Test
        void getTasks_whenVehicleAssigned_returnsOkWithTasks() throws Exception {
                when(authUtil.getCurrentDriverId()).thenReturn(42L);

                Vehicle vehicle = mock(Vehicle.class);
                when(vehicle.getId()).thenReturn(10L);
                VehicleDriver vd = mock(VehicleDriver.class);
                when(vd.getVehicle()).thenReturn(vehicle);
                when(vehicleDriverRepository.findActiveByDriverId(42L)).thenReturn(Optional.of(vd));

                when(maintenanceTaskRepository.findByVehicleIdOrderByDueDateAsc(10L))
                                .thenReturn(Collections.emptyList());

                mockMvc.perform(get("/api/driver/maintenance/my-vehicle/tasks"))
                                .andExpect(status().isOk())
                                .andExpect(jsonPath("$.success").value(true));
        }

        // ── POST /api/driver/maintenance/requests ────────────────────────────────

        @Test
        void submitRequest_whenNotADriver_returnsForbidden() throws Exception {
                when(authUtil.getCurrentDriverId()).thenThrow(new RuntimeException("not a driver"));

                mockMvc.perform(post("/api/driver/maintenance/requests")
                                .contentType(MediaType.APPLICATION_JSON)
                                .content("{\"title\":\"Oil change\",\"priority\":\"LOW\",\"requestType\":\"PREVENTIVE\"}"))
                                .andExpect(status().isForbidden());
        }

        @Test
        void submitRequest_whenNoVehicleAssigned_returnsBadRequest() throws Exception {
                when(authUtil.getCurrentDriverId()).thenReturn(42L);
                when(vehicleDriverRepository.findActiveByDriverId(42L)).thenReturn(Optional.empty());

                mockMvc.perform(post("/api/driver/maintenance/requests")
                                .contentType(MediaType.APPLICATION_JSON)
                                .content("{\"title\":\"Oil change\",\"priority\":\"LOW\",\"requestType\":\"PREVENTIVE\"}"))
                                .andExpect(status().isBadRequest());
        }

        @Test
        void submitRequest_whenVehicleAssigned_returnsCreated() throws Exception {
                when(authUtil.getCurrentDriverId()).thenReturn(42L);
                when(authUtil.getCurrentUserId()).thenReturn(7L);

                Vehicle vehicle = mock(Vehicle.class);
                when(vehicle.getId()).thenReturn(10L);
                VehicleDriver vd = mock(VehicleDriver.class);
                when(vd.getVehicle()).thenReturn(vehicle);
                when(vehicleDriverRepository.findActiveByDriverId(42L)).thenReturn(Optional.of(vd));

                MaintenanceRequestDto result = new MaintenanceRequestDto();
                when(maintenanceRequestService.create(any(MaintenanceRequestDto.class), anyLong()))
                                .thenReturn(result);

                mockMvc.perform(post("/api/driver/maintenance/requests")
                                .contentType(MediaType.APPLICATION_JSON)
                                .content("{\"title\":\"Oil change\",\"priority\":\"LOW\",\"requestType\":\"PREVENTIVE\"}"))
                                .andExpect(status().isCreated())
                                .andExpect(jsonPath("$.success").value(true));
        }
}
