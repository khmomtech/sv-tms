package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.CompanyCustomer;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface CompanyCustomerRepository extends JpaRepository<CompanyCustomer, Long> {}
