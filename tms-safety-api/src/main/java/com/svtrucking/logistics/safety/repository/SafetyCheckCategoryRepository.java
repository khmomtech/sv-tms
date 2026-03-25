package com.svtrucking.logistics.safety.repository;

import com.svtrucking.logistics.safety.domain.SafetyCheckCategory;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface SafetyCheckCategoryRepository extends JpaRepository<SafetyCheckCategory, Long> {
  Optional<SafetyCheckCategory> findByCodeIgnoreCase(String code);

  List<SafetyCheckCategory> findByIsActiveTrueOrderBySortOrderAsc();

  List<SafetyCheckCategory> findAllByOrderBySortOrderAsc();

  @Query("select coalesce(max(c.sortOrder), 0) from SafetyCheckCategory c")
  Integer findMaxSortOrder();
}

