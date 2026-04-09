package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.enums.TruckSize;
import com.svtrucking.logistics.enums.VehicleStatus;
import com.svtrucking.logistics.enums.VehicleType;
import com.svtrucking.logistics.model.Vehicle;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface VehicleRepository extends JpaRepository<Vehicle, Long> {

  @Query("select v.licensePlate from Vehicle v where v.licensePlate is not null")
  Set<String> findAllPlates();

  // Find a vehicle by its license plate
  Optional<Vehicle> findByLicensePlate(String licensePlate);

  // Check if a vehicle exists by license plate
  boolean existsByLicensePlate(String licensePlate);

  // Find all vehicles by status
  List<Vehicle> findAllByStatus(VehicleStatus status);

  // Find all available vehicles by status and assigned zone
  List<Vehicle> findAllByStatusAndAssignedZone(VehicleStatus status, String assignedZone);

  // Find all available vehicles by status and type
  List<Vehicle> findAllByStatusAndType(VehicleStatus status, VehicleType type);

  // Find all available vehicles by status, zone, and type
  List<Vehicle> findAllByStatusAndAssignedZoneAndType(
      VehicleStatus status, String assignedZone, VehicleType type);

  // ✨ Advanced search and filter queries
  @Query(
      "SELECT v FROM Vehicle v WHERE "
          + "(:search IS NULL OR LOWER(v.licensePlate) LIKE LOWER(CONCAT('%', :search, '%')) "
          + "OR LOWER(v.model) LIKE LOWER(CONCAT('%', :search, '%')) "
          + "OR LOWER(v.manufacturer) LIKE LOWER(CONCAT('%', :search, '%'))) "
          + "AND (:status IS NULL OR v.status = :status) "
          + "AND (:type IS NULL OR v.type = :type) "
          + "AND (:truckSize IS NULL OR v.truckSize = :truckSize) "
          + "AND (:zone IS NULL OR v.assignedZone = :zone) "
          + "AND (:assigned IS NULL "
          + "OR (:assigned = TRUE AND EXISTS (SELECT 1 FROM VehicleDriver vd WHERE vd.vehicle = v AND vd.revokedAt IS NULL)) "
          + "OR (:assigned = FALSE AND NOT EXISTS (SELECT 1 FROM VehicleDriver vd WHERE vd.vehicle = v AND vd.revokedAt IS NULL)))")
  Page<Vehicle> searchVehicles(
      @Param("search") String search,
      @Param("status") VehicleStatus status,
      @Param("type") VehicleType type,
      @Param("truckSize") TruckSize truckSize,
      @Param("zone") String zone,
      @Param("assigned") Boolean assigned,
      Pageable pageable);

  // Find vehicles requiring service (past due date)
  @Query("SELECT v FROM Vehicle v WHERE v.nextServiceDue IS NOT NULL AND v.nextServiceDue <= :date")
  List<Vehicle> findVehiclesRequiringService(@Param("date") LocalDate date);

  // Find vehicles by mileage range
  @Query("SELECT v FROM Vehicle v WHERE v.mileage BETWEEN :minMileage AND :maxMileage")
  List<Vehicle> findByMileageRange(
      @Param("minMileage") java.math.BigDecimal minMileage,
      @Param("maxMileage") java.math.BigDecimal maxMileage);

  // Find vehicles without current assignment
  @Query(
      "SELECT v FROM Vehicle v WHERE NOT EXISTS "
          + "(SELECT a FROM VehicleDriver a WHERE a.vehicle = v AND a.revokedAt IS NULL)")
  List<Vehicle> findUnassignedVehicles();

  // Find vehicles with GPS device
  List<Vehicle> findByGpsDeviceIdIsNotNull();

  // Count vehicles by status
  @Query("SELECT v.status, COUNT(v) FROM Vehicle v GROUP BY v.status")
  List<Object[]> countByStatus();

  // Count vehicles by type
  @Query("SELECT v.type, COUNT(v) FROM Vehicle v GROUP BY v.type")
  List<Object[]> countByType();

  // Find trailers (vehicles with parent vehicle)
  @Query("SELECT v FROM Vehicle v WHERE v.parentVehicle IS NOT NULL")
  List<Vehicle> findAllTrailers();

  // Find vehicles by year range
  List<Vehicle> findByYearMadeBetween(Integer startYear, Integer endYear);
}
