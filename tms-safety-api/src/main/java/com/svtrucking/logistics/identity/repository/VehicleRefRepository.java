package com.svtrucking.logistics.identity.repository;

import com.svtrucking.logistics.identity.domain.VehicleRef;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface VehicleRefRepository extends JpaRepository<VehicleRef, Long> {

  @Query("select v.licensePlate from VehicleRef v where v.licensePlate is not null")
  Set<String> findAllPlates();

  Optional<VehicleRef> findByLicensePlate(String licensePlate);

  boolean existsByLicensePlate(String licensePlate);

  @Query("select v.id from VehicleRef v where lower(v.licensePlate) like :term")
  List<Long> searchIdsByPlate(@Param("term") String term);
}
