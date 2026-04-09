package com.svtrucking.logistics.service;

import static org.assertj.core.api.Assertions.assertThat;

import com.svtrucking.logistics.model.*;
import com.svtrucking.logistics.repository.*;
import java.io.ByteArrayInputStream;
import java.io.InputStream;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.ss.usermodel.WorkbookFactory;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.multipart.MultipartFile;

/**
 * Test bulk import with REAL data structure from user's Excel file.
 * Data columns: DeliveryDate, CustomerCode, TrackingNo, TruckTripCount,
 * TruckNumber,
 * TripNo, FromDestination, ToDestination, ItemCode, ItemName,
 * Qty, UOM, UomPallet, LoadingPlace, Status
 */
@SpringBootTest
@Transactional
public class TransportOrderImportRealDataTest {

    @Autowired
    private TransportOrderService transportOrderService;
    @Autowired
    private CustomerRepository customerRepository;
    @Autowired
    private VehicleRepository vehicleRepository;
    @Autowired
    private ItemRepository itemRepository;
    @Autowired
    private CustomerAddressRepository orderAddressRepository;
    @Autowired
    private DispatchRepository dispatchRepository;
    @Autowired
    private UserRepository userRepository;

    @Test
    @EnabledIfEnvironmentVariable(named = "SVTMS_REAL_IMPORT_XLSX", matches = ".+")
    void testImportWithRealDataStructure() throws Exception {
        // Create authenticated user
        User sysUser = new User();
        sysUser.setUsername("testuser");
        sysUser.setPassword("password");
        sysUser.setEmail("test@example.com");
        userRepository.save(sysUser);
        SecurityContextHolder.getContext()
                .setAuthentication(new UsernamePasswordAuthenticationToken("testuser", null, List.of()));

        // Load the real Excel file from the provided path.
        // This test is opt-in because local files aren't available in CI by default.
        String path = System.getenv("SVTMS_REAL_IMPORT_XLSX");
        byte[] fileBytes = java.nio.file.Files.readAllBytes(java.nio.file.Paths.get(path));

        // Setup fixtures directly from real file values to validate full parser behavior.
        Set<String> customerCodes = new HashSet<>();
        Set<String> vehiclePlates = new HashSet<>();
        Set<String> addresses = new HashSet<>();
        Map<String, String> itemCodeToName = new HashMap<>();

        try (InputStream in = new ByteArrayInputStream(fileBytes); Workbook wb = WorkbookFactory.create(in)) {
            Sheet sheet = wb.getSheetAt(0);
            if (sheet != null) {
                boolean isHeader = true;
                for (Row row : sheet) {
                    if (isHeader) {
                        isHeader = false;
                        continue;
                    }
                    String customerCode = cellAsText(row, 1);
                    String vehicle = cellAsText(row, 4);
                    String from = cellAsText(row, 6);
                    String to = cellAsText(row, 7);
                    String itemCode = cellAsText(row, 8);
                    String itemName = cellAsText(row, 9);

                    if (customerCode != null && !customerCode.isBlank()) {
                        customerCodes.add(customerCode);
                    }
                    if (vehicle != null && !vehicle.isBlank()) {
                        vehiclePlates.add(vehicle);
                    }
                    if (from != null && !from.isBlank()) {
                        addresses.add(from);
                    }
                    if (to != null && !to.isBlank()) {
                        addresses.add(to);
                    }
                    if (itemCode != null && !itemCode.isBlank()) {
                        itemCodeToName.putIfAbsent(itemCode, (itemName == null || itemName.isBlank()) ? itemCode : itemName);
                    }
                }
            }
        }

        for (String code : customerCodes) {
            Customer customer = new Customer();
            customer.setCustomerCode(code);
            customer.setName("Test Customer " + code);
            customerRepository.save(customer);
        }

        for (String plate : vehiclePlates) {
            Vehicle v = new Vehicle();
            v.setLicensePlate(plate);
            v.setModel("Model-X");
            v.setManufacturer("ACME");
            v.setMileage(java.math.BigDecimal.ZERO);
            vehicleRepository.save(v);
        }

        for (Map.Entry<String, String> e : itemCodeToName.entrySet()) {
            Item item = new Item();
            item.setItemCode(e.getKey());
            item.setItemName(e.getValue());
            item.setQuantity(1);
            itemRepository.save(item);
        }

        for (String name : addresses) {
            CustomerAddress addr = new CustomerAddress();
            addr.setName(name);
            orderAddressRepository.save(addr);
        }

        MultipartFile mf = new MockMultipartFile(
                "file",
                "real_import_data.xlsx",
                "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                fileBytes);

        // Perform import
        var response = transportOrderService.importBulkOrders(mf);

        // Assertions
        if (response.getStatusCode().value() != 200) {
            System.out.println("Import failed status=" + response.getStatusCode().value());
            if (response.getBody() != null) {
                System.out.println("message=" + response.getBody().getMessage());
                Object data = response.getBody().getData();
                if (data instanceof List<?> list) {
                    for (Object o : list) {
                        if (o instanceof com.svtrucking.logistics.dto.ImportError ie) {
                            System.out.println("error row=" + ie.getRow()
                                    + " field=" + ie.getField()
                                    + " value=" + ie.getValue()
                                    + " message=" + ie.getMessage()
                                    + " group=" + ie.getGroupKey());
                        } else {
                            System.out.println("error=" + o);
                        }
                    }
                } else {
                    System.out.println("data=" + data);
                }
            }
        }
        assertThat(response.getStatusCode().value()).isEqualTo(200);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().isSuccess()).isTrue();

        // Verify dispatches were created
        List<Dispatch> dispatches = dispatchRepository.findAll();
        assertThat(dispatches).isNotEmpty();
        System.out.println("✓ Successfully imported " + dispatches.size() + " orders");
    }

    private String cellAsText(Row row, int index) {
        if (row == null || row.getCell(index) == null) {
            return null;
        }
        String raw = row.getCell(index).toString();
        if (raw == null) {
            return null;
        }
        String trimmed = raw.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }
}
