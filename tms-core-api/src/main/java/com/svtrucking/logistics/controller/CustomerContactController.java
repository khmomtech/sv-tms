package com.svtrucking.logistics.controller;

import java.util.List;

import com.svtrucking.logistics.dto.CustomerContactDto;
import com.svtrucking.logistics.dto.request.CustomerContactRequest;
import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.service.CustomerContactService;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/admin/customer-contacts")
@RequiredArgsConstructor
@Validated
@Tag(name = "Customer Contacts", description = "Manage customer contact persons")
@PreAuthorize("hasAnyRole('ADMIN', 'SUPERADMIN', 'MANAGER')")
public class CustomerContactController {

    private final CustomerContactService contactService;

    @GetMapping("/customer/{customerId}")
    @Operation(summary = "Get all contacts for a customer")
    public ResponseEntity<ApiResponse<List<CustomerContactDto>>> getContactsByCustomer(
            @PathVariable Long customerId,
            @RequestParam(required = false, defaultValue = "false") boolean activeOnly) {
        
        List<CustomerContactDto> contacts = activeOnly 
            ? contactService.getActiveContactsByCustomerId(customerId)
            : contactService.getContactsByCustomerId(customerId);
        
        return ResponseEntity.ok(ApiResponse.ok("Contacts retrieved", contacts));
    }

    @GetMapping("/customer/{customerId}/primary")
    @Operation(summary = "Get primary contact for a customer")
    public ResponseEntity<ApiResponse<CustomerContactDto>> getPrimaryContact(@PathVariable Long customerId) {
        CustomerContactDto contact = contactService.getPrimaryContact(customerId);
        return ResponseEntity.ok(ApiResponse.ok("Primary contact retrieved", contact));
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get contact by ID")
    public ResponseEntity<ApiResponse<CustomerContactDto>> getContactById(@PathVariable Long id) {
        CustomerContactDto contact = contactService.getContactById(id);
        return ResponseEntity.ok(ApiResponse.ok("Contact retrieved", contact));
    }

    @PostMapping
    @Operation(summary = "Create new contact")
    public ResponseEntity<ApiResponse<CustomerContactDto>> createContact(
            @Valid @RequestBody CustomerContactRequest request) {
        CustomerContactDto created = contactService.createContact(request);
        return ResponseEntity.status(HttpStatus.CREATED)
            .body(ApiResponse.ok("Contact created successfully", created));
    }

    @PutMapping("/{id}")
    @Operation(summary = "Update existing contact")
    public ResponseEntity<ApiResponse<CustomerContactDto>> updateContact(
            @PathVariable Long id,
            @Valid @RequestBody CustomerContactRequest request) {
        CustomerContactDto updated = contactService.updateContact(id, request);
        return ResponseEntity.ok(ApiResponse.ok("Contact updated successfully", updated));
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Delete contact")
    public ResponseEntity<ApiResponse<Void>> deleteContact(@PathVariable Long id) {
        contactService.deleteContact(id);
        return ResponseEntity.ok(ApiResponse.success("Contact deleted successfully"));
    }

    @GetMapping("/customer/{customerId}/search")
    @Operation(summary = "Search contacts by name or email")
    public ResponseEntity<ApiResponse<List<CustomerContactDto>>> searchContacts(
            @PathVariable Long customerId,
            @RequestParam String query) {
        List<CustomerContactDto> contacts = contactService.searchContacts(customerId, query);
        return ResponseEntity.ok(ApiResponse.ok("Search results", contacts));
    }

    @GetMapping("/customer/{customerId}/count")
    @Operation(summary = "Count contacts for a customer")
    public ResponseEntity<ApiResponse<Long>> countContacts(@PathVariable Long customerId) {
        long count = contactService.countContacts(customerId);
        return ResponseEntity.ok(ApiResponse.ok("Contact count", count));
    }
}
