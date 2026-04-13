package com.svtrucking.logistics.controller;

import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.svtrucking.logistics.dto.ItemDto;
import com.svtrucking.logistics.service.ItemService;
import java.util.List;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

class ItemControllerTest {

  private MockMvc mockMvc;
  private ItemService itemService;

  @BeforeEach
  void setup() {
    itemService = Mockito.mock(ItemService.class);
    ItemController controller = new ItemController(itemService);
    mockMvc = MockMvcBuilders.standaloneSetup(controller).build();
  }

  @Test
  void searchItems_acceptsKeywordParam() throws Exception {
    var item = new com.svtrucking.logistics.model.Item();
    item.setId(1L);
    item.setItemCode("ITEM-001");
    item.setItemName("Rice");
    item.setQuantity(1);

    when(itemService.searchItems("rice")).thenReturn(List.of(item));

    mockMvc.perform(get("/api/items/search").param("keyword", "rice"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$[0].itemCode").value("ITEM-001"))
        .andExpect(jsonPath("$[0].itemName").value("Rice"));

    verify(itemService).searchItems("rice");
  }

  @Test
  void searchItems_acceptsQParamFallback() throws Exception {
    var item = new com.svtrucking.logistics.model.Item();
    item.setId(2L);
    item.setItemCode("ITEM-002");
    item.setItemName("Water");
    item.setQuantity(1);

    when(itemService.searchItems("water")).thenReturn(List.of(item));

    mockMvc.perform(get("/api/items/search").param("q", "water"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$[0].itemCode").value("ITEM-002"))
        .andExpect(jsonPath("$[0].itemName").value("Water"));

    verify(itemService).searchItems("water");
  }
}
