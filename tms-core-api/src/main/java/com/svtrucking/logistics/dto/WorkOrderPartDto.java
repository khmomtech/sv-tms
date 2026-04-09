package com.svtrucking.logistics.dto;

import com.svtrucking.logistics.model.WorkOrderPart;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class WorkOrderPartDto {

  private Long id;

  @NotNull(message = "Work order ID is required")
  private Long workOrderId;

  private Long taskId;

  @NotNull(message = "Part ID is required")
  private Long partId;

  private String partCode;

  private String partName;

  @NotNull(message = "Quantity is required")
  @DecimalMin(value = "0.0", inclusive = false, message = "Quantity must be greater than 0")
  private Double quantity;

  @NotNull(message = "Unit price is required")
  @DecimalMin(value = "0.0", inclusive = false, message = "Unit price must be greater than 0")
  private Double unitPrice;

  private Double totalCost;

  @Size(max = 500, message = "Notes cannot exceed 500 characters")
  private String notes;

  private java.time.LocalDateTime addedAt;

  private Long addedById;

  private String addedByName;

  public static WorkOrderPartDto fromEntity(WorkOrderPart entity) {
    if (entity == null) return null;

    return WorkOrderPartDto.builder()
        .id(entity.getId())
        .workOrderId(entity.getWorkOrder() != null ? entity.getWorkOrder().getId() : null)
        .taskId(entity.getTask() != null ? entity.getTask().getId() : null)
        .partId(entity.getPart() != null ? entity.getPart().getId() : null)
        .partCode(entity.getPart() != null ? entity.getPart().getPartCode() : null)
        .partName(entity.getPart() != null ? entity.getPart().getPartName() : null)
        .quantity(entity.getQuantity() != null ? entity.getQuantity().doubleValue() : null)
        .unitPrice(entity.getUnitPrice() != null ? entity.getUnitPrice().doubleValue() : null)
        .totalCost(entity.getTotalCost() != null ? entity.getTotalCost().doubleValue() : null)
        .notes(entity.getNotes())
        .addedAt(entity.getAddedAt())
        .addedById(entity.getAddedBy() != null ? entity.getAddedBy().getId() : null)
        .addedByName(entity.getAddedBy() != null ? entity.getAddedBy().getUsername() : null)
        .build();
  }
}
