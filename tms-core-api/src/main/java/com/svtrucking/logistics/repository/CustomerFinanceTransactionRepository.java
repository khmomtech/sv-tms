package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.enums.CustomerFinanceTransactionType;
import com.svtrucking.logistics.model.CustomerFinanceTransaction;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface CustomerFinanceTransactionRepository
    extends JpaRepository<CustomerFinanceTransaction, Long> {

  List<CustomerFinanceTransaction> findByCustomerIdOrderByCreatedAtDesc(Long customerId);

  boolean existsByCustomerIdAndTransactionType(
      Long customerId, CustomerFinanceTransactionType transactionType);
}
