package com.svtrucking.logistics.controller;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.dto.CustomerAddressDto;
import com.svtrucking.logistics.model.CustomerAddress;
import com.svtrucking.logistics.service.CustomerAddressService;
import com.svtrucking.logistics.service.OrderAddressExcelService;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.io.InputStreamResource;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/admin/customer-addresses")
@CrossOrigin(origins = "*")
public class CustomerAddressController {

    private final CustomerAddressService customerAddressService;

    @Autowired
    private OrderAddressExcelService excelService;

    public CustomerAddressController(CustomerAddressService customerAddressService) {
        this.customerAddressService = customerAddressService;
    }

    @GetMapping
    @PreAuthorize("@authorizationService.hasPermission('customer:read')")
    public ResponseEntity<ApiResponse<List<CustomerAddressDto>>> list(
            @RequestParam(required = false) Long customerId) {
        List<CustomerAddress> addresses = customerId != null
                ? customerAddressService.findByCustomerId(customerId)
                : customerAddressService.findAll();
        return ResponseEntity.ok(
                new ApiResponse<>(true, "Addresses loaded", CustomerAddressDto.fromEntityList(addresses)));
    }

    @GetMapping("/detail/{id}")
    @PreAuthorize("@authorizationService.hasPermission('customer:read')")
    public ResponseEntity<ApiResponse<CustomerAddressDto>> getAddressById(@PathVariable Long id) {
        return customerAddressService
                .getAddressById(id)
                .map(
                        address -> ResponseEntity.ok(
                                new ApiResponse<>(true, "Address found", CustomerAddressDto.fromEntity(address))))
                .orElseGet(
                        () -> ResponseEntity.status(404)
                                .body(new ApiResponse<>(false, "Address not found", null)));
    }

    @GetMapping("/{id}")
    @PreAuthorize("@authorizationService.hasPermission('customer:read')")
    public ResponseEntity<ApiResponse<CustomerAddressDto>> getAddressByIdCanonical(
            @PathVariable Long id) {
        return getAddressById(id);
    }

    @PostMapping
    @PreAuthorize("@authorizationService.hasPermission('customer:update')")
    public ResponseEntity<ApiResponse<CustomerAddressDto>> createAddress(
            @RequestBody CustomerAddressDto dto) {
        CustomerAddress entity = dto.toEntity();
        CustomerAddress saved = customerAddressService.createAddress(entity);
        return ResponseEntity.ok(
                new ApiResponse<>(
                        true, "Address created successfully", CustomerAddressDto.fromEntity(saved)));
    }

    @PostMapping("/add")
    @PreAuthorize("@authorizationService.hasPermission('customer:update')")
    public ResponseEntity<ApiResponse<CustomerAddressDto>> createAddressLegacy(
            @RequestBody CustomerAddressDto dto) {
        return createAddress(dto);
    }

    @PutMapping("/{id}")
    @PreAuthorize("@authorizationService.hasPermission('customer:update')")
    public ResponseEntity<ApiResponse<CustomerAddressDto>> updateAddress(
            @PathVariable Long id, @RequestBody CustomerAddressDto dto) {
        CustomerAddress updated = customerAddressService.updateAddress(id, dto.toEntity());
        return ResponseEntity.ok(
                new ApiResponse<>(
                        true, "Address updated successfully", CustomerAddressDto.fromEntity(updated)));
    }

    @PutMapping("/update/{id}")
    @PreAuthorize("@authorizationService.hasPermission('customer:update')")
    public ResponseEntity<ApiResponse<CustomerAddressDto>> updateAddressLegacy(
            @PathVariable Long id, @RequestBody CustomerAddressDto dto) {
        return updateAddress(id, dto);
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("@authorizationService.hasPermission('customer:update')")
    public ResponseEntity<ApiResponse<String>> deleteAddress(@PathVariable Long id) {
        customerAddressService.deleteAddress(id);
        return ResponseEntity.ok(new ApiResponse<>(true, "Address deleted successfully", null));
    }

    @DeleteMapping("/delete/{id}")
    @PreAuthorize("@authorizationService.hasPermission('customer:update')")
    public ResponseEntity<ApiResponse<String>> deleteAddressLegacy(@PathVariable Long id) {
        return deleteAddress(id);
    }

    @GetMapping("/search")
    @PreAuthorize("@authorizationService.hasPermission('customer:read')")
    public ResponseEntity<ApiResponse<List<CustomerAddressDto>>> searchLocations(
            @RequestParam String name) {
        List<CustomerAddressDto> results = customerAddressService.searchLocationsByName(name);
        return ResponseEntity.ok(new ApiResponse<>(true, "Search complete", results));
    }

    @GetMapping("/search/customer")
    // @PreAuthorize("@authorizationService.hasPermission('customer:read')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> searchCustomerAddresses(
            @RequestParam Long customerId,
            @RequestParam(required = false) String search,
            @RequestParam(required = false) String type,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        Page<CustomerAddress> addresses = customerAddressService.searchAddresses(
                customerId, blankToNull(search), blankToNull(type), PageRequest.of(page, size));
        Map<String, Object> payload = new HashMap<>();
        payload.put("addresses", CustomerAddressDto.fromEntityList(addresses.getContent()));
        payload.put("total", addresses.getTotalElements());
        payload.put("page", addresses.getNumber());
        payload.put("size", addresses.getSize());
        return ResponseEntity.ok(new ApiResponse<>(true, "Paged addresses fetched", payload));
    }

    private String blankToNull(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }

    @GetMapping("/export")
    @PreAuthorize("@authorizationService.hasPermission('customer:read')")
    public ResponseEntity<InputStreamResource> exportAddresses(@RequestParam Long customerId)
            throws IOException {
        List<CustomerAddress> addresses = customerAddressService.findByCustomerId(customerId);
        ByteArrayInputStream in = excelService.exportToExcel(addresses);
        HttpHeaders headers = new HttpHeaders();
        headers.add(
                "Content-Disposition", "attachment; filename=addresses-customer-" + customerId + ".xlsx");
        return ResponseEntity.ok()
                .headers(headers)
                .contentType(
                        MediaType.parseMediaType(
                                "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"))
                .body(new InputStreamResource(in));
    }

    @PostMapping("/import")
    @PreAuthorize("@authorizationService.hasPermission('customer:update')")
    public ResponseEntity<ApiResponse<String>> importAddresses(
            @RequestParam("file") MultipartFile file, @RequestParam("customerId") Long customerId) {
        try {
            int importedCount = customerAddressService.importAddresses(file, customerId);
            return ResponseEntity.ok(
                    new ApiResponse<>(true, importedCount + " addresses imported successfully", null));
        } catch (Exception e) {
            return ResponseEntity.status(400)
                    .body(new ApiResponse<>(false, "Import failed and rolled back: " + e.getMessage(), null));
        }
    }
}
