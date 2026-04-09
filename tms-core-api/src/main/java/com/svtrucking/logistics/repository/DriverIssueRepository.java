package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.DriverIssue;
import com.svtrucking.logistics.enums.IssueStatus;
import com.svtrucking.logistics.enums.IssueSeverity;
import com.svtrucking.logistics.enums.IncidentStatus;
import com.svtrucking.logistics.enums.IncidentGroup;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface DriverIssueRepository extends JpaRepository<DriverIssue, Long> {

  Optional<DriverIssue> findByCode(String code);

  Optional<DriverIssue> findFirstByCodeStartingWithOrderByCodeDesc(String codePrefix);

  Page<DriverIssue> findByIsDeletedFalse(Pageable pageable);

  @EntityGraph(attributePaths = { "images", "photos" })
  Page<DriverIssue> findByDriverIdAndIsDeletedFalse(Long driverId, Pageable pageable);

  @EntityGraph(attributePaths = { "images", "photos" })
  Page<DriverIssue> findByDriverIdAndStatusAndIsDeletedFalse(Long driverId, IssueStatus status, Pageable pageable);

  Page<DriverIssue> findByStatusAndIsDeletedFalse(IssueStatus status, Pageable pageable);

  Page<DriverIssue> findBySeverityAndIsDeletedFalse(IssueSeverity severity, Pageable pageable);

  List<DriverIssue> findByStatusAndIsDeletedFalse(IssueStatus status);

  @Query("""
          SELECT i FROM DriverIssue i
          WHERE i.isDeleted = FALSE
            AND (:status IS NULL OR i.status = :status)
            AND (:severity IS NULL OR i.severity = :severity)
            AND (:driverId IS NULL OR i.driver.id = :driverId)
            AND (:vehicleId IS NULL OR i.vehicle.id = :vehicleId)
            AND (:reportedAfter IS NULL OR i.reportedAt >= :reportedAfter)
            AND (:reportedBefore IS NULL OR i.reportedAt <= :reportedBefore)
      """)
  Page<DriverIssue> filterIssues(
      @Param("status") IssueStatus status,
      @Param("severity") IssueSeverity severity,
      @Param("driverId") Long driverId,
      @Param("vehicleId") Long vehicleId,
      @Param("reportedAfter") LocalDateTime reportedAfter,
      @Param("reportedBefore") LocalDateTime reportedBefore,
      Pageable pageable);

  @Query("""
          SELECT i FROM DriverIssue i
          WHERE i.isDeleted = FALSE
            AND i.status IN ('OPEN', 'IN_PROGRESS')
            AND i.severity IN ('HIGH', 'CRITICAL')
          ORDER BY i.severity DESC, i.reportedAt ASC
      """)
  List<DriverIssue> findUrgentIssues();

  @Query("""
          SELECT i FROM DriverIssue i
          WHERE i.isDeleted = FALSE
            AND (:incidentStatus IS NULL OR i.incidentStatus = :incidentStatus)
            AND (:incidentGroup IS NULL OR i.incidentGroup = :incidentGroup)
            AND (:severity IS NULL OR i.severity = :severity)
            AND (:driverId IS NULL OR i.driver.id = :driverId)
            AND (:vehicleId IS NULL OR i.vehicle.id = :vehicleId)
            AND (:reportedAfter IS NULL OR i.reportedAt >= :reportedAfter)
            AND (:reportedBefore IS NULL OR i.reportedAt <= :reportedBefore)
          ORDER BY i.reportedAt DESC
      """)
  Page<DriverIssue> filterIncidentsByNew(
      @Param("incidentStatus") IncidentStatus incidentStatus,
      @Param("incidentGroup") IncidentGroup incidentGroup,
      @Param("severity") IssueSeverity severity,
      @Param("driverId") Long driverId,
      @Param("vehicleId") Long vehicleId,
      @Param("reportedAfter") LocalDateTime reportedAfter,
      @Param("reportedBefore") LocalDateTime reportedBefore,
      Pageable pageable);

  Long countByStatusAndIsDeletedFalse(IssueStatus status);

  Long countByDriverIdAndStatusAndIsDeletedFalse(Long driverId, IssueStatus status);

  /**
   * Returns paginated non-deleted incidents linked to dispatches that belong to
   * the given customer, ordered most-recent-first.
   * Used by the customer-facing incident view.
   */
  @Query("""
          SELECT i FROM DriverIssue i
          WHERE i.isDeleted = FALSE
            AND i.dispatch IS NOT NULL
            AND i.dispatch.customer.id = :customerId
          ORDER BY i.reportedAt DESC
      """)
  Page<DriverIssue> findByDispatchCustomerId(
      @Param("customerId") Long customerId, Pageable pageable);
}
