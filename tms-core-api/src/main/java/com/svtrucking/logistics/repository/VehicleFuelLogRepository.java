package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.VehicleFuelLog;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface VehicleFuelLogRepository extends JpaRepository<VehicleFuelLog, Long> {

  @Query(
      """
        SELECT f FROM VehicleFuelLog f
        WHERE f.vehicle.id = :vehicleId
          AND (:search IS NULL OR LOWER(f.station) LIKE LOWER(CONCAT('%', :search, '%'))
               OR LOWER(f.notes) LIKE LOWER(CONCAT('%', :search, '%')))
      """)
  Page<VehicleFuelLog> searchByVehicle(
      @Param("vehicleId") Long vehicleId, @Param("search") String search, Pageable pageable);
}
