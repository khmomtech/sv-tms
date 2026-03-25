package com.svtrucking.logistics.service;

import com.svtrucking.logistics.enums.MaintenanceRequestStatus;
import com.svtrucking.logistics.enums.PaymentStatus;
import com.svtrucking.logistics.enums.Priority;
import com.svtrucking.logistics.enums.RepairType;
import com.svtrucking.logistics.enums.VendorQuotationStatus;
import com.svtrucking.logistics.enums.VehicleStatus;
import com.svtrucking.logistics.enums.VehicleType;
import com.svtrucking.logistics.enums.WorkOrderStatus;
import com.svtrucking.logistics.enums.WorkOrderType;
import com.svtrucking.logistics.model.Invoice;
import com.svtrucking.logistics.model.MaintenanceRequest;
import com.svtrucking.logistics.model.Mechanic;
import com.svtrucking.logistics.model.PartsMaster;
import com.svtrucking.logistics.model.PartnerCompany;
import com.svtrucking.logistics.model.Payment;
import com.svtrucking.logistics.model.User;
import com.svtrucking.logistics.model.Vehicle;
import com.svtrucking.logistics.model.Vendor;
import com.svtrucking.logistics.model.VendorQuotation;
import com.svtrucking.logistics.model.WorkOrder;
import com.svtrucking.logistics.model.WorkOrderMechanic;
import com.svtrucking.logistics.model.WorkOrderPart;
import com.svtrucking.logistics.repository.InvoiceRepository;
import com.svtrucking.logistics.repository.MaintenanceRequestRepository;
import com.svtrucking.logistics.repository.MechanicRepository;
import com.svtrucking.logistics.repository.PartnerCompanyRepository;
import com.svtrucking.logistics.repository.PartsMasterRepository;
import com.svtrucking.logistics.repository.PaymentRepository;
import com.svtrucking.logistics.repository.UserRepository;
import com.svtrucking.logistics.repository.VehicleRepository;
import com.svtrucking.logistics.repository.VendorQuotationRepository;
import com.svtrucking.logistics.repository.VendorRepository;
import com.svtrucking.logistics.repository.WorkOrderMechanicRepository;
import com.svtrucking.logistics.repository.WorkOrderPartRepository;
import com.svtrucking.logistics.repository.WorkOrderRepository;
import java.io.InputStream;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.poi.ss.usermodel.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

/**
 * SV Standard Excel import (CSV-like).
 *
 * Supported sheets (by name):
 * - Vehicles
 * - Maintenance_Requests
 * - Work_Orders
 * - OWN_Repair_Log
 * - Vendors
 * - Vendor_Quotations
 * - Parts_Usage
 * - Invoices
 * - Payments
 *
 * The importer is best-effort + idempotent by natural keys (plate, mr_number, wo_number, etc).
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class MaintenanceImportService {

  private final VehicleRepository vehicleRepository;
  private final MaintenanceRequestRepository maintenanceRequestRepository;
  private final WorkOrderRepository workOrderRepository;
  private final MechanicRepository mechanicRepository;
  private final WorkOrderMechanicRepository workOrderMechanicRepository;
  private final PartnerCompanyRepository partnerCompanyRepository;
  private final VendorRepository vendorRepository;
  private final VendorQuotationRepository vendorQuotationRepository;
  private final PartsMasterRepository partsMasterRepository;
  private final WorkOrderPartRepository workOrderPartRepository;
  private final InvoiceRepository invoiceRepository;
  private final PaymentRepository paymentRepository;
  private final UserRepository userRepository;

  @Transactional
  public Map<String, Object> importWorkbook(MultipartFile file, String username) {
    if (file == null || file.isEmpty()) throw new IllegalArgumentException("File is required");

    User actor = username != null ? userRepository.findByUsername(username).orElse(null) : null;
    Map<String, Object> result = new HashMap<>();
    Map<String, Integer> counts = new HashMap<>();

    try (InputStream in = file.getInputStream(); Workbook wb = WorkbookFactory.create(in)) {
      for (int i = 0; i < wb.getNumberOfSheets(); i++) {
        Sheet sheet = wb.getSheetAt(i);
        if (sheet == null) continue;
        String name = sheet.getSheetName();
        int imported = switch (name) {
          case "Vehicles" -> importVehicles(sheet);
          case "Maintenance_Requests" -> importMaintenanceRequests(sheet, actor);
          case "Work_Orders" -> importWorkOrders(sheet, actor);
          case "OWN_Repair_Log" -> importOwnRepairLog(sheet);
          case "Vendors" -> importVendors(sheet);
          case "Vendor_Quotations" -> importVendorQuotations(sheet, actor);
          case "Parts_Usage" -> importPartsUsage(sheet, actor);
          case "Invoices" -> importInvoices(sheet);
          case "Payments" -> importPayments(sheet, actor);
          default -> 0;
        };
        counts.put(name, imported);
      }
    } catch (Exception ex) {
      log.error("Maintenance import failed", ex);
      throw new RuntimeException("Import failed: " + ex.getMessage(), ex);
    }

    result.put("imported", counts);
    return result;
  }

  private int importVehicles(Sheet sheet) {
    Header h = Header.of(sheet);
    if (!h.valid()) return 0;
    int count = 0;
    for (Row r : h.dataRows()) {
      String plate = h.str(r, "license_plate", "LicensePlate", "TruckNumber");
      if (plate == null || plate.isBlank()) continue;
      Vehicle v = vehicleRepository.findByLicensePlate(plate).orElseGet(Vehicle::new);
      v.setLicensePlate(plate);
      v.setManufacturer(Optional.ofNullable(h.str(r, "manufacturer", "Manufacturer")).orElse("N/A"));
      v.setModel(Optional.ofNullable(h.str(r, "model", "Model")).orElse("N/A"));
      v.setType(parseEnum(h.str(r, "type", "Type"), VehicleType.class, VehicleType.TRUCK));
      v.setStatus(parseEnum(h.str(r, "status", "Status"), VehicleStatus.class, VehicleStatus.AVAILABLE));
      if (v.getMileage() == null) v.setMileage(BigDecimal.ZERO);
      vehicleRepository.save(v);
      count++;
    }
    return count;
  }

  private int importMaintenanceRequests(Sheet sheet, User actor) {
    Header h = Header.of(sheet);
    if (!h.valid()) return 0;
    int count = 0;
    for (Row r : h.dataRows()) {
      String mrNumber = h.str(r, "mr_number", "MRNumber");
      String plate = h.str(r, "license_plate", "VehiclePlate", "TruckNumber");
      if (plate == null || plate.isBlank()) continue;
      Vehicle vehicle =
          vehicleRepository
              .findByLicensePlate(plate)
              .orElseThrow(() -> new IllegalStateException("Vehicle not found for MR: " + plate));

      MaintenanceRequest mr =
          (mrNumber != null && !mrNumber.isBlank())
              ? maintenanceRequestRepository.findByMrNumber(mrNumber).orElseGet(MaintenanceRequest::new)
              : new MaintenanceRequest();

      if (mr.getMrNumber() == null) {
        mr.setMrNumber(mrNumber != null ? mrNumber : "MR-" + System.currentTimeMillis());
      }
      mr.setVehicle(vehicle);
      mr.setTitle(Optional.ofNullable(h.str(r, "title", "Title")).orElse("Maintenance Request"));
      mr.setDescription(h.str(r, "description", "Description"));
      mr.setPriority(parseEnum(h.str(r, "priority", "Priority"), Priority.class, Priority.NORMAL));
      mr.setRequestType(
          parseEnum(
              h.str(r, "request_type", "RequestType"),
              com.svtrucking.logistics.enums.MaintenanceRequestType.class,
              com.svtrucking.logistics.enums.MaintenanceRequestType.REPAIR));
      mr.setStatus(parseEnum(h.str(r, "status", "Status"), MaintenanceRequestStatus.class, MaintenanceRequestStatus.SUBMITTED));
      mr.setCreatedBy(actor);
      maintenanceRequestRepository.save(mr);
      count++;
    }
    return count;
  }

  private int importWorkOrders(Sheet sheet, User actor) {
    Header h = Header.of(sheet);
    if (!h.valid()) return 0;
    int count = 0;
    for (Row r : h.dataRows()) {
      String woNumber = h.str(r, "wo_number", "WONumber");
      if (woNumber == null || woNumber.isBlank()) continue;
      String plate = h.str(r, "license_plate", "VehiclePlate", "TruckNumber");
      if (plate == null || plate.isBlank()) continue;
      Vehicle vehicle =
          vehicleRepository
              .findByLicensePlate(plate)
              .orElseThrow(() -> new IllegalStateException("Vehicle not found for WO: " + plate));

      WorkOrder wo = workOrderRepository.findByWoNumber(woNumber).orElseGet(WorkOrder::new);
      wo.setWoNumber(woNumber);
      wo.setVehicle(vehicle);
      wo.setTitle(Optional.ofNullable(h.str(r, "title", "Title")).orElse("Work Order"));
      wo.setDescription(h.str(r, "description", "Description"));
      wo.setType(parseEnum(h.str(r, "type", "Type"), WorkOrderType.class, WorkOrderType.REPAIR));
      wo.setStatus(parseEnum(h.str(r, "status", "Status"), WorkOrderStatus.class, WorkOrderStatus.OPEN));
      wo.setPriority(parseEnum(h.str(r, "priority", "Priority"), Priority.class, Priority.NORMAL));
      wo.setRepairType(parseEnum(h.str(r, "repair_type", "RepairType"), RepairType.class, null));
      wo.setCreatedBy(actor);

      String mrNumber = h.str(r, "mr_number", "MRNumber");
      if (mrNumber != null && !mrNumber.isBlank()) {
        maintenanceRequestRepository.findByMrNumber(mrNumber).ifPresent(wo::setMaintenanceRequest);
      }

      workOrderRepository.save(wo);
      count++;
    }
    return count;
  }

  private int importOwnRepairLog(Sheet sheet) {
    Header h = Header.of(sheet);
    if (!h.valid()) return 0;
    int count = 0;
    for (Row r : h.dataRows()) {
      String woNumber = h.str(r, "wo_number", "WONumber");
      if (woNumber == null) continue;
      WorkOrder wo = workOrderRepository.findByWoNumber(woNumber).orElse(null);
      if (wo == null) continue;

      String mechName = h.str(r, "mechanic", "Mechanic", "full_name");
      if (mechName == null || mechName.isBlank()) continue;
      Mechanic mechanic =
          mechanicRepository
              .findByFullNameIgnoreCase(mechName)
              .orElseGet(
                  () -> mechanicRepository.save(Mechanic.builder().fullName(mechName).active(true).build()));

      // Idempotent (unique constraint prevents duplicates)
      try {
        workOrderMechanicRepository.save(
            WorkOrderMechanic.builder().workOrder(wo).mechanic(mechanic).role("MECHANIC").build());
        count++;
      } catch (Exception ignored) {
        // duplicate row
      }
    }
    return count;
  }

  private int importVendors(Sheet sheet) {
    Header h = Header.of(sheet);
    if (!h.valid()) return 0;
    int count = 0;
    for (Row r : h.dataRows()) {
      String companyCode = h.str(r, "company_code", "CompanyCode");
      Long id = h.longVal(r, "id", "Id");
      PartnerCompany pc = null;
      if (id != null) pc = partnerCompanyRepository.findById(id).orElse(null);
      if (pc == null && companyCode != null) pc = partnerCompanyRepository.findByCompanyCode(companyCode).orElse(null);
      if (pc == null) continue;
      if (vendorRepository.findById(pc.getId()).isEmpty()) {
        vendorRepository.save(Vendor.builder().partnerCompany(pc).build());
      }
      count++;
    }
    return count;
  }

  private int importVendorQuotations(Sheet sheet, User actor) {
    Header h = Header.of(sheet);
    if (!h.valid()) return 0;
    int count = 0;
    for (Row r : h.dataRows()) {
      String woNumber = h.str(r, "wo_number", "WONumber");
      if (woNumber == null) continue;
      WorkOrder wo = workOrderRepository.findByWoNumber(woNumber).orElse(null);
      if (wo == null) continue;

      Long vendorId = h.longVal(r, "vendor_id", "VendorId");
      if (vendorId == null) continue;
      PartnerCompany pc = partnerCompanyRepository.findById(vendorId).orElse(null);
      if (pc == null) continue;
      Vendor vendor = vendorRepository.findById(pc.getId()).orElseGet(() -> vendorRepository.save(Vendor.builder().partnerCompany(pc).build()));

      VendorQuotation q = vendorQuotationRepository.findByWorkOrderId(wo.getId()).orElseGet(VendorQuotation::new);
      q.setWorkOrder(wo);
      q.setVendor(vendor);
      q.setQuotationNumber(h.str(r, "quotation_number", "QuotationNumber"));
      q.setAmount(h.decimal(r, "amount", "Amount"));
      q.setStatus(parseEnum(h.str(r, "status", "Status"), VendorQuotationStatus.class, VendorQuotationStatus.SUBMITTED));
      q.setNotes(h.str(r, "notes", "Notes"));
      q.setApprovedBy(actor);
      if (q.getStatus() == VendorQuotationStatus.APPROVED) q.setApprovedAt(LocalDateTime.now());
      vendorQuotationRepository.save(q);
      count++;
    }
    return count;
  }

  private int importPartsUsage(Sheet sheet, User actor) {
    Header h = Header.of(sheet);
    if (!h.valid()) return 0;
    int count = 0;
    for (Row r : h.dataRows()) {
      String woNumber = h.str(r, "wo_number", "WONumber");
      if (woNumber == null) continue;
      WorkOrder wo = workOrderRepository.findByWoNumber(woNumber).orElse(null);
      if (wo == null) continue;

      String partCode = h.str(r, "part_code", "PartCode");
      if (partCode == null) continue;
      PartsMaster part =
          partsMasterRepository
              .findByPartCode(partCode)
              .orElseGet(
                  () ->
                      partsMasterRepository.save(
                          PartsMaster.builder()
                              .partCode(partCode)
                              .partName(Optional.ofNullable(h.str(r, "part_name", "PartName")).orElse(partCode))
                              .category(Optional.ofNullable(h.str(r, "category", "Category")).orElse("GENERAL"))
                              .referenceCost(h.decimal(r, "unit_cost", "UnitCost"))
                              .active(true)
                              .isDeleted(false)
                              .build()));

      Integer qty = h.intVal(r, "quantity", "Quantity");
      if (qty == null || qty <= 0) qty = 1;
      BigDecimal unitCost = h.decimal(r, "unit_cost", "UnitCost");

      WorkOrderPart woPart = new WorkOrderPart();
      woPart.setWorkOrder(wo);
      woPart.setPart(part);
      woPart.setQuantity(qty);
      woPart.setUnitCost(unitCost != null ? unitCost : (part.getUnitPrice() != null ? part.getUnitPrice() : BigDecimal.ZERO));
      woPart.setAddedBy(actor);
      workOrderPartRepository.save(woPart);
      count++;
    }
    return count;
  }

  private int importInvoices(Sheet sheet) {
    Header h = Header.of(sheet);
    if (!h.valid()) return 0;
    int count = 0;
    for (Row r : h.dataRows()) {
      Long invoiceId = h.longVal(r, "id", "Id");
      String woNumber = h.str(r, "wo_number", "WONumber");
      WorkOrder wo = (woNumber != null) ? workOrderRepository.findByWoNumber(woNumber).orElse(null) : null;

      Invoice inv = invoiceId != null ? invoiceRepository.findById(invoiceId).orElse(new Invoice()) : new Invoice();
      if (wo != null) inv.setWorkOrder(wo);
      inv.setInvoiceDate(h.date(r, "invoice_date", "InvoiceDate"));
      inv.setTotalAmount(h.decimal(r, "total_amount", "TotalAmount").doubleValue());
      String status = Optional.ofNullable(h.str(r, "payment_status", "PaymentStatus")).orElse(PaymentStatus.UNPAID.name());
      inv.setPaymentStatus(status);
      invoiceRepository.save(inv);
      count++;
    }
    return count;
  }

  private int importPayments(Sheet sheet, User actor) {
    Header h = Header.of(sheet);
    if (!h.valid()) return 0;
    int count = 0;
    for (Row r : h.dataRows()) {
      Long invoiceId = h.longVal(r, "invoice_id", "InvoiceId");
      if (invoiceId == null) continue;
      Invoice inv = invoiceRepository.findById(invoiceId).orElse(null);
      if (inv == null) continue;
      Payment p =
          Payment.builder()
              .invoice(inv)
              .amount(h.decimal(r, "amount", "Amount"))
              .method(h.str(r, "method", "Method"))
              .referenceNo(h.str(r, "reference_no", "ReferenceNo"))
              .paidAt(LocalDateTime.now())
              .createdBy(actor)
              .build();
      paymentRepository.save(p);
      count++;
    }
    return count;
  }

  private static <E extends Enum<E>> E parseEnum(String raw, Class<E> type, E fallback) {
    if (raw == null || raw.isBlank()) return fallback;
    try {
      return Enum.valueOf(type, raw.trim().toUpperCase());
    } catch (Exception ignored) {
      return fallback;
    }
  }

  private static final class Header {
    private final Map<String, Integer> idx;
    private final Sheet sheet;

    private Header(Sheet sheet, Map<String, Integer> idx) {
      this.sheet = sheet;
      this.idx = idx;
    }

    static Header of(Sheet sheet) {
      Map<String, Integer> idx = new HashMap<>();
      Row header = sheet.getRow(0);
      if (header == null) return new Header(sheet, idx);
      for (Cell c : header) {
        String v = cellToString(c);
        if (v == null) continue;
        idx.put(normalize(v), c.getColumnIndex());
      }
      return new Header(sheet, idx);
    }

    boolean valid() {
      return !idx.isEmpty();
    }

    Iterable<Row> dataRows() {
      return () -> sheet.rowIterator();
    }

    String str(Row r, String... names) {
      Integer col = col(names);
      if (col == null) return null;
      if (r.getRowNum() == 0) return null;
      return cellToString(r.getCell(col));
    }

    Long longVal(Row r, String... names) {
      String s = str(r, names);
      if (s == null || s.isBlank()) return null;
      try {
        return Long.parseLong(s.trim());
      } catch (Exception ignored) {
        return null;
      }
    }

    Integer intVal(Row r, String... names) {
      String s = str(r, names);
      if (s == null || s.isBlank()) return null;
      try {
        return Integer.parseInt(s.trim());
      } catch (Exception ignored) {
        return null;
      }
    }

    BigDecimal decimal(Row r, String... names) {
      String s = str(r, names);
      if (s == null || s.isBlank()) return BigDecimal.ZERO;
      try {
        return new BigDecimal(s.trim());
      } catch (Exception ignored) {
        return BigDecimal.ZERO;
      }
    }

    LocalDate date(Row r, String... names) {
      Integer col = col(names);
      if (col == null) return null;
      Cell c = r.getCell(col);
      if (c == null) return null;
      if (c.getCellType() == CellType.NUMERIC && DateUtil.isCellDateFormatted(c)) {
        return c.getDateCellValue().toInstant().atZone(ZoneId.systemDefault()).toLocalDate();
      }
      String s = cellToString(c);
      if (s == null || s.isBlank()) return null;
      try {
        return LocalDate.parse(s.trim());
      } catch (Exception ignored) {
        return null;
      }
    }

    private Integer col(String... names) {
      for (String n : names) {
        Integer i = idx.get(normalize(n));
        if (i != null) return i;
      }
      return null;
    }

    private static String normalize(String s) {
      return s.trim().toLowerCase().replace(" ", "_");
    }

    private static String cellToString(Cell c) {
      if (c == null) return null;
      return switch (c.getCellType()) {
        case STRING -> c.getStringCellValue();
        case NUMERIC -> DateUtil.isCellDateFormatted(c) ? c.getDateCellValue().toString() : String.valueOf((long) c.getNumericCellValue());
        case BOOLEAN -> String.valueOf(c.getBooleanCellValue());
        case FORMULA -> {
          try {
            yield c.getStringCellValue();
          } catch (Exception ex) {
            yield null;
          }
        }
        default -> null;
      };
    }
  }
}
