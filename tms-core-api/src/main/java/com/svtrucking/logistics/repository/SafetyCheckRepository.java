package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.SafetyCheck;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.EntityGraph;

public interface SafetyCheckRepository
    extends JpaRepository<SafetyCheck, Long>, JpaSpecificationExecutor<SafetyCheck> {

  List<SafetyCheck> findByCheckDateAndDriverIdAndVehicleIdOrderByIdDesc(
      LocalDate checkDate, Long driverId, Long vehicleId);

  List<SafetyCheck> findByCheckDateAndVehicleIdOrderByIdDesc(LocalDate checkDate, Long vehicleId);

  default Optional<SafetyCheck> findLatestByCheckDateAndDriverIdAndVehicleId(
      LocalDate checkDate, Long driverId, Long vehicleId) {
    return findByCheckDateAndDriverIdAndVehicleIdOrderByIdDesc(checkDate, driverId, vehicleId)
        .stream()
        .findFirst();
  }

  default Optional<SafetyCheck> findLatestByCheckDateAndVehicleId(LocalDate checkDate, Long vehicleId) {
    return findByCheckDateAndVehicleIdOrderByIdDesc(checkDate, vehicleId).stream().findFirst();
  }

  @EntityGraph(attributePaths = {"driver", "vehicle"})
  Page<SafetyCheck> findByDriverIdAndCheckDateBetween(
      Long driverId, LocalDate from, LocalDate to, Pageable pageable);

  @EntityGraph(attributePaths = {"driver", "vehicle"})
  List<SafetyCheck> findByDriverIdAndCheckDateBetween(Long driverId, LocalDate from, LocalDate to);

  @EntityGraph(attributePaths = {"driver", "vehicle"})
  List<SafetyCheck> findByVehicleIdAndCheckDateBetween(Long vehicleId, LocalDate from, LocalDate to);
}
