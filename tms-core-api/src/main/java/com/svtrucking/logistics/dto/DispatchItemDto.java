package com.svtrucking.logistics.dto;

import com.svtrucking.logistics.model.DispatchItem;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DispatchItemDto {
  private Long id;
  private String itemName;
  private Double quantity;
  private String unitOfMeasurement;
  private String palletType;
  private String dimensions;
  private Double weight;
  private Integer palletQty;
  private String loadingPlace;

  public static DispatchItemDto fromEntity(DispatchItem item) {
    return DispatchItemDto.builder()
        .id(item.getId())
        .itemName(item.getItemName())
        .quantity(item.getQuantity())
        .unitOfMeasurement(item.getUnitOfMeasurement())
        .palletType(item.getPalletType())
        .dimensions(item.getDimensions())
        .weight(item.getWeight())
        .palletQty(item.getPalletQty())
        .loadingPlace(item.getLoadingPlace())
        .build();
  }
}
