package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.SafetyCheckAudit;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface SafetyCheckAuditRepository extends JpaRepository<SafetyCheckAudit, Long> {
  List<SafetyCheckAudit> findBySafetyCheckIdOrderByCreatedAtDesc(Long safetyCheckId);
}
