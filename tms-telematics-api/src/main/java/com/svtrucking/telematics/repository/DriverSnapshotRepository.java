package com.svtrucking.telematics.repository;

import com.svtrucking.telematics.model.DriverSnapshot;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface DriverSnapshotRepository extends JpaRepository<DriverSnapshot, Long> {
}
