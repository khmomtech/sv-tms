package com.svtrucking.logistics.mapper;

import com.svtrucking.logistics.dto.ItemDto;
import com.svtrucking.logistics.model.Item;
import org.mapstruct.Mapper;

@Mapper(componentModel = "spring")
public interface ItemMapper {
    ItemDto toDto(Item e);
    Item toEntity(ItemDto dto);
}
