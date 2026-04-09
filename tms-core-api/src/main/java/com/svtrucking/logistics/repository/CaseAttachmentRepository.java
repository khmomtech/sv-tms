package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.CaseAttachment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface CaseAttachmentRepository extends JpaRepository<CaseAttachment, Long> {

  List<CaseAttachment> findByCaseEntityIdOrderByUploadedAtDesc(Long caseId);

  @Query("SELECT COUNT(a) FROM CaseAttachment a WHERE a.caseEntity.id = :caseId")
  long countByCaseId(@Param("caseId") Long caseId);

  @Query("SELECT SUM(a.fileSize) FROM CaseAttachment a WHERE a.caseEntity.id = :caseId")
  Long sumFileSizeByCaseId(@Param("caseId") Long caseId);
}
