// This is a Java file, no markdown fence needed
package com.svtrucking.logistics.dto;

import com.svtrucking.logistics.enums.ItemType;
import com.svtrucking.logistics.model.Item;
import lombok.Data;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Data
public class ItemDto {

  private static final Logger LOG = LoggerFactory.getLogger(ItemDto.class);

  private Long id;
  private String itemCode;
  private String itemName;
  private String itemNameKh;
  private Integer quantity;
  private String unit;
  private String size;
  private String weight;
  private String itemType; // raw string
  private String palletType;
  private String pallets;
  private Integer status;
  private Integer sortOrder;

  public static ItemDto fromEntity(Item item) {
    ItemDto dto = new ItemDto();
    dto.setId(item.getId());
    dto.setItemCode(item.getItemCode());
    dto.setItemName(item.getItemName());
    dto.setItemNameKh(item.getItemNameKh());
    dto.setQuantity(item.getQuantity());
    dto.setUnit(item.getUnit());
    dto.setSize(item.getSize());
    dto.setWeight(item.getWeight());
    dto.setItemType(item.getItemType() != null ? item.getItemType().name() : null);
    dto.setPalletType(item.getPalletType());
    dto.setPallets(item.getPallets());
    dto.setStatus(item.getStatus());
    dto.setSortOrder(item.getSortOrder());
    return dto;
  }

  public static Item toEntity(ItemDto dto) {
    Item item = new Item();
    item.setId(dto.getId());
    item.setItemCode(dto.getItemCode());
    item.setItemName(dto.getItemName());
    item.setItemNameKh(dto.getItemNameKh());
    item.setQuantity(dto.getQuantity());
    item.setUnit(dto.getUnit());
    item.setSize(dto.getSize());
    item.setWeight(dto.getWeight());

    // Normalize and match itemType
    ItemType resolvedType = resolveItemType(dto.getItemType());
    item.setItemType(resolvedType);

    item.setPalletType(dto.getPalletType());
    item.setPallets(dto.getPallets());
    item.setStatus(dto.getStatus());
    item.setSortOrder(dto.getSortOrder());
    return item;
  }

  private static ItemType resolveItemType(String rawType) {
    if (rawType == null || rawType.isEmpty()) return ItemType.OTHERS;

    String normalized = rawType.trim().toUpperCase();

    // Special mapping
    if (normalized.equals("BEVERAGE"))
      return ItemType.CONSUMER_GOODS; // or define BEVERAGE in enum if needed

    try {
      return ItemType.valueOf(normalized);
    } catch (IllegalArgumentException e) {
        LOG.warn("Unknown itemType: '{}'. Defaulting to OTHERS.", rawType);
      return ItemType.OTHERS;
    }
  }
}
