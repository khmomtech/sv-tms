package com.svtrucking.logistics.dto;

import com.svtrucking.logistics.model.PartsMaster;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PartsMasterDto {

  private Long id;

  @NotBlank(message = "Part code is required")
  @Size(max = 50, message = "Part code cannot exceed 50 characters")
  @Pattern(
      regexp = "^[A-Z0-9-]+$",
      message = "Part code must contain only uppercase letters, numbers, and hyphens")
  private String partCode;

  @NotBlank(message = "Part name is required")
  @Size(max = 200, message = "Part name cannot exceed 200 characters")
  private String partName;

  @NotBlank(message = "Category is required")
  @Size(max = 100, message = "Category cannot exceed 100 characters")
  private String category;

  @Size(max = 1000, message = "Description cannot exceed 1000 characters")
  private String description;

  @NotNull(message = "Unit price is required")
  @DecimalMin(value = "0.0", inclusive = false, message = "Unit price must be greater than 0")
  private Double unitPrice;

  @NotBlank(message = "Unit is required")
  @Size(max = 20, message = "Unit cannot exceed 20 characters")
  private String unit;

  @Size(max = 100, message = "Supplier cannot exceed 100 characters")
  private String supplier;

  @Size(max = 100, message = "Manufacturer cannot exceed 100 characters")
  private String manufacturer;

  private Boolean active;

  public static PartsMasterDto fromEntity(PartsMaster entity) {
    if (entity == null) return null;

    return PartsMasterDto.builder()
        .id(entity.getId())
        .partCode(entity.getPartCode())
        .partName(entity.getPartName())
        .category(entity.getCategory())
        .description(entity.getDescription())
        .unitPrice(entity.getUnitPrice() != null ? entity.getUnitPrice().doubleValue() : null)
        .unit(entity.getUnit())
        .supplier(entity.getSupplier())
        .manufacturer(entity.getManufacturer())
        .active(entity.getActive())
        .build();
  }

  public PartsMaster toEntity() {
    return PartsMaster.builder()
        .id(this.id)
        .partCode(this.partCode)
        .partName(this.partName)
        .category(this.category)
        .description(this.description)
        .referenceCost(this.unitPrice != null ? java.math.BigDecimal.valueOf(this.unitPrice) : null)
        .supplierName(this.supplier)
        .manufacturer(this.manufacturer)
        .active(this.active != null ? this.active : true)
        .isDeleted(false)
        .build();
  }
}
