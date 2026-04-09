package com.svtrucking.logistics.service;

import com.svtrucking.logistics.dto.ItemDto;
import com.svtrucking.logistics.dto.ItemFilterDto;
import com.svtrucking.logistics.dto.SuggestDto;
import com.svtrucking.logistics.exception.ResourceNotFoundException;
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
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.transaction.annotation.Transactional;

@Service
public class ItemService {

  private static final Logger LOG = LoggerFactory.getLogger(ItemService.class);
  private final ItemRepository itemRepository;
  private final ItemMapper mapper;
  private final JdbcTemplate jdbcTemplate;

  public ItemService(ItemRepository itemRepository, ItemMapper mapper, JdbcTemplate jdbcTemplate) {
    this.itemRepository = itemRepository;
    this.mapper = mapper;
    this.jdbcTemplate = jdbcTemplate;
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
  @Transactional(transactionManager = "jpaTransactionManager")
  public Item saveItem(Item item) {
    String itemCode = item.getItemCode() != null ? item.getItemCode().trim() : null;
    if (itemCode != null && !itemCode.isEmpty()) {
      Optional<Item> existing = getItemByCode(itemCode);
      if (existing.isPresent()) {
        throw new IllegalStateException("Item code already exists: " + itemCode);
      }
      item.setItemCode(itemCode);
    }

    LOG.info(" Saving item [{}]", item.getItemCode());
    return itemRepository.save(item);
  }

  /** 🔁 Update existing item */
  @Transactional(transactionManager = "jpaTransactionManager")
  public Optional<Item> updateItem(Long id, Item updatedItem) {
    return itemRepository
        .findById(id)
        .map(
            existing -> {
              String requestedCode =
                  updatedItem.getItemCode() != null ? updatedItem.getItemCode().trim() : null;
              if (requestedCode != null && !requestedCode.isEmpty()) {
                itemRepository
                    .findByItemCode(requestedCode)
                    .filter(item -> !item.getId().equals(id))
                    .ifPresent(
                        item -> {
                          throw new IllegalStateException(
                              "Item code already exists: " + requestedCode);
                        });
              }

              // Use direct SQL for updates because the live VPS image has shown
              // non-persisting JPA merge behavior while still returning a mutated entity.
              jdbcTemplate.update(
                  """
                  UPDATE items
                     SET item_code = ?,
                         item_name = ?,
                         item_name_kh = ?,
                         item_type = ?,
                         size = ?,
                         weight = ?,
                         unit = ?,
                         quantity = ?,
                         pallets = ?,
                         pallet_type = ?,
                         status = ?,
                         sort_order = ?,
                         updated_at = NOW(6)
                   WHERE id = ?
                  """,
                  requestedCode,
                  updatedItem.getItemName(),
                  updatedItem.getItemNameKh(),
                  updatedItem.getItemType() != null ? updatedItem.getItemType().name() : null,
                  updatedItem.getSize(),
                  updatedItem.getWeight(),
                  updatedItem.getUnit(),
                  updatedItem.getQuantity(),
                  updatedItem.getPallets(),
                  updatedItem.getPalletType(),
                  updatedItem.getStatus(),
                  updatedItem.getSortOrder(),
                  id);
              return itemRepository.findById(id).orElse(existing);
            });
  }

  /** Delete item by ID */
  @Transactional(transactionManager = "jpaTransactionManager")
  public void deleteItem(Long id) {
    if (!itemRepository.existsById(id)) {
      throw new ResourceNotFoundException("Item not found with id: " + id);
    }
    LOG.info("🗑️ Deleting item with ID {}", id);
    itemRepository.deleteById(id);
  }
}
