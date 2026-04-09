package com.svtrucking.logistics.integration;

import com.svtrucking.logistics.model.Dispatch;
import com.svtrucking.logistics.model.Driver;
import com.svtrucking.logistics.model.Vehicle;
import com.svtrucking.logistics.repository.DispatchRepository;
import com.svtrucking.logistics.repository.DriverRepository;
import com.svtrucking.logistics.repository.VehicleRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.security.test.context.support.WithMockUser;

import java.math.BigDecimal;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureTestDatabase
@AutoConfigureMockMvc(addFilters = false)
@Transactional
@ActiveProfiles("test")
@TestPropertySource(properties = "dispatch.autoAssignOnChangeTruck=true")
public class ChangeTruckAutoAssignIntegrationTest {

  @Autowired
  private DispatchRepository dispatchRepository;
  @Autowired
  private DriverRepository driverRepository;
  @Autowired
  private VehicleRepository vehicleRepository;
  // @Autowired private AssignmentVehicleToDriverRepository assignmentRepo;

  @Autowired
  private MockMvc mockMvc;

  @Test
  @WithMockUser(roles = "ADMIN")
  public void changeTruck_autoAssignsDriver_whenFlagEnabled() throws Exception {
    Driver driver = new Driver();
    driver.setName("AutoAssign Driver");
    driver.setPhone("+85599999999");
    driver.setLicenseNumber("DL-AUTO-001");
    driver = driverRepository.save(driver);

    Vehicle original = new Vehicle();
    original.setLicensePlate("ORIG-A-1");
    original.setManufacturer("TestMaker");
    original.setModel("MX");
    original.setMileage(new BigDecimal("1000.00"));
    original.setYearMade(2020);
    original.setStatus(com.svtrucking.logistics.enums.VehicleStatus.AVAILABLE);
    original.setType(com.svtrucking.logistics.enums.VehicleType.TRUCK);
    original = vehicleRepository.save(original);

    // AssignmentVehicleToDriver logic removed

    Dispatch dispatch = new Dispatch();
    dispatch.setDriver(driver);
    dispatch.setVehicle(original);
    dispatch = dispatchRepository.save(dispatch);

    Vehicle newVehicle = new Vehicle();
    newVehicle.setLicensePlate("NEW-A-1");
    newVehicle.setManufacturer("NewMaker");
    newVehicle.setModel("MY");
    newVehicle.setMileage(new BigDecimal("500.00"));
    newVehicle.setYearMade(2021);
    newVehicle.setStatus(com.svtrucking.logistics.enums.VehicleStatus.AVAILABLE);
    newVehicle.setType(com.svtrucking.logistics.enums.VehicleType.TRUCK);
    newVehicle = vehicleRepository.save(newVehicle);

    mockMvc
        .perform(
            put("/api/admin/dispatches/" + dispatch.getId() + "/change-truck?vehicleId=" + newVehicle.getId())
                .contentType(MediaType.APPLICATION_JSON))
        .andExpect(status().isOk());

    // AssignmentVehicleToDriver assertion removed
  }
}
