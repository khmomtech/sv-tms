package com.svtrucking.logistics.dto;

import com.svtrucking.logistics.enums.CustomerFinanceTransactionType;
import com.svtrucking.logistics.model.CustomerFinanceTransaction;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class CustomerFinanceTransactionDto {
  private Long id;
  private Long customerId;
  private CustomerFinanceTransactionType transactionType;
  private BigDecimal amount;
  private BigDecimal balanceBefore;
  private BigDecimal balanceAfter;
  private String currency;
  private LocalDate effectiveDate;
  private String reference;
  private String note;
  private String createdBy;
  private LocalDateTime createdAt;

  public static CustomerFinanceTransactionDto fromEntity(CustomerFinanceTransaction tx) {
    return new CustomerFinanceTransactionDto(
        tx.getId(),
        tx.getCustomer() != null ? tx.getCustomer().getId() : null,
        tx.getTransactionType(),
        tx.getAmount(),
        tx.getBalanceBefore(),
        tx.getBalanceAfter(),
        tx.getCurrency(),
        tx.getEffectiveDate(),
        tx.getReference(),
        tx.getNote(),
        tx.getCreatedBy(),
        tx.getCreatedAt());
  }
}
