package com.svtrucking.logistics.integration;

import com.svtrucking.logistics.model.Dispatch;
import com.svtrucking.logistics.model.Driver;
import com.svtrucking.logistics.model.Vehicle;
import com.svtrucking.logistics.repository.DispatchRepository;
import com.svtrucking.logistics.repository.DriverRepository;
import com.svtrucking.logistics.repository.VehicleRepository;
import org.junit.jupiter.api.Test;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureTestDatabase
@AutoConfigureMockMvc(addFilters = false)
@Transactional
@ActiveProfiles("test")
public class ChangeTruckIntegrationTest {

    @Autowired
    private DispatchRepository dispatchRepository;
    @Autowired
    private DriverRepository driverRepository;
    @Autowired
    private VehicleRepository vehicleRepository;
    // @Autowired
    // private AssignmentVehicleToDriverRepository assignmentRepo;

    @Autowired
    private MockMvc mockMvc;

    @Test
    @WithMockUser(roles = "ADMIN")
    public void changeTruck_returnsWarning_whenDriverNotAssignedToNewVehicle() throws Exception {
        // Create driver with required fields
        Driver driver = new Driver();
        driver.setName("Integration Driver");
        driver.setPhone("+85512345678");
        driver.setLicenseNumber("DL-INT-001");
        driver = driverRepository.save(driver);

        // Create original vehicle and save (set all required fields)
        Vehicle original = new Vehicle();
        original.setLicensePlate("ORIG-123");
        original.setManufacturer("TestMaker");
        original.setModel("ModelX");
        original.setMileage(new BigDecimal("1000.00"));
        original.setYearMade(2020);
        original.setStatus(com.svtrucking.logistics.enums.VehicleStatus.AVAILABLE);
        original.setType(com.svtrucking.logistics.enums.VehicleType.TRUCK);
        original = vehicleRepository.save(original);

        // AssignmentVehicleToDriver logic removed

        // Create dispatch assigned to driver and original vehicle
        Dispatch dispatch = new Dispatch();
        dispatch.setDriver(driver);
        dispatch.setVehicle(original);
        dispatch.setStatus(com.svtrucking.logistics.enums.DispatchStatus.ASSIGNED);
        dispatch.setStartTime(java.time.LocalDateTime.now());
        dispatch.setEstimatedArrival(java.time.LocalDateTime.now().plusHours(1));
        dispatch = dispatchRepository.save(dispatch);

        // Create a new vehicle that driver is NOT assigned to (set all required fields)
        Vehicle newVehicle = new Vehicle();
        newVehicle.setLicensePlate("NEW-999");
        newVehicle.setManufacturer("NewMaker");
        newVehicle.setModel("ModelY");
        newVehicle.setMileage(new BigDecimal("500.00"));
        newVehicle.setYearMade(2022);
        newVehicle.setStatus(com.svtrucking.logistics.enums.VehicleStatus.AVAILABLE);
        newVehicle.setType(com.svtrucking.logistics.enums.VehicleType.TRUCK);
        newVehicle = vehicleRepository.save(newVehicle);

        // Create a conflicting active dispatch already using the new vehicle.
        Dispatch conflict = new Dispatch();
        conflict.setVehicle(newVehicle);
        conflict.setStatus(com.svtrucking.logistics.enums.DispatchStatus.ASSIGNED);
        conflict.setStartTime(java.time.LocalDateTime.now());
        conflict.setEstimatedArrival(java.time.LocalDateTime.now().plusHours(2));
        dispatchRepository.save(conflict);
        // AssignmentVehicleToDriver assign = new AssignmentVehicleToDriver(); //
        // Removed
        // assign.setDriver(driver);
        // assign.setVehicle(original);
        // assignmentRepo.save(assign); // Removed

        mockMvc
                .perform(
                        put("/api/admin/dispatches/" + dispatch.getId() + "/change-truck?vehicleId="
                                + newVehicle.getId())
                                .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.errors.warnings").exists());
    }
}
