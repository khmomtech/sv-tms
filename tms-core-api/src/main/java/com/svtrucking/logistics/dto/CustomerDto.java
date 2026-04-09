package com.svtrucking.logistics.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.svtrucking.logistics.enums.CustomerType;
import com.svtrucking.logistics.enums.CustomerLifecycleStage;
import com.svtrucking.logistics.enums.Status;
import com.svtrucking.logistics.model.Customer;
import java.math.BigDecimal;
import java.time.LocalDate;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@JsonIgnoreProperties(ignoreUnknown = true)
@NoArgsConstructor
@AllArgsConstructor
public class CustomerDto {
  private Long id;
  private String customerCode;
  private CustomerType type;
  private String customerName;
  private String email;
  private String phone;
  private String address;
  private Status status;
  
  // Financial fields
  private BigDecimal creditLimit;
  private String paymentTerms;
  private String currency;
  private BigDecimal currentBalance;
  
  // Lifecycle and business metrics
  private CustomerLifecycleStage lifecycleStage;
  private LocalDate lastOrderDate;
  private Integer totalOrders;
  private BigDecimal totalRevenue;
  private String segment;
  private Long accountManagerId;

  public static CustomerDto fromEntity(Customer customer) {
    CustomerDto dto = new CustomerDto();
    dto.setId(customer.getId());
    dto.setCustomerCode(customer.getCustomerCode());
    dto.setType(customer.getType());
    dto.setCustomerName(customer.getName());
    dto.setEmail(customer.getEmail());
    dto.setPhone(customer.getPhone());
    dto.setAddress(customer.getAddress());
    dto.setStatus(customer.getStatus());
    
    // Financial fields
    dto.setCreditLimit(customer.getCreditLimit());
    dto.setPaymentTerms(customer.getPaymentTerms());
    dto.setCurrency(customer.getCurrency());
    dto.setCurrentBalance(customer.getCurrentBalance());
    
    // Lifecycle fields
    dto.setLifecycleStage(customer.getLifecycleStage());
    dto.setLastOrderDate(customer.getLastOrderDate());
    dto.setTotalOrders(customer.getTotalOrders());
    dto.setTotalRevenue(customer.getTotalRevenue());
    dto.setSegment(customer.getSegment());
    if (customer.getAccountManager() != null) {
      dto.setAccountManagerId(customer.getAccountManager().getId());
    }
    
    return dto;
  }

  public void updateEntity(Customer customer) {
    customer.setCustomerCode(this.customerCode);
    customer.setType(this.type);
    customer.setName(this.customerName);
    customer.setEmail(this.email);
    customer.setPhone(this.phone);
    customer.setAddress(this.address);
    customer.setStatus(this.status);
    
    // Financial fields
    if (this.creditLimit != null) customer.setCreditLimit(this.creditLimit);
    if (this.paymentTerms != null) customer.setPaymentTerms(this.paymentTerms);
    if (this.currency != null) customer.setCurrency(this.currency);
    if (this.currentBalance != null) customer.setCurrentBalance(this.currentBalance);
    
    // Lifecycle fields
    if (this.lifecycleStage != null) customer.setLifecycleStage(this.lifecycleStage);
    if (this.segment != null) customer.setSegment(this.segment);
  }
}
