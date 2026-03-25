package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.DriverLicense;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface DriverLicenseRepository extends JpaRepository<DriverLicense, Long> {

  // Optional<DriverLicense> findByDriverId(Long driverId);

  Optional<DriverLicense> findByDriverId(Long driverId); // Normal use

  @Query("SELECT l FROM DriverLicense l JOIN FETCH l.driver d WHERE d.id = :driverId")
  Optional<DriverLicense> findByDriverIdWithDriver(Long driverId);

  @Query("SELECT l FROM DriverLicense l WHERE l.licenseNumber = :licenseNumber")
  Optional<DriverLicense> findByLicenseNumberIncludingDeleted(String licenseNumber);

  @Query("SELECT d FROM DriverLicense d") // Ignores @Where
  List<DriverLicense> findAllIncludingDeleted();

  List<DriverLicense> findAllByOrderByIdDesc();
}
