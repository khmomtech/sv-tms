package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.SafetyCheckAttachment;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface SafetyCheckAttachmentRepository extends JpaRepository<SafetyCheckAttachment, Long> {
  List<SafetyCheckAttachment> findBySafetyCheckId(Long safetyCheckId);
}
