package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.CustomerBillToAddress;
import java.util.List;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface CustomerBillToAddressRepository extends JpaRepository<CustomerBillToAddress, Long> {
  List<CustomerBillToAddress> findByCustomerId(Long customerId);

  @Query("""
      select b from CustomerBillToAddress b
      where (:customerId is null or b.customer.id = :customerId)
        and (
          :search is null or
          lower(b.name) like concat('%', lower(:search), '%') or
          lower(b.address) like concat('%', lower(:search), '%') or
          lower(b.city) like concat('%', lower(:search), '%') or
          lower(b.email) like concat('%', lower(:search), '%') or
          lower(b.taxId) like concat('%', lower(:search), '%')
        )
      """)
  Page<CustomerBillToAddress> search(
      @Param("customerId") Long customerId,
      @Param("search") String search,
      Pageable pageable);
}
