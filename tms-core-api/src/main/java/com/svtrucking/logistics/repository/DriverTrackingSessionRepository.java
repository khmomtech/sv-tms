package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.DriverTrackingSession;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface DriverTrackingSessionRepository extends JpaRepository<DriverTrackingSession, String> {
  Optional<DriverTrackingSession> findBySessionIdAndRevokedAtIsNull(String sessionId);

    List<DriverTrackingSession> findByDriverIdAndDeviceIdAndRevokedAtIsNullOrderByIssuedAtDesc(
      Long driverId, String deviceId);
}
