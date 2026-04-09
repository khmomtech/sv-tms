package com.svtrucking.logistics.model;

import com.svtrucking.logistics.core.BaseEntity;
import com.svtrucking.logistics.enums.CustomerFinanceTransactionType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.time.LocalDate;
import lombok.EqualsAndHashCode;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.ToString;

@Entity
@Table(name = "customer_finance_transactions")
@Getter
@Setter
@NoArgsConstructor
@ToString
@EqualsAndHashCode(callSuper = true)
public class CustomerFinanceTransaction extends BaseEntity {

  @ManyToOne(fetch = FetchType.LAZY, optional = false)
  @JoinColumn(name = "customer_id", nullable = false)
  @ToString.Exclude
  @EqualsAndHashCode.Exclude
  private Customer customer;

  @Enumerated(EnumType.STRING)
  @Column(name = "transaction_type", nullable = false, length = 30)
  private CustomerFinanceTransactionType transactionType;

  @Column(nullable = false, precision = 15, scale = 2)
  private BigDecimal amount;

  @Column(name = "balance_before", nullable = false, precision = 15, scale = 2)
  private BigDecimal balanceBefore;

  @Column(name = "balance_after", nullable = false, precision = 15, scale = 2)
  private BigDecimal balanceAfter;

  @Column(length = 3, nullable = false)
  private String currency;

  @Column(name = "effective_date", nullable = false)
  private LocalDate effectiveDate;

  @Column(length = 120)
  private String reference;

  @Column(columnDefinition = "TEXT")
  private String note;

  @Column(name = "created_by", nullable = false, length = 100)
  private String createdBy;
}
