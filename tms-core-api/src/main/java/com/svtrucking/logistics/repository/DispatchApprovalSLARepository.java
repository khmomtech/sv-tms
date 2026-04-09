package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.DispatchApprovalSLA;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

/**
 * Repository for DispatchApprovalSLA tracking.
 * Enables SLA measurement and breach reporting.
 */
@Repository
public interface DispatchApprovalSLARepository extends JpaRepository<DispatchApprovalSLA, Long> {

    /**
     * Find SLA record by dispatch ID
     */
    Optional<DispatchApprovalSLA> findByDispatchId(Long dispatchId);

    /**
     * Find all BREACHED SLAs
     */
    @Query("SELECT s FROM DispatchApprovalSLA s WHERE s.slaStatus = 'BREACHED' ORDER BY s.actualMinutes DESC")
    List<DispatchApprovalSLA> findAllSLABreaches();

    /**
     * Find SLAs delivered within a time range
     */
    @Query("SELECT s FROM DispatchApprovalSLA s WHERE s.deliveredAt BETWEEN :startTime AND :endTime ORDER BY s.actualMinutes DESC NULLS LAST")
    List<DispatchApprovalSLA> findByDeliveryTimeRange(
            @Param("startTime") LocalDateTime startTime,
            @Param("endTime") LocalDateTime endTime);

    /**
     * Find BREACHED SLAs within a time range
     */
    @Query("SELECT s FROM DispatchApprovalSLA s WHERE s.slaStatus = 'BREACHED' AND s.deliveredAt BETWEEN :startTime AND :endTime ORDER BY s.actualMinutes DESC")
    List<DispatchApprovalSLA> findBreachedSLAsByTimeRange(
            @Param("startTime") LocalDateTime startTime,
            @Param("endTime") LocalDateTime endTime);

    /**
     * Find pending approvals (not yet approved)
     */
    @Query("SELECT s FROM DispatchApprovalSLA s WHERE s.status IN ('PENDING_APPROVAL') ORDER BY s.deliveredAt ASC")
    List<DispatchApprovalSLA> findPendingApprovals();

    /**
     * Calculate average SLA minutes for completed approvals
     */
    @Query("SELECT AVG(s.actualMinutes) FROM DispatchApprovalSLA s WHERE s.status = 'APPROVED' AND s.approvedAt BETWEEN :startTime AND :endTime")
    Double getAverageApprovalMinutes(
            @Param("startTime") LocalDateTime startTime,
            @Param("endTime") LocalDateTime endTime);

    /**
     * Count SLA breaches in a time range
     */
    @Query("SELECT COUNT(s) FROM DispatchApprovalSLA s WHERE s.slaStatus = 'BREACHED' AND s.approvedAt BETWEEN :startTime AND :endTime")
    int countSLABreachesInRange(
            @Param("startTime") LocalDateTime startTime,
            @Param("endTime") LocalDateTime endTime);

    /**
     * Find dispatches with actual minutes exceeding target by percentage
     */
    @Query("SELECT s FROM DispatchApprovalSLA s WHERE s.actualMinutes > (s.slaTargetMinutes * 1.5) ORDER BY s.actualMinutes DESC")
    List<DispatchApprovalSLA> findSignificantlyBreachedSLAs();
}
