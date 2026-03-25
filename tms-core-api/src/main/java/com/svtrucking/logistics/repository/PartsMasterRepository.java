package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.PartsMaster;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.List;
import java.util.Optional;

public interface PartsMasterRepository extends JpaRepository<PartsMaster, Long> {

  Optional<PartsMaster> findByPartCode(String partCode);

  Page<PartsMaster> findByActiveAndIsDeletedFalse(Boolean active, Pageable pageable);

  Page<PartsMaster> findByCategoryAndActiveAndIsDeletedFalse(
      String category, Boolean active, Pageable pageable);

  List<PartsMaster> findByActiveAndIsDeletedFalse(Boolean active);

  @Query(
      """
        SELECT p FROM PartsMaster p
        WHERE p.isDeleted = FALSE
          AND p.active = TRUE
          AND (:keyword IS NULL OR LOWER(p.partName) LIKE LOWER(CONCAT('%', :keyword, '%'))
               OR LOWER(p.partCode) LIKE LOWER(CONCAT('%', :keyword, '%')))
          AND (:category IS NULL OR p.category = :category)
    """)
  Page<PartsMaster> searchParts(
      @Param("keyword") String keyword, @Param("category") String category, Pageable pageable);

  @Query("SELECT DISTINCT p.category FROM PartsMaster p WHERE p.isDeleted = FALSE AND p.active = TRUE ORDER BY p.category")
  List<String> findDistinctCategories();

  Long countByActiveAndIsDeletedFalse(Boolean active);
}
