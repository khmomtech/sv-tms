package com.svtrucking.logistics.dto;

import com.svtrucking.logistics.enums.PaymentStatus;
import com.svtrucking.logistics.model.Invoice;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Optional;
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
public class InvoiceDto {
  private Long id;
  private Long transportOrderId; //  Reference to Transport Order
  private Long workOrderId; // SV Standard: maintenance invoice reference
  private LocalDate invoiceDate;
  private BigDecimal totalAmount;
  private PaymentStatus paymentStatus; //  Enum: PAID, UNPAID, PARTIAL

  public static InvoiceDto fromEntity(Invoice invoice) {
    if (invoice == null) {
      return null;
    }
    return InvoiceDto.builder()
        .id(invoice.getId())
        .transportOrderId(
            Optional.ofNullable(invoice.getTransportOrder()).map(t -> t.getId()).orElse(null))
        .workOrderId(Optional.ofNullable(invoice.getWorkOrder()).map(w -> w.getId()).orElse(null))
        .invoiceDate(invoice.getInvoiceDate())
        .totalAmount(BigDecimal.valueOf(invoice.getTotalAmount())) // Convert double to BigDecimal
        .paymentStatus(
            PaymentStatus.valueOf(
                invoice.getPaymentStatus().toUpperCase())) // Convert String to Enum
        .build();
  }
}
