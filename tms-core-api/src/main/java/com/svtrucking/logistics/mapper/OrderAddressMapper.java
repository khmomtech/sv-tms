// package com.svtrucking.logistics.mapper;

// import com.svtrucking.logistics.dto.OrderAddressDto;
// import com.svtrucking.logistics.model.OrderAddress;
// import org.springframework.stereotype.Component;

// @Component
// public class OrderAddressMapper {

//     //  Convert DTO to Entity
//     public OrderAddress toEntity(OrderAddressDto dto) {
//         if (dto == null) {
//             return null;
//         }
//         return OrderAddress.builder()
//                 .id(dto.getId())
//                 .address(dto.getAddress())
//                 .city(dto.getCity())
//                 .state(dto.getState())
//                 .postalCode(dto.getPostalCode())
//                 .country(dto.getCountry())
//                 .isPickup(dto.isPickup())  //  Ensures Pickup/Drop Flag is Mapped
//                 .build();
//     }

//     //  Convert Entity to DTO
//     public OrderAddressDto toDto(OrderAddress entity) {
//         if (entity == null) {
//             return null;
//         }
//         return OrderAddressDto.builder()
//                 .id(entity.getId())
//                 .address(entity.getAddress())
//                 .city(entity.getCity())
//                 .state(entity.getState())
//                 .postalCode(entity.getPostalCode())
//                 .country(entity.getCountry())
//                 .isPickup(entity.isPickup())  //  Ensures Pickup/Drop Flag is Mapped
//                 .build();
//     }
// }
