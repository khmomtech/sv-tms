package com.svtrucking.logistics.service;

import com.svtrucking.logistics.dto.*;
import com.svtrucking.logistics.dto.requests.PublicSafetyCheckItemRequest;
import com.svtrucking.logistics.dto.requests.PublicSafetyCheckRequest;
import com.svtrucking.logistics.enums.*;
import com.svtrucking.logistics.exception.ResourceNotFoundException;
import com.svtrucking.logistics.model.*;
import com.svtrucking.logistics.repository.*;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.*;
import java.util.stream.Collectors;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.poi.ss.usermodel.BorderStyle;
import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.CellStyle;
import org.apache.poi.ss.usermodel.FillPatternType;
import org.apache.poi.ss.usermodel.Font;
import org.apache.poi.ss.usermodel.HorizontalAlignment;
import org.apache.poi.ss.usermodel.IndexedColors;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.VerticalAlignment;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

@Slf4j
@Service
@RequiredArgsConstructor
public class SafetyCheckService {

  private static final ZoneId PHNOM_PENH = ZoneId.of("Asia/Phnom_Penh");

  private final SafetyCheckRepository safetyCheckRepository;
  private final SafetyCheckItemRepository safetyCheckItemRepository;
  private final SafetyCheckAttachmentRepository safetyCheckAttachmentRepository;
  private final SafetyCheckAuditRepository safetyCheckAuditRepository;
  private final SafetyCheckMasterItemRepository safetyCheckMasterItemRepository;
  private final SafetyCheckCategoryRepository safetyCheckCategoryRepository;
  private final DriverRepository driverRepository;
  private final VehicleRepository vehicleRepository;
  private final UserRepository userRepository;
  private final FileStorageService fileStorageService;

  @Transactional(readOnly = true)
  public SafetyCheckDto getToday(Long driverId, Long vehicleId) {
    LocalDate today = LocalDate.now(PHNOM_PENH);
    Optional<SafetyCheck> existing =
        safetyCheckRepository.findLatestByCheckDateAndDriverIdAndVehicleId(
            today, driverId, vehicleId);

    if (existing.isPresent()) {
      return toDto(existing.get(), true, true);
    }

    return SafetyCheckDto.builder()
        .checkDate(today)
        .driverId(driverId)
        .vehicleId(vehicleId)
        .status(DailySafetyCheckStatus.NOT_STARTED)
        .items(defaultItems())
        .build();
  }

  @Transactional(readOnly = true)
  public SafetyCheckDto getPublicToday(String plate) {
    String normalized = plate != null ? plate.trim() : "";
    if (normalized.isEmpty()) {
      throw new IllegalArgumentException("vehiclePlate is required");
    }
    Vehicle vehicle =
        vehicleRepository
            .findByLicensePlate(normalized)
            .orElseGet(
                () ->
                    vehicleRepository
                        .findByLicensePlate(normalized.toUpperCase(Locale.ROOT))
                        .orElseThrow(() -> new ResourceNotFoundException("Vehicle not found")));

    LocalDate today = LocalDate.now(PHNOM_PENH);
    Optional<SafetyCheck> existing =
        safetyCheckRepository.findLatestByCheckDateAndVehicleId(today, vehicle.getId());
    if (existing.isPresent()) {
      return toDto(existing.get(), true, true);
    }

    return SafetyCheckDto.builder()
        .checkDate(today)
        .vehicleId(vehicle.getId())
        .status(DailySafetyCheckStatus.NOT_STARTED)
        .items(defaultItems())
        .build();
  }

  @Transactional(readOnly = true)
  public List<SafetyCheckItemDto> getPublicMasterItems() {
    return defaultItems();
  }

  @Transactional(readOnly = true)
  public List<SafetyCheckDto> getPublicHistory(String plate, LocalDate from, LocalDate to) {
    String normalized = plate != null ? plate.trim() : "";
    if (normalized.isEmpty()) {
      throw new IllegalArgumentException("vehiclePlate is required");
    }
    Vehicle vehicle =
        vehicleRepository
            .findByLicensePlate(normalized)
            .orElseGet(
                () ->
                    vehicleRepository
                        .findByLicensePlate(normalized.toUpperCase(Locale.ROOT))
                        .orElseThrow(() -> new ResourceNotFoundException("Vehicle not found")));
    LocalDate fromDate = from != null ? from : LocalDate.now(PHNOM_PENH);
    LocalDate toDate = to != null ? to : fromDate;

    List<SafetyCheck> list =
        safetyCheckRepository.findByVehicleIdAndCheckDateBetween(
            vehicle.getId(), fromDate, toDate);
    return list.stream()
        .sorted(Comparator.comparing(SafetyCheck::getCheckDate).reversed())
        .map(sc -> toDto(sc, false, false))
        .toList();
  }

  @Transactional(readOnly = true)
  public SafetyCheckDto getPublicDetail(Long id, String plate) {
    String normalized = plate != null ? plate.trim() : "";
    if (normalized.isEmpty()) {
      throw new IllegalArgumentException("vehiclePlate is required");
    }

    SafetyCheck safetyCheck =
        safetyCheckRepository
            .findById(id)
            .orElseThrow(() -> new ResourceNotFoundException("Safety check not found"));

    String entityPlate =
        safetyCheck.getVehicle() != null && safetyCheck.getVehicle().getLicensePlate() != null
            ? safetyCheck.getVehicle().getLicensePlate().trim()
            : "";

    if (!entityPlate.equalsIgnoreCase(normalized)) {
      throw new ResourceNotFoundException("Safety check not found for this vehicle");
    }

    return toDto(safetyCheck, true, false);
  }

  @Transactional
  public SafetyCheckDto saveDraft(
      SafetyCheckDto payload, Long driverId, Long actorUserId, String actorRole) {
    if (payload.getVehicleId() == null) {
      throw new IllegalArgumentException("vehicleId is required");
    }

    LocalDate checkDate =
        payload.getCheckDate() != null ? payload.getCheckDate() : LocalDate.now(PHNOM_PENH);

    SafetyCheck safetyCheck =
        safetyCheckRepository
            .findLatestByCheckDateAndDriverIdAndVehicleId(
                checkDate, driverId, payload.getVehicleId())
            .orElseGet(
                () -> {
                  Driver driver =
                      driverRepository
                          .findById(driverId)
                          .orElseThrow(() -> new ResourceNotFoundException("Driver not found"));
                  Vehicle vehicle =
                      vehicleRepository
                          .findById(payload.getVehicleId())
                          .orElseThrow(() -> new ResourceNotFoundException("Vehicle not found"));

                  return SafetyCheck.builder()
                      .checkDate(checkDate)
                      .driver(driver)
                      .vehicle(vehicle)
                      .status(DailySafetyCheckStatus.DRAFT)
                      .build();
                });

    if (safetyCheck.getStatus() == DailySafetyCheckStatus.WAITING_APPROVAL
        || safetyCheck.getStatus() == DailySafetyCheckStatus.APPROVED) {
      throw new IllegalStateException("Safety check cannot be edited while waiting or approved");
    }

    if (safetyCheck.getStatus() == null || safetyCheck.getStatus() == DailySafetyCheckStatus.NOT_STARTED) {
      safetyCheck.setStatus(DailySafetyCheckStatus.DRAFT);
    }

    if (safetyCheck.getStatus() == DailySafetyCheckStatus.REJECTED) {
      safetyCheck.setStatus(DailySafetyCheckStatus.DRAFT);
      safetyCheck.setRejectReason(null);
      safetyCheck.setApprovedAt(null);
      safetyCheck.setApprovedBy(null);
      safetyCheck.setSubmittedAt(null);
      saveAudit(
          safetyCheck,
          "RESUBMIT_AFTER_FIX",
          actorUserId,
          actorRole,
          "Driver resubmitted after fix");
    }

    safetyCheck.setShift(payload.getShift());
    safetyCheck.setNotes(payload.getNotes());
    safetyCheck.setGpsLat(payload.getGpsLat());
    safetyCheck.setGpsLng(payload.getGpsLng());

    SafetyCheck saved = safetyCheckRepository.save(safetyCheck);

    upsertItems(saved, payload.getItems());

    SafetyRiskLevel computed = calculateRiskLevel(saved.getId());
    saved.setRiskLevel(computed);

    SafetyCheck finalSaved = safetyCheckRepository.save(saved);
    saveAudit(finalSaved, "DRAFT_SAVE", actorUserId, actorRole, "Draft saved");

    return toDto(finalSaved, true, true);
  }

  @Transactional
  public SafetyCheckAttachmentDto addAttachment(
      Long safetyCheckId,
      Long itemId,
      MultipartFile file,
      Long actorUserId,
      String actorRole,
      Long driverId) {
    SafetyCheck safetyCheck =
        safetyCheckRepository
            .findById(safetyCheckId)
            .orElseThrow(() -> new ResourceNotFoundException("Safety check not found"));

    if (driverId != null && safetyCheck.getDriver() != null) {
      if (!safetyCheck.getDriver().getId().equals(driverId)) {
        throw new SecurityException("Not allowed to attach to this safety check");
      }
    }

    if (safetyCheck.getStatus() != DailySafetyCheckStatus.DRAFT
        && safetyCheck.getStatus() != DailySafetyCheckStatus.REJECTED) {
      throw new IllegalStateException("Cannot add attachment after submission");
    }

    SafetyCheckItem item = null;
    if (itemId != null) {
      item =
          safetyCheckItemRepository
              .findById(itemId)
              .orElseThrow(() -> new ResourceNotFoundException("Safety check item not found"));
      if (!item.getSafetyCheck().getId().equals(safetyCheckId)) {
        throw new IllegalArgumentException("Item does not belong to this safety check");
      }
    }

    String fileUrl = fileStorageService.storeFileInSubfolder(file, "safety-checks");

    User uploader =
        actorUserId == null
            ? null
            : userRepository
                .findById(actorUserId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

    SafetyCheckAttachment attachment =
        SafetyCheckAttachment.builder()
            .safetyCheck(safetyCheck)
            .item(item)
            .fileUrl(fileUrl)
            .fileName(file.getOriginalFilename())
            .mimeType(file.getContentType())
            .uploadedBy(uploader)
            .build();

    SafetyCheckAttachment saved = safetyCheckAttachmentRepository.save(attachment);

    saveAudit(safetyCheck, "ATTACHMENT_UPLOADED", actorUserId, actorRole, "Attachment uploaded");

    return toDto(saved);
  }

  @Transactional
  public SafetyCheckDto submit(Long safetyCheckId, Long driverId, Long actorUserId, String actorRole) {
    SafetyCheck safetyCheck =
        safetyCheckRepository
            .findById(safetyCheckId)
            .orElseThrow(() -> new ResourceNotFoundException("Safety check not found"));

    if (!safetyCheck.getDriver().getId().equals(driverId)) {
      throw new SecurityException("Not allowed to submit this safety check");
    }

    if (safetyCheck.getStatus() != DailySafetyCheckStatus.DRAFT) {
      throw new IllegalStateException("Only drafts can be submitted");
    }

    SafetyRiskLevel risk = calculateRiskLevel(safetyCheckId);

    safetyCheck.setRiskLevel(risk);
    safetyCheck.setStatus(DailySafetyCheckStatus.WAITING_APPROVAL);
    safetyCheck.setSubmittedAt(LocalDateTime.now());

    SafetyCheck saved = safetyCheckRepository.save(safetyCheck);

    saveAudit(saved, "SUBMITTED", actorUserId, actorRole, "Submitted for approval");

    return toDto(saved, true, true);
  }

  @Transactional
  public SafetyCheckDto submitPublic(PublicSafetyCheckRequest request) {
    if (request == null) {
      throw new IllegalArgumentException("Request is required");
    }
    String plate = request.getVehiclePlate() != null ? request.getVehiclePlate().trim() : "";
    if (plate.isEmpty()) {
      throw new IllegalArgumentException("vehiclePlate is required");
    }

    Vehicle vehicle =
        vehicleRepository
            .findByLicensePlate(plate)
            .orElseGet(
                () ->
                    vehicleRepository
                        .findByLicensePlate(plate.toUpperCase(Locale.ROOT))
                        .orElseThrow(() -> new ResourceNotFoundException("Vehicle not found")));

    String requestedDriverName =
        request.getDriverName() != null ? request.getDriverName().trim() : "";
    String requestedDriverPhone =
        request.getDriverPhone() != null ? request.getDriverPhone().trim() : "";

    final String driverName = requestedDriverName.isEmpty() ? "Public Driver" : requestedDriverName;
    final String driverPhone = requestedDriverPhone.isEmpty() ? "N/A" : requestedDriverPhone;

    Driver driver =
        driverRepository
            .findTopByPhone(driverPhone)
            .orElseGet(
                () -> {
                  Driver created = new Driver();
                  created.setFirstName(driverName);
                  created.setLastName("");
                  created.setPhone(driverPhone);
                  created.setIsActive(true);
                  created.setPartner(false);
                  created.setStatus(DriverStatus.ONLINE);
                  return driverRepository.save(created);
                });

    SafetyCheckDto draftPayload =
        SafetyCheckDto.builder()
            .vehicleId(vehicle.getId())
            .checkDate(LocalDate.now(PHNOM_PENH))
            .shift(request.getShift())
            .notes(request.getNotes())
            .gpsLat(request.getGpsLat())
            .gpsLng(request.getGpsLng())
            .items(mapPublicItems(request.getItems()))
            .build();

    SafetyCheckDto draft = saveDraft(draftPayload, driver.getId(), null, "PUBLIC");
    return submit(draft.getId(), driver.getId(), null, "PUBLIC");
  }

  private List<SafetyCheckItemDto> mapPublicItems(List<PublicSafetyCheckItemRequest> items) {
    if (items == null) return Collections.emptyList();
    List<SafetyCheckItemDto> mapped = new ArrayList<>();
    for (PublicSafetyCheckItemRequest item : items) {
      if (item == null) continue;
      String category = item.getCategory() != null ? item.getCategory().trim() : null;
      String label = item.getLabel() != null ? item.getLabel().trim() : null;
      if (category == null || category.isEmpty() || label == null || label.isEmpty()) {
        continue;
      }
      String key = slugify(category + "-" + label);
      boolean ok = item.getOk() != null ? item.getOk() : true;
      SafetyItemResult result = ok ? SafetyItemResult.OK : SafetyItemResult.NOT_OK;
      SafetySeverity severity = ok ? SafetySeverity.LOW : SafetySeverity.HIGH;

      mapped.add(
          SafetyCheckItemDto.builder()
              .category(category)
              .itemKey(key)
              .itemLabelKm(label)
              .result(result)
              .severity(severity)
              .remark(item.getRemark())
              .build());
    }
    return mapped;
  }

  private String slugify(String raw) {
    if (raw == null) return "";
    String normalized =
        raw.trim()
            .toLowerCase(Locale.ROOT)
            .replace('\u200b', ' ')
            .replaceAll("[^\\p{L}\\p{M}\\p{Nd}]+", "_")
            .replaceAll("_+", "_")
            .replaceAll("^_|_$", "");
    if (normalized.isBlank()) {
      return "item_" + Integer.toHexString(raw.hashCode());
    }
    return normalized;
  }

  @Transactional(readOnly = true)
  public List<SafetyCheckDto> getHistory(Long driverId, LocalDate from, LocalDate to) {
    LocalDate start = from != null ? from : LocalDate.now(PHNOM_PENH).minusDays(30);
    LocalDate end = to != null ? to : LocalDate.now(PHNOM_PENH);

    List<SafetyCheck> checks =
        safetyCheckRepository.findByDriverIdAndCheckDateBetween(driverId, start, end);
    checks.sort(Comparator.comparing(SafetyCheck::getCheckDate).reversed());

    return checks.stream().map(sc -> toDto(sc, false, false)).collect(Collectors.toList());
  }

  @Transactional(readOnly = true)
  public Page<SafetyCheckDto> getAdminList(
      String search,
      LocalDate from,
      LocalDate to,
      DailySafetyCheckStatus status,
      SafetyRiskLevel risk,
      Pageable pageable) {
    Specification<SafetyCheck> spec = Specification.where(null);
    if (search != null && !search.trim().isEmpty()) {
      String term = "%" + search.trim().toLowerCase(Locale.ROOT) + "%";
      spec =
          spec.and(
              (root, query, cb) -> {
                var driver = root.join("driver", jakarta.persistence.criteria.JoinType.LEFT);
                var vehicle = root.join("vehicle", jakarta.persistence.criteria.JoinType.LEFT);
                return cb.or(
                    cb.like(cb.lower(driver.get("firstName")), term),
                    cb.like(cb.lower(driver.get("lastName")), term),
                    cb.like(cb.lower(driver.get("phone")), term),
                    cb.like(cb.lower(vehicle.get("licensePlate")), term));
              });
    }

    if (from != null) {
      spec = spec.and((root, query, cb) -> cb.greaterThanOrEqualTo(root.get("checkDate"), from));
    }
    if (to != null) {
      spec = spec.and((root, query, cb) -> cb.lessThanOrEqualTo(root.get("checkDate"), to));
    }
    if (status != null) {
      spec = spec.and((root, query, cb) -> cb.equal(root.get("status"), status));
    }
    if (risk != null) {
      spec = spec.and((root, query, cb) -> cb.equal(root.get("riskLevel"), risk));
    }

    return safetyCheckRepository.findAll(spec, pageable).map(sc -> toDto(sc, false, false));
  }

  @Transactional(readOnly = true)
  public byte[] exportAdminCsv(
      String search,
      LocalDate from,
      LocalDate to,
      DailySafetyCheckStatus status,
      SafetyRiskLevel risk) {
    Specification<SafetyCheck> spec = Specification.where(null);
    if (search != null && !search.trim().isEmpty()) {
      String term = "%" + search.trim().toLowerCase(Locale.ROOT) + "%";
      spec =
          spec.and(
              (root, query, cb) -> {
                var driver = root.join("driver", jakarta.persistence.criteria.JoinType.LEFT);
                var vehicle = root.join("vehicle", jakarta.persistence.criteria.JoinType.LEFT);
                return cb.or(
                    cb.like(cb.lower(driver.get("firstName")), term),
                    cb.like(cb.lower(driver.get("lastName")), term),
                    cb.like(cb.lower(driver.get("phone")), term),
                    cb.like(cb.lower(vehicle.get("licensePlate")), term));
              });
    }

    if (from != null) {
      spec = spec.and((root, query, cb) -> cb.greaterThanOrEqualTo(root.get("checkDate"), from));
    }
    if (to != null) {
      spec = spec.and((root, query, cb) -> cb.lessThanOrEqualTo(root.get("checkDate"), to));
    }
    if (status != null) {
      spec = spec.and((root, query, cb) -> cb.equal(root.get("status"), status));
    }
    if (risk != null) {
      spec = spec.and((root, query, cb) -> cb.equal(root.get("riskLevel"), risk));
    }

    List<SafetyCheck> checks =
        safetyCheckRepository.findAll(spec, org.springframework.data.domain.Sort.by("checkDate").descending());

    StringBuilder csv = new StringBuilder();
    csv.append(
        "CheckDate,DriverName,DriverPhone,VehiclePlate,Status,RiskLevel,RiskOverride,SubmittedAt,ApprovedAt,IssuesCount,IssueRemarks\n");

    for (SafetyCheck check : checks) {
      String driverName = resolveDriverName(check.getDriver());
      String driverPhone = check.getDriver() != null ? check.getDriver().getPhone() : "";
      String vehiclePlate = check.getVehicle() != null ? check.getVehicle().getLicensePlate() : "";
      String statusVal = check.getStatus() != null ? check.getStatus().name() : "";
      String riskLevel = check.getRiskLevel() != null ? check.getRiskLevel().name() : "";
      String riskOverride = check.getRiskOverride() != null ? check.getRiskOverride().name() : "";
      String submittedAt = check.getSubmittedAt() != null ? check.getSubmittedAt().toString() : "";
      String approvedAt = check.getApprovedAt() != null ? check.getApprovedAt().toString() : "";

      List<SafetyCheckItem> items =
          safetyCheckItemRepository.findBySafetyCheckId(check.getId());
      long issues =
          items.stream()
              .filter(
                  item ->
                      item.getResult() != null
                          && item.getResult() != SafetyItemResult.OK)
              .count();
      String remarks =
          items.stream()
              .filter(item -> item.getRemark() != null && !item.getRemark().isBlank())
              .map(item -> item.getItemLabelKm() + ": " + item.getRemark())
              .collect(Collectors.joining(" | "));

      csv.append(csvEscape(check.getCheckDate() != null ? check.getCheckDate().toString() : ""))
          .append(',')
          .append(csvEscape(driverName))
          .append(',')
          .append(csvEscape(driverPhone))
          .append(',')
          .append(csvEscape(vehiclePlate))
          .append(',')
          .append(csvEscape(statusVal))
          .append(',')
          .append(csvEscape(riskLevel))
          .append(',')
          .append(csvEscape(riskOverride))
          .append(',')
          .append(csvEscape(submittedAt))
          .append(',')
          .append(csvEscape(approvedAt))
          .append(',')
          .append(issues)
          .append(',')
          .append(csvEscape(remarks))
          .append('\n');
    }

    return csv.toString().getBytes(java.nio.charset.StandardCharsets.UTF_8);
  }

  @Transactional(readOnly = true)
  public byte[] exportAdminExcel(
      String search,
      LocalDate from,
      LocalDate to,
      DailySafetyCheckStatus status,
      SafetyRiskLevel risk) {
    Specification<SafetyCheck> spec = Specification.where(null);
    if (search != null && !search.trim().isEmpty()) {
      String term = "%" + search.trim().toLowerCase(Locale.ROOT) + "%";
      spec =
          spec.and(
              (root, query, cb) -> {
                var driver = root.join("driver", jakarta.persistence.criteria.JoinType.LEFT);
                var vehicle = root.join("vehicle", jakarta.persistence.criteria.JoinType.LEFT);
                return cb.or(
                    cb.like(cb.lower(driver.get("firstName")), term),
                    cb.like(cb.lower(driver.get("lastName")), term),
                    cb.like(cb.lower(driver.get("phone")), term),
                    cb.like(cb.lower(vehicle.get("licensePlate")), term));
              });
    }

    if (from != null) {
      spec = spec.and((root, query, cb) -> cb.greaterThanOrEqualTo(root.get("checkDate"), from));
    }
    if (to != null) {
      spec = spec.and((root, query, cb) -> cb.lessThanOrEqualTo(root.get("checkDate"), to));
    }
    if (status != null) {
      spec = spec.and((root, query, cb) -> cb.equal(root.get("status"), status));
    }
    if (risk != null) {
      spec = spec.and((root, query, cb) -> cb.equal(root.get("riskLevel"), risk));
    }

    List<SafetyCheck> checks =
        safetyCheckRepository.findAll(spec, org.springframework.data.domain.Sort.by("checkDate").descending());

    try (Workbook wb = new XSSFWorkbook();
        ByteArrayOutputStream out = new ByteArrayOutputStream()) {
      var sheet = wb.createSheet("Safety Checks");

      Font khmerFont = wb.createFont();
      khmerFont.setFontName("Khmer OS");
      khmerFont.setFontHeightInPoints((short) 11);

      Font titleFont = wb.createFont();
      titleFont.setFontName("Khmer OS");
      titleFont.setFontHeightInPoints((short) 14);
      titleFont.setBold(true);

      Font headerFont = wb.createFont();
      headerFont.setFontName("Khmer OS");
      headerFont.setFontHeightInPoints((short) 11);
      headerFont.setBold(true);

      CellStyle titleStyle = wb.createCellStyle();
      titleStyle.setFont(titleFont);
      titleStyle.setAlignment(HorizontalAlignment.LEFT);
      titleStyle.setVerticalAlignment(VerticalAlignment.CENTER);

      CellStyle headerStyle = wb.createCellStyle();
      headerStyle.setFont(headerFont);
      headerStyle.setFillForegroundColor(IndexedColors.LIGHT_CORNFLOWER_BLUE.getIndex());
      headerStyle.setFillPattern(FillPatternType.SOLID_FOREGROUND);
      headerStyle.setAlignment(HorizontalAlignment.CENTER);
      headerStyle.setVerticalAlignment(VerticalAlignment.CENTER);
      headerStyle.setBorderBottom(BorderStyle.THIN);
      headerStyle.setBorderTop(BorderStyle.THIN);
      headerStyle.setBorderLeft(BorderStyle.THIN);
      headerStyle.setBorderRight(BorderStyle.THIN);

      CellStyle bodyStyle = wb.createCellStyle();
      bodyStyle.setFont(khmerFont);
      bodyStyle.setVerticalAlignment(VerticalAlignment.CENTER);
      bodyStyle.setBorderBottom(BorderStyle.THIN);
      bodyStyle.setBorderTop(BorderStyle.THIN);
      bodyStyle.setBorderLeft(BorderStyle.THIN);
      bodyStyle.setBorderRight(BorderStyle.THIN);

      int rowIdx = 0;
      Row titleRow = sheet.createRow(rowIdx++);
      Cell titleCell = titleRow.createCell(0);
      titleCell.setCellValue("របាយការណ៍ត្រួតពិនិត្យសុវត្ថិភាព (Safety Check Report)");
      titleCell.setCellStyle(titleStyle);
      sheet.addMergedRegion(new org.apache.poi.ss.util.CellRangeAddress(0, 0, 0, 10));

      Row filterRow = sheet.createRow(rowIdx++);
      Cell filterCell = filterRow.createCell(0);
      String filterText =
          "Filter: "
              + (from != null ? "From " + from : "From -")
              + " | "
              + (to != null ? "To " + to : "To -")
              + " | Status: "
              + (status != null ? status.name() : "All")
              + " | Risk: "
              + (risk != null ? risk.name() : "All")
              + " | Search: "
              + (search != null && !search.isBlank() ? search : "-");
      filterCell.setCellValue(filterText);
      filterCell.setCellStyle(bodyStyle);
      sheet.addMergedRegion(new org.apache.poi.ss.util.CellRangeAddress(1, 1, 0, 10));

      rowIdx++; // blank row

      Row headerRow = sheet.createRow(rowIdx++);
      String[] headers = {
        "កាលបរិច្ឆេទ",
        "ឈ្មោះអ្នកបើកបរ",
        "ទូរស័ព្ទ",
        "ស្លាកលេខ",
        "ស្ថានភាព",
        "ហានិភ័យ",
        "ហានិភ័យកែសម្រួល",
        "បានដាក់ស្នើ",
        "បានអនុម័ត",
        "ចំនួនបញ្ហា",
        "សេចក្តីសម្គាល់"
      };
      for (int c = 0; c < headers.length; c++) {
        Cell cell = headerRow.createCell(c);
        cell.setCellValue(headers[c]);
        cell.setCellStyle(headerStyle);
      }

      for (SafetyCheck check : checks) {
        Row row = sheet.createRow(rowIdx++);
        String driverName = resolveDriverName(check.getDriver());
        String driverPhone = check.getDriver() != null ? check.getDriver().getPhone() : "";
        String vehiclePlate = check.getVehicle() != null ? check.getVehicle().getLicensePlate() : "";
        String statusVal = check.getStatus() != null ? check.getStatus().name() : "";
        String riskLevel = check.getRiskLevel() != null ? check.getRiskLevel().name() : "";
        String riskOverride = check.getRiskOverride() != null ? check.getRiskOverride().name() : "";
        String submittedAt = check.getSubmittedAt() != null ? check.getSubmittedAt().toString() : "";
        String approvedAt = check.getApprovedAt() != null ? check.getApprovedAt().toString() : "";

        List<SafetyCheckItem> items =
            safetyCheckItemRepository.findBySafetyCheckId(check.getId());
        long issues =
            items.stream()
                .filter(
                    item ->
                        item.getResult() != null
                            && item.getResult() != SafetyItemResult.OK)
                .count();
        String remarks =
            items.stream()
                .filter(item -> item.getRemark() != null && !item.getRemark().isBlank())
                .map(item -> item.getItemLabelKm() + ": " + item.getRemark())
                .collect(Collectors.joining(" | "));

        Object[] values = {
          check.getCheckDate() != null ? check.getCheckDate().toString() : "",
          driverName,
          driverPhone,
          vehiclePlate,
          statusVal,
          riskLevel,
          riskOverride,
          submittedAt,
          approvedAt,
          issues,
          remarks
        };
        for (int c = 0; c < values.length; c++) {
          Cell cell = row.createCell(c);
          Object val = values[c];
          if (val instanceof Number) {
            cell.setCellValue(((Number) val).doubleValue());
          } else {
            cell.setCellValue(val != null ? String.valueOf(val) : "");
          }
          cell.setCellStyle(bodyStyle);
        }
      }

      for (int c = 0; c < headers.length; c++) {
        sheet.autoSizeColumn(c);
      }

      wb.write(out);
      return out.toByteArray();
    } catch (IOException e) {
      throw new RuntimeException("Failed to export Excel", e);
    }
  }

  private String csvEscape(String raw) {
    if (raw == null) return "";
    String escaped = raw.replace("\"", "\"\"");
    if (escaped.contains(",") || escaped.contains("\"") || escaped.contains("\n")) {
      return "\"" + escaped + "\"";
    }
    return escaped;
  }

  @Transactional(readOnly = true)
  public SafetyCheckDto getAdminDetail(Long id) {
    SafetyCheck safetyCheck =
        safetyCheckRepository
            .findById(id)
            .orElseThrow(() -> new ResourceNotFoundException("Safety check not found"));

    return toDto(safetyCheck, true, true);
  }

  @Transactional
  public SafetyCheckDto approve(
      Long id, Long adminUserId, String actorRole, SafetyRiskLevel riskOverride) {
    SafetyCheck safetyCheck =
        safetyCheckRepository
            .findById(id)
            .orElseThrow(() -> new ResourceNotFoundException("Safety check not found"));

    User admin =
        userRepository
            .findById(adminUserId)
            .orElseThrow(() -> new ResourceNotFoundException("User not found"));

    safetyCheck.setStatus(DailySafetyCheckStatus.APPROVED);
    safetyCheck.setApprovedAt(LocalDateTime.now());
    safetyCheck.setApprovedBy(admin);

    if (riskOverride != null) {
      safetyCheck.setRiskOverride(riskOverride);
    }

    SafetyCheck saved = safetyCheckRepository.save(safetyCheck);
    saveAudit(saved, "APPROVED", adminUserId, actorRole, "Approved safety check");

    return toDto(saved, true, true);
  }

  @Transactional
  public SafetyCheckDto reject(Long id, Long adminUserId, String actorRole, String reason) {
    if (reason == null || reason.isBlank()) {
      throw new IllegalArgumentException("Reject reason is required");
    }

    SafetyCheck safetyCheck =
        safetyCheckRepository
            .findById(id)
            .orElseThrow(() -> new ResourceNotFoundException("Safety check not found"));

    User admin =
        userRepository
            .findById(adminUserId)
            .orElseThrow(() -> new ResourceNotFoundException("User not found"));

    safetyCheck.setStatus(DailySafetyCheckStatus.REJECTED);
    safetyCheck.setRejectReason(reason);
    safetyCheck.setApprovedAt(LocalDateTime.now());
    safetyCheck.setApprovedBy(admin);

    SafetyCheck saved = safetyCheckRepository.save(safetyCheck);
    saveAudit(saved, "REJECTED", adminUserId, actorRole, "Rejected: " + reason);

    return toDto(saved, true, true);
  }

  @Transactional(readOnly = true)
  public SafetyEligibilityDto checkEligibility(Long driverId, Long vehicleId, LocalDate date) {
    LocalDate checkDate = date != null ? date : LocalDate.now(PHNOM_PENH);

    Optional<SafetyCheck> existing =
        safetyCheckRepository.findLatestByCheckDateAndDriverIdAndVehicleId(
            checkDate, driverId, vehicleId);

    if (existing.isEmpty()) {
      return SafetyEligibilityDto.builder()
          .eligible(false)
          .status(DailySafetyCheckStatus.NOT_STARTED)
          .message("មិនទាន់បានបំពេញការត្រួតពិនិត្យសុវត្ថិភាពសម្រាប់ថ្ងៃនេះ")
          .build();
    }

    SafetyCheck safetyCheck = existing.get();
    boolean approved = safetyCheck.getStatus() == DailySafetyCheckStatus.APPROVED;
    String message =
        approved
            ? "អាចចេញដំណើរ"
            : "មិនអាចចេញដំណើរបានទេ ព្រោះការត្រួតពិនិត្យសុវត្ថិភាពមិនទាន់បានអនុម័ត";

    return SafetyEligibilityDto.builder()
        .eligible(approved)
        .status(safetyCheck.getStatus())
        .riskLevel(safetyCheck.getRiskLevel())
        .safetyCheckId(safetyCheck.getId())
        .message(message)
        .build();
  }

  @Transactional(readOnly = true)
  public void assertEligibility(Long driverId, Long vehicleId, LocalDate date) {
    SafetyEligibilityDto eligibility = checkEligibility(driverId, vehicleId, date);
    if (!eligibility.isEligible()) {
      throw new IllegalStateException(
          "មិនអាចចាប់ផ្តើម Trip បានទេ ព្រោះការត្រួតពិនិត្យសុវត្ថិភាពមិនទាន់បានអនុម័ត");
    }
  }

  private void upsertItems(SafetyCheck safetyCheck, List<SafetyCheckItemDto> items) {
    if (items == null) {
      return;
    }

    List<SafetyCheckItem> existingItems =
        safetyCheckItemRepository.findBySafetyCheckId(safetyCheck.getId());

    Map<String, SafetyCheckItem> byKey =
        existingItems.stream()
            .collect(Collectors.toMap(this::itemMapKey, item -> item, (a, b) -> a));

    Set<String> seenKeys = new HashSet<>();

    for (SafetyCheckItemDto dto : items) {
      if (dto.getCategory() == null || dto.getItemKey() == null) {
        continue;
      }
      String key = itemMapKey(dto.getCategory(), dto.getItemKey());
      seenKeys.add(key);

      SafetyCheckItem item = byKey.get(key);
      if (item == null) {
        item = SafetyCheckItem.builder().safetyCheck(safetyCheck).build();
      }

      item.setCategory(dto.getCategory());
      item.setItemKey(dto.getItemKey());
      item.setItemLabelKm(dto.getItemLabelKm());
      item.setResult(dto.getResult());
      item.setSeverity(dto.getSeverity());
      item.setRemark(dto.getRemark());

      safetyCheckItemRepository.save(item);
    }

    for (SafetyCheckItem item : existingItems) {
      String key = itemMapKey(item);
      if (!seenKeys.contains(key)) {
        safetyCheckItemRepository.delete(item);
      }
    }
  }

  private SafetyRiskLevel calculateRiskLevel(Long safetyCheckId) {
    List<SafetyCheckItem> items = safetyCheckItemRepository.findBySafetyCheckId(safetyCheckId);

    boolean hasHigh =
        items.stream().anyMatch(item -> item.getSeverity() == SafetySeverity.HIGH);

    long issues =
        items.stream()
            .filter(
                item ->
                    item.getResult() != null
                        && item.getResult() != SafetyItemResult.OK)
            .count();

    if (hasHigh) {
      return SafetyRiskLevel.HIGH;
    }
    if (issues >= 3) {
      return SafetyRiskLevel.MEDIUM;
    }
    return SafetyRiskLevel.LOW;
  }

  private void saveAudit(
      SafetyCheck safetyCheck,
      String action,
      Long actorId,
      String actorRole,
      String message) {
    SafetyCheckAudit audit =
        SafetyCheckAudit.builder()
            .safetyCheck(safetyCheck)
            .action(action)
            .actorId(actorId)
            .actorRole(actorRole)
            .message(message)
            .build();
    safetyCheckAuditRepository.save(audit);
  }

  private SafetyCheckDto toDto(SafetyCheck safetyCheck, boolean includeItems, boolean includeAudit) {
    SafetyCheckDto dto = SafetyCheckDto.builder()
        .id(safetyCheck.getId())
        .checkDate(safetyCheck.getCheckDate())
        .shift(safetyCheck.getShift())
        .driverId(safetyCheck.getDriver() != null ? safetyCheck.getDriver().getId() : null)
        .driverName(resolveDriverName(safetyCheck.getDriver()))
        .vehicleId(safetyCheck.getVehicle() != null ? safetyCheck.getVehicle().getId() : null)
        .vehiclePlate(safetyCheck.getVehicle() != null ? safetyCheck.getVehicle().getLicensePlate() : null)
        .status(safetyCheck.getStatus())
        .riskLevel(safetyCheck.getRiskLevel())
        .riskOverride(safetyCheck.getRiskOverride())
        .submittedAt(safetyCheck.getSubmittedAt())
        .approvedAt(safetyCheck.getApprovedAt())
        .approvedBy(safetyCheck.getApprovedBy() != null ? safetyCheck.getApprovedBy().getId() : null)
        .approvedByName(safetyCheck.getApprovedBy() != null ? safetyCheck.getApprovedBy().getUsername() : null)
        .rejectReason(safetyCheck.getRejectReason())
        .notes(safetyCheck.getNotes())
        .gpsLat(safetyCheck.getGpsLat())
        .gpsLng(safetyCheck.getGpsLng())
        .createdAt(safetyCheck.getCreatedAt())
        .updatedAt(safetyCheck.getUpdatedAt())
        .build();

    if (includeItems) {
      List<SafetyCheckItem> items =
          safetyCheckItemRepository.findBySafetyCheckId(safetyCheck.getId());

      Map<String, String> categoryLabelMap = loadCategoryLabelMap();
      Map<String, Integer> orderMap = loadItemOrderMap();
      items.sort(
          Comparator.comparingInt(
              item ->
                  orderMap.getOrDefault(
                      item.getCategory() + "::" + item.getItemKey(), Integer.MAX_VALUE)));
      dto.setItems(
          items.stream().map(item -> toDto(item, categoryLabelMap)).collect(Collectors.toList()));

      List<SafetyCheckAttachment> attachments =
          safetyCheckAttachmentRepository.findBySafetyCheckId(safetyCheck.getId());
      dto.setAttachments(attachments.stream().map(this::toDto).collect(Collectors.toList()));
    }

    if (includeAudit) {
      List<SafetyCheckAudit> audits =
          safetyCheckAuditRepository.findBySafetyCheckIdOrderByCreatedAtDesc(safetyCheck.getId());
      dto.setAudits(audits.stream().map(this::toDto).collect(Collectors.toList()));
    }

    return dto;
  }

  private SafetyCheckItemDto toDto(SafetyCheckItem item, Map<String, String> categoryLabelMap) {
    return SafetyCheckItemDto.builder()
        .id(item.getId())
        .category(item.getCategory())
        .categoryLabelKm(categoryLabelMap.get(item.getCategory()))
        .itemKey(item.getItemKey())
        .itemLabelKm(item.getItemLabelKm())
        .result(item.getResult())
        .severity(item.getSeverity())
        .remark(item.getRemark())
        .createdAt(item.getCreatedAt())
        .build();
  }

  private SafetyCheckAttachmentDto toDto(SafetyCheckAttachment attachment) {
    return SafetyCheckAttachmentDto.builder()
        .id(attachment.getId())
        .itemId(attachment.getItem() != null ? attachment.getItem().getId() : null)
        .fileUrl(attachment.getFileUrl())
        .fileName(attachment.getFileName())
        .mimeType(attachment.getMimeType())
        .uploadedById(attachment.getUploadedBy() != null ? attachment.getUploadedBy().getId() : null)
        .uploadedByName(attachment.getUploadedBy() != null ? attachment.getUploadedBy().getUsername() : null)
        .createdAt(attachment.getCreatedAt())
        .build();
  }

  private SafetyCheckAuditDto toDto(SafetyCheckAudit audit) {
    return SafetyCheckAuditDto.builder()
        .id(audit.getId())
        .action(audit.getAction())
        .actorId(audit.getActorId())
        .actorRole(audit.getActorRole())
        .message(audit.getMessage())
        .createdAt(audit.getCreatedAt())
        .build();
  }

  private String resolveDriverName(Driver driver) {
    if (driver == null) return null;
    if (driver.getName() != null && !driver.getName().isBlank()) {
      return driver.getName();
    }
    String first = driver.getFirstName() != null ? driver.getFirstName().trim() : "";
    String last = driver.getLastName() != null ? driver.getLastName().trim() : "";
    String name = (first + " " + last).trim();
    return name.isBlank() ? null : name;
  }

  private String itemMapKey(SafetyCheckItem item) {
    return itemMapKey(item.getCategory(), item.getItemKey());
  }

  private String itemMapKey(String category, String itemKey) {
    return category + "::" + itemKey;
  }

  private List<SafetyCheckItemDto> defaultItems() {
    List<SafetyCheckMasterItem> masters =
        safetyCheckMasterItemRepository.findByIsActiveTrueOrderBySortOrderAsc();
    if (masters.isEmpty()) {
      return fallbackItems();
    }

    return masters.stream()
        .map(
            item ->
                SafetyCheckItemDto.builder()
                    .category(item.getCategory().getCode())
                    .categoryLabelKm(item.getCategory().getNameKm())
                    .itemKey(item.getItemKey())
                    .itemLabelKm(item.getItemLabelKm())
                    .build())
        .collect(Collectors.toList());
  }

  private List<SafetyCheckItemDto> fallbackItems() {
    List<SafetyCheckItemDto> items = new ArrayList<>();
    items.add(template("ENGINE", "engine_oil", "ប្រេងម៉ាស៊ីន", "ផ្នែកម៉ាស៊ីន"));
    items.add(template("ENGINE", "coolant", "ទឹកស្អំម៉ាស៊ីន", "ផ្នែកម៉ាស៊ីន"));
    items.add(template("DRIVER_HEALTH", "slept_enough", "គេងគ្រប់គ្រាន់", "សុខភាពអ្នកបើកបរ"));
    items.add(template("DRIVER_HEALTH", "sick", "មានជំងឺ", "សុខភាពអ្នកបើកបរ"));
    items.add(template("SAFETY_EQUIPMENT", "fire_extinguisher", "ឧបករណ៍ពន្លត់អគ្គីភ័យ", "ឧបករណ៍សុវត្ថិភាព"));
    items.add(template("LOAD", "secured", "ទំនិញបានចាក់សោរល្អ", "ទំនិញ"));
    items.add(template("ENVIRONMENT", "weather", "អាកាសធាតុ", "បរិស្ថាន"));
    return items;
  }

  private SafetyCheckItemDto template(
      String category, String key, String labelKm, String categoryLabelKm) {
    return SafetyCheckItemDto.builder()
        .category(category)
        .categoryLabelKm(categoryLabelKm)
        .itemKey(key)
        .itemLabelKm(labelKm)
        .build();
  }

  private Map<String, String> loadCategoryLabelMap() {
    List<SafetyCheckCategory> categories =
        safetyCheckCategoryRepository.findByIsActiveTrueOrderBySortOrderAsc();
    Map<String, String> map = new HashMap<>();
    for (SafetyCheckCategory cat : categories) {
      map.put(cat.getCode(), cat.getNameKm());
    }
    return map;
  }

  private Map<String, Integer> loadItemOrderMap() {
    List<SafetyCheckMasterItem> masters =
        safetyCheckMasterItemRepository.findByIsActiveTrueOrderBySortOrderAsc();
    Map<String, Integer> map = new HashMap<>();
    for (SafetyCheckMasterItem item : masters) {
      String key = item.getCategory().getCode() + "::" + item.getItemKey();
      map.put(key, item.getSortOrder() != null ? item.getSortOrder() : Integer.MAX_VALUE);
    }
    return map;
  }
}
