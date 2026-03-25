package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.enums.DispatchStatus;
import com.svtrucking.logistics.model.Dispatch;
import java.time.LocalDateTime;
import java.util.EnumSet;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface DispatchRepository
                extends JpaRepository<Dispatch, Long>,
                JpaSpecificationExecutor<Dispatch> { // enable Specifications

        // --- Simple finders ---


        Page<Dispatch> findByVehicleId(Long vehicleId, Pageable pageable);

        Page<Dispatch> findByStatus(DispatchStatus status, Pageable pageable);

        List<Dispatch> findByStatusIn(java.util.Collection<DispatchStatus> statuses);

        Page<Dispatch> findByStartTimeBetween(LocalDateTime start, LocalDateTime end, Pageable pageable);

        Page<Dispatch> findByDriverIdAndStatus(Long driverId, DispatchStatus status, Pageable pageable);

        // Public Tracking API - find dispatches by TransportOrder (eager load
        // driver/vehicle)
        @EntityGraph(attributePaths = { "driver", "vehicle" })
        List<Dispatch> findByTransportOrderOrderByCreatedDateDesc(
                        com.svtrucking.logistics.model.TransportOrder transportOrder);

        // Exact match
        Dispatch findByRouteCode(String routeCode);

        @EntityGraph(attributePaths = {
                        "driver",
                        "vehicle",
                        "transportOrder",
                        "transportOrder.pickupAddress",
                        "transportOrder.dropAddress",
                        "loadProof"
        })
        @Query("SELECT d FROM Dispatch d")
        Page<Dispatch> findAllWithDetails(Pageable pageable);

        // --- Dynamic filter (legacy JPQL version; optional if you now use
        // Specifications) ---
        @EntityGraph(attributePaths = {
                        "driver",
                        "vehicle",
                        "transportOrder",
                        "transportOrder.pickupAddress",
                        "transportOrder.dropAddress",
                        "loadProof"
        })
        @Query("""
                        SELECT d FROM Dispatch d
                        WHERE (:driverId IS NULL OR d.driver.id = :driverId)
                          AND (:vehicleId IS NULL OR d.vehicle.id = :vehicleId)
                          AND (:status IS NULL OR d.status = :status)
                          AND (:start IS NULL OR d.startTime >= :start)
                          AND (:end IS NULL OR d.startTime <= :end)
                        """)
        Page<Dispatch> filterDispatches(
                        @Param("driverId") Long driverId,
                        @Param("vehicleId") Long vehicleId,
                        @Param("status") DispatchStatus status,
                        @Param("start") LocalDateTime start,
                        @Param("end") LocalDateTime end,
                        Pageable pageable);

        // Note: Use findByDriverIdAndStartTimeBetween(Pageable) instead.
        // Multiple FETCH JOINs on OneToMany relationships cause cartesian product
        // (MultipleBagFetchException).
        // The EntityGraph approach with @BatchSize is safer and supports pagination.

        @EntityGraph(attributePaths = {
                        "driver",
                        "vehicle",
                        "transportOrder",
                        "transportOrder.pickupAddress",
                        "transportOrder.dropAddress",
                        "loadProof"
        })
        Page<Dispatch> findByDriverIdAndStartTimeBetween(
                        Long driverId, LocalDateTime startTime, LocalDateTime endTime, Pageable pageable);

        @EntityGraph(attributePaths = {
                        "driver",
                        "vehicle",
                        "transportOrder",
                        "transportOrder.pickupAddress",
                        "transportOrder.dropAddress",
                        "loadProof"
        })
        Page<Dispatch> findByDriverId(Long driverId, Pageable pageable);

        @EntityGraph(attributePaths = {
                        "driver",
                        "vehicle",
                        "transportOrder",
                        "transportOrder.customer",
                        "transportOrder.pickupAddress",
                        "transportOrder.dropAddress",
                        "loadProof",
                        "unloadProof",
                        "createdBy"
        })
        @Query("SELECT d FROM Dispatch d WHERE d.id = :id")
        Optional<Dispatch> findByIdWithActionDetails(@Param("id") Long id);

        // --- Last routeCode with prefix ---
        // Use JPQL with ROW_NUMBER for database-agnostic ordering
        @Query("""
                        SELECT d.routeCode FROM Dispatch d
                        WHERE d.routeCode LIKE CONCAT(:prefix, '-%')
                        ORDER BY d.routeCode DESC
                        """)
        Optional<String> findLastRouteCodeStartingWith(@Param("prefix") String prefix);

        // Alternative (entity return, no native, let service map to String):
        // Optional<Dispatch> findTopByRouteCodeStartingWithOrderByRouteCodeDesc(String
        // prefix);

        // --- Counts / tops ---

        @Query("SELECT COUNT(d) FROM Dispatch d WHERE d.status = :status")
        int countByStatus(@Param("status") DispatchStatus status); // no need for FQN

        int countByStatusNotIn(List<DispatchStatus> excludedStatuses);

        Optional<Dispatch> findTopByDriverIdAndStatusInOrderByUpdatedDateDesc(
                        Long driverId, List<DispatchStatus> statuses);

        Optional<Dispatch> findTopByDriverIdAndStatusInOrderByIdDesc(
                        Long driverId, EnumSet<DispatchStatus> statuses);

        // Recent by driver + statuses
        Page<Dispatch> findByDriverIdAndStatusIn(
                        Long driverId, List<DispatchStatus> statuses, Pageable pageable);

        // Validator support methods
        List<Dispatch> findByDriverIdAndStatusIn(Long driverId, EnumSet<DispatchStatus> statuses);

        List<Dispatch> findByDriverIdAndStatusInAndIdNot(Long driverId, EnumSet<DispatchStatus> statuses,
                        Long excludeId);

        List<Dispatch> findByVehicleIdAndStatusIn(Long vehicleId, EnumSet<DispatchStatus> statuses);

        @Query("SELECT COUNT(d) FROM Dispatch d WHERE d.status IN :statuses")
        long countByStatusIn(@Param("statuses") List<DispatchStatus> statuses);

        List<Dispatch> findByVehicleIdAndStatusInAndIdNot(Long vehicleId, EnumSet<DispatchStatus> statuses,
                        Long excludeId);
}
