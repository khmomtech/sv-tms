package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.enums.VendorQuotationStatus;
import com.svtrucking.logistics.model.VendorQuotation;
import java.util.Optional;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface VendorQuotationRepository extends JpaRepository<VendorQuotation, Long> {

  Optional<VendorQuotation> findByWorkOrderId(Long workOrderId);

  @Query(
      "SELECT q FROM VendorQuotation q WHERE "
          + "(:status IS NULL OR q.status = :status) "
          + "AND (:vendorId IS NULL OR q.vendor.id = :vendorId)")
  Page<VendorQuotation> search(
      @Param("status") VendorQuotationStatus status, @Param("vendorId") Long vendorId, Pageable pageable);
}

