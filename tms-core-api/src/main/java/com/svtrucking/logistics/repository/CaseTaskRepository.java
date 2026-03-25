package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.enums.CaseTaskStatus;
import com.svtrucking.logistics.model.CaseTask;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface CaseTaskRepository extends JpaRepository<CaseTask, Long> {

  List<CaseTask> findByCaseEntityId(Long caseId);

  List<CaseTask> findByCaseEntityIdOrderByCreatedAtDesc(Long caseId);

  List<CaseTask> findByCaseEntityIdAndStatus(Long caseId, CaseTaskStatus status);

  List<CaseTask> findByOwnerUserIdAndStatus(Long userId, CaseTaskStatus status);

  @Query("SELECT t FROM CaseTask t WHERE t.ownerUser.id = :userId AND t.dueAt < :now AND t.status != 'DONE'")
  List<CaseTask> findOverdueTasksByUser(@Param("userId") Long userId, @Param("now") LocalDateTime now);

  @Query("SELECT COUNT(t) FROM CaseTask t WHERE t.caseEntity.id = :caseId AND t.status = :status")
  long countByCaseIdAndStatus(@Param("caseId") Long caseId, @Param("status") CaseTaskStatus status);

  @Query("SELECT COUNT(t) FROM CaseTask t WHERE t.caseEntity.id = :caseId")
  long countByCaseId(@Param("caseId") Long caseId);
}
