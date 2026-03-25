package com.svtrucking.logistics.service;

import static org.assertj.core.api.Assertions.assertThat;

import com.svtrucking.logistics.enums.DispatchStatus;
import com.svtrucking.logistics.model.Customer;
import com.svtrucking.logistics.model.CustomerAddress;
import com.svtrucking.logistics.model.Dispatch;
import com.svtrucking.logistics.model.Driver;
import com.svtrucking.logistics.model.User;
import com.svtrucking.logistics.model.Vehicle;
import com.svtrucking.logistics.model.VehicleDriver;
import com.svtrucking.logistics.repository.CustomerAddressRepository;
import com.svtrucking.logistics.repository.CustomerRepository;
import com.svtrucking.logistics.repository.DispatchRepository;
import com.svtrucking.logistics.repository.DriverRepository;
import com.svtrucking.logistics.repository.UserRepository;
import com.svtrucking.logistics.repository.VehicleDriverRepository;
import com.svtrucking.logistics.repository.VehicleRepository;
import java.io.ByteArrayOutputStream;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Map;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

@SpringBootTest
@Transactional
class DispatchBulkImportIntegrationTest {

    @Autowired
    private DispatchService dispatchService;
    @Autowired
    private DispatchRepository dispatchRepository;
    @Autowired
    private CustomerRepository customerRepository;
    @Autowired
    private VehicleRepository vehicleRepository;
    @Autowired
    private DriverRepository driverRepository;
    @Autowired
    private VehicleDriverRepository vehicleDriverRepository;
    @Autowired
    private UserRepository userRepository;
    @Autowired
    private CustomerAddressRepository customerAddressRepository;

    @Test
    void import_should_auto_assign_driver_from_active_vehicle_assignment() throws Exception {
        ensureAdminUser();
        ensureImportAddresses();
        Customer customer = createCustomer("DCUST1");
        Vehicle vehicle = createVehicle("3A-1111");
        Driver driver = createDriver("Dispatch Driver A", "099111111");
        createActiveAssignment(vehicle, driver, LocalDateTime.now().minusHours(1), "test-auto");

        MultipartFile file = buildDispatchImportFile("DCUST1", "3A-1111", "TRIP-A", "TRACK-A");
        Map<String, Object> response = dispatchService.importBulkDispatchesFromExcel(file, false);

        assertThat(response.get("success")).isEqualTo(true);
        Dispatch created = dispatchRepository.findAll().stream()
                .filter(d -> "TRIP-A".equals(d.getTruckTrip()))
                .findFirst()
                .orElseThrow();
        assertThat(created.getCustomer().getId()).isEqualTo(customer.getId());
        assertThat(created.getDriver()).isNotNull();
        assertThat(created.getDriver().getId()).isEqualTo(driver.getId());
        assertThat(created.getStatus()).isEqualTo(DispatchStatus.ASSIGNED);
    }

    @Test
    void import_should_leave_driver_unassigned_when_no_active_assignment() throws Exception {
        ensureAdminUser();
        ensureImportAddresses();
        createCustomer("DCUST2");
        createVehicle("3A-2222");

        MultipartFile file = buildDispatchImportFile("DCUST2", "3A-2222", "TRIP-B", "TRACK-B");
        Map<String, Object> response = dispatchService.importBulkDispatchesFromExcel(file, false);

        assertThat(response.get("success")).isEqualTo(true);
        Dispatch created = dispatchRepository.findAll().stream()
                .filter(d -> "TRIP-B".equals(d.getTruckTrip()))
                .findFirst()
                .orElseThrow();
        assertThat(created.getDriver()).isNull();
        assertThat(created.getStatus()).isEqualTo(DispatchStatus.PENDING);
    }

    @Test
    void import_should_match_driver_assignment_by_normalized_truck_plate() throws Exception {
        ensureAdminUser();
        ensureImportAddresses();
        createCustomer("DCUST3");
        Vehicle vehicle = createVehicle("3A-9494");
        Driver driver = createDriver("Dispatch Driver B", "099222222");
        createActiveAssignment(vehicle, driver, LocalDateTime.now().minusMinutes(30), "test-plate");

        MultipartFile file = buildDispatchImportFile("DCUST3", "3A 9494", "TRIP-C", "TRACK-C");
        Map<String, Object> response = dispatchService.importBulkDispatchesFromExcel(file, false);

        assertThat(response.get("success")).isEqualTo(true);
        Dispatch created = dispatchRepository.findAll().stream()
                .filter(d -> "TRIP-C".equals(d.getTruckTrip()))
                .findFirst()
                .orElseThrow();
        assertThat(created.getVehicle()).isNotNull();
        assertThat(created.getVehicle().getLicensePlate()).isEqualTo("3A-9494");
        assertThat(created.getDriver()).isNotNull();
        assertThat(created.getDriver().getId()).isEqualTo(driver.getId());
        assertThat(created.getStatus()).isEqualTo(DispatchStatus.ASSIGNED);
    }

    @Test
    void import_should_pick_latest_driver_when_multiple_active_assignments_exist() throws Exception {
        ensureAdminUser();
        ensureImportAddresses();
        createCustomer("DCUST4");
        Vehicle vehicle = createVehicle("3A-3333");
        Driver oldDriver = createDriver("Dispatch Old Driver", "099333333");
        Driver newDriver = createDriver("Dispatch New Driver", "099444444");
        createActiveAssignment(vehicle, oldDriver, LocalDateTime.now().minusDays(2), "dup-old");
        createActiveAssignment(vehicle, newDriver, LocalDateTime.now().minusMinutes(2), "dup-new");

        MultipartFile file = buildDispatchImportFile("DCUST4", "3A-3333", "TRIP-D", "TRACK-D");
        Map<String, Object> response = dispatchService.importBulkDispatchesFromExcel(file, false);

        assertThat(response.get("success")).isEqualTo(true);
        Dispatch created = dispatchRepository.findAll().stream()
                .filter(d -> "TRIP-D".equals(d.getTruckTrip()))
                .findFirst()
                .orElseThrow();
        assertThat(created.getDriver()).isNotNull();
        assertThat(created.getDriver().getId()).isEqualTo(newDriver.getId());
        assertThat(created.getStatus()).isEqualTo(DispatchStatus.ASSIGNED);
    }

    private MultipartFile buildDispatchImportFile(String customerCode, String truckNumber, String truckTripCount,
            String trackingNo) throws Exception {
        Workbook wb = new XSSFWorkbook();
        Sheet s = wb.createSheet("sheet1");
        Row header = s.createRow(0);
        List<String> headers = List.of(
                "DeliveryDate",
                "CustomerCode",
                "TrackingNo",
                "TruckNumber",
                "TruckTripCount",
                "FromDestination",
                "ToDestination",
                "Item",
                "Qty",
                "UoM",
                "UoMPallet",
                "LoadingPlace",
                "Status");
        for (int i = 0; i < headers.size(); i++) {
            header.createCell(i).setCellValue(headers.get(i));
        }

        Row r = s.createRow(1);
        r.createCell(0).setCellValue(LocalDate.now().format(DateTimeFormatter.ISO_DATE));
        r.createCell(1).setCellValue(customerCode);
        r.createCell(2).setCellValue(trackingNo);
        r.createCell(3).setCellValue(truckNumber);
        r.createCell(4).setCellValue(truckTripCount);
        r.createCell(5).setCellValue("Warehouse Test");
        r.createCell(6).setCellValue("Customer Test");
        r.createCell(7).setCellValue("Product A");
        r.createCell(8).setCellValue(3);
        r.createCell(9).setCellValue("PCS");
        r.createCell(10).setCellValue(0);
        r.createCell(11).setCellValue("WH1");
        r.createCell(12).setCellValue("PENDING");

        ByteArrayOutputStream out = new ByteArrayOutputStream();
        wb.write(out);
        wb.close();
        return new MockMultipartFile(
                "file",
                "dispatch-import.xlsx",
                "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                out.toByteArray());
    }

    private User ensureAdminUser() {
        return userRepository.findByUsername("admin").orElseGet(() -> {
            User user = new User();
            user.setUsername("admin");
            user.setPassword("password");
            user.setEmail("admin@example.com");
            return userRepository.save(user);
        });
    }

    private void ensureImportAddresses() {
        long currentCount = customerAddressRepository.count();
        for (long i = currentCount; i < 34; i++) {
            CustomerAddress address = new CustomerAddress();
            address.setName("AutoAddr-" + i);
            customerAddressRepository.save(address);
        }
    }

    private Customer createCustomer(String code) {
        Customer customer = new Customer();
        customer.setName("Customer " + code);
        customer.setCustomerCode(code);
        return customerRepository.save(customer);
    }

    private Vehicle createVehicle(String plate) {
        Vehicle vehicle = new Vehicle();
        vehicle.setLicensePlate(plate);
        vehicle.setModel("Model-" + plate);
        vehicle.setManufacturer("ACME");
        vehicle.setMileage(java.math.BigDecimal.ZERO);
        return vehicleRepository.save(vehicle);
    }

    private Driver createDriver(String name, String phone) {
        Driver driver = new Driver();
        driver.setName(name);
        driver.setPhone(phone);
        return driverRepository.save(driver);
    }

    private VehicleDriver createActiveAssignment(Vehicle vehicle, Driver driver, LocalDateTime assignedAt, String assignedBy) {
        VehicleDriver assignment = new VehicleDriver();
        assignment.setVehicle(vehicle);
        assignment.setDriver(driver);
        assignment.setAssignedAt(assignedAt);
        assignment.setAssignedBy(assignedBy);
        assignment.setCreatedAt(LocalDateTime.now());
        return vehicleDriverRepository.save(assignment);
    }
}
