package com.svtrucking.logistics.service;

import com.svtrucking.logistics.dto.ItemDto;
import com.svtrucking.logistics.dto.ItemFilterDto;
import com.svtrucking.logistics.dto.SuggestDto;
import com.svtrucking.logistics.mapper.ItemMapper;
import com.svtrucking.logistics.model.Item;
import com.svtrucking.logistics.repository.ItemRepository;
import com.svtrucking.logistics.spec.ItemSpecification;
import java.util.List;
import java.util.Optional;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

@Service
public class ItemService {

  private static final Logger LOG = LoggerFactory.getLogger(ItemService.class);
  private final ItemRepository itemRepository;
  private final ItemMapper mapper;

  public ItemService(ItemRepository itemRepository, ItemMapper mapper) {
    this.itemRepository = itemRepository;
    this.mapper = mapper;
  }

  /** 🔍 Get all items */
  public List<Item> getAllItems() {
    return itemRepository.findAll();
  }

  /** 🔍 Get only active items */
  public List<Item> getActiveItems() {
    return itemRepository.findByStatus(1);
  }

  /** 🔍 Flexible search by multiple fields including code, Khmer name */
  public List<Item> searchItems(String keyword) {
    if (keyword == null || keyword.trim().isEmpty()) {
      return getAllItems();
    }

    final String lowerKeyword = keyword.toLowerCase();

    return itemRepository.findAll().stream()
        .filter(
            item ->
                (item.getItemCode() != null
                        && item.getItemCode().toLowerCase().contains(lowerKeyword))
                    || (item.getItemName() != null
                        && item.getItemName().toLowerCase().contains(lowerKeyword))
                    || (item.getItemNameKh() != null
                        && item.getItemNameKh().toLowerCase().contains(lowerKeyword))
                    || (item.getItemType() != null
                        && item.getItemType().name().toLowerCase().contains(lowerKeyword))
                    || (item.getSize() != null
                        && item.getSize().toLowerCase().contains(lowerKeyword))
                    || (item.getUnit() != null
                        && item.getUnit().toLowerCase().contains(lowerKeyword))
                    || (item.getWeight() != null
                        && item.getWeight().toLowerCase().contains(lowerKeyword))
                    || (item.getPallets() != null
                        && item.getPallets().toLowerCase().contains(lowerKeyword))
                    || (item.getPalletType() != null
                        && item.getPalletType().toLowerCase().contains(lowerKeyword)))
        .toList();
  }

  /** 🔎 Get item by ID */
  public Optional<Item> getItemById(Long id) {
    return itemRepository.findById(id);
  }

  /** 🔎 Get item by Code */
  public Optional<Item> getItemByCode(String code) {
    return itemRepository.findByItemCode(code);
  }

  /** Page search using DTO filter and specification */
  public Page<ItemDto> search(ItemFilterDto filter, Pageable pageable) {
    return itemRepository.findAll(ItemSpecification.from(filter), pageable).map(mapper::toDto);
  }

  /** Autocomplete suggestions */
  public List<SuggestDto> autocomplete(String q, int limit) {
    Pageable p = PageRequest.of(0, Math.min(limit, 50));
    ItemFilterDto f = new ItemFilterDto();
    f.q = q;
    return itemRepository.findAll(ItemSpecification.from(f), p).stream()
        .map(i -> new SuggestDto(i.getId(), i.getItemName()))
        .toList();
  }

  /** Save new item, prevent duplicates by itemCode */
  public Item saveItem(Item item) {
    Optional<Item> existing = getItemByCode(item.getItemCode());
    if (existing.isPresent()) {
      LOG.warn(
          "Item with code [{}] already exists. Skipping or handle update manually.",
          item.getItemCode());
      return existing.get(); // Or throw exception, or update instead
    }

    LOG.info(" Saving item [{}]", item.getItemCode());
    return itemRepository.save(item);
  }

  /** 🔁 Update existing item */
  public Optional<Item> updateItem(Long id, Item updatedItem) {
    return itemRepository
        .findById(id)
        .map(
            existing -> {
              existing.setItemCode(updatedItem.getItemCode());
              existing.setItemName(updatedItem.getItemName());
              existing.setItemNameKh(updatedItem.getItemNameKh());
              existing.setItemType(updatedItem.getItemType());
              existing.setSize(updatedItem.getSize());
              existing.setWeight(updatedItem.getWeight());
              existing.setUnit(updatedItem.getUnit());
              existing.setQuantity(updatedItem.getQuantity());
              existing.setPallets(updatedItem.getPallets());
              existing.setPalletType(updatedItem.getPalletType());
              existing.setStatus(updatedItem.getStatus());
              existing.setSortOrder(updatedItem.getSortOrder());
              return itemRepository.save(existing);
            });
  }

  /** Delete item by ID */
  public void deleteItem(Long id) {
    LOG.info("🗑️ Deleting item with ID {}", id);
    itemRepository.deleteById(id);
  }
}
