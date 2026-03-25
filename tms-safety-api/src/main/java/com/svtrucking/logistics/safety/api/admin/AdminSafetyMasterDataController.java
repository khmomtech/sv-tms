package com.svtrucking.logistics.safety.api.admin;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.dto.SafetyCheckCategoryDto;
import com.svtrucking.logistics.dto.SafetyCheckMasterItemDto;
import com.svtrucking.logistics.dto.SafetyMasterImportResultDto;
import com.svtrucking.logistics.safety.domain.SafetyCheckCategory;
import com.svtrucking.logistics.safety.domain.SafetyCheckMasterItem;
import com.svtrucking.logistics.safety.repository.SafetyCheckCategoryRepository;
import com.svtrucking.logistics.safety.repository.SafetyCheckMasterItemRepository;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.Map;
import java.util.Locale;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.poi.ss.usermodel.*;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.http.HttpHeaders;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.http.MediaType;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.transaction.annotation.Transactional;

@RestController
@RequestMapping("/api/admin/safety-master")
@RequiredArgsConstructor
@Slf4j
public class AdminSafetyMasterDataController {

  private static final Pattern SECTION_HEADER_PATTERN =
      Pattern.compile("^\\s*(\\d+)\\s*\\.\\s*(.+)\\s*$");
  private static final String FORMAT_NEW_ONE_SHEET = "NEW_ONE_SHEET";
  private static final String FORMAT_LEGACY_TWO_SHEET = "LEGACY_TWO_SHEET";

  private final SafetyCheckCategoryRepository categoryRepository;
  private final SafetyCheckMasterItemRepository itemRepository;

  @GetMapping("/categories")
  @PreAuthorize("hasAnyAuthority('ROLE_ADMIN','ROLE_SUPERADMIN','ROLE_SAFETY','all_functions')")
  public ResponseEntity<ApiResponse<List<SafetyCheckCategoryDto>>> getCategories(
      @RequestParam(name = "activeOnly", defaultValue = "false") boolean activeOnly) {
    List<SafetyCheckCategory> categories =
        activeOnly
            ? categoryRepository.findByIsActiveTrueOrderBySortOrderAsc()
            : categoryRepository.findAllByOrderBySortOrderAsc();

    List<SafetyCheckCategoryDto> data =
        categories.stream().map(this::toDto).collect(Collectors.toList());

    return ResponseEntity.ok(new ApiResponse<>(true, "Safety categories", data));
  }

  @PostMapping("/categories")
  @PreAuthorize("hasAnyAuthority('ROLE_ADMIN','ROLE_SUPERADMIN','ROLE_SAFETY','all_functions')")
  public ResponseEntity<ApiResponse<SafetyCheckCategoryDto>> createCategory(
      @RequestBody SafetyCheckCategoryDto payload) {
    String code = normalizeCategoryCode(payload.getCode());
    String nameKm = payload.getNameKm() != null ? payload.getNameKm().trim() : "";
    if (code.isBlank()) {
      throw new IllegalArgumentException("Category code is required");
    }
    if (nameKm.isBlank()) {
      throw new IllegalArgumentException("Category Khmer name is required");
    }
    if (categoryRepository.findByCodeIgnoreCase(code).isPresent()) {
      throw new IllegalArgumentException("Category code already exists");
    }

    Integer sortOrder = payload.getSortOrder();
    if (sortOrder == null) {
      sortOrder = categoryRepository.findMaxSortOrder() + 1;
    } else if (sortOrder < 0) {
      throw new IllegalArgumentException("sortOrder must be >= 0");
    }

    SafetyCheckCategory category =
        SafetyCheckCategory.builder()
            .code(code)
            .nameKm(nameKm)
            .sortOrder(sortOrder)
            .isActive(payload.getIsActive() != null ? payload.getIsActive() : Boolean.TRUE)
            .build();

    SafetyCheckCategory saved = categoryRepository.save(category);
    return ResponseEntity.ok(new ApiResponse<>(true, "Category created", toDto(saved)));
  }

  @PutMapping("/categories/{id}")
  @PreAuthorize("hasAnyAuthority('ROLE_ADMIN','ROLE_SUPERADMIN','ROLE_SAFETY','all_functions')")
  public ResponseEntity<ApiResponse<SafetyCheckCategoryDto>> updateCategory(
      @PathVariable Long id, @RequestBody SafetyCheckCategoryDto payload) {
    SafetyCheckCategory category =
        categoryRepository
            .findById(id)
            .orElseThrow(() -> new IllegalArgumentException("Category not found"));

    if (payload.getCode() != null && !payload.getCode().trim().isBlank()) {
      String newCode = normalizeCategoryCode(payload.getCode());
      Optional<SafetyCheckCategory> existing = categoryRepository.findByCodeIgnoreCase(newCode);
      if (existing.isPresent() && !existing.get().getId().equals(id)) {
        throw new IllegalArgumentException("Category code already exists");
      }
      category.setCode(newCode);
    }
    if (payload.getNameKm() != null && !payload.getNameKm().trim().isBlank()) {
      category.setNameKm(payload.getNameKm().trim());
    }
    if (payload.getSortOrder() != null) {
      if (payload.getSortOrder() < 0) {
        throw new IllegalArgumentException("sortOrder must be >= 0");
      }
      category.setSortOrder(payload.getSortOrder());
    }
    if (payload.getIsActive() != null) {
      category.setIsActive(payload.getIsActive());
    }

    SafetyCheckCategory saved = categoryRepository.save(category);
    return ResponseEntity.ok(new ApiResponse<>(true, "Category updated", toDto(saved)));
  }

  @DeleteMapping("/categories/{id}")
  @PreAuthorize("hasAnyAuthority('ROLE_ADMIN','ROLE_SUPERADMIN','ROLE_SAFETY','all_functions')")
  public ResponseEntity<ApiResponse<SafetyCheckCategoryDto>> deactivateCategory(@PathVariable Long id) {
    SafetyCheckCategory category =
        categoryRepository
            .findById(id)
            .orElseThrow(() -> new IllegalArgumentException("Category not found"));
    long activeItems = itemRepository.countByCategoryIdAndIsActiveTrue(id);
    if (activeItems > 0) {
      throw new IllegalArgumentException(
          "Cannot deactivate category while active items still exist. Please deactivate items first.");
    }
    category.setIsActive(false);
    SafetyCheckCategory saved = categoryRepository.save(category);
    return ResponseEntity.ok(new ApiResponse<>(true, "Category deactivated", toDto(saved)));
  }

  @GetMapping("/items")
  @PreAuthorize("hasAnyAuthority('ROLE_ADMIN','ROLE_SUPERADMIN','ROLE_SAFETY','all_functions')")
  public ResponseEntity<ApiResponse<List<SafetyCheckMasterItemDto>>> getItems(
      @RequestParam(name = "categoryId", required = false) Long categoryId,
      @RequestParam(name = "activeOnly", defaultValue = "false") boolean activeOnly,
      @RequestParam(name = "q", required = false) String keyword) {
    String safeKeyword = keyword != null ? keyword.trim() : null;
    if (safeKeyword != null && safeKeyword.isBlank()) {
      safeKeyword = null;
    }
    List<SafetyCheckMasterItem> items =
        itemRepository.searchItems(categoryId, activeOnly, safeKeyword);

    List<SafetyCheckMasterItemDto> data =
        items.stream().map(this::toDto).collect(Collectors.toList());
    return ResponseEntity.ok(new ApiResponse<>(true, "Safety master items", data));
  }

  @PostMapping(value = "/import", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
  @PreAuthorize("hasAnyAuthority('ROLE_ADMIN','ROLE_SUPERADMIN','ROLE_SAFETY','all_functions')")
  @Transactional(rollbackFor = Exception.class)
  public ResponseEntity<ApiResponse<SafetyMasterImportResultDto>> importFromExcel(
      @RequestParam("file") MultipartFile file) {
    if (file == null || file.isEmpty()) {
      throw new IllegalArgumentException("Excel file is required");
    }

    SafetyMasterImportResultDto result = doImport(file);
    return ResponseEntity.ok(new ApiResponse<>(true, "Imported safety master data", result));
  }

  @GetMapping("/template")
  @PreAuthorize("hasAnyAuthority('ROLE_ADMIN','ROLE_SUPERADMIN','ROLE_SAFETY','all_functions')")
  public ResponseEntity<byte[]> downloadTemplate() {
    try (Workbook workbook = new XSSFWorkbook();
         java.io.ByteArrayOutputStream out = new java.io.ByteArrayOutputStream()) {
      Sheet sheet = workbook.createSheet("Sheet1");
      int rowIdx = 0;
      Row title = sheet.createRow(rowIdx++);
      title.createCell(0).setCellValue("Driver safety Check-list Master Data");

      Row h1 = sheet.createRow(rowIdx++);
      h1.createCell(0).setCellValue("1.ផ្នែកម៉ាស៊ីន");
      Row i1 = sheet.createRow(rowIdx++);
      i1.createCell(0).setCellValue(1);
      i1.createCell(1).setCellValue("ប្រេងម៉ាស៊ីន");

      Row h2 = sheet.createRow(rowIdx++);
      h2.createCell(0).setCellValue("2.ផ្នែកគ្រឿងក្រោម");
      Row i2 = sheet.createRow(rowIdx++);
      i2.createCell(0).setCellValue(1);
      i2.createCell(1).setCellValue("ប្រព័ន្ធប្រេងអ៊ំព្រីយ៉ា");

      Row h3 = sheet.createRow(rowIdx++);
      h3.createCell(0).setCellValue("3.ផ្នែកភ្លើង");
      Row i3 = sheet.createRow(rowIdx++);
      i3.createCell(0).setCellValue(1);
      i3.createCell(1).setCellValue("ភ្លើងហ្វាកូដ /ភ្លើងដឺមី /ភ្លើងស៊ីញ៉ូ /ភ្លើងសុំផ្លូវ");

      Row h4 = sheet.createRow(rowIdx++);
      h4.createCell(0).setCellValue("4.សម្ភារះបំពាក់លើរថយន្ត");
      Row i4 = sheet.createRow(rowIdx++);
      i4.createCell(0).setCellValue(1);
      i4.createCell(1).setCellValue("តង់គ្រប់ធំ");

      Row h5 = sheet.createRow(rowIdx++);
      h5.createCell(0).setCellValue("5.សោភ័ណ្ឌភាពរថយន្ត");
      Row i5 = sheet.createRow(rowIdx++);
      i5.createCell(0).setCellValue(1);
      i5.createCell(1).setCellValue("កាងក្បាលឡាន /កាងរឺម៉ក");

      sheet.autoSizeColumn(0);
      sheet.autoSizeColumn(1);
      workbook.write(out);

      return ResponseEntity.ok()
          .header(
              HttpHeaders.CONTENT_DISPOSITION,
              "attachment; filename=\"driver-safety-master-template.xlsx\"")
          .contentType(
              MediaType.parseMediaType(
                  "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"))
          .body(out.toByteArray());
    } catch (Exception e) {
      throw new IllegalStateException("Failed to generate template: " + e.getMessage(), e);
    }
  }

  @PostMapping("/items")
  @PreAuthorize("hasAnyAuthority('ROLE_ADMIN','ROLE_SUPERADMIN','ROLE_SAFETY','all_functions')")
  public ResponseEntity<ApiResponse<SafetyCheckMasterItemDto>> createItem(
      @RequestBody SafetyCheckMasterItemDto payload) {
    if (payload.getCategoryId() == null) {
      throw new IllegalArgumentException("categoryId is required");
    }
    String itemLabelKm =
        payload.getItemLabelKm() != null ? payload.getItemLabelKm().trim() : "";
    if (itemLabelKm.isBlank()) {
      throw new IllegalArgumentException("Item Khmer label is required");
    }

    SafetyCheckCategory category =
        categoryRepository
            .findById(payload.getCategoryId())
            .orElseThrow(() -> new IllegalArgumentException("Category not found"));

    String itemKey = payload.getItemKey() != null ? payload.getItemKey().trim() : "";
    if (!itemKey.isBlank()) {
      itemKey = normalizeItemKey(itemKey);
      if (itemRepository.findByItemKeyIgnoreCase(itemKey).isPresent()) {
        throw new IllegalArgumentException("Item key already exists");
      }
    }

    Integer sortOrder = payload.getSortOrder();
    if (sortOrder == null) {
      sortOrder = itemRepository.findMaxSortOrderByCategoryId(category.getId()) + 1;
    } else if (sortOrder < 0) {
      throw new IllegalArgumentException("sortOrder must be >= 0");
    }

    String initialKey = itemKey.isBlank() ? "tmp_" + UUID.randomUUID() : itemKey;

    SafetyCheckMasterItem item =
        SafetyCheckMasterItem.builder()
            .category(category)
            .itemKey(initialKey)
            .itemLabelKm(itemLabelKm)
            .checkTime(payload.getCheckTime() != null && !payload.getCheckTime().trim().isBlank()
                ? payload.getCheckTime().trim()
                : null)
            .sortOrder(sortOrder)
            .isActive(payload.getIsActive() != null ? payload.getIsActive() : Boolean.TRUE)
            .build();

    SafetyCheckMasterItem saved = itemRepository.save(item);
    if (itemKey.isBlank()) {
      saved.setItemKey("item_" + saved.getId());
      saved = itemRepository.save(saved);
    }

    return ResponseEntity.ok(new ApiResponse<>(true, "Item created", toDto(saved)));
  }

  @PutMapping("/items/{id}")
  @PreAuthorize("hasAnyAuthority('ROLE_ADMIN','ROLE_SUPERADMIN','ROLE_SAFETY','all_functions')")
  public ResponseEntity<ApiResponse<SafetyCheckMasterItemDto>> updateItem(
      @PathVariable Long id, @RequestBody SafetyCheckMasterItemDto payload) {
    SafetyCheckMasterItem item =
        itemRepository.findById(id).orElseThrow(() -> new IllegalArgumentException("Item not found"));

    if (payload.getCategoryId() != null) {
      SafetyCheckCategory category =
          categoryRepository
              .findById(payload.getCategoryId())
              .orElseThrow(() -> new IllegalArgumentException("Category not found"));
      item.setCategory(category);
    }

    if (payload.getItemKey() != null && !payload.getItemKey().trim().isBlank()) {
      String newKey = normalizeItemKey(payload.getItemKey());
      Optional<SafetyCheckMasterItem> existing = itemRepository.findByItemKeyIgnoreCase(newKey);
      if (existing.isPresent() && !existing.get().getId().equals(id)) {
        throw new IllegalArgumentException("Item key already exists");
      }
      item.setItemKey(newKey);
    }

    if (payload.getItemLabelKm() != null && !payload.getItemLabelKm().trim().isBlank()) {
      item.setItemLabelKm(payload.getItemLabelKm().trim());
    }

    if (payload.getCheckTime() != null) {
      String checkTime = payload.getCheckTime().trim();
      item.setCheckTime(checkTime.isEmpty() ? null : checkTime);
    }

    if (payload.getSortOrder() != null) {
      if (payload.getSortOrder() < 0) {
        throw new IllegalArgumentException("sortOrder must be >= 0");
      }
      item.setSortOrder(payload.getSortOrder());
    }

    if (payload.getIsActive() != null) {
      item.setIsActive(payload.getIsActive());
    }

    SafetyCheckMasterItem saved = itemRepository.save(item);
    return ResponseEntity.ok(new ApiResponse<>(true, "Item updated", toDto(saved)));
  }

  @DeleteMapping("/items/{id}")
  @PreAuthorize("hasAnyAuthority('ROLE_ADMIN','ROLE_SUPERADMIN','ROLE_SAFETY','all_functions')")
  public ResponseEntity<ApiResponse<SafetyCheckMasterItemDto>> deactivateItem(@PathVariable Long id) {
    SafetyCheckMasterItem item =
        itemRepository.findById(id).orElseThrow(() -> new IllegalArgumentException("Item not found"));
    item.setIsActive(false);
    SafetyCheckMasterItem saved = itemRepository.save(item);
    return ResponseEntity.ok(new ApiResponse<>(true, "Item deactivated", toDto(saved)));
  }

  private SafetyCheckCategoryDto toDto(SafetyCheckCategory category) {
    return SafetyCheckCategoryDto.builder()
        .id(category.getId())
        .code(category.getCode())
        .nameKm(category.getNameKm())
        .sortOrder(category.getSortOrder())
        .isActive(category.getIsActive())
        .createdAt(category.getCreatedAt())
        .updatedAt(category.getUpdatedAt())
        .build();
  }

  private SafetyCheckMasterItemDto toDto(SafetyCheckMasterItem item) {
    SafetyCheckCategory category = item.getCategory();
    return SafetyCheckMasterItemDto.builder()
        .id(item.getId())
        .categoryId(category != null ? category.getId() : null)
        .categoryCode(category != null ? category.getCode() : null)
        .categoryNameKm(category != null ? category.getNameKm() : null)
        .itemKey(item.getItemKey())
        .itemLabelKm(item.getItemLabelKm())
        .checkTime(item.getCheckTime())
        .sortOrder(item.getSortOrder())
        .isActive(item.getIsActive())
        .createdAt(item.getCreatedAt())
        .updatedAt(item.getUpdatedAt())
        .build();
  }

  private SafetyMasterImportResultDto doImport(MultipartFile file) {
    try (InputStream input = file.getInputStream(); Workbook workbook = WorkbookFactory.create(input)) {
      String detectedFormat = detectFormat(workbook);
      ParsedWorkbook parsed =
          FORMAT_NEW_ONE_SHEET.equals(detectedFormat)
              ? parseNewOneSheet(workbook)
              : parseLegacyTwoSheet(workbook);

      validateParsedData(parsed);

      // Clear all old data then insert all fresh rows from authoritative Excel.
      itemRepository.deleteAllInBatch();
      categoryRepository.deleteAllInBatch();

      Map<String, SafetyCheckCategory> savedCategoriesByCode = new LinkedHashMap<>();
      for (ParsedCategory category : parsed.categories) {
        SafetyCheckCategory saved =
            categoryRepository.save(
                SafetyCheckCategory.builder()
                    .code(category.code)
                    .nameKm(category.nameKm)
                    .sortOrder(category.sortOrder)
                    .isActive(Boolean.TRUE)
                    .build());
        savedCategoriesByCode.put(category.code, saved);
      }

      int insertedItems = 0;
      for (ParsedItem item : parsed.items) {
        SafetyCheckCategory category = savedCategoriesByCode.get(item.categoryCode);
        if (category == null) {
          throw new IllegalArgumentException(
              "Missing category reference for item: " + item.itemLabelKm + " (" + item.categoryCode + ")");
        }
        itemRepository.save(
            SafetyCheckMasterItem.builder()
                .category(category)
                .itemKey(item.itemKey)
                .itemLabelKm(item.itemLabelKm)
                .checkTime(item.checkTime)
                .sortOrder(item.sortOrder)
                .isActive(Boolean.TRUE)
                .build());
        insertedItems++;
      }

      String message =
          "Imported "
              + parsed.categories.size()
              + " categories and "
              + insertedItems
              + " items (format: "
              + detectedFormat
              + ")";

      return SafetyMasterImportResultDto.builder()
          .detectedFormat(detectedFormat)
          .categoriesInserted(parsed.categories.size())
          .itemsInserted(insertedItems)
          .categoriesCreated(parsed.categories.size())
          .categoriesUpdated(0)
          .itemsCreated(insertedItems)
          .itemsUpdated(0)
          .itemsSkipped(0)
          .warnings(parsed.warnings)
          .message(message)
          .build();
    } catch (Exception e) {
      log.error("Failed to import safety master data: {}", e.getMessage(), e);
      throw new IllegalStateException("Failed to import safety master data: " + e.getMessage(), e);
    }
  }

  private String normalizeCategoryCode(String raw) {
    if (raw == null) return "";
    return raw.trim().toUpperCase(Locale.ROOT);
  }

  private String normalizeItemKey(String raw) {
    if (raw == null) return "";
    return raw.trim().toLowerCase(Locale.ROOT).replaceAll("[^a-z0-9_]+", "_");
  }

  private String detectFormat(Workbook workbook) {
    Sheet categorySheet = findSheet(workbook, "Category", "Category");
    Sheet legacyItemSheet = findSheet(workbook, "របាយការណ៍ប្រចាំថ្ងៃ", "ប្រចាំថ្ងៃ");
    if (categorySheet != null && legacyItemSheet != null) {
      return FORMAT_LEGACY_TWO_SHEET;
    }

    for (int i = 0; i < workbook.getNumberOfSheets(); i++) {
      Sheet sheet = workbook.getSheetAt(i);
      DataFormatter formatter = new DataFormatter();
      for (Row row : sheet) {
        String col0 = cellString(formatter, row, 0);
        Matcher m = SECTION_HEADER_PATTERN.matcher(col0);
        if (m.matches()) {
          return FORMAT_NEW_ONE_SHEET;
        }
      }
    }
    throw new IllegalArgumentException(
        "Unsupported Excel format. Expected one-sheet checklist format or legacy Category/ប្រចាំថ្ងៃ sheets.");
  }

  private ParsedWorkbook parseNewOneSheet(Workbook workbook) {
    Sheet sheet = findNewOneSheet(workbook);
    if (sheet == null) {
      throw new IllegalArgumentException("Sheet is missing in the uploaded Excel file");
    }

    DataFormatter formatter = new DataFormatter();
    LinkedHashMap<String, ParsedCategory> categoriesByCode = new LinkedHashMap<>();
    List<ParsedItem> items = new ArrayList<>();
    Set<String> itemKeys = new LinkedHashSet<>();
    List<String> warnings = new ArrayList<>();

    String currentCategoryCode = null;
    int categoryOrder = 1;
    int itemOrder = 1;

    for (Row row : sheet) {
      String col0 = cellString(formatter, row, 0);
      String col1 = cellString(formatter, row, 1);
      if (col0.isBlank() && col1.isBlank()) {
        continue;
      }

      if (col0.toLowerCase(Locale.ROOT).contains("driver safety check-list master data")) {
        continue;
      }

      Matcher sectionMatcher = SECTION_HEADER_PATTERN.matcher(col0);
      if (sectionMatcher.matches()) {
        String categoryName = sectionMatcher.group(2).trim();
        String categoryCode = requireSupportedCategoryCode(categoryName);
        currentCategoryCode = categoryCode;
        categoriesByCode.putIfAbsent(
            categoryCode, new ParsedCategory(categoryCode, categoryName, categoryOrder++));
        continue;
      }

      Integer no = tryParseInt(col0);
      if (no == null) {
        continue;
      }
      if (currentCategoryCode == null) {
        throw new IllegalArgumentException(
            "Invalid sheet structure: item row found before category header at row " + (row.getRowNum() + 1));
      }
      if (col1.isBlank()) {
        throw new IllegalArgumentException(
            "Item label is required at row " + (row.getRowNum() + 1));
      }

      String normalizedLabel = normalizeKhmerLabel(col1);
      String key = buildDeterministicItemKey(currentCategoryCode, normalizedLabel);
      if (!itemKeys.add(key)) {
        throw new IllegalArgumentException(
            "Duplicate item key detected after normalization: " + key + " (row " + (row.getRowNum() + 1) + ")");
      }

      if (!normalizedLabel.equals(col1.trim())) {
        warnings.add("Normalized spacing for item: " + col1.trim());
      }

      items.add(new ParsedItem(currentCategoryCode, key, normalizedLabel, null, itemOrder++));
    }

    return new ParsedWorkbook(new ArrayList<>(categoriesByCode.values()), items, warnings);
  }

  private ParsedWorkbook parseLegacyTwoSheet(Workbook workbook) {
    Sheet categorySheet = findSheet(workbook, "Category", "Category");
    Sheet itemSheet = findSheet(workbook, "របាយការណ៍ប្រចាំថ្ងៃ", "ប្រចាំថ្ងៃ");
    if (categorySheet == null || itemSheet == null) {
      throw new IllegalArgumentException("Legacy template must contain Category and របាយការណ៍ប្រចាំថ្ងៃ sheets");
    }

    List<ExcelCategory> excelCategories = parseCategories(categorySheet);
    LinkedHashMap<String, ParsedCategory> categoriesByCode = new LinkedHashMap<>();
    int categoryOrder = 1;
    for (ExcelCategory c : excelCategories) {
      String categoryCode = requireSupportedCategoryCode(c.nameKm);
      categoriesByCode.putIfAbsent(
          categoryCode,
          new ParsedCategory(categoryCode, c.nameKm.trim(), c.id != null ? c.id : categoryOrder));
      categoryOrder++;
    }

    List<ExcelItem> excelItems = parseItems(itemSheet);
    List<ParsedItem> items = new ArrayList<>();
    Set<String> itemKeys = new LinkedHashSet<>();
    List<String> warnings = new ArrayList<>();
    int itemOrder = 1;
    for (ExcelItem item : excelItems) {
      if (item.categoryName == null || item.categoryName.isBlank()) {
        throw new IllegalArgumentException("Legacy item row missing category");
      }
      if (item.itemLabelKm == null || item.itemLabelKm.isBlank()) {
        continue;
      }
      String categoryCode = requireSupportedCategoryCode(item.categoryName);
      String normalizedLabel = normalizeKhmerLabel(item.itemLabelKm);
      String key = buildDeterministicItemKey(categoryCode, normalizedLabel);
      if (!itemKeys.add(key)) {
        throw new IllegalArgumentException("Duplicate item key in legacy import: " + key);
      }
      if (!normalizedLabel.equals(item.itemLabelKm.trim())) {
        warnings.add("Normalized spacing for item: " + item.itemLabelKm.trim());
      }

      categoriesByCode.putIfAbsent(
          categoryCode,
          new ParsedCategory(categoryCode, normalizeKhmerLabel(item.categoryName), categoryOrder++));
      items.add(
          new ParsedItem(
              categoryCode,
              key,
              normalizedLabel,
              normalizeOptional(item.checkTime),
              item.id != null ? item.id : itemOrder));
      itemOrder++;
    }
    return new ParsedWorkbook(new ArrayList<>(categoriesByCode.values()), items, warnings);
  }

  private void validateParsedData(ParsedWorkbook parsed) {
    if (parsed.categories.isEmpty()) {
      throw new IllegalArgumentException("No categories found in the Excel file");
    }
    if (parsed.items.isEmpty()) {
      throw new IllegalArgumentException("No checklist items found in the Excel file");
    }
    if (parsed.categories.size() != 5) {
      throw new IllegalArgumentException(
          "Expected exactly 5 categories from the approved checklist template, found " + parsed.categories.size());
    }
  }

  private Sheet findSheet(Workbook workbook, String exactName, String contains) {
    Sheet exact = workbook.getSheet(exactName);
    if (exact != null) return exact;
    for (int i = 0; i < workbook.getNumberOfSheets(); i++) {
      Sheet sheet = workbook.getSheetAt(i);
      if (sheet.getSheetName().contains(contains)) {
        return sheet;
      }
    }
    return null;
  }

  private Sheet findNewOneSheet(Workbook workbook) {
    DataFormatter formatter = new DataFormatter();
    for (int i = 0; i < workbook.getNumberOfSheets(); i++) {
      Sheet sheet = workbook.getSheetAt(i);
      for (Row row : sheet) {
        String col0 = cellString(formatter, row, 0);
        if (SECTION_HEADER_PATTERN.matcher(col0).matches()) {
          return sheet;
        }
      }
    }
    return workbook.getNumberOfSheets() > 0 ? workbook.getSheetAt(0) : null;
  }

  private List<ExcelCategory> parseCategories(Sheet sheet) {
    List<ExcelCategory> categories = new ArrayList<>();
    DataFormatter formatter = new DataFormatter();
    for (Row row : sheet) {
      String idText = cellString(formatter, row, 0);
      String name = cellString(formatter, row, 1);
      if (idText.isEmpty() || name.isEmpty()) continue;
      Integer id = tryParseInt(idText);
      if (id == null) continue;
      categories.add(new ExcelCategory(id, name));
    }
    return categories;
  }

  private List<ExcelItem> parseItems(Sheet sheet) {
    List<ExcelItem> items = new ArrayList<>();
    DataFormatter formatter = new DataFormatter();
    String currentCategory = null;

    for (Row row : sheet) {
      String col0 = cellString(formatter, row, 0);
      String col1 = cellString(formatter, row, 1);
      String col4 = cellString(formatter, row, 4);

      if (col0.isEmpty()) continue;

      // Category header (non-numeric)
      if (!isNumeric(col0)) {
        if (col0.contains("របាយការណ") || col0.equalsIgnoreCase("No")) {
          continue;
        }
        currentCategory = col0;
        continue;
      }

      Integer id = tryParseInt(col0);
      if (id == null) continue;
      String label = col1.isEmpty() ? null : col1;
      String checkTime = col4.isEmpty() ? null : col4;
      items.add(new ExcelItem(id, currentCategory, label, checkTime));
    }
    return items;
  }

  private String cellString(DataFormatter formatter, Row row, int idx) {
    if (row == null) return "";
    Cell cell = row.getCell(idx, Row.MissingCellPolicy.RETURN_BLANK_AS_NULL);
    return cell == null ? "" : formatter.formatCellValue(cell).trim();
  }

  private boolean isNumeric(String value) {
    return value != null && value.matches("\\d+");
  }

  private Integer tryParseInt(String value) {
    try {
      return Integer.parseInt(value);
    } catch (Exception e) {
      return null;
    }
  }

  private String mapCategoryCode(String nameKm) {
    if (nameKm == null) return null;
    String trimmed = normalizeKhmerLabel(nameKm);
    Matcher sectionMatcher = SECTION_HEADER_PATTERN.matcher(trimmed);
    if (sectionMatcher.matches()) {
      trimmed = normalizeKhmerLabel(sectionMatcher.group(2));
    }
    return switch (trimmed) {
      case "ផ្នែកម៉ាស៊ីន" -> "ENGINE";
      case "ផ្នែកគ្រឿងក្រោម" -> "UNDERBODY";
      case "ផ្នែកភ្លើង" -> "LIGHTS";
      case "សម្ភារះបំពាក់លើរថយន្ត" -> "VEHICLE_EQUIPMENT";
      case "សោភ័ណ្ឌភាពរថយន្ត" -> "APPEARANCE";
      default -> null;
    };
  }

  private String requireSupportedCategoryCode(String nameKm) {
    String code = mapCategoryCode(nameKm);
    if (code == null) {
      throw new IllegalArgumentException("Unsupported category in master file: " + nameKm);
    }
    return code;
  }

  private String buildDeterministicItemKey(String categoryCode, String itemLabelKm) {
    String base = normalizeItemKeyUnicode(itemLabelKm);
    if (base.isBlank()) {
      base = "item_" + Integer.toHexString(itemLabelKm.hashCode());
    }
    String key = categoryCode + "_" + base;
    if (key.length() > 100) {
      key = key.substring(0, 100);
    }
    return key;
  }

  private String normalizeItemKeyUnicode(String raw) {
    if (raw == null) return "";
    String value =
        raw.trim()
            .toLowerCase(Locale.ROOT)
            .replace('\u200b', ' ')
            .replaceAll("[^\\p{L}\\p{M}\\p{Nd}]+", "_")
            .replaceAll("_+", "_")
            .replaceAll("^_|_$", "");
    return value;
  }

  private String normalizeKhmerLabel(String raw) {
    if (raw == null) return "";
    return raw.replace('\u200b', ' ').trim().replaceAll("\\s+", " ");
  }

  private String normalizeOptional(String raw) {
    if (raw == null) return null;
    String normalized = normalizeKhmerLabel(raw);
    return normalized.isBlank() ? null : normalized;
  }

  private static class ExcelCategory {
    final Integer id;
    final String nameKm;

    ExcelCategory(Integer id, String nameKm) {
      this.id = id;
      this.nameKm = nameKm;
    }
  }

  private static class ExcelItem {
    final Integer id;
    final String categoryName;
    final String itemLabelKm;
    final String checkTime;

    ExcelItem(Integer id, String categoryName, String itemLabelKm, String checkTime) {
      this.id = id;
      this.categoryName = categoryName;
      this.itemLabelKm = itemLabelKm;
      this.checkTime = checkTime;
    }
  }

  private static class ParsedCategory {
    final String code;
    final String nameKm;
    final Integer sortOrder;

    ParsedCategory(String code, String nameKm, Integer sortOrder) {
      this.code = code;
      this.nameKm = nameKm;
      this.sortOrder = sortOrder;
    }
  }

  private static class ParsedItem {
    final String categoryCode;
    final String itemKey;
    final String itemLabelKm;
    final String checkTime;
    final Integer sortOrder;

    ParsedItem(
        String categoryCode, String itemKey, String itemLabelKm, String checkTime, Integer sortOrder) {
      this.categoryCode = categoryCode;
      this.itemKey = itemKey;
      this.itemLabelKm = itemLabelKm;
      this.checkTime = checkTime;
      this.sortOrder = sortOrder;
    }
  }

  private static class ParsedWorkbook {
    final List<ParsedCategory> categories;
    final List<ParsedItem> items;
    final List<String> warnings;

    ParsedWorkbook(List<ParsedCategory> categories, List<ParsedItem> items, List<String> warnings) {
      this.categories = categories;
      this.items = items;
      this.warnings = warnings;
    }
  }
}
