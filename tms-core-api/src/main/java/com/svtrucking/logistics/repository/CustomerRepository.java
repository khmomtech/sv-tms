package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.Customer;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

@Repository
public interface CustomerRepository
    extends JpaRepository<Customer, Long>, JpaSpecificationExecutor<Customer> {

  Page<Customer> findAll(Pageable pageable);

  List<Customer>
      findByNameContainingIgnoreCaseOrPhoneContainingIgnoreCaseOrEmailContainingIgnoreCase(
          String name, String phone, String email);

  Optional<Customer> findByCustomerCode(String customerCode);

  @Query("select c.customerCode from Customer c where c.customerCode is not null")
  Set<String> findAllCodes();
  
  // ==================== Duplicate Detection Methods ====================
  boolean existsByCustomerCode(String customerCode);
  
  boolean existsByCustomerCodeAndIdNot(String customerCode, Long id);
  
  Optional<Customer> findByPhone(String phone);
  
  Optional<Customer> findByEmail(String email);
  
  boolean existsByPhone(String phone);
  
  boolean existsByEmail(String email);
  
  boolean existsByPhoneAndIdNot(String phone, Long id);
  
  boolean existsByEmailAndIdNot(String email, Long id);
  
  // ==================== Soft Delete Support ====================
  @Query("SELECT c FROM Customer c WHERE c.deletedAt IS NULL")
  Page<Customer> findAllActive(Pageable pageable);
  
  @Query("SELECT c FROM Customer c WHERE c.deletedAt IS NULL AND c.id = :id")
  Optional<Customer> findActiveById(Long id);
  
  @Query("SELECT c FROM Customer c WHERE c.deletedAt IS NULL AND " +
         "(LOWER(c.name) LIKE LOWER(CONCAT('%', :search, '%')) OR " +
         "LOWER(c.phone) LIKE LOWER(CONCAT('%', :search, '%')) OR " +
         "LOWER(c.email) LIKE LOWER(CONCAT('%', :search, '%')))")
  List<Customer> searchActive(String search);
  
  // ==================== Business Metrics ====================
  @Query("SELECT COUNT(c) FROM Customer c WHERE c.deletedAt IS NULL AND c.lifecycleStage = :stage")
  long countByLifecycleStage(com.svtrucking.logistics.enums.CustomerLifecycleStage stage);
  
  @Query("SELECT c FROM Customer c WHERE c.deletedAt IS NULL AND c.currentBalance > :threshold ORDER BY c.currentBalance DESC")
  List<Customer> findCustomersWithHighBalance(java.math.BigDecimal threshold, Pageable pageable);
}
