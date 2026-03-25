package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.CustomerAddress;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface CustomerAddressRepository extends JpaRepository<CustomerAddress, Long> {

  @Query("select a.name from CustomerAddress a where a.name is not null")
  Set<String> findAllNames();

  // Fetch all pickup or drop locations
  List<CustomerAddress> findByType(String type);

  // Search locations by name (case-insensitive)
  List<CustomerAddress> findByNameContainingIgnoreCase(String name);

  // Fetch addresses by Customer ID
  List<CustomerAddress> findByCustomerId(Long customerId);

  @Query("""
      select a from CustomerAddress a
      where (:customerId is null or a.customer.id = :customerId)
        and (:type is null or lower(a.type) like concat('%', lower(:type), '%'))
        and (
          :search is null or
          lower(a.name) like concat('%', lower(:search), '%') or
          lower(a.address) like concat('%', lower(:search), '%') or
          lower(a.city) like concat('%', lower(:search), '%')
        )
      """)
  Page<CustomerAddress> search(
      @Param("customerId") Long customerId,
      @Param("search") String search,
      @Param("type") String type,
      Pageable pageable);

  Optional<CustomerAddress> findByNameIgnoreCase(String name);

  @SuppressWarnings("checkstyle:MethodName")
  boolean existsByCustomer_IdAndNameIgnoreCase(Long customerId, String name);
}
