package com.svtrucking.logistics.service;

import static org.assertj.core.api.Assertions.assertThat;

import com.svtrucking.logistics.enums.DispatchStatus;
import com.svtrucking.logistics.model.*;
import com.svtrucking.logistics.repository.*;
import java.io.ByteArrayOutputStream;
import java.time.LocalDate;
import java.util.Date;
import java.util.List;
import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.multipart.MultipartFile;

@SpringBootTest
@Transactional
public class TransportOrderImportIntegrationTest {

    @Autowired
    private TransportOrderService transportOrderService;
    @Autowired
    private CustomerRepository customerRepository;
    @Autowired
    private VehicleRepository vehicleRepository;
    @Autowired
    private ItemRepository itemRepository;
    @Autowired
    private CustomerAddressRepository customerAddressRepository;
    @Autowired
    private DriverRepository driverRepository;
    @Autowired
    private VehicleDriverRepository vehicleDriverRepository;
    @Autowired
    private DispatchRepository dispatchRepository;
    @Autowired
    private com.svtrucking.logistics.repository.UserRepository userRepository;

    @Test
    void import_should_auto_assign_driver_when_active_vehicle_driver_exists_even_requiresDriver_false() throws Exception {
        // Create minimal fixtures
        Customer c = new Customer();
        c.setName("Test Customer");
        c.setCustomerCode("TCUST");
        customerRepository.save(c);

        Vehicle v = new Vehicle();
        v.setLicensePlate("TRUCK-1");
        // required fields for persistence/validation
        v.setModel("Model-X");
        v.setManufacturer("ACME Trucks");
        v.setMileage(java.math.BigDecimal.ZERO);
        vehicleRepository.save(v);

        CustomerAddress from = new CustomerAddress();
        from.setName("Warehouse A");
        customerAddressRepository.save(from);
        CustomerAddress to = new CustomerAddress();
        to.setName("Customer Site");
        customerAddressRepository.save(to);

        Item item = new Item();
        item.setItemCode("ITEM1");
        item.setItemName("Test Item 1");
        item.setQuantity(1);
        itemRepository.save(item);

        // Create a driver and active assignment for the vehicle
        Driver d = new Driver();
        d.setName("Driver One");
        d.setPhone("0123456789");
        driverRepository.save(d);

        VehicleDriver assignment = new VehicleDriver();
        assignment.setDriver(d);
        assignment.setVehicle(v);
        assignment.setAssignedBy("testuser");
        assignment.setAssignedAt(java.time.LocalDateTime.now().minusHours(1));
        assignment.setCreatedAt(java.time.LocalDateTime.now());
        vehicleDriverRepository.save(assignment);

        // Create a system user and set authentication for the import flow
        com.svtrucking.logistics.model.User sysUser = new com.svtrucking.logistics.model.User();
        sysUser.setUsername("testuser");
        sysUser.setPassword("password");
        sysUser.setEmail("test@example.com");
        userRepository.save(sysUser);
        SecurityContextHolder.getContext()
                .setAuthentication(new UsernamePasswordAuthenticationToken("testuser", null, java.util.List.of()));

        // Build a simple Excel file matching parser expectations
        Workbook wb = new XSSFWorkbook();
        Sheet s = wb.createSheet("sheet1");
        Row header = s.createRow(0);
        for (int i = 0; i < 16; i++)
            header.createCell(i).setCellValue("H" + i);

        Row r = s.createRow(1);
        // deliveryDate (dd.MM.yyyy)
        r.createCell(0)
                .setCellValue(LocalDate.now().format(java.time.format.DateTimeFormatter.ofPattern("dd.MM.yyyy")));
        // customerCode
        r.createCell(1).setCellValue("TCUST");
        // trackingNo
        r.createCell(2).setCellValue("TRACK-1");
        // truckTripCount
        r.createCell(3).setCellValue("1");
        // truckNumber (license plate)
        r.createCell(4).setCellValue("TRUCK-1");
        // tripNo
        r.createCell(5).setCellValue("TRIP1");
        // fromDest
        r.createCell(6).setCellValue("Warehouse A");
        // toDest
        r.createCell(7).setCellValue("Customer Site");
        // itemCode
        r.createCell(8).setCellValue("ITEM1");
        // qty at index 10
        r.createCell(10).setCellValue(5);
        // uom at 11
        r.createCell(11).setCellValue("PCS");
        // pallet at 12
        r.createCell(12).setCellValue(0);
        // warehouse at 13
        r.createCell(13).setCellValue("WH1");
        // status at 14
        r.createCell(14).setCellValue("PENDING");
        // requiresDriver flag at index 15 -> FALSE to indicate G-team / no driver
        // required
        r.createCell(15).setCellValue("FALSE");

        ByteArrayOutputStream out = new ByteArrayOutputStream();
        wb.write(out);
        wb.close();

        MultipartFile mf = new MockMultipartFile("file", "import.xlsx",
                "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", out.toByteArray());

        // Perform import (creates order and dispatch). The test Excel set
        // requiresDriver=FALSE
        transportOrderService.importBulkOrders(mf);

        // Find the created dispatch and assert driver was auto-assigned
        List<Dispatch> dispatches = dispatchRepository.findAll();
        assertThat(dispatches).isNotEmpty();
        Dispatch created = dispatches.get(0);
        assertThat(created.getDriver()).isNotNull();
        assertThat(created.getDriver().getId()).isEqualTo(d.getId());
        assertThat(created.getStatus()).isEqualTo(DispatchStatus.ASSIGNED);
    }

    @Test
    void import_should_leave_dispatch_unassigned_when_no_active_vehicle_driver_exists() throws Exception {
        Customer c = new Customer();
        c.setName("No Assignment Customer");
        c.setCustomerCode("TCUSTNA");
        customerRepository.save(c);

        Vehicle v = new Vehicle();
        v.setLicensePlate("TRUCK-NA");
        v.setModel("Model-NA");
        v.setManufacturer("ACME Trucks");
        v.setMileage(java.math.BigDecimal.ZERO);
        vehicleRepository.save(v);

        CustomerAddress from = new CustomerAddress();
        from.setName("Warehouse NA");
        customerAddressRepository.save(from);
        CustomerAddress to = new CustomerAddress();
        to.setName("Customer Site NA");
        customerAddressRepository.save(to);

        Item item = new Item();
        item.setItemCode("ITEMNA");
        item.setItemName("Test Item NA");
        item.setQuantity(1);
        itemRepository.save(item);

        User sysUser = new User();
        sysUser.setUsername("testuserna");
        sysUser.setPassword("password");
        sysUser.setEmail("testna@example.com");
        userRepository.save(sysUser);
        SecurityContextHolder.getContext()
                .setAuthentication(new UsernamePasswordAuthenticationToken("testuserna", null, List.of()));

        Workbook wb = new XSSFWorkbook();
        Sheet s = wb.createSheet("sheet1");
        Row header = s.createRow(0);
        for (int i = 0; i < 16; i++) {
            header.createCell(i).setCellValue("H" + i);
        }

        Row r = s.createRow(1);
        r.createCell(0).setCellValue(LocalDate.now().format(java.time.format.DateTimeFormatter.ofPattern("dd.MM.yyyy")));
        r.createCell(1).setCellValue("TCUSTNA");
        r.createCell(2).setCellValue("TRACK-NA");
        r.createCell(3).setCellValue("1");
        r.createCell(4).setCellValue("TRUCK-NA");
        r.createCell(5).setCellValue("TRIPNA");
        r.createCell(6).setCellValue("Warehouse NA");
        r.createCell(7).setCellValue("Customer Site NA");
        r.createCell(8).setCellValue("ITEMNA");
        r.createCell(10).setCellValue(2);
        r.createCell(11).setCellValue("PCS");
        r.createCell(12).setCellValue(0);
        r.createCell(13).setCellValue("WH1");
        r.createCell(14).setCellValue("PENDING");
        r.createCell(15).setCellValue("FALSE");

        ByteArrayOutputStream out = new ByteArrayOutputStream();
        wb.write(out);
        wb.close();

        MultipartFile mf = new MockMultipartFile("file", "import-no-assignment.xlsx",
                "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", out.toByteArray());

        var response = transportOrderService.importBulkOrders(mf);
        assertThat(response.getStatusCode().value()).isEqualTo(200);

        Dispatch created = dispatchRepository.findAll().stream()
                .filter(disp -> "TRACK-NA".equals(disp.getTrackingNo()))
                .findFirst()
                .orElseThrow();
        assertThat(created.getDriver()).isNull();
        assertThat(created.getStatus()).isEqualTo(DispatchStatus.PENDING);
    }

    @Test
    void import_should_reject_non_excel_content_type() {
        byte[] bytes = "not-excel".getBytes();
        MultipartFile mf = new MockMultipartFile("file", "data.txt", "text/plain", bytes);

        var response = transportOrderService.importBulkOrders(mf);

        assertThat(response.getStatusCode().value()).isEqualTo(400);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().isSuccess()).isFalse();
        assertThat(response.getBody().getMessage()).contains("Only Excel files");
    }

    @Test
    void import_should_reject_empty_file() {
        MultipartFile mf = new MockMultipartFile(
                "file",
                "empty.xlsx",
                "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                new byte[0]);

        var response = transportOrderService.importBulkOrders(mf);

        assertThat(response.getStatusCode().value()).isEqualTo(400);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().isSuccess()).isFalse();
        assertThat(response.getBody().getMessage()).contains("File is required");
    }

    @Test
    void import_should_accept_date_cell_and_string_qty() throws Exception {
        Customer c = new Customer();
        c.setName("Test Customer");
        c.setCustomerCode("TCUST2");
        customerRepository.save(c);

        Vehicle v = new Vehicle();
        v.setLicensePlate("TRUCK-2");
        v.setModel("Model-Y");
        v.setManufacturer("ACME Trucks");
        v.setMileage(java.math.BigDecimal.ZERO);
        vehicleRepository.save(v);

        CustomerAddress from = new CustomerAddress();
        from.setName("Warehouse B");
        customerAddressRepository.save(from);
        CustomerAddress to = new CustomerAddress();
        to.setName("Customer Site B");
        customerAddressRepository.save(to);

        Item item = new Item();
        item.setItemCode("ITEM2");
        item.setItemName("Test Item 2");
        item.setQuantity(1);
        itemRepository.save(item);

        com.svtrucking.logistics.model.User sysUser = new com.svtrucking.logistics.model.User();
        sysUser.setUsername("testuser2");
        sysUser.setPassword("password");
        sysUser.setEmail("test2@example.com");
        userRepository.save(sysUser);
        SecurityContextHolder.getContext()
                .setAuthentication(new UsernamePasswordAuthenticationToken("testuser2", null, java.util.List.of()));

        Workbook wb = new XSSFWorkbook();
        Sheet s = wb.createSheet("sheet1");
        Row header = s.createRow(0);
        for (int i = 0; i < 16; i++) {
            header.createCell(i).setCellValue("H" + i);
        }

        Row r = s.createRow(1);
        Cell dateCell = r.createCell(0);
        dateCell.setCellValue(new Date());
        var dateStyle = wb.createCellStyle();
        short dateFormat = wb.getCreationHelper().createDataFormat().getFormat("dd.MM.yyyy");
        dateStyle.setDataFormat(dateFormat);
        dateCell.setCellStyle(dateStyle);

        r.createCell(1).setCellValue("TCUST2");
        r.createCell(2).setCellValue("TRACK-2");
        r.createCell(3).setCellValue(1);
        r.createCell(4).setCellValue("TRUCK-2");
        r.createCell(5).setCellValue("TRIP2");
        r.createCell(6).setCellValue("Warehouse B");
        r.createCell(7).setCellValue("Customer Site B");
        r.createCell(8).setCellValue("ITEM2");
        r.createCell(10).setCellValue("7"); // String quantity
        r.createCell(11).setCellValue("PCS");
        r.createCell(12).setCellValue(0);
        r.createCell(13).setCellValue("WH1");
        r.createCell(14).setCellValue("PENDING");
        r.createCell(15).setCellValue("FALSE");

        ByteArrayOutputStream out = new ByteArrayOutputStream();
        wb.write(out);
        wb.close();

        MultipartFile mf = new MockMultipartFile("file", "mixed-types.xlsx",
                "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", out.toByteArray());

        var response = transportOrderService.importBulkOrders(mf);
        assertThat(response.getStatusCode().value()).isEqualTo(200);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().isSuccess()).isTrue();
    }

    @Test
    void import_should_match_vehicle_plate_with_format_variants() throws Exception {
        Customer c = new Customer();
        c.setName("Test Customer");
        c.setCustomerCode("TCUST3");
        customerRepository.save(c);

        Vehicle v = new Vehicle();
        v.setLicensePlate("3A-9494");
        v.setModel("Model-Z");
        v.setManufacturer("ACME Trucks");
        v.setMileage(java.math.BigDecimal.ZERO);
        vehicleRepository.save(v);

        CustomerAddress from = new CustomerAddress();
        from.setName("Warehouse C");
        customerAddressRepository.save(from);
        CustomerAddress to = new CustomerAddress();
        to.setName("Customer Site C");
        customerAddressRepository.save(to);

        Item item = new Item();
        item.setItemCode("ITEM3");
        item.setItemName("Test Item 3");
        item.setQuantity(1);
        itemRepository.save(item);

        Driver d = new Driver();
        d.setName("Plate Variant Driver");
        d.setPhone("0987654321");
        driverRepository.save(d);
        VehicleDriver assignment = new VehicleDriver();
        assignment.setDriver(d);
        assignment.setVehicle(v);
        assignment.setAssignedBy("testuser3");
        assignment.setAssignedAt(java.time.LocalDateTime.now().minusHours(2));
        assignment.setCreatedAt(java.time.LocalDateTime.now());
        vehicleDriverRepository.save(assignment);

        User sysUser = new User();
        sysUser.setUsername("testuser3");
        sysUser.setPassword("password");
        sysUser.setEmail("test3@example.com");
        userRepository.save(sysUser);
        SecurityContextHolder.getContext()
                .setAuthentication(new UsernamePasswordAuthenticationToken("testuser3", null, java.util.List.of()));

        Workbook wb = new XSSFWorkbook();
        Sheet s = wb.createSheet("sheet1");
        Row header = s.createRow(0);
        for (int i = 0; i < 16; i++) {
            header.createCell(i).setCellValue("H" + i);
        }

        Row r = s.createRow(1);
        r.createCell(0)
                .setCellValue(LocalDate.now().format(java.time.format.DateTimeFormatter.ofPattern("dd.MM.yyyy")));
        r.createCell(1).setCellValue("TCUST3");
        r.createCell(2).setCellValue("TRACK-3");
        r.createCell(3).setCellValue(1);
        r.createCell(4).setCellValue("3A 9494");
        r.createCell(5).setCellValue("TRIP3");
        r.createCell(6).setCellValue("Warehouse C");
        r.createCell(7).setCellValue("Customer Site C");
        r.createCell(8).setCellValue("ITEM3");
        r.createCell(10).setCellValue(3);
        r.createCell(11).setCellValue("PCS");
        r.createCell(12).setCellValue(0);
        r.createCell(13).setCellValue("WH1");
        r.createCell(14).setCellValue("PENDING");
        r.createCell(15).setCellValue("FALSE");

        ByteArrayOutputStream out = new ByteArrayOutputStream();
        wb.write(out);
        wb.close();

        MultipartFile mf = new MockMultipartFile("file", "plate-variant.xlsx",
                "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", out.toByteArray());

        var response = transportOrderService.importBulkOrders(mf);
        assertThat(response.getStatusCode().value()).isEqualTo(200);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().isSuccess()).isTrue();

        Dispatch created = dispatchRepository.findAll().stream()
                .filter(dispatch -> "TRACK-3".equals(dispatch.getTrackingNo()))
                .findFirst()
                .orElseThrow();
        assertThat(created.getVehicle()).isNotNull();
        assertThat(created.getVehicle().getLicensePlate()).isEqualTo("3A-9494");
        assertThat(created.getTransportOrder()).isNotNull();
        assertThat(created.getTransportOrder().getTruckNumber()).isEqualTo("3A-9494");
        assertThat(created.getDriver()).isNotNull();
        assertThat(created.getDriver().getId()).isEqualTo(d.getId());
        assertThat(created.getStatus()).isEqualTo(DispatchStatus.ASSIGNED);
    }

    @Test
    void import_should_pick_latest_active_assignment_when_duplicate_vehicle_assignments_exist() throws Exception {
        Customer c = new Customer();
        c.setName("Duplicate Assignment Customer");
        c.setCustomerCode("TCUSTDUP");
        customerRepository.save(c);

        Vehicle v = new Vehicle();
        v.setLicensePlate("TRUCK-DUP");
        v.setModel("Model-DUP");
        v.setManufacturer("ACME Trucks");
        v.setMileage(java.math.BigDecimal.ZERO);
        vehicleRepository.save(v);

        CustomerAddress from = new CustomerAddress();
        from.setName("Warehouse DUP");
        customerAddressRepository.save(from);
        CustomerAddress to = new CustomerAddress();
        to.setName("Customer Site DUP");
        customerAddressRepository.save(to);

        Item item = new Item();
        item.setItemCode("ITEMDUP");
        item.setItemName("Test Item DUP");
        item.setQuantity(1);
        itemRepository.save(item);

        Driver oldDriver = new Driver();
        oldDriver.setName("Old Driver");
        oldDriver.setPhone("011111111");
        driverRepository.save(oldDriver);
        VehicleDriver oldAssignment = new VehicleDriver();
        oldAssignment.setDriver(oldDriver);
        oldAssignment.setVehicle(v);
        oldAssignment.setAssignedBy("dup-old");
        oldAssignment.setAssignedAt(java.time.LocalDateTime.now().minusDays(1));
        oldAssignment.setCreatedAt(java.time.LocalDateTime.now());
        vehicleDriverRepository.save(oldAssignment);

        Driver newDriver = new Driver();
        newDriver.setName("New Driver");
        newDriver.setPhone("022222222");
        driverRepository.save(newDriver);
        VehicleDriver newAssignment = new VehicleDriver();
        newAssignment.setDriver(newDriver);
        newAssignment.setVehicle(v);
        newAssignment.setAssignedBy("dup-new");
        newAssignment.setAssignedAt(java.time.LocalDateTime.now().minusMinutes(5));
        newAssignment.setCreatedAt(java.time.LocalDateTime.now());
        vehicleDriverRepository.save(newAssignment);

        User sysUser = new User();
        sysUser.setUsername("testuserdup");
        sysUser.setPassword("password");
        sysUser.setEmail("testdup@example.com");
        userRepository.save(sysUser);
        SecurityContextHolder.getContext()
                .setAuthentication(new UsernamePasswordAuthenticationToken("testuserdup", null, List.of()));

        Workbook wb = new XSSFWorkbook();
        Sheet s = wb.createSheet("sheet1");
        Row header = s.createRow(0);
        for (int i = 0; i < 16; i++) {
            header.createCell(i).setCellValue("H" + i);
        }
        Row r = s.createRow(1);
        r.createCell(0).setCellValue(LocalDate.now().format(java.time.format.DateTimeFormatter.ofPattern("dd.MM.yyyy")));
        r.createCell(1).setCellValue("TCUSTDUP");
        r.createCell(2).setCellValue("TRACK-DUP");
        r.createCell(3).setCellValue("1");
        r.createCell(4).setCellValue("TRUCK-DUP");
        r.createCell(5).setCellValue("TRIPDUP");
        r.createCell(6).setCellValue("Warehouse DUP");
        r.createCell(7).setCellValue("Customer Site DUP");
        r.createCell(8).setCellValue("ITEMDUP");
        r.createCell(10).setCellValue(2);
        r.createCell(11).setCellValue("PCS");
        r.createCell(12).setCellValue(0);
        r.createCell(13).setCellValue("WH1");
        r.createCell(14).setCellValue("PENDING");
        r.createCell(15).setCellValue("TRUE");

        ByteArrayOutputStream out = new ByteArrayOutputStream();
        wb.write(out);
        wb.close();

        MultipartFile mf = new MockMultipartFile("file", "duplicate-assignment.xlsx",
                "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", out.toByteArray());
        var response = transportOrderService.importBulkOrders(mf);
        assertThat(response.getStatusCode().value()).isEqualTo(200);

        Dispatch created = dispatchRepository.findAll().stream()
                .filter(disp -> "TRACK-DUP".equals(disp.getTrackingNo()))
                .findFirst()
                .orElseThrow();
        assertThat(created.getDriver()).isNotNull();
        assertThat(created.getDriver().getId()).isEqualTo(newDriver.getId());
        assertThat(created.getStatus()).isEqualTo(DispatchStatus.ASSIGNED);
    }
}
