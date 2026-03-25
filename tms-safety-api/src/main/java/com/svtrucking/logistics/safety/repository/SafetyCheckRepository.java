package com.svtrucking.logistics.safety.repository;

import com.svtrucking.logistics.safety.domain.SafetyCheck;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;

public interface SafetyCheckRepository
    extends JpaRepository<SafetyCheck, Long>, JpaSpecificationExecutor<SafetyCheck> {

  Optional<SafetyCheck> findByCheckDateAndDriverIdAndVehicleId(
      LocalDate checkDate, Long driverId, Long vehicleId);

  Optional<SafetyCheck> findByCheckDateAndVehicleId(LocalDate checkDate, Long vehicleId);

  Page<SafetyCheck> findByDriverIdAndCheckDateBetween(
      Long driverId, LocalDate from, LocalDate to, Pageable pageable);

  List<SafetyCheck> findByVehicleIdAndCheckDateBetween(Long vehicleId, LocalDate from, LocalDate to);
}

