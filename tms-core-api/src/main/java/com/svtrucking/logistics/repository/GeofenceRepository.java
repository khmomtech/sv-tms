package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.Geofence;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface GeofenceRepository extends JpaRepository<Geofence, Long> {

    List<Geofence> findByCompanyIdAndActiveTrue(Long companyId);

    List<Geofence> findByCompanyId(Long companyId);
}
