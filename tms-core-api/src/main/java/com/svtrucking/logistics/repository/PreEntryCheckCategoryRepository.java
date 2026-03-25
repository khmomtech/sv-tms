package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.PreEntryCheckCategory;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface PreEntryCheckCategoryRepository extends JpaRepository<PreEntryCheckCategory, Long> {
  Optional<PreEntryCheckCategory> findByCodeIgnoreCase(String code);

  List<PreEntryCheckCategory> findByIsActiveTrueOrderBySortOrderAsc();

  List<PreEntryCheckCategory> findAllByOrderBySortOrderAsc();

  @Query("select coalesce(max(c.sortOrder), 0) from PreEntryCheckCategory c")
  Integer findMaxSortOrder();
}
