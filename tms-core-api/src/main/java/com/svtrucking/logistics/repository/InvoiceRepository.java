package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.Invoice;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface InvoiceRepository extends JpaRepository<Invoice, Long> {
  Optional<Invoice> findByWorkOrderId(Long workOrderId);
}
