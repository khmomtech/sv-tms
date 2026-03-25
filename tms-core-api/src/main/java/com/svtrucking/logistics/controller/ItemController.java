package com.svtrucking.logistics.controller;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.dto.ItemDto;
import com.svtrucking.logistics.model.Item;
import com.svtrucking.logistics.service.ItemService;
import org.springframework.security.access.prepost.PreAuthorize;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/items")
@CrossOrigin(origins = "*")
public class ItemController {

  private final ItemService itemService;

  public ItemController(ItemService itemService) {
    this.itemService = itemService;
  }

  /** 🔍 Get all items */
  @GetMapping
  @PreAuthorize("@authorizationService.hasPermission('item:read')")
  public ResponseEntity<List<ItemDto>> getAllItems() {
    List<ItemDto> items =
        itemService.getAllItems().stream().map(ItemDto::fromEntity).collect(Collectors.toList());
    return ResponseEntity.ok(items);
  }

  /** 🔍 Search items by keyword */
  @GetMapping("/search")
  @PreAuthorize("@authorizationService.hasPermission('item:read')")
  public ResponseEntity<List<ItemDto>> searchItems(@RequestParam String keyword) {
    List<ItemDto> items =
        itemService.searchItems(keyword).stream()
            .map(ItemDto::fromEntity)
            .collect(Collectors.toList());
    return ResponseEntity.ok(items);
  }

  /** 🔎 Get item by ID */
  @GetMapping("/{id}")
  @PreAuthorize("@authorizationService.hasPermission('item:read')")
  public ResponseEntity<ItemDto> getItemById(@PathVariable Long id) {
    Optional<Item> item = itemService.getItemById(id);
    return item.map(value -> ResponseEntity.ok(ItemDto.fromEntity(value)))
        .orElse(ResponseEntity.notFound().build());
  }

  /** 🆕 Create new item */
  /** 🆕 Create new item */
  @PostMapping
  @PreAuthorize("@authorizationService.hasPermission('item:create')")
  public ResponseEntity<ApiResponse<ItemDto>> createItem(@RequestBody ItemDto itemDto) {
    try {
      Item itemEntity = ItemDto.toEntity(itemDto); // Convert DTO to entity (may throw exception)
      Item saved = itemService.saveItem(itemEntity);
      return ResponseEntity.ok(new ApiResponse<>(true, " Item created", ItemDto.fromEntity(saved)));

    } catch (IllegalArgumentException e) {
      return ResponseEntity.badRequest()
          .body(new ApiResponse<>(false, " Invalid item type or input: " + e.getMessage(), null));

    } catch (Exception e) {
      // General fallback for server errors
      return ResponseEntity.internalServerError()
          .body(new ApiResponse<>(false, " Failed to create item: " + e.getMessage(), null));
    }
  }

  /** 🔁 Update existing item */
  @PutMapping("/{id}")
  @PreAuthorize("@authorizationService.hasPermission('item:update')")
  public ResponseEntity<ApiResponse<ItemDto>> updateItem(
      @PathVariable Long id, @RequestBody ItemDto itemDto) {
    Optional<Item> updated = itemService.updateItem(id, ItemDto.toEntity(itemDto));
    return updated
        .map(
            value ->
                ResponseEntity.ok(
                    new ApiResponse<>(true, "Item updated", ItemDto.fromEntity(value))))
        .orElse(ResponseEntity.notFound().build());
  }

  /** Delete item by ID */
  @DeleteMapping("/{id}")
  @PreAuthorize("@authorizationService.hasPermission('item:delete')")
  public ResponseEntity<Void> deleteItem(@PathVariable Long id) {
    itemService.deleteItem(id);
    return ResponseEntity.noContent().build();
  }

  @PostMapping("/bulk-import")
  @PreAuthorize("@authorizationService.hasPermission('item:create')")
  public ResponseEntity<ApiResponse<List<ItemDto>>> bulkImport(
      @RequestBody List<ItemDto> itemDtos) {
    List<ItemDto> successful = new ArrayList<>();
    List<String> errors = new ArrayList<>();

    for (ItemDto dto : itemDtos) {
      try {
        Item item = ItemDto.toEntity(dto);
        Item saved = itemService.saveItem(item);
        successful.add(ItemDto.fromEntity(saved));
      } catch (Exception e) {
        errors.add(" Failed [" + dto.getItemCode() + "]: " + e.getMessage());
      }
    }

    boolean allSuccessful = errors.isEmpty();
    String message =
        allSuccessful
            ? " All items imported successfully"
            : "Imported " + successful.size() + " items. Errors: " + errors.size();

    return ResponseEntity.ok(new ApiResponse<>(allSuccessful, message, successful));
  }
}
