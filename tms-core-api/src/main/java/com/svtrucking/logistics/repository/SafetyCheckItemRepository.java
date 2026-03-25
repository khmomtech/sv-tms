package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.SafetyCheckItem;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface SafetyCheckItemRepository extends JpaRepository<SafetyCheckItem, Long> {
  List<SafetyCheckItem> findBySafetyCheckId(Long safetyCheckId);
}
