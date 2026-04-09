package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.Address;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface AddressRepository extends JpaRepository<Address, Long> {
  List<Address> findByCustomerId(Long customerId); //  Find addresses for a specific customer
}
