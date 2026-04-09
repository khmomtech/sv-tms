package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.VehicleDriver;
import java.time.LocalDateTime;
import java.util.Optional;
import java.util.List;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface VehicleDriverRepository extends JpaRepository<VehicleDriver, Long> {

    List<VehicleDriver> findByDriver_IdAndRevokedAtIsNullOrderByAssignedAtDescIdDesc(Long driverId);

    List<VehicleDriver> findByVehicle_IdAndRevokedAtIsNullOrderByAssignedAtDescIdDesc(Long vehicleId);

    List<VehicleDriver> findByDriver_IdAndVehicle_IdAndRevokedAtIsNullOrderByAssignedAtDescIdDesc(
            Long driverId,
            Long vehicleId);

    default Optional<VehicleDriver> findActiveByDriverId(Long driverId) {
        return findByDriver_IdAndRevokedAtIsNullOrderByAssignedAtDescIdDesc(driverId).stream().findFirst();
    }

    default Optional<VehicleDriver> findActiveByVehicleId(Long vehicleId) {
        return findByVehicle_IdAndRevokedAtIsNullOrderByAssignedAtDescIdDesc(vehicleId).stream().findFirst();
    }

    default Optional<VehicleDriver> findActiveByDriverIdAndVehicleId(Long driverId, Long vehicleId) {
        return findByDriver_IdAndVehicle_IdAndRevokedAtIsNullOrderByAssignedAtDescIdDesc(driverId, vehicleId)
                .stream()
                .findFirst();
    }

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
