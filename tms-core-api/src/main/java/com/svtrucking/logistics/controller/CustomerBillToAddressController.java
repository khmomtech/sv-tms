package com.svtrucking.logistics.controller;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.dto.CustomerBillToAddressDto;
import com.svtrucking.logistics.model.CustomerBillToAddress;
import com.svtrucking.logistics.service.CustomerBillToAddressService;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.HashMap;
import java.util.Map;
import org.springframework.data.domain.PageRequest;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/admin/customers/{customerId}/bill-to-addresses")
@CrossOrigin(origins = "*")
public class CustomerBillToAddressController {

    private final CustomerBillToAddressService service;

    public CustomerBillToAddressController(CustomerBillToAddressService service) {
        this.service = service;
    }

    private String blankToNull(String value) {
        if (value == null)
            return null;
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }

    @GetMapping
    @PreAuthorize("@authorizationService.hasPermission('customer:read')")
    public ResponseEntity<ApiResponse<?>> list(
            @PathVariable Long customerId,
            @RequestParam(required = false) String search,
            @RequestParam(required = false) Integer page,
            @RequestParam(required = false) Integer size) {
        // If page is not provided, return full list for backward compatibility
        if (page == null) {
            List<CustomerBillToAddressDto> data = CustomerBillToAddressDto.fromEntityList(service.list(customerId));
            return ResponseEntity.ok(new ApiResponse<>(true, "Bill To addresses loaded", data));
        }

        int p = page < 0 ? 0 : page;
        int s = (size == null || size <= 0) ? 10 : size;
        var paged = service.search(customerId, blankToNull(search), PageRequest.of(p, s));
        Map<String, Object> payload = new HashMap<>();
        payload.put("addresses", CustomerBillToAddressDto.fromEntityList(paged.getContent()));
        payload.put("total", paged.getTotalElements());
        payload.put("page", paged.getNumber());
        payload.put("size", paged.getSize());
        return ResponseEntity.ok(new ApiResponse<>(true, "Paged bill-to addresses fetched", payload));
    }

    @PostMapping
    @PreAuthorize("@authorizationService.hasPermission('customer:update')")
    public ResponseEntity<ApiResponse<CustomerBillToAddressDto>> create(
            @PathVariable Long customerId, @RequestBody CustomerBillToAddressDto dto) {
        CustomerBillToAddress saved = service.create(customerId, dto.toEntity());
        return ResponseEntity.ok(
                new ApiResponse<>(true, "Bill To address created", CustomerBillToAddressDto.fromEntity(saved)));
    }

    @PutMapping("/{billToId}")
    @PreAuthorize("@authorizationService.hasPermission('customer:update')")
    public ResponseEntity<ApiResponse<CustomerBillToAddressDto>> update(
            @PathVariable Long customerId,
            @PathVariable Long billToId,
            @RequestBody CustomerBillToAddressDto dto) {
        CustomerBillToAddress updated = service.update(customerId, billToId, dto.toEntity());
        return ResponseEntity.ok(
                new ApiResponse<>(true, "Bill To address updated", CustomerBillToAddressDto.fromEntity(updated)));
    }

    @DeleteMapping("/{billToId}")
    @PreAuthorize("@authorizationService.hasPermission('customer:update')")
    public ResponseEntity<ApiResponse<String>> delete(
            @PathVariable Long customerId, @PathVariable Long billToId) {
        service.delete(customerId, billToId);
        return ResponseEntity.ok(new ApiResponse<>(true, "Bill To address deleted", null));
    }

    @GetMapping("/export")
    @PreAuthorize("@authorizationService.hasPermission('customer:read')")
    public ResponseEntity<byte[]> exportCsv(@PathVariable Long customerId) {
        List<CustomerBillToAddress> list = service.list(customerId);
        StringBuilder sb = new StringBuilder();
        sb.append("id,customerId,name,address,city,state,zip,country,contactName,contactPhone,email,taxId,isPrimary\n");
        for (CustomerBillToAddress a : list) {
            sb.append(a.getId() != null ? a.getId() : "")
                    .append(',')
                    .append(customerId)
                    .append(',')
                    .append(csv(a.getName()))
                    .append(',')
                    .append(csv(a.getAddress()))
                    .append(',')
                    .append(csv(a.getCity()))
                    .append(',')
                    .append(csv(a.getState()))
                    .append(',')
                    .append(csv(a.getZip()))
                    .append(',')
                    .append(csv(a.getCountry()))
                    .append(',')
                    .append(csv(a.getContactName()))
                    .append(',')
                    .append(csv(a.getContactPhone()))
                    .append(',')
                    .append(csv(a.getEmail()))
                    .append(',')
                    .append(csv(a.getTaxId()))
                    .append(',')
                    .append(a.isPrimary())
                    .append('\n');
        }

        byte[] bytes = sb.toString().getBytes(StandardCharsets.UTF_8);
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.parseMediaType("text/csv"));
        headers.add(
                HttpHeaders.CONTENT_DISPOSITION,
                "attachment; filename=bill-to-addresses-customer-" + customerId + ".csv");
        return ResponseEntity.ok().headers(headers).body(bytes);
    }

    /**
     * For local dev environments where Flyway migrations might be disabled:
     * migrate legacy BILL_* rows from customer_addresses into
     * customer_bill_to_addresses.
     */
    @PostMapping("/migrate-legacy")
    @PreAuthorize("@authorizationService.hasPermission('customer:update')")
    public ResponseEntity<ApiResponse<Integer>> migrateLegacy(@PathVariable Long customerId) {
        int migrated = service.migrateLegacyFromCustomerAddresses(customerId);
        String msg = migrated > 0
                ? "Migrated " + migrated + " legacy bill-to address(es)"
                : "No legacy bill-to addresses found";
        return ResponseEntity.ok(new ApiResponse<>(true, msg, migrated));
    }

    private String csv(String value) {
        if (value == null)
            return "";
        String v = value.replace("\"", "\"\"");
        if (v.contains(",") || v.contains("\n") || v.contains("\r")) {
            return "\"" + v + "\"";
        }
        return v;
    }
}
