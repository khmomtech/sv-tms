package com.svtrucking.telematics.repository;

import com.svtrucking.telematics.model.Geofence;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface GeofenceRepository extends JpaRepository<Geofence, Long> {

    List<Geofence> findByCompanyId(Long companyId);

    List<Geofence> findByCompanyIdAndActiveTrue(Long companyId);
}
