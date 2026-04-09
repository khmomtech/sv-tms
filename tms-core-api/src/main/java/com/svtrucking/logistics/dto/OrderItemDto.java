package com.svtrucking.logistics.dto;

import com.fasterxml.jackson.annotation.JsonFormat;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.svtrucking.logistics.enums.ItemType;
import com.svtrucking.logistics.model.Item;
import com.svtrucking.logistics.model.OrderItem;
import java.util.Optional;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@JsonIgnoreProperties(ignoreUnknown = true)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class OrderItemDto {

  private Long id;
  private Long itemId; // Reference only
  private String itemCode; // Reference alternative (lookup)
  private ItemType itemType; // Snapshot from Item entity
  private String itemName; // From Item entity
  private String itemNameKh; // 🆕 Khmer name (from Item entity)

  private double quantity;
  private String unitOfMeasurement;

  @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "0.00")
  private double palletType;

  private String dimensions;
  private double weight;

  private CustomerAddressDto pickupAddress;
  private CustomerAddressDto dropAddress;

  private String fromDestination;
  private String toDestination;
  private String warehouse;
  private String department;

  public static OrderItemDto fromEntity(OrderItem entity) {
    if (entity == null) return null;

    return OrderItemDto.builder()
        .id(entity.getId())
        .itemId(entity.getItem() != null ? entity.getItem().getId() : null)
        .itemCode(entity.getItem() != null ? entity.getItem().getItemCode() : null)
        .itemType(entity.getItem() != null ? entity.getItem().getItemType() : null)
        .itemName(entity.getItem() != null ? entity.getItem().getItemName() : null)
        .itemNameKh(entity.getItem() != null ? entity.getItem().getItemNameKh() : null)
        .quantity(entity.getQuantity())
        .unitOfMeasurement(entity.getUnitOfMeasurement())
        .palletType(entity.getPalletType())
        .dimensions(entity.getDimensions())
        .weight(entity.getWeight())
        .pickupAddress(
          Optional.ofNullable(entity.getPickupAddress())
            .map(CustomerAddressDto::fromEntity)
            .orElse(null))
        .dropAddress(
          Optional.ofNullable(entity.getDropAddress())
            .map(CustomerAddressDto::fromEntity)
            .orElse(null))
        .fromDestination(entity.getFromDestination())
        .toDestination(entity.getToDestination())
        .warehouse(entity.getWarehouse())
        .department(entity.getDepartment())
        .build();
  }

  public OrderItem toEntity(Item item) {
    return OrderItem.builder()
        .id(this.id)
        .item(item) // reference full Item entity
        .quantity(this.quantity)
        .unitOfMeasurement(
            (this.unitOfMeasurement != null && !this.unitOfMeasurement.isBlank())
                ? this.unitOfMeasurement
                : (item != null ? item.getUnit() : null))
        .palletType(this.palletType)
        .dimensions(this.dimensions)
        .weight(this.weight)
        .pickupAddress(this.pickupAddress != null ? this.pickupAddress.toEntity() : null)
        .dropAddress(this.dropAddress != null ? this.dropAddress.toEntity() : null)
        .fromDestination(this.fromDestination)
        .toDestination(this.toDestination)
        .warehouse(this.warehouse)
        .department(this.department)
        .build();
  }

  public void mergeInto(OrderItem target, Item item) {
    if (target == null) return;
    if (item != null) {
      target.setItem(item);
    }
    target.setQuantity(this.quantity);
    if (this.unitOfMeasurement != null && !this.unitOfMeasurement.isBlank()) {
      target.setUnitOfMeasurement(this.unitOfMeasurement);
    } else if (item != null && item.getUnit() != null) {
      target.setUnitOfMeasurement(item.getUnit());
    }
    target.setPalletType(this.palletType);
    target.setDimensions(this.dimensions);
    target.setWeight(this.weight);
    target.setFromDestination(this.fromDestination);
    target.setToDestination(this.toDestination);
    target.setWarehouse(this.warehouse);
    target.setDepartment(this.department);
    target.setPickupAddress(this.pickupAddress != null ? this.pickupAddress.toEntity() : null);
    target.setDropAddress(this.dropAddress != null ? this.dropAddress.toEntity() : null);
  }
}
