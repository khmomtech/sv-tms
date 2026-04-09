package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.dto.TopDriverDto;
import com.svtrucking.logistics.enums.DispatchStatus;
import com.svtrucking.logistics.enums.DriverStatus;
import com.svtrucking.logistics.enums.VehicleType;
import com.svtrucking.logistics.model.Driver;
import com.svtrucking.logistics.model.LocationHistory;
import java.util.List;
import java.util.Optional;
import org.springframework.data.domain.Page;
// ...existing code...
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface DriverRepository extends JpaRepository<Driver, Long> {

        // License data is stored in driver_documents (category='license')
        // findByDriverLicense_LicenseNumber removed — driverLicense relationship is
        // gone

        Optional<Driver> findByDeviceToken(String deviceToken);

        Optional<Driver> findByUserId(Long userId);

        Optional<Driver> findByUserUsername(String username);

        Optional<Driver> findTopByPhone(String phone);

        boolean existsById(Long id);

        @Query("SELECT DISTINCT d FROM Driver d " +
                        "LEFT JOIN FETCH d.assignedVehicle " +
                        "LEFT JOIN FETCH d.tempAssignedVehicle " +
                        "LEFT JOIN FETCH d.vehicleDriverAssignments vda " +
                        "LEFT JOIN FETCH vda.vehicle " +
                        "WHERE d.id = :id")
        Optional<Driver> findByIdWithVehicles(@Param("id") Long id);

        List<Driver> findByNameContainingIgnoreCaseOrPhoneContainingIgnoreCase(String name, String phone);

        @Query("""
                         SELECT DISTINCT d
                         FROM Driver d
                         LEFT JOIN d.vehicleDriverAssignments vda ON vda.revokedAt IS NULL
                             AND vda.id = (
                                 SELECT MAX(vda2.id) FROM VehicleDriver vda2
                                 WHERE vda2.driver = d AND vda2.revokedAt IS NULL
                             )
                         LEFT JOIN vda.vehicle v
                         LEFT JOIN d.assignedVehicle av
                         LEFT JOIN d.tempAssignedVehicle tv
                         WHERE (:keyword IS NULL OR :keyword = ''
                          OR LOWER(d.name) LIKE LOWER(CONCAT('%', :keyword, '%'))
                          OR LOWER(d.firstName) LIKE LOWER(CONCAT('%', :keyword, '%'))
                          OR LOWER(d.lastName) LIKE LOWER(CONCAT('%', :keyword, '%'))
                          OR LOWER(d.phone) LIKE LOWER(CONCAT('%', :keyword, '%')))
                        AND (:licensePlate IS NULL OR :licensePlate = ''
                          OR LOWER(v.licensePlate) = LOWER(:licensePlate)
                          OR LOWER(av.licensePlate) = LOWER(:licensePlate)
                          OR LOWER(tv.licensePlate) = LOWER(:licensePlate))
                        AND (:truckType IS NULL OR d.vehicleType = :truckType)
                        AND (:status IS NULL OR d.status = :status)
                        AND (:zone IS NULL OR d.zone = :zone)
                         """)
        List<Driver> searchDriversWithFilters(
                        @Param("keyword") String keyword,
                        @Param("licensePlate") String licensePlate,
                        @Param("truckType") VehicleType truckType,
                        @Param("status") DriverStatus status,
                        @Param("zone") String zone);

        @Query("SELECT d FROM Driver d "
                        + "WHERE (:query IS NULL OR LOWER(d.name) LIKE LOWER(CONCAT('%', :query, '%'))) "
                        + "AND (:isActive IS NULL OR d.isActive = :isActive) "
                        + "AND (:minRating IS NULL OR d.rating >= :minRating) "
                        + "AND (:maxRating IS NULL OR d.rating <= :maxRating) "
                        + "AND (:zone IS NULL OR d.zone = :zone) "
                        + "AND (:vehicleType IS NULL OR d.vehicleType = :vehicleType) "
                        + "AND (:status IS NULL OR d.status = :status) "
                        + "AND (:isPartner IS NULL OR d.isPartner = :isPartner)")
        Page<Driver> advancedSearch(
                        @Param("query") String query,
                        @Param("isActive") Boolean isActive,
                        @Param("minRating") Double minRating,
                        @Param("maxRating") Double maxRating,
                        @Param("zone") String zone,
                        @Param("vehicleType") VehicleType vehicleType,
                        @Param("status") DriverStatus status,
                        @Param("isPartner") Boolean isPartner,
                        Pageable pageable);

        @Query("SELECT COUNT(d) FROM Driver d WHERE d.status = :status")
        int countDriversByStatus(@Param("status") DriverStatus status);

        @Query("SELECT COUNT(d) FROM Driver d WHERE d.status IN :statuses")
        int countDriversByStatuses(@Param("statuses") List<DriverStatus> statuses);

        @Query("SELECT d FROM Driver d "
                        + "JOIN d.latestLocation loc "
                        + "WHERE loc.latitude IS NOT NULL AND loc.longitude IS NOT NULL "
                        + "AND d.status IN :statuses")
        List<Driver> findLiveDrivers(@Param("statuses") List<DriverStatus> statuses);

        @Query("""
                            SELECT new com.svtrucking.logistics.dto.TopDriverDto(d.name, COUNT(dist.id))
                            FROM Dispatch dist
                            JOIN dist.driver d
                            WHERE dist.status = :status
                              AND FUNCTION('WEEK', dist.createdDate) = FUNCTION('WEEK', CURRENT_DATE)
                            GROUP BY d.name
                            ORDER BY COUNT(dist.id) DESC
                        """)
        List<TopDriverDto> findTopDriversByDeliveriesThisWeek(@Param("status") DispatchStatus status);

        @Query(value = """
                        SELECT lh.*
                        FROM location_history lh
                        INNER JOIN (
                            SELECT driver_id, MAX(timestamp) AS latest_time
                            FROM location_history
                            GROUP BY driver_id
                        ) latest ON lh.driver_id = latest.driver_id AND lh.timestamp = latest.latest_time
                        """, nativeQuery = true)
        List<LocationHistory> findLatestLocationPerDriver();

        @Query("SELECT d FROM Driver d WHERE d.user.username = :username")
        Optional<Driver> findByUsername(@Param("username") String username);

        @Query("SELECT d FROM Driver d "
                        + "LEFT JOIN FETCH d.user u "
                        + "LEFT JOIN FETCH u.roles r "
                        + "WHERE d.id = :id")
        Optional<Driver> findByIdWithUserAndRoles(@Param("id") Long id);

        // Optional<Dispatch> findTopByDriverIdAndStatusInOrderByUpdatedDateDesc(Long
        // driverId,
        // List<DispatchStatus> statuses);
        // 🔹 Filter by assigned vehicle license plate (ACTIVE assignment only,
        // case-insensitive)
        // ...existing code...

        // Drivers whose temporary assignment has expired (or has no expiry but should
        // be cleared)
        @Query("SELECT d FROM Driver d WHERE d.tempAssignedVehicle IS NOT NULL AND (d.tempAssignmentExpiry IS NULL OR d.tempAssignmentExpiry <= :now)")
        List<Driver> findExpiredTemporaryAssignments(@Param("now") java.time.LocalDateTime now);

        // existsByDriverLicense_* removed — license uniqueness is no longer validated
        // via
        // the driver_licenses table. License documents live in driver_documents.

}
