package com.svtrucking.logistics.controller.admin;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.dto.SafetyCheckCategoryDto;
import com.svtrucking.logistics.dto.SafetyCheckMasterItemDto;
import com.svtrucking.logistics.model.PreEntryCheckCategory;
import com.svtrucking.logistics.model.PreEntryCheckMasterItem;
import com.svtrucking.logistics.repository.PreEntryCheckCategoryRepository;
import com.svtrucking.logistics.repository.PreEntryCheckMasterItemRepository;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/admin/pre-entry-master")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
public class AdminPreEntryMasterDataController {

  private final PreEntryCheckCategoryRepository categoryRepository;
  private final PreEntryCheckMasterItemRepository itemRepository;

  @GetMapping("/categories")
  @PreAuthorize("hasAnyAuthority('ROLE_ADMIN','ROLE_SUPERADMIN','ROLE_SAFETY','all_functions')")
  public ResponseEntity<ApiResponse<List<SafetyCheckCategoryDto>>> getCategories(
      @RequestParam(name = "activeOnly", defaultValue = "false") boolean activeOnly) {
    ensureDefaultDataIfEmpty();

    List<PreEntryCheckCategory> categories =
        activeOnly
            ? categoryRepository.findByIsActiveTrueOrderBySortOrderAsc()
            : categoryRepository.findAllByOrderBySortOrderAsc();

    List<SafetyCheckCategoryDto> data =
        categories.stream().map(this::toDto).collect(Collectors.toList());

    return ResponseEntity.ok(new ApiResponse<>(true, "Pre-entry categories", data));
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

    PreEntryCheckCategory category =
        PreEntryCheckCategory.builder()
            .code(code)
            .nameKm(nameKm)
            .sortOrder(sortOrder)
            .isActive(payload.getIsActive() != null ? payload.getIsActive() : Boolean.TRUE)
            .build();

    PreEntryCheckCategory saved = categoryRepository.save(category);
    return ResponseEntity.ok(new ApiResponse<>(true, "Category created", toDto(saved)));
  }

  @PutMapping("/categories/{id}")
  @PreAuthorize("hasAnyAuthority('ROLE_ADMIN','ROLE_SUPERADMIN','ROLE_SAFETY','all_functions')")
  public ResponseEntity<ApiResponse<SafetyCheckCategoryDto>> updateCategory(
      @PathVariable Long id, @RequestBody SafetyCheckCategoryDto payload) {
    PreEntryCheckCategory category =
        categoryRepository
            .findById(id)
            .orElseThrow(() -> new IllegalArgumentException("Category not found"));

    if (payload.getCode() != null && !payload.getCode().trim().isBlank()) {
      String newCode = normalizeCategoryCode(payload.getCode());
      Optional<PreEntryCheckCategory> existing = categoryRepository.findByCodeIgnoreCase(newCode);
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

    PreEntryCheckCategory saved = categoryRepository.save(category);
    return ResponseEntity.ok(new ApiResponse<>(true, "Category updated", toDto(saved)));
  }

  @DeleteMapping("/categories/{id}")
  @PreAuthorize("hasAnyAuthority('ROLE_ADMIN','ROLE_SUPERADMIN','ROLE_SAFETY','all_functions')")
  public ResponseEntity<ApiResponse<SafetyCheckCategoryDto>> deactivateCategory(@PathVariable Long id) {
    PreEntryCheckCategory category =
        categoryRepository
            .findById(id)
            .orElseThrow(() -> new IllegalArgumentException("Category not found"));
    long activeItems = itemRepository.countByCategoryIdAndIsActiveTrue(id);
    if (activeItems > 0) {
      throw new IllegalArgumentException(
          "Cannot deactivate category while active items still exist. Please deactivate items first.");
    }
    category.setIsActive(false);
    PreEntryCheckCategory saved = categoryRepository.save(category);
    return ResponseEntity.ok(new ApiResponse<>(true, "Category deactivated", toDto(saved)));
  }

  @GetMapping("/items")
  @PreAuthorize("hasAnyAuthority('ROLE_ADMIN','ROLE_SUPERADMIN','ROLE_SAFETY','all_functions')")
  public ResponseEntity<ApiResponse<List<SafetyCheckMasterItemDto>>> getItems(
      @RequestParam(name = "categoryId", required = false) Long categoryId,
      @RequestParam(name = "activeOnly", defaultValue = "false") boolean activeOnly,
      @RequestParam(name = "q", required = false) String keyword) {
    ensureDefaultDataIfEmpty();

    String safeKeyword = keyword != null ? keyword.trim() : null;
    if (safeKeyword != null && safeKeyword.isBlank()) {
      safeKeyword = null;
    }
    List<PreEntryCheckMasterItem> items =
        itemRepository.searchItems(categoryId, activeOnly, safeKeyword);

    List<SafetyCheckMasterItemDto> data =
        items.stream().map(this::toDto).collect(Collectors.toList());
    return ResponseEntity.ok(new ApiResponse<>(true, "Pre-entry master items", data));
  }

  @PostMapping("/items")
  @PreAuthorize("hasAnyAuthority('ROLE_ADMIN','ROLE_SUPERADMIN','ROLE_SAFETY','all_functions')")
  public ResponseEntity<ApiResponse<SafetyCheckMasterItemDto>> createItem(
      @RequestBody SafetyCheckMasterItemDto payload) {
    if (payload.getCategoryId() == null) {
      throw new IllegalArgumentException("categoryId is required");
    }
    String itemLabelKm = payload.getItemLabelKm() != null ? payload.getItemLabelKm().trim() : "";
    if (itemLabelKm.isBlank()) {
      throw new IllegalArgumentException("Item Khmer label is required");
    }

    PreEntryCheckCategory category =
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

    PreEntryCheckMasterItem item =
        PreEntryCheckMasterItem.builder()
            .category(category)
            .itemKey(initialKey)
            .itemLabelKm(itemLabelKm)
            .checkTime(payload.getCheckTime() != null && !payload.getCheckTime().trim().isBlank()
                ? payload.getCheckTime().trim()
                : null)
            .sortOrder(sortOrder)
            .isActive(payload.getIsActive() != null ? payload.getIsActive() : Boolean.TRUE)
            .build();

    PreEntryCheckMasterItem saved = itemRepository.save(item);
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
    PreEntryCheckMasterItem item =
        itemRepository.findById(id).orElseThrow(() -> new IllegalArgumentException("Item not found"));

    if (payload.getCategoryId() != null) {
      PreEntryCheckCategory category =
          categoryRepository
              .findById(payload.getCategoryId())
              .orElseThrow(() -> new IllegalArgumentException("Category not found"));
      item.setCategory(category);
    }

    if (payload.getItemKey() != null && !payload.getItemKey().trim().isBlank()) {
      String newKey = normalizeItemKey(payload.getItemKey());
      Optional<PreEntryCheckMasterItem> existing = itemRepository.findByItemKeyIgnoreCase(newKey);
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

    PreEntryCheckMasterItem saved = itemRepository.save(item);
    return ResponseEntity.ok(new ApiResponse<>(true, "Item updated", toDto(saved)));
  }

  @DeleteMapping("/items/{id}")
  @PreAuthorize("hasAnyAuthority('ROLE_ADMIN','ROLE_SUPERADMIN','ROLE_SAFETY','all_functions')")
  public ResponseEntity<ApiResponse<SafetyCheckMasterItemDto>> deactivateItem(@PathVariable Long id) {
    PreEntryCheckMasterItem item =
        itemRepository.findById(id).orElseThrow(() -> new IllegalArgumentException("Item not found"));
    item.setIsActive(false);
    PreEntryCheckMasterItem saved = itemRepository.save(item);
    return ResponseEntity.ok(new ApiResponse<>(true, "Item deactivated", toDto(saved)));
  }

  private SafetyCheckCategoryDto toDto(PreEntryCheckCategory category) {
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

  private SafetyCheckMasterItemDto toDto(PreEntryCheckMasterItem item) {
    PreEntryCheckCategory category = item.getCategory();
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

  private String normalizeCategoryCode(String raw) {
    if (raw == null) return "";
    return raw.trim().toUpperCase(Locale.ROOT);
  }

  private String normalizeItemKey(String raw) {
    if (raw == null) return "";
    return raw.trim().toLowerCase(Locale.ROOT).replaceAll("[^a-z0-9_]+", "_");
  }

  /**
   * Local fail-safe seeding.
   * Needed when Flyway is disabled in local profile and migration SQL does not execute.
   */
  private void ensureDefaultDataIfEmpty() {
    if (categoryRepository.count() > 0) {
      return;
    }

    PreEntryCheckCategory loadCategory = categoryRepository.save(
        PreEntryCheckCategory.builder()
            .code("LOAD")
            .nameKm("ត្រូតពិនិត្យសម្ភារះលើឡានមុនចូលរោងចក្រ")
            .sortOrder(1)
            .isActive(Boolean.TRUE)
            .build());

    PreEntryCheckCategory documentsCategory = categoryRepository.save(
        PreEntryCheckCategory.builder()
            .code("DOCUMENTS")
            .nameKm("តង់គ្របទំនិញគ្រប់គ្រាន់ នឹងត្រឹមត្រូវអត់")
            .sortOrder(2)
            .isActive(Boolean.TRUE)
            .build());

    PreEntryCheckCategory vehicleCategory = categoryRepository.save(
        PreEntryCheckCategory.builder()
            .code("WINDSHIELD")
            .nameKm("ត្រួតពិនិត្យឡាន")
            .sortOrder(3)
            .isActive(Boolean.TRUE)
            .build());

    List<PreEntryCheckMasterItem> defaults = new ArrayList<>();
    defaults.add(buildDefaultItem(loadCategory, "pre_entry_load_strap", "ខ្សែរឹតទំនិញគ្រប់គ្រាន់អត់", 1));
    defaults.add(buildDefaultItem(loadCategory, "pre_entry_load_dunnage", "កំណល់គ្រប់គ្រាន់ នឹងត្រឹមត្រូវអត់", 2));
    defaults.add(buildDefaultItem(loadCategory, "pre_entry_load_insulation", "អ៊ីសូឡង់គ្រប់គ្រាន់ នឹងត្រឹមត្រូវអត់", 3));
    defaults.add(buildDefaultItem(loadCategory, "pre_entry_load_steel_bar", "ដែកវ៉េគ្រប់គ្រាន់ នឹងត្រឹមត្រូវអត់", 4));
    defaults.add(buildDefaultItem(documentsCategory, "pre_entry_load_floor_tarp", "តង់ក្រាលបាតត្រឹមត្រូវអត់", 5));

    defaults.add(buildDefaultItem(documentsCategory, "pre_entry_driver_general_check", "ត្រូតពិនិត្យតៃកុងឡាន", 6));
    defaults.add(buildDefaultItem(documentsCategory, "pre_entry_driver_safety_shoes", "ស្បែកជើងសុវត្ថិភាព នឹងស្រោមជើងត្រឹមត្រូវអត់", 7));
    defaults.add(buildDefaultItem(documentsCategory, "pre_entry_driver_reflective_vest", "អាវពន្លឺត្រឹមត្រូវអត់", 8));
    defaults.add(buildDefaultItem(documentsCategory, "pre_entry_driver_alcohol", "តៃកុងសារធាតុស្រវឹងអត់?", 9));

    defaults.add(buildDefaultItem(vehicleCategory, "pre_entry_vehicle_clean_before_entry", "បាញ់ទឹកសម្អាតឡានអត់មុនចូលរោងចក្រ", 10));
    defaults.add(buildDefaultItem(vehicleCategory, "pre_entry_vehicle_door_glass_open", "ទ្វាឡានបើកកញ្ចក់មុនចូលរោងចក្រ", 11));
    defaults.add(buildDefaultItem(vehicleCategory, "pre_entry_vehicle_trailer_floor_hole", "បាតរម៉ក់ផតអត់", 12));
    defaults.add(buildDefaultItem(vehicleCategory, "pre_entry_vehicle_trailer_board_out", "ក្តរម៉កលៀនចេញក្រៅអត់", 13));

    itemRepository.saveAll(defaults);
  }

  private PreEntryCheckMasterItem buildDefaultItem(
      PreEntryCheckCategory category, String itemKey, String itemLabelKm, int sortOrder) {
    return PreEntryCheckMasterItem.builder()
        .category(category)
        .itemKey(itemKey)
        .itemLabelKm(itemLabelKm)
        .sortOrder(sortOrder)
        .isActive(Boolean.TRUE)
        .build();
  }
}
