package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.DispatchApprovalHistory;
import com.svtrucking.logistics.model.DispatchApprovalHistory.ApprovalAction;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

/**
 * Repository for DispatchApprovalHistory audit trail.
 */
@Repository
public interface DispatchApprovalHistoryRepository extends JpaRepository<DispatchApprovalHistory, Long> {

    /**
     * Find all approval history records for a dispatch, ordered by creation date
     */
    List<DispatchApprovalHistory> findByDispatchIdOrderByCreatedAtDesc(Long dispatchId);

    /**
     * Find the latest approval decision for a dispatch
     */
    @Query("SELECT h FROM DispatchApprovalHistory h WHERE h.dispatch.id = :dispatchId ORDER BY h.createdAt DESC LIMIT 1")
    Optional<DispatchApprovalHistory> findLatestByDispatchId(@Param("dispatchId") Long dispatchId);

    /**
     * Count rejections for a dispatch (for tracking rework attempts)
     */
    @Query("SELECT COUNT(h) FROM DispatchApprovalHistory h WHERE h.dispatch.id = :dispatchId AND h.action = 'REJECTED'")
    int countRejectionsByDispatchId(@Param("dispatchId") Long dispatchId);

    /**
     * Find all rejections for a dispatch
     */
    List<DispatchApprovalHistory> findByDispatchIdAndAction(Long dispatchId, ApprovalAction action);

    /**
     * Find approval history within a time range
     */
    @Query("SELECT h FROM DispatchApprovalHistory h WHERE h.dispatch.id = :dispatchId AND h.createdAt BETWEEN :startTime AND :endTime ORDER BY h.createdAt")
    List<DispatchApprovalHistory> findByDispatchIdAndTimeRange(
            @Param("dispatchId") Long dispatchId,
            @Param("startTime") LocalDateTime startTime,
            @Param("endTime") LocalDateTime endTime);

    /**
     * Find all approvals by a specific user
     */
    @Query("SELECT h FROM DispatchApprovalHistory h WHERE h.reviewedBy.id = :userId AND h.createdAt >= :since ORDER BY h.createdAt DESC")
    List<DispatchApprovalHistory> findByReviewedUserIdSince(@Param("userId") Long userId,
            @Param("since") LocalDateTime since);

    /**
     * Count approvals/rejections by action type
     */
    @Query("SELECT COUNT(h) FROM DispatchApprovalHistory h WHERE h.dispatch.id = :dispatchId AND h.action = :action")
    int countByDispatchIdAndAction(@Param("dispatchId") Long dispatchId, @Param("action") ApprovalAction action);
}
