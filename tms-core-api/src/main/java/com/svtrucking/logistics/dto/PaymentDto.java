package com.svtrucking.logistics.dto;

import com.svtrucking.logistics.model.Payment;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PaymentDto {

  private Long id;

  @NotNull(message = "Invoice ID is required")
  private Long invoiceId;

  @NotNull(message = "Amount is required")
  @DecimalMin(value = "0.0", inclusive = false, message = "Amount must be > 0")
  private BigDecimal amount;

  @Size(max = 50, message = "Method cannot exceed 50 characters")
  private String method;

  @Size(max = 100, message = "Reference cannot exceed 100 characters")
  private String referenceNo;

  private LocalDateTime paidAt;
  private String notes;

  private Long createdById;
  private String createdByName;

  public static PaymentDto fromEntity(Payment p) {
    if (p == null) return null;
    return PaymentDto.builder()
        .id(p.getId())
        .invoiceId(p.getInvoice() != null ? p.getInvoice().getId() : null)
        .amount(p.getAmount())
        .method(p.getMethod())
        .referenceNo(p.getReferenceNo())
        .paidAt(p.getPaidAt())
        .notes(p.getNotes())
        .createdById(p.getCreatedBy() != null ? p.getCreatedBy().getId() : null)
        .createdByName(p.getCreatedBy() != null ? p.getCreatedBy().getUsername() : null)
        .build();
  }
}

