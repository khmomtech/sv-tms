package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.ImportAudit;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface ImportAuditRepository extends JpaRepository<ImportAudit, Long> {
  Optional<ImportAudit> findByImportId(String importId);
}
