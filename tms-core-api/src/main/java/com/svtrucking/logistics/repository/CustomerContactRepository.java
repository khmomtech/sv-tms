package com.svtrucking.logistics.repository;

import java.util.List;

import com.svtrucking.logistics.model.CustomerContact;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface CustomerContactRepository extends JpaRepository<CustomerContact, Long> {

    /**
     * Find all contacts for a specific customer
     */
    List<CustomerContact> findByCustomerId(Long customerId);

    /**
     * Find all active contacts for a customer
     */
    List<CustomerContact> findByCustomerIdAndIsActiveTrue(Long customerId);

    /**
     * Find the primary contact for a customer
     */
    @Query("SELECT c FROM CustomerContact c WHERE c.customer.id = :customerId AND c.isPrimary = true")
    CustomerContact findPrimaryContactByCustomerId(@Param("customerId") Long customerId);

    /**
     * Count contacts for a customer
     */
    long countByCustomerId(Long customerId);

    /**
     * Search contacts by name or email
     */
    @Query("SELECT c FROM CustomerContact c WHERE c.customer.id = :customerId " +
           "AND (LOWER(c.fullName) LIKE LOWER(CONCAT('%', :query, '%')) " +
           "OR LOWER(c.email) LIKE LOWER(CONCAT('%', :query, '%')))")
    List<CustomerContact> searchByCustomerIdAndQuery(@Param("customerId") Long customerId, 
                                                      @Param("query") String query);
}
