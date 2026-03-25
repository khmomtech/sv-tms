package com.svtrucking.logistics.controller;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.dto.InvoiceDto;
import com.svtrucking.logistics.dto.PaymentDto;
import com.svtrucking.logistics.dto.VendorQuotationDto;
import com.svtrucking.logistics.dto.WorkOrderDto;
import com.svtrucking.logistics.repository.UserRepository;
import com.svtrucking.logistics.security.PermissionNames;
import com.svtrucking.logistics.service.SvMaintenanceWorkOrderService;
import java.time.Instant;
import java.util.List;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping({
    "/api/admin/maintenance/work-orders",
    "/api/maintenance/work-orders"
})
@RequiredArgsConstructor
public class MaintenanceWorkOrderController {

  private final SvMaintenanceWorkOrderService service;
  private final com.svtrucking.logistics.service.WorkOrderService workOrderService;
  private final UserRepository userRepository;

  @GetMapping
  @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.MAINTENANCE_WORKORDER_READ + "')")
  public ResponseEntity<ApiResponse<org.springframework.data.domain.Page<WorkOrderDto>>> list(
      @RequestParam(required = false) com.svtrucking.logistics.enums.WorkOrderStatus status,
      @RequestParam(required = false) com.svtrucking.logistics.enums.WorkOrderType type,
      @RequestParam(required = false) com.svtrucking.logistics.enums.Priority priority,
      @RequestParam(required = false) Long vehicleId,
      @RequestParam(required = false) Long technicianId,
      @RequestParam(required = false)
          @org.springframework.format.annotation.DateTimeFormat(
              iso = org.springframework.format.annotation.DateTimeFormat.ISO.DATE_TIME)
          java.time.LocalDateTime scheduledAfter,
      @RequestParam(required = false)
          @org.springframework.format.annotation.DateTimeFormat(
              iso = org.springframework.format.annotation.DateTimeFormat.ISO.DATE_TIME)
          java.time.LocalDateTime scheduledBefore,
      org.springframework.data.domain.Pageable pageable) {
    org.springframework.data.domain.Page<WorkOrderDto> data =
        workOrderService.filterWorkOrders(
            status, type, priority, vehicleId, technicianId, scheduledAfter, scheduledBefore, pageable);
    return ResponseEntity.ok(new ApiResponse<>(true, "Work orders loaded", data, null, Instant.now()));
  }

  @GetMapping("/filter")
  @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.MAINTENANCE_WORKORDER_READ + "')")
  public ResponseEntity<ApiResponse<org.springframework.data.domain.Page<WorkOrderDto>>> filter(
      @RequestParam(required = false) com.svtrucking.logistics.enums.WorkOrderStatus status,
      @RequestParam(required = false) com.svtrucking.logistics.enums.WorkOrderType type,
      @RequestParam(required = false) com.svtrucking.logistics.enums.Priority priority,
      @RequestParam(required = false) Long vehicleId,
      @RequestParam(required = false) Long technicianId,
      @RequestParam(required = false)
          @org.springframework.format.annotation.DateTimeFormat(
              iso = org.springframework.format.annotation.DateTimeFormat.ISO.DATE_TIME)
          java.time.LocalDateTime scheduledAfter,
      @RequestParam(required = false)
          @org.springframework.format.annotation.DateTimeFormat(
              iso = org.springframework.format.annotation.DateTimeFormat.ISO.DATE_TIME)
          java.time.LocalDateTime scheduledBefore,
      org.springframework.data.domain.Pageable pageable) {
    org.springframework.data.domain.Page<WorkOrderDto> data =
        workOrderService.filterWorkOrders(
            status, type, priority, vehicleId, technicianId, scheduledAfter, scheduledBefore, pageable);
    return ResponseEntity.ok(new ApiResponse<>(true, "Work orders loaded", data, null, Instant.now()));
  }

  @PostMapping("/from-request/{maintenanceRequestId}")
  @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.MAINTENANCE_WORKORDER_READ + "')")
  public ResponseEntity<ApiResponse<WorkOrderDto>> createFromRequest(
      @PathVariable Long maintenanceRequestId,
      @RequestBody WorkOrderDto dto,
      Authentication authentication) {
    Long userId = resolveUserId(authentication);
    WorkOrderDto created = service.createWorkOrderFromApprovedMr(maintenanceRequestId, dto, userId);
    return ResponseEntity.status(HttpStatus.CREATED)
        .body(new ApiResponse<>(true, "Work order created", created, null, Instant.now()));
  }

  @PostMapping("/{workOrderId}/mechanics")
  @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.MAINTENANCE_WORKORDER_READ + "')")
  public ResponseEntity<ApiResponse<WorkOrderDto>> assignMechanics(
      @PathVariable Long workOrderId, @RequestBody AssignMechanicsRequest request) {
    WorkOrderDto updated = service.assignMechanics(workOrderId, request.getMechanicIds());
    return ResponseEntity.ok(new ApiResponse<>(true, "Mechanics assigned", updated, null, Instant.now()));
  }

  @PostMapping("/{workOrderId}/vendor-quotation")
  @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.MAINTENANCE_WORKORDER_READ + "')")
  public ResponseEntity<ApiResponse<VendorQuotationDto>> upsertVendorQuotation(
      @PathVariable Long workOrderId, @RequestBody VendorQuotationDto dto) {
    dto.setWorkOrderId(workOrderId);
    VendorQuotationDto saved = service.upsertVendorQuotation(workOrderId, dto);
    return ResponseEntity.ok(new ApiResponse<>(true, "Vendor quotation saved", saved, null, Instant.now()));
  }

  @PostMapping("/{workOrderId}/vendor-quotation/approve")
  @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.MAINTENANCE_WORKORDER_READ + "')")
  public ResponseEntity<ApiResponse<VendorQuotationDto>> approveVendorQuotation(
      @PathVariable Long workOrderId, Authentication authentication) {
    Long userId = resolveUserId(authentication);
    VendorQuotationDto approved = service.approveVendorQuotation(workOrderId, userId);
    return ResponseEntity.ok(new ApiResponse<>(true, "Vendor quotation approved", approved, null, Instant.now()));
  }

  @PostMapping("/{workOrderId}/vendor-quotation/reject")
  @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.MAINTENANCE_WORKORDER_READ + "')")
  public ResponseEntity<ApiResponse<VendorQuotationDto>> rejectVendorQuotation(
      @PathVariable Long workOrderId, @RequestParam(required = false) String reason, Authentication authentication) {
    Long userId = resolveUserId(authentication);
    VendorQuotationDto rejected = service.rejectVendorQuotation(workOrderId, userId, reason);
    return ResponseEntity.ok(new ApiResponse<>(true, "Vendor quotation rejected", rejected, null, Instant.now()));
  }

  @PostMapping("/{workOrderId}/invoice")
  @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.MAINTENANCE_WORKORDER_READ + "')")
  public ResponseEntity<ApiResponse<InvoiceDto>> createInvoice(@PathVariable Long workOrderId, @RequestBody InvoiceDto dto) {
    InvoiceDto inv = service.createInvoiceForWorkOrder(workOrderId, dto);
    return ResponseEntity.ok(new ApiResponse<>(true, "Invoice created", inv, null, Instant.now()));
  }

  @PostMapping("/invoices/{invoiceId}/payments")
  @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.MAINTENANCE_WORKORDER_READ + "')")
  public ResponseEntity<ApiResponse<PaymentDto>> createPayment(
      @PathVariable Long invoiceId, @RequestBody PaymentDto dto, Authentication authentication) {
    Long userId = resolveUserId(authentication);
    dto.setInvoiceId(invoiceId);
    PaymentDto saved = service.recordPayment(invoiceId, dto, userId);
    return ResponseEntity.status(HttpStatus.CREATED)
        .body(new ApiResponse<>(true, "Payment recorded", saved, null, Instant.now()));
  }

  @PostMapping("/{workOrderId}/complete")
  @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.MAINTENANCE_WORKORDER_READ + "')")
  public ResponseEntity<ApiResponse<WorkOrderDto>> complete(@PathVariable Long workOrderId, Authentication authentication) {
    Long userId = resolveUserId(authentication);
    WorkOrderDto updated = service.completeWorkOrder(workOrderId, userId);
    return ResponseEntity.ok(new ApiResponse<>(true, "Work order completed", updated, null, Instant.now()));
  }

  @Data
  public static class AssignMechanicsRequest {
    private List<Long> mechanicIds;
  }

  private Long resolveUserId(Authentication authentication) {
    if (authentication == null) return null;
    Object principal = authentication.getPrincipal();
    if (principal instanceof org.springframework.security.core.userdetails.UserDetails ud) {
      return userRepository.findByUsername(ud.getUsername()).map(u -> u.getId()).orElse(null);
    }
    if (principal instanceof String s) {
      return userRepository.findByUsername(s).map(u -> u.getId()).orElse(null);
    }
    return null;
  }
}
