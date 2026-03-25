package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.CustomerActivity;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface CustomerActivityRepository extends JpaRepository<CustomerActivity, Long> {
    
    Page<CustomerActivity> findByCustomerIdOrderByCreatedAtDesc(Long customerId, Pageable pageable);
    
    long countByCustomerId(Long customerId);
}
