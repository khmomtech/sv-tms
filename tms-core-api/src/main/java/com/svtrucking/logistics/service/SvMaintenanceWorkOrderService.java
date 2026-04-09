package com.svtrucking.logistics.service;

import com.svtrucking.logistics.dto.InvoiceDto;
import com.svtrucking.logistics.dto.PaymentDto;
import com.svtrucking.logistics.dto.VendorQuotationDto;
import com.svtrucking.logistics.dto.WorkOrderDto;
import com.svtrucking.logistics.enums.MaintenanceRequestStatus;
import com.svtrucking.logistics.enums.PaymentStatus;
import com.svtrucking.logistics.enums.RepairType;
import com.svtrucking.logistics.enums.VendorQuotationStatus;
import com.svtrucking.logistics.enums.VehicleStatus;
import com.svtrucking.logistics.enums.WorkOrderStatus;
import com.svtrucking.logistics.enums.WorkOrderType;
import com.svtrucking.logistics.exception.ResourceNotFoundException;
import com.svtrucking.logistics.model.Invoice;
import com.svtrucking.logistics.model.MaintenanceRequest;
import com.svtrucking.logistics.model.Payment;
import com.svtrucking.logistics.model.User;
import com.svtrucking.logistics.model.Vehicle;
import com.svtrucking.logistics.model.Vendor;
import com.svtrucking.logistics.model.VendorQuotation;
import com.svtrucking.logistics.model.WorkOrder;
import com.svtrucking.logistics.model.WorkOrderMechanic;
import com.svtrucking.logistics.repository.InvoiceRepository;
import com.svtrucking.logistics.repository.MaintenanceRequestRepository;
import com.svtrucking.logistics.repository.MechanicRepository;
import com.svtrucking.logistics.repository.PartnerCompanyRepository;
import com.svtrucking.logistics.repository.PaymentRepository;
import com.svtrucking.logistics.repository.UserRepository;
import com.svtrucking.logistics.repository.VehicleRepository;
import com.svtrucking.logistics.repository.VendorQuotationRepository;
import com.svtrucking.logistics.repository.VendorRepository;
import com.svtrucking.logistics.repository.WorkOrderMechanicRepository;
import com.svtrucking.logistics.repository.WorkOrderRepository;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * SV Standard maintenance workflow service.
 *
 * Locked rules enforced here:
 * - No WO without approved MR (for REPAIR/EMERGENCY).
 * - Repair decision at WO level: OWN vs VENDOR.
 * - VENDOR requires quotation approval + invoice + payment before completion.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class SvMaintenanceWorkOrderService {

  private final MaintenanceRequestRepository maintenanceRequestRepository;
  private final WorkOrderRepository workOrderRepository;
  private final VehicleRepository vehicleRepository;
  private final UserRepository userRepository;

  private final MechanicRepository mechanicRepository;
  private final WorkOrderMechanicRepository workOrderMechanicRepository;

  private final PartnerCompanyRepository partnerCompanyRepository;
  private final VendorRepository vendorRepository;
  private final VendorQuotationRepository vendorQuotationRepository;

  private final InvoiceRepository invoiceRepository;
  private final PaymentRepository paymentRepository;

  private synchronized String generateWorkOrderNumber() {
    int year = LocalDateTime.now().getYear();
    String yearPrefix = "WO-" + year + "-%";
    Integer maxNumber = workOrderRepository.findMaxWoNumberForYear(yearPrefix);
    int nextNumber = (maxNumber == null) ? 1 : maxNumber + 1;
    return String.format("WO-%d-%05d", year, nextNumber);
  }

  @Transactional
  public WorkOrderDto createWorkOrderFromApprovedMr(Long maintenanceRequestId, WorkOrderDto dto, Long userId) {
    MaintenanceRequest mr =
        maintenanceRequestRepository
            .findById(maintenanceRequestId)
            .orElseThrow(() -> new ResourceNotFoundException("Maintenance request not found: " + maintenanceRequestId));

    if (mr.getStatus() != MaintenanceRequestStatus.APPROVED) {
      throw new IllegalStateException("Work order requires an APPROVED maintenance request.");
    }

    if (workOrderRepository.findByMaintenanceRequestId(maintenanceRequestId).isPresent()) {
      throw new IllegalStateException("This maintenance request already has a work order.");
    }

    if (dto.getType() == null) {
      dto.setType(WorkOrderType.REPAIR);
    }
    if (dto.getType() != WorkOrderType.REPAIR && dto.getType() != WorkOrderType.EMERGENCY) {
      // SV Standard MR -> WO path is for repairs; allow REPAIR/EMERGENCY only.
      throw new IllegalArgumentException("SV Standard work orders must be type REPAIR or EMERGENCY.");
    }
    if (dto.getRepairType() == null) {
      throw new IllegalArgumentException("repairType is required (OWN or VENDOR).");
    }

    Vehicle vehicle =
        vehicleRepository
            .findById(mr.getVehicle().getId())
            .orElseThrow(() -> new ResourceNotFoundException("Vehicle not found: " + mr.getVehicle().getId()));

    User createdBy = userId != null ? userRepository.findById(userId).orElse(null) : null;

    WorkOrder wo =
        WorkOrder.builder()
            .woNumber(generateWorkOrderNumber())
            .vehicle(vehicle)
            .maintenanceRequest(mr)
            .type(dto.getType())
            .priority(dto.getPriority() != null ? dto.getPriority() : com.svtrucking.logistics.enums.Priority.NORMAL)
            .status(WorkOrderStatus.OPEN)
            .title(dto.getTitle())
            .description(dto.getDescription())
            .repairType(dto.getRepairType())
            .scheduledDate(dto.getScheduledDate())
            .createdBy(createdBy)
            .requiresApproval(false)
            .approved(false)
            .isDeleted(false)
            .build();

    WorkOrder saved = workOrderRepository.save(wo);

    // Auto-update vehicle status during repair lifecycle.
    if (vehicle.getStatus() != VehicleStatus.MAINTENANCE) {
      vehicle.setStatus(VehicleStatus.MAINTENANCE);
      vehicleRepository.save(vehicle);
    }

    return hydrateStandardFields(WorkOrderDto.fromEntity(saved, true));
  }

  @Transactional
  public WorkOrderDto assignMechanics(Long workOrderId, List<Long> mechanicIds) {
    WorkOrder wo =
        workOrderRepository
            .findById(workOrderId)
            .orElseThrow(() -> new ResourceNotFoundException("Work order not found: " + workOrderId));

    if (wo.getRepairType() != RepairType.OWN) {
      throw new IllegalStateException("Mechanic assignment is only allowed for OWN repairs.");
    }

    workOrderMechanicRepository.deleteByWorkOrderId(workOrderId);
    if (mechanicIds != null) {
      for (Long id : mechanicIds) {
        var mech =
            mechanicRepository
                .findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Mechanic not found: " + id));
        workOrderMechanicRepository.save(
            WorkOrderMechanic.builder().workOrder(wo).mechanic(mech).role("MECHANIC").build());
      }
    }
    return hydrateStandardFields(WorkOrderDto.fromEntity(wo, true));
  }

  @Transactional
  public VendorQuotationDto upsertVendorQuotation(Long workOrderId, VendorQuotationDto dto) {
    WorkOrder wo =
        workOrderRepository
            .findById(workOrderId)
            .orElseThrow(() -> new ResourceNotFoundException("Work order not found: " + workOrderId));
    if (wo.getRepairType() != RepairType.VENDOR) {
      throw new IllegalStateException("Vendor quotation is only allowed for VENDOR repairs.");
    }
    if (dto.getVendorId() == null) {
      throw new IllegalArgumentException("vendorId is required for vendor quotation.");
    }
    // Ensure vendor exists (extension table) for FK integrity.
    Vendor vendor =
        vendorRepository
            .findById(dto.getVendorId())
            .orElseGet(
                () ->
                    vendorRepository.save(
                        Vendor.builder()
                            .partnerCompany(
                                partnerCompanyRepository
                                    .findById(dto.getVendorId())
                                    .orElseThrow(
                                        () -> new ResourceNotFoundException("Vendor company not found: " + dto.getVendorId())))
                            .build()));

    VendorQuotation q =
        vendorQuotationRepository
            .findByWorkOrderId(workOrderId)
            .orElseGet(
                () ->
                    VendorQuotation.builder()
                        .workOrder(wo)
                        .vendor(vendor)
                        .status(VendorQuotationStatus.SUBMITTED)
                        .build());

    q.setVendor(vendor);
    q.setQuotationNumber(dto.getQuotationNumber());
    q.setAmount(dto.getAmount() != null ? dto.getAmount() : BigDecimal.ZERO);
    q.setNotes(dto.getNotes());
    if (q.getStatus() == null) {
      q.setStatus(VendorQuotationStatus.SUBMITTED);
    }
    VendorQuotation saved = vendorQuotationRepository.save(q);
    return VendorQuotationDto.fromEntity(saved);
  }

  @Transactional
  public VendorQuotationDto approveVendorQuotation(Long workOrderId, Long userId) {
    VendorQuotation q =
        vendorQuotationRepository
            .findByWorkOrderId(workOrderId)
            .orElseThrow(() -> new ResourceNotFoundException("Vendor quotation not found for work order: " + workOrderId));
    User approver = userId != null ? userRepository.findById(userId).orElse(null) : null;
    q.setStatus(VendorQuotationStatus.APPROVED);
    q.setApprovedAt(LocalDateTime.now());
    q.setApprovedBy(approver);
    q.setRejectionReason(null);
    return VendorQuotationDto.fromEntity(vendorQuotationRepository.save(q));
  }

  @Transactional
  public VendorQuotationDto rejectVendorQuotation(Long workOrderId, Long userId, String reason) {
    VendorQuotation q =
        vendorQuotationRepository
            .findByWorkOrderId(workOrderId)
            .orElseThrow(() -> new ResourceNotFoundException("Vendor quotation not found for work order: " + workOrderId));
    User rejector = userId != null ? userRepository.findById(userId).orElse(null) : null;
    q.setStatus(VendorQuotationStatus.REJECTED);
    q.setApprovedAt(null);
    q.setApprovedBy(null);
    q.setRejectionReason(reason);
    // store "rejected_by" not modeled - keep audit-friendly via logs
    log.info("Vendor quotation rejected by userId={} for workOrderId={}: {}", userId, workOrderId, reason);
    return VendorQuotationDto.fromEntity(vendorQuotationRepository.save(q));
  }

  @Transactional
  public InvoiceDto createInvoiceForWorkOrder(Long workOrderId, InvoiceDto dto) {
    WorkOrder wo =
        workOrderRepository
            .findById(workOrderId)
            .orElseThrow(() -> new ResourceNotFoundException("Work order not found: " + workOrderId));

    if (wo.getRepairType() != RepairType.VENDOR) {
      throw new IllegalStateException("Invoice is only required for VENDOR repairs.");
    }

    VendorQuotation q =
        vendorQuotationRepository
            .findByWorkOrderId(workOrderId)
            .orElseThrow(() -> new IllegalStateException("Quotation is required before invoice."));
    if (q.getStatus() != VendorQuotationStatus.APPROVED) {
      throw new IllegalStateException("Quotation must be approved before invoice.");
    }

    // One invoice per WO (enforced via unique constraint)
    var existing = invoiceRepository.findByWorkOrderId(workOrderId);
    if (existing.isPresent()) return InvoiceDto.fromEntity(existing.get());

    Invoice inv = new Invoice();
    inv.setWorkOrder(wo);
    inv.setInvoiceDate(dto.getInvoiceDate());
    inv.setTotalAmount(dto.getTotalAmount() != null ? dto.getTotalAmount().doubleValue() : q.getAmount().doubleValue());
    inv.setPaymentStatus(PaymentStatus.UNPAID.name());
    Invoice saved = invoiceRepository.save(inv);
    return InvoiceDto.fromEntity(saved);
  }

  @Transactional
  public PaymentDto recordPayment(Long invoiceId, PaymentDto dto, Long userId) {
    Invoice inv =
        invoiceRepository
            .findById(invoiceId)
            .orElseThrow(() -> new ResourceNotFoundException("Invoice not found: " + invoiceId));
    User createdBy = userId != null ? userRepository.findById(userId).orElse(null) : null;

    Payment p =
        Payment.builder()
            .invoice(inv)
            .amount(dto.getAmount())
            .method(dto.getMethod())
            .referenceNo(dto.getReferenceNo())
            .paidAt(dto.getPaidAt() != null ? dto.getPaidAt() : LocalDateTime.now())
            .notes(dto.getNotes())
            .createdBy(createdBy)
            .build();
    Payment saved = paymentRepository.save(p);

    // Update invoice payment status based on total paid.
    BigDecimal totalPaid =
        paymentRepository.findByInvoiceId(invoiceId).stream()
            .map(Payment::getAmount)
            .filter(a -> a != null)
            .reduce(BigDecimal.ZERO, BigDecimal::add);
    BigDecimal total = BigDecimal.valueOf(inv.getTotalAmount());

    if (totalPaid.compareTo(total) >= 0) {
      inv.setPaymentStatus(PaymentStatus.PAID.name());
    } else if (totalPaid.compareTo(BigDecimal.ZERO) > 0) {
      inv.setPaymentStatus(PaymentStatus.PARTIAL.name());
    } else {
      inv.setPaymentStatus(PaymentStatus.UNPAID.name());
    }
    invoiceRepository.save(inv);

    return PaymentDto.fromEntity(saved);
  }

  @Transactional
  public WorkOrderDto completeWorkOrder(Long workOrderId, Long userId) {
    WorkOrder wo =
        workOrderRepository
            .findById(workOrderId)
            .orElseThrow(() -> new ResourceNotFoundException("Work order not found: " + workOrderId));

    if (wo.getRepairType() == RepairType.VENDOR) {
      VendorQuotation q =
          vendorQuotationRepository
              .findByWorkOrderId(workOrderId)
              .orElseThrow(() -> new IllegalStateException("Quotation is required for vendor repair."));
      if (q.getStatus() != VendorQuotationStatus.APPROVED) {
        throw new IllegalStateException("Quotation must be approved for vendor repair.");
      }

      Invoice inv =
          invoiceRepository
              .findByWorkOrderId(workOrderId)
              .orElseThrow(() -> new IllegalStateException("Invoice is required for vendor repair."));

      if (!PaymentStatus.PAID.name().equalsIgnoreCase(inv.getPaymentStatus())) {
        throw new IllegalStateException("Payment is mandatory before completing vendor repair.");
      }

      wo.setActualCost(BigDecimal.valueOf(inv.getTotalAmount()));
    } else if (wo.getRepairType() == RepairType.OWN) {
      // Internal expense is recorded on the work order costs (labor + parts).
      wo.calculateTotalCost();
      wo.setActualCost(wo.getTotalCost());
    }

    wo.setStatus(WorkOrderStatus.COMPLETED);
    wo.setCompletedAt(LocalDateTime.now());
    wo.setClosedAt(LocalDateTime.now());

    WorkOrder saved = workOrderRepository.save(wo);

    // Auto-update vehicle status back to AVAILABLE when no other active work orders exist.
    Vehicle vehicle = saved.getVehicle();
    if (vehicle != null) {
      long activeCount = workOrderRepository.countActiveForVehicle(vehicle.getId());
      if (activeCount <= 0) {
        vehicle.setStatus(VehicleStatus.AVAILABLE);
        vehicleRepository.save(vehicle);
      }
    }

    log.info("Completed SV Standard work order {} by userId={}", saved.getId(), userId);
    return hydrateStandardFields(WorkOrderDto.fromEntity(saved, true));
  }

  @Transactional(readOnly = true)
  public WorkOrderDto hydrateStandardFields(WorkOrderDto dto) {
    if (dto == null || dto.getId() == null) return dto;
    Long workOrderId = dto.getId();

    vendorQuotationRepository.findByWorkOrderId(workOrderId).ifPresent(q -> dto.setVendorQuotation(VendorQuotationDto.fromEntity(q)));

    invoiceRepository.findByWorkOrderId(workOrderId).ifPresent(inv -> dto.setInvoice(InvoiceDto.fromEntity(inv)));

    return dto;
  }
}
