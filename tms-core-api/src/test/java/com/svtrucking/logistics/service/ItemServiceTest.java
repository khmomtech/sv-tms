package com.svtrucking.logistics.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.svtrucking.logistics.exception.ResourceNotFoundException;
import com.svtrucking.logistics.mapper.ItemMapper;
import com.svtrucking.logistics.model.Item;
import com.svtrucking.logistics.repository.ItemRepository;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class ItemServiceTest {

  @Mock private ItemRepository itemRepository;
  @Mock private ItemMapper itemMapper;

  @InjectMocks private ItemService service;

  @Test
  void saveItem_rejectsDuplicateItemCode() {
    Item existing = new Item();
    existing.setId(10L);
    existing.setItemCode("ITEM-001");

    Item incoming = new Item();
    incoming.setItemCode(" ITEM-001 ");
    incoming.setItemName("Rice");
    incoming.setQuantity(1);

    when(itemRepository.findByItemCode("ITEM-001")).thenReturn(Optional.of(existing));

    IllegalStateException ex = assertThrows(IllegalStateException.class, () -> service.saveItem(incoming));

    assertEquals("Item code already exists: ITEM-001", ex.getMessage());
    verify(itemRepository, never()).save(any(Item.class));
  }

  @Test
  void deleteItem_throwsNotFoundWhenMissing() {
    when(itemRepository.existsById(99L)).thenReturn(false);

    ResourceNotFoundException ex =
        assertThrows(ResourceNotFoundException.class, () -> service.deleteItem(99L));

    assertEquals("Item not found with id: 99", ex.getMessage());
    verify(itemRepository, never()).deleteById(99L);
  }
}
