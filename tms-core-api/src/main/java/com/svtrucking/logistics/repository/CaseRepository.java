package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.enums.CaseStatus;
import com.svtrucking.logistics.enums.CaseCategory;
import com.svtrucking.logistics.enums.IssueSeverity;
import com.svtrucking.logistics.model.Case;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface CaseRepository extends JpaRepository<Case, Long> {

  Optional<Case> findByCode(String code);

  Optional<Case> findFirstByCodeStartingWithOrderByCodeDesc(String codePrefix);

  Page<Case> findByIsDeletedFalse(Pageable pageable);

  Page<Case> findByStatusAndIsDeletedFalse(CaseStatus status, Pageable pageable);

  Page<Case> findByCategoryAndIsDeletedFalse(CaseCategory category, Pageable pageable);

  Page<Case> findByDriverIdAndIsDeletedFalse(Long driverId, Pageable pageable);

  Page<Case> findByVehicleIdAndIsDeletedFalse(Long vehicleId, Pageable pageable);

  Page<Case> findByAssignedToUserIdAndIsDeletedFalse(Long userId, Pageable pageable);

  List<Case> findByStatusAndIsDeletedFalse(CaseStatus status);

  @Query("""
      SELECT c FROM Case c
      WHERE c.isDeleted = FALSE
        AND (:status IS NULL OR c.status = :status)
        AND (:category IS NULL OR c.category = :category)
        AND (:severity IS NULL OR c.severity = :severity)
        AND (:assignedToUserId IS NULL OR c.assignedToUser.id = :assignedToUserId)
        AND (:driverId IS NULL OR c.driver.id = :driverId)
        AND (:vehicleId IS NULL OR c.vehicle.id = :vehicleId)
        AND (:createdAfter IS NULL OR c.createdAt >= :createdAfter)
        AND (:createdBefore IS NULL OR c.createdAt <= :createdBefore)
      ORDER BY c.createdAt DESC
      """)
  Page<Case> filterCases(
      @Param("status") CaseStatus status,
      @Param("category") CaseCategory category,
      @Param("severity") IssueSeverity severity,
      @Param("assignedToUserId") Long assignedToUserId,
      @Param("driverId") Long driverId,
      @Param("vehicleId") Long vehicleId,
      @Param("createdAfter") LocalDateTime createdAfter,
      @Param("createdBefore") LocalDateTime createdBefore,
      Pageable pageable);

  @Query("""
      SELECT c FROM Case c
      WHERE c.isDeleted = FALSE
        AND c.status != 'CLOSED'
        AND c.slaTargetAt IS NOT NULL
        AND c.slaTargetAt < :now
      ORDER BY c.slaTargetAt ASC
      """)
  List<Case> findOverdueCases(@Param("now") LocalDateTime now);

  @Query("SELECT COUNT(c) FROM Case c WHERE c.status = :status AND c.isDeleted = FALSE")
  long countByStatusAndIsDeletedFalse(@Param("status") CaseStatus status);

  @Query("""
      SELECT c FROM Case c
      WHERE c.isDeleted = FALSE
        AND (LOWER(c.code) LIKE LOWER(CONCAT('%', :searchTerm, '%'))
         OR LOWER(c.title) LIKE LOWER(CONCAT('%', :searchTerm, '%'))
         OR LOWER(c.description) LIKE LOWER(CONCAT('%', :searchTerm, '%')))
      ORDER BY c.createdAt DESC
      """)
  Page<Case> searchCases(@Param("searchTerm") String searchTerm, Pageable pageable);
}
