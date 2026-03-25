package com.svtrucking.logistics.controller;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.dto.CustomerDto;
import com.svtrucking.logistics.dto.CustomerAddressDto;
import com.svtrucking.logistics.exception.CustomerNotFoundException;
import com.svtrucking.logistics.model.Customer;
import com.svtrucking.logistics.service.CustomerAddressService;
import com.svtrucking.logistics.service.CustomerService;
import org.springframework.security.access.prepost.PreAuthorize;
import java.util.*;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.core.io.Resource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/admin/customers")
@CrossOrigin(origins = "*")
public class CustomerController {

  private final CustomerService customerService;

  @Autowired private CustomerAddressService customerAddressService;

  public CustomerController(CustomerService customerService) {
    this.customerService = customerService;
  }

  @GetMapping
  @PreAuthorize("@authorizationService.hasPermission('customer:read')")
  public ResponseEntity<ApiResponse<Page<Customer>>> getAllCustomers(
      @RequestParam(defaultValue = "0") int page, @RequestParam(defaultValue = "10") int size) {
    Page<Customer> customers = customerService.getAllCustomers(page, size);
    return ResponseEntity.ok(new ApiResponse<>(true, "Customers fetched successfully", customers));
  }

  @GetMapping("/search")
  @PreAuthorize("@authorizationService.hasPermission('customer:read')")
  public ResponseEntity<ApiResponse<List<Customer>>> searchCustomers(@RequestParam String keyword) {
    List<Customer> customers = customerService.searchCustomers(keyword, keyword, keyword);
    return ResponseEntity.ok(
        new ApiResponse<>(true, "Search results fetched successfully", customers));
  }

  @GetMapping("/{id}")
  @PreAuthorize("@authorizationService.hasPermission('customer:read')")
  public ResponseEntity<ApiResponse<Map<String, Object>>> getCustomerById(@PathVariable Long id) {
    try {
      Customer customer = customerService.getCustomerById(id);
        List<CustomerAddressDto> addressDtos =
          customerAddressService.findByCustomerId(id).stream().map(CustomerAddressDto::fromEntity).toList();

      Map<String, Object> data = new HashMap<>();
      data.put("customer", CustomerDto.fromEntity(customer));
      data.put("addresses", addressDtos);

      return ResponseEntity.ok(new ApiResponse<>(true, "Customer loaded successfully", data));
    } catch (CustomerNotFoundException ex) {
      return ResponseEntity.status(HttpStatus.NOT_FOUND)
          .body(new ApiResponse<>(false, "Customer not found", null));
    }
  }

  @GetMapping("/generate-code")
  @PreAuthorize("@authorizationService.hasPermission('customer:create')")
  public ResponseEntity<ApiResponse<String>> generateNextCustomerCode() {
    String nextCode = customerService.generateNextCustomerCode();
    return ResponseEntity.ok(new ApiResponse<>(true, "Next customer code generated", nextCode));
  }

  @PostMapping
  @PreAuthorize("@authorizationService.hasPermission('customer:create')")
  public ResponseEntity<ApiResponse<CustomerDto>> createCustomer(
      @RequestBody CustomerDto customerDto) {
    Customer customer = new Customer();
    customerDto.updateEntity(customer);
    Customer saved = customerService.saveCustomer(customer);
    return ResponseEntity.status(HttpStatus.CREATED)
        .body(new ApiResponse<>(true, "Customer created", CustomerDto.fromEntity(saved)));
  }

  @DeleteMapping("/{id}")
  @PreAuthorize("@authorizationService.hasPermission('customer:delete')")
  public ResponseEntity<Void> deleteCustomer(@PathVariable Long id) {
    try {
      customerService.getCustomerById(id);
      customerService.deleteCustomer(id);
      return ResponseEntity.ok().build();
    } catch (CustomerNotFoundException ex) {
      return ResponseEntity.notFound().build();
    }
  }

  @GetMapping("/{id}/addresses")
  @PreAuthorize("@authorizationService.hasPermission('customer:read')")
  public ResponseEntity<ApiResponse<Map<String, Object>>> getCustomerWithAddresses(
      @PathVariable Long id) {
    try {
      Customer customer = customerService.getCustomerById(id);
      List<CustomerAddressDto> addressDtos =
          customerAddressService.findByCustomerId(id).stream().map(CustomerAddressDto::fromEntity).toList();
      Map<String, Object> result = new HashMap<>();
      result.put("customer", CustomerDto.fromEntity(customer));
      result.put("addresses", addressDtos);

      return ResponseEntity.ok(
          new ApiResponse<>(true, "Customer and addresses fetched successfully", result));
    } catch (CustomerNotFoundException ex) {
      return ResponseEntity.status(HttpStatus.NOT_FOUND)
          .body(new ApiResponse<>(false, "Customer not found", null));
    }
  }

  @PutMapping("/{id}")
  @PreAuthorize("@authorizationService.hasPermission('customer:update')")
  public ResponseEntity<ApiResponse<CustomerDto>> updateCustomer(
      @PathVariable Long id, @RequestBody CustomerDto customerDto) {
    try {
      Customer payload = new Customer();
      customerDto.updateEntity(payload);
      Customer updated = customerService.updateCustomer(id, payload);
      return ResponseEntity.ok(
          new ApiResponse<>(true, "Customer updated", CustomerDto.fromEntity(updated)));
    } catch (CustomerNotFoundException ex) {
      return ResponseEntity.status(HttpStatus.NOT_FOUND)
          .body(new ApiResponse<>(false, "Customer not found"));
    }
  }

  @GetMapping("/filter")
  @PreAuthorize("@authorizationService.hasPermission('customer:read')")
  public ResponseEntity<ApiResponse<Page<Customer>>> filterCustomers(
      @RequestParam(required = false) String customerCode,
      @RequestParam(required = false) String name,
      @RequestParam(required = false) String phone,
      @RequestParam(required = false) String email,
      @RequestParam(required = false) String type,
      @RequestParam(required = false) String status,
      @RequestParam(defaultValue = "0") int page,
      @RequestParam(defaultValue = "10") int size) {

    Page<Customer> filteredCustomers =
        customerService.filterCustomers(customerCode, name, phone, email, type, status, page, size);

    return ResponseEntity.ok(
        new ApiResponse<>(true, "Filtered customers fetched successfully", filteredCustomers));
  }

  // Import
  @PostMapping("/import")
  @PreAuthorize("@authorizationService.hasPermission('customer:create')")
  public ResponseEntity<ApiResponse<CustomerImportPayload>> importCustomers(
      @RequestParam MultipartFile file) {
    CustomerService.CustomerImportResult result = customerService.importCustomersFromExcel(file);
    List<CustomerDto> dtoList = result.customers().stream().map(CustomerDto::fromEntity).toList();

    String summary =
        String.format(
            "Customer import completed: %d succeeded, %d failed",
            result.successCount(), result.failureCount());
    ApiResponse<CustomerImportPayload> response =
        new ApiResponse<>(
            true,
            summary,
            new CustomerImportPayload(
                dtoList, result.successCount(), result.failureCount(), result.failureMessages()));
    response.setErrors(result.failureMessages());
    return ResponseEntity.ok(response);
  }

  public record CustomerImportPayload(
      List<CustomerDto> importedCustomers,
      int successCount,
      int failureCount,
      List<String> failureMessages) {}

  /**
   * Download a CSV template for customer import (matches importCustomersFromExcel column order).
   */
  @GetMapping("/import/template")
  @PreAuthorize("@authorizationService.hasPermission('customer:read')")
  public ResponseEntity<Resource> downloadImportTemplate() {
    String[] headers = {"customerCode", "name", "type", "phone", "email", "address", "status"};
    String[][] samples = {
      {"CUST-001", "Acme Corp", "COMPANY", "+85512345678", "info@acme.com", "123 Main St Phnom Penh", "ACTIVE"},
      {"CUST-002", "Beta Trading", "COMPANY", "+85598765432", "sales@beta.com", "45 Riverside Blvd Phnom Penh", "ACTIVE"},
      {"CUST-003", "Charlie Logistics", "COMPANY", "+85577123456", "ops@charlielog.com", "88 Airport Rd Siem Reap", "INACTIVE"},
      {"CUST-004", "Dara Sok", "INDIVIDUAL", "+85512312345", "dara@example.com", "Street 2004 Phnom Penh", "ACTIVE"},
      {"CUST-005", "Emily Chan", "INDIVIDUAL", "+85598989898", "emily@example.com", "Kampot Center", "ACTIVE"},
    };

    StringBuilder sb = new StringBuilder(String.join(",", headers)).append("\n");
    for (String[] row : samples) {
      sb.append(String.join(",", row)).append("\n");
    }

    ByteArrayResource resource = new ByteArrayResource(sb.toString().getBytes());

    return ResponseEntity.ok()
        .header("Content-Disposition", "attachment; filename=customer-import-template.csv")
        .header("Content-Type", "text/csv")
        .body(resource);
  }

  /**
   * Export all active customers as CSV (basic fields aligned to template).
   */
  @GetMapping("/export")
  @PreAuthorize("@authorizationService.hasPermission('customer:read')")
  public ResponseEntity<Resource> exportCustomers() {
    List<Customer> customers = customerService.getAllActiveForExport();
    String header =
        "customerCode,name,type,phone,email,address,status";
    StringBuilder sb = new StringBuilder(header).append("\n");
    customers.forEach(
        c ->
            sb.append(safe(c.getCustomerCode()))
                .append(',')
                .append(safe(c.getName()))
                .append(',')
                .append(safe(c.getType()))
                .append(',')
                .append(safe(c.getPhone()))
                .append(',')
                .append(safe(c.getEmail()))
                .append(',')
                .append(safe(c.getAddress()))
                .append(',')
                .append(safe(c.getStatus()))
                .append('\n'));

    ByteArrayResource resource = new ByteArrayResource(sb.toString().getBytes());
    return ResponseEntity.ok()
        .header("Content-Disposition", "attachment; filename=customers.csv")
        .header("Content-Type", "text/csv")
        .body(resource);
  }

  private String safe(Object value) {
    return value == null ? "" : String.valueOf(value).replace(",", " ");
  }

  /**
   * Create login account for an existing customer
   * POST /api/admin/customers/{id}/account
   */
  @PostMapping("/{id}/account")
  @PreAuthorize("@authorizationService.hasPermission('customer:update')")
  public ResponseEntity<ApiResponse<Map<String, Object>>> createCustomerAccount(
      @PathVariable Long id, @RequestBody CreateAccountRequest request) {
    try {
      Customer customer = customerService.getCustomerById(id);

      // Check if customer already has an account
      if (customer.getUser() != null) {
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
            .body(new ApiResponse<>(false, "Customer already has a login account", null));
      }

      Customer updated =
          customerService.createCustomerAccount(
              customer, request.getUsername(), request.getPassword(), request.getEmail());

      Map<String, Object> data = new HashMap<>();
      data.put("customer", CustomerDto.fromEntity(updated));
      data.put("username", request.getUsername());

      return ResponseEntity.status(HttpStatus.CREATED)
          .body(new ApiResponse<>(true, "Customer account created successfully", data));
    } catch (CustomerNotFoundException ex) {
      return ResponseEntity.status(HttpStatus.NOT_FOUND)
          .body(new ApiResponse<>(false, "Customer not found", null));
    } catch (RuntimeException e) {
      return ResponseEntity.status(HttpStatus.BAD_REQUEST)
          .body(new ApiResponse<>(false, e.getMessage(), null));
    }
  }

  // DTO for account creation
  @lombok.Data
  public static class CreateAccountRequest {
    private String username;
    private String password;
    private String email;
  }
}
