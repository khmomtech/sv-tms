package com.svtrucking.logistics.safety.repository;

import com.svtrucking.logistics.safety.domain.SafetyCheckAudit;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface SafetyCheckAuditRepository extends JpaRepository<SafetyCheckAudit, Long> {
  List<SafetyCheckAudit> findBySafetyCheckIdOrderByCreatedAtDesc(Long safetyCheckId);
}

