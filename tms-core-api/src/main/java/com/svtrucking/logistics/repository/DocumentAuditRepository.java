package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.DocumentAudit;
import com.svtrucking.logistics.model.DriverDocument;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface DocumentAuditRepository extends JpaRepository<DocumentAudit, Long> {
    Optional<DocumentAudit> findByDocumentId(Long documentId);
    Optional<DocumentAudit> findByDocument(DriverDocument document);
    List<DocumentAudit> findByThumbnailUrlIsNullAndThumbnailAttemptedFalse();
}
