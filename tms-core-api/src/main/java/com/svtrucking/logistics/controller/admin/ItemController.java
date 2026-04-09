package com.svtrucking.logistics.controller.admin;

import com.svtrucking.logistics.dto.ItemDto;
import com.svtrucking.logistics.dto.ItemFilterDto;
import com.svtrucking.logistics.dto.SuggestDto;
import com.svtrucking.logistics.service.ItemService;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController("adminItemController")
@RequestMapping("/api/admin/items")
public class ItemController {
    private final ItemService svc;

    public ItemController(ItemService svc) { this.svc = svc; }

    @PostMapping("/search")
    public Page<ItemDto> search(@RequestBody ItemFilterDto filter, Pageable pageable) {
        return svc.search(filter, pageable);
    }

    @GetMapping("/search")
    public List<SuggestDto> autocomplete(@RequestParam String q, @RequestParam(defaultValue = "10") int limit) {
        return svc.autocomplete(q, limit);
    }
}
