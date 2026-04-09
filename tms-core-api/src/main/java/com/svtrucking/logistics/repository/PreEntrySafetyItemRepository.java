package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.PreEntrySafetyItem;
import com.svtrucking.logistics.model.PreEntrySafetyItem.SafetyCategory;
import com.svtrucking.logistics.model.PreEntrySafetyItem.SafetyItemStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

/**
 * Repository for PreEntrySafetyItem (individual safety checklist items).
 */
@Repository
public interface PreEntrySafetyItemRepository extends JpaRepository<PreEntrySafetyItem, Long> {

    /**
     * Find all items for a safety check
     */
    List<PreEntrySafetyItem> findBySafetyCheckIdOrderByCreatedAt(Long safetyCheckId);

    /**
     * Find all items with a specific status for a safety check
     */
    @Query("SELECT i FROM PreEntrySafetyItem i WHERE i.safetyCheck.id = :safetyCheckId AND i.status = :status")
    List<PreEntrySafetyItem> findByCheckIdAndStatus(
            @Param("safetyCheckId") Long safetyCheckId,
            @Param("status") SafetyItemStatus status);

    /**
     * Find all failed items for a safety check
     */
    @Query("SELECT i FROM PreEntrySafetyItem i WHERE i.safetyCheck.id = :safetyCheckId AND i.status = 'FAILED'")
    List<PreEntrySafetyItem> findFailedItems(@Param("safetyCheckId") Long safetyCheckId);

    /**
     * Find all conditional (requires override) items for a safety check
     */
    @Query("SELECT i FROM PreEntrySafetyItem i WHERE i.safetyCheck.id = :safetyCheckId AND i.status = 'CONDITIONAL'")
    List<PreEntrySafetyItem> findConditionalItems(@Param("safetyCheckId") Long safetyCheckId);

    /**
     * Find items by category for a safety check
     */
    @Query("SELECT i FROM PreEntrySafetyItem i WHERE i.safetyCheck.id = :safetyCheckId AND i.category = :category")
    List<PreEntrySafetyItem> findByCheckIdAndCategory(
            @Param("safetyCheckId") Long safetyCheckId,
            @Param("category") SafetyCategory category);

    /**
     * Find problematic items (FAILED or CONDITIONAL) across all checks
     */
    @Query("SELECT i FROM PreEntrySafetyItem i WHERE i.status IN ('FAILED', 'CONDITIONAL') ORDER BY i.createdAt DESC")
    List<PreEntrySafetyItem> findProblematicItems();

    /**
     * Find items with photos for a safety check
     */
    @Query("SELECT i FROM PreEntrySafetyItem i WHERE i.safetyCheck.id = :safetyCheckId AND i.photoPath IS NOT NULL")
    List<PreEntrySafetyItem> findItemsWithPhotos(@Param("safetyCheckId") Long safetyCheckId);

    /**
     * Count items by status for a safety check
     */
    @Query("SELECT COUNT(i) FROM PreEntrySafetyItem i WHERE i.safetyCheck.id = :safetyCheckId AND i.status = :status")
    int countByCheckIdAndStatus(@Param("safetyCheckId") Long safetyCheckId, @Param("status") SafetyItemStatus status);

    /**
     * Count failed items for a safety check
     */
    @Query("SELECT COUNT(i) FROM PreEntrySafetyItem i WHERE i.safetyCheck.id = :safetyCheckId AND i.status = 'FAILED'")
    int countFailedItems(@Param("safetyCheckId") Long safetyCheckId);

    /**
     * Delete all items for a safety check.
     */
    void deleteBySafetyCheckId(Long safetyCheckId);
}
