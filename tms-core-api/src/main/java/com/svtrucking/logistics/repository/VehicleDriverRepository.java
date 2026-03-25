package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.VehicleDriver;
import java.time.LocalDateTime;
import java.util.List;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface VehicleDriverRepository extends JpaRepository<VehicleDriver, Long> {

    @Query("SELECT vd FROM VehicleDriver vd WHERE vd.driver.id = :driverId AND vd.revokedAt IS"
            + " NULL")
    Optional<VehicleDriver> findActiveByDriverId(@Param("driverId") Long driverId);

    @Query("SELECT vd FROM VehicleDriver vd WHERE vd.vehicle.id = :vehicleId AND vd.revokedAt IS NULL")
    Optional<VehicleDriver> findActiveByVehicleId(@Param("vehicleId") Long vehicleId);

    @Query("SELECT vd FROM VehicleDriver vd WHERE vd.driver.id = :driverId AND vd.vehicle.id = :vehicleId AND vd.revokedAt IS NULL")
    Optional<VehicleDriver> findActiveByDriverIdAndVehicleId(
            @Param("driverId") Long driverId,
            @Param("vehicleId") Long vehicleId);

    @Query("SELECT vd FROM VehicleDriver vd WHERE vd.driver.id IN :driverIds AND vd.revokedAt IS NULL")
    List<VehicleDriver> findActiveByDriverIdIn(@Param("driverIds") java.util.Set<Long> driverIds);

    @Query("SELECT COUNT(vd) FROM VehicleDriver vd WHERE vd.driver.id = :driverId AND vd.revokedAt"
            + " IS NULL")
    long countActiveByDriverId(@Param("driverId") Long driverId);

    @Query("SELECT COUNT(vd) FROM VehicleDriver vd WHERE vd.vehicle.id = :vehicleId AND vd.revokedAt"
            + " IS NULL")
    long countActiveByVehicleId(@Param("vehicleId") Long vehicleId);

    @Query("SELECT vd FROM VehicleDriver vd WHERE vd.revokedAt IS NULL")
    List<VehicleDriver> findAllActive();

    @Query("""
            SELECT vd
            FROM VehicleDriver vd
            JOIN FETCH vd.vehicle v
            JOIN FETCH vd.driver d
            WHERE vd.revokedAt IS NULL
            ORDER BY vd.assignedAt DESC
            """)
    List<VehicleDriver> findAllActiveWithVehicleAndDriverOrderByAssignedAtDesc();

    // Pagination support for active assignments
    Page<VehicleDriver> findByRevokedAtIsNull(Pageable pageable);

    @Query("SELECT vd FROM VehicleDriver vd WHERE vd.assignedAt >= :startDate AND vd.assignedAt"
            + " <= :endDate")
    List<VehicleDriver> findByAssignedAtBetween(
            @Param("startDate") LocalDateTime startDate, @Param("endDate") LocalDateTime endDate);

    // Health check and reconciliation methods
    long countByRevokedAtIsNull();

    long countByRevokedAtIsNotNull();

    List<VehicleDriver> findByRevokedAtIsNull();

    List<VehicleDriver> findByRevokedAtIsNullAndAssignedAtBefore(LocalDateTime threshold);
}
