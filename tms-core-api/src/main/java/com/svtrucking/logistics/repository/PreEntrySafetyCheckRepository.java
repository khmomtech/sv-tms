package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.PreEntrySafetyCheck;
import com.svtrucking.logistics.enums.PreEntrySafetyStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

/**
 * Repository for PreEntrySafetyCheck (pre-entry gate safety inspections).
 * Different from PreLoadingSafetyCheckRepository which is for warehouse loading
 * checks.
 */
@Repository
public interface PreEntrySafetyCheckRepository extends JpaRepository<PreEntrySafetyCheck, Long> {

    /**
     * Find pre-entry safety check for a specific dispatch
     */
    Optional<PreEntrySafetyCheck> findByDispatchId(Long dispatchId);

    /**
     * Find all FAILED safety checks for a vehicle on a given date
     */
    @Query("SELECT p FROM PreEntrySafetyCheck p WHERE p.vehicle.id = :vehicleId AND p.checkDate = :checkDate AND p.status = 'FAILED'")
    List<PreEntrySafetyCheck> findFailedChecksByVehicleAndDate(
            @Param("vehicleId") Long vehicleId,
            @Param("checkDate") LocalDate checkDate);

    /**
     * Find all CONDITIONAL checks awaiting supervisor override
     */
    @Query("SELECT p FROM PreEntrySafetyCheck p WHERE p.status = 'CONDITIONAL' AND p.overrideApprovedAt IS NULL ORDER BY p.checkedAt ASC")
    List<PreEntrySafetyCheck> findPendingConditionalOverrides();

    /**
     * Find safety checks by warehouse code
     */
    List<PreEntrySafetyCheck> findByWarehouseCodeAndCheckDateOrderByCheckedAtDesc(String warehouseCode,
            LocalDate checkDate);

    /**
     * Find safety checks by vehicle and status
     */
    @Query("SELECT p FROM PreEntrySafetyCheck p WHERE p.vehicle.id = :vehicleId AND p.status = :status ORDER BY p.createdAt DESC")
    List<PreEntrySafetyCheck> findByVehicleAndStatus(
            @Param("vehicleId") Long vehicleId,
            @Param("status") PreEntrySafetyStatus status);

    /**
     * Find safety checks by driver and status
     */
    @Query("SELECT p FROM PreEntrySafetyCheck p WHERE p.driver.id = :driverId AND p.status = :status ORDER BY p.createdAt DESC")
    List<PreEntrySafetyCheck> findByDriverAndStatus(
            @Param("driverId") Long driverId,
            @Param("status") PreEntrySafetyStatus status);

    /**
     * Count failed checks for a vehicle since a specific date
     */
    @Query("SELECT COUNT(p) FROM PreEntrySafetyCheck p WHERE p.vehicle.id = :vehicleId AND p.checkDate >= :sinceDate AND p.status = 'FAILED'")
    int countRecentFailures(@Param("vehicleId") Long vehicleId, @Param("sinceDate") LocalDate sinceDate);

    /**
     * Find safety checks that need recheck (FAILED or CONDITIONAL without override)
     */
    @Query("SELECT p FROM PreEntrySafetyCheck p WHERE (p.status = 'FAILED' OR (p.status = 'CONDITIONAL' AND p.overrideApprovedAt IS NULL)) ORDER by p.checkedAt DESC")
    List<PreEntrySafetyCheck> findChecksNeedingRework();

    /**
     * Find passed checks for a dispatch
     */
    @Query("SELECT p FROM PreEntrySafetyCheck p WHERE p.dispatch.id = :dispatchId AND p.status = 'PASSED'")
    Optional<PreEntrySafetyCheck> findPassedCheckByDispatchId(@Param("dispatchId") Long dispatchId);

    @Query("""
            SELECT p
            FROM PreEntrySafetyCheck p
            JOIN FETCH p.dispatch d
            LEFT JOIN FETCH p.vehicle v
            LEFT JOIN FETCH p.driver dr
            WHERE (:status IS NULL OR p.status = :status)
              AND (:warehouseCode IS NULL OR :warehouseCode = '' OR LOWER(p.warehouseCode) = LOWER(:warehouseCode))
              AND (:fromDate IS NULL OR p.checkDate >= :fromDate)
              AND (:toDate IS NULL OR p.checkDate <= :toDate)
            ORDER BY p.createdAt DESC
            """)
    List<PreEntrySafetyCheck> findForList(
            @Param("status") PreEntrySafetyStatus status,
            @Param("warehouseCode") String warehouseCode,
            @Param("fromDate") LocalDate fromDate,
            @Param("toDate") LocalDate toDate);

    @Query("""
            SELECT p
            FROM PreEntrySafetyCheck p
            JOIN FETCH p.dispatch d
            LEFT JOIN FETCH p.vehicle v
            LEFT JOIN FETCH p.driver dr
            WHERE (:status IS NULL OR p.status = :status)
              AND (:warehouseCode IS NULL OR :warehouseCode = '' OR LOWER(p.warehouseCode) = LOWER(:warehouseCode))
              AND (:fromDate IS NULL OR p.checkDate >= :fromDate)
              AND (:toDate IS NULL OR p.checkDate <= :toDate)
              AND p.dispatch.id IN :dispatchIds
            ORDER BY p.createdAt DESC
            """)
    List<PreEntrySafetyCheck> findForListByDispatchIds(
            @Param("status") PreEntrySafetyStatus status,
            @Param("warehouseCode") String warehouseCode,
            @Param("fromDate") LocalDate fromDate,
            @Param("toDate") LocalDate toDate,
            @Param("dispatchIds") List<Long> dispatchIds);
}
