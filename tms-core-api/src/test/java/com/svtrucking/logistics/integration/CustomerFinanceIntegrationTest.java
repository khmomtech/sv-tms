package com.svtrucking.logistics.integration;

import static org.assertj.core.api.Assertions.assertThat;

import com.svtrucking.logistics.dto.CustomerFinanceTransactionDto;
import com.svtrucking.logistics.enums.CustomerFinanceTransactionType;
import com.svtrucking.logistics.model.Customer;
import com.svtrucking.logistics.repository.CustomerRepository;
import com.svtrucking.logistics.service.CustomerService;
import java.math.BigDecimal;
import java.util.List;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest
@ActiveProfiles("test")
class CustomerFinanceIntegrationTest {

  @Autowired private CustomerRepository customerRepository;
  @Autowired private CustomerService customerService;

  private Long customerId;

  @BeforeEach
  void setUp() {
    Customer customer = new Customer();
    customer.setName("Finance Customer " + System.nanoTime());
    customer.setCustomerCode("CF" + System.nanoTime());
    customer.setPhone("+855123" + (System.nanoTime() % 100000));
    customer.setCurrentBalance(BigDecimal.ZERO);
    customer.setCreditLimit(new BigDecimal("1000.00"));
    customer = customerRepository.save(customer);
    customerId = customer.getId();
  }

  @Test
  @DisplayName("opening balance, credit note, and debit note update customer balance and history")
  void financeTransactionsUpdateBalanceAndHistory() {
    CustomerFinanceTransactionDto opening =
        customerService.applyOpeningBalance(
            customerId, new BigDecimal("150.00"), "OPEN-1", "Initial balance", null);

    CustomerFinanceTransactionDto debit =
        customerService.applyDebitNote(
            customerId, new BigDecimal("25.00"), "DB-1", "Manual charge", null);

    CustomerFinanceTransactionDto credit =
        customerService.applyCreditNote(
            customerId, new BigDecimal("10.00"), "CR-1", "Approved discount", null);

    Customer customer = customerRepository.findById(customerId).orElseThrow();
    List<CustomerFinanceTransactionDto> history = customerService.getFinanceTransactions(customerId);

    assertThat(opening.getTransactionType()).isEqualTo(CustomerFinanceTransactionType.OPENING_BALANCE);
    assertThat(debit.getBalanceAfter()).isEqualByComparingTo("175.00");
    assertThat(credit.getBalanceAfter()).isEqualByComparingTo("165.00");
    assertThat(customer.getCurrentBalance()).isEqualByComparingTo("165.00");
    assertThat(history).hasSize(3);
    assertThat(history.get(0).getTransactionType()).isEqualTo(CustomerFinanceTransactionType.CREDIT_NOTE);
    assertThat(history.get(1).getTransactionType()).isEqualTo(CustomerFinanceTransactionType.DEBIT_NOTE);
    assertThat(history.get(2).getTransactionType()).isEqualTo(CustomerFinanceTransactionType.OPENING_BALANCE);
  }
}
