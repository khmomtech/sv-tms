package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.CustomerAudit;
import com.svtrucking.logistics.model.CustomerAudit.AuditAction;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

/**
 * Repository for Customer audit trail operations
 */
@Repository
public interface CustomerAuditRepository extends JpaRepository<CustomerAudit, Long> {
    
    /**
     * Find all audit records for a specific customer
     */
    Page<CustomerAudit> findByCustomerIdOrderByChangedAtDesc(Long customerId, Pageable pageable);
    
    /**
     * Find audit records by action type
     */
    List<CustomerAudit> findByActionOrderByChangedAtDesc(AuditAction action);
    
    /**
     * Find audit records within date range
     */
    @Query("SELECT a FROM CustomerAudit a WHERE a.changedAt BETWEEN :startDate AND :endDate ORDER BY a.changedAt DESC")
    List<CustomerAudit> findByDateRange(LocalDateTime startDate, LocalDateTime endDate);
    
    /**
     * Find all changes by a specific user
     */
    List<CustomerAudit> findByChangedByOrderByChangedAtDesc(String changedBy);
    
    /**
     * Count audit records for a customer
     */
    long countByCustomerId(Long customerId);
}
