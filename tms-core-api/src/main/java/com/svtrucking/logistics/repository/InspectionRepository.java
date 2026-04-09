package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.VehicleInspection;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface InspectionRepository extends JpaRepository<VehicleInspection, Long> {
  List<VehicleInspection> findByVehicleId(Long vehicleId);
}
