package com.svtrucking.telematics.repository;

import com.svtrucking.telematics.model.DriverTrackingSession;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface DriverTrackingSessionRepository
                extends JpaRepository<DriverTrackingSession, String> {

        Optional<DriverTrackingSession> findBySessionIdAndRevokedAtIsNull(String sessionId);

        // Note: driverId is a plain Long field (not a JPA navigation property), so no
        // underscore needed
        List<DriverTrackingSession> findByDriverIdAndDeviceIdAndRevokedAtIsNullOrderByIssuedAtDesc(
                        Long driverId, String deviceId);

        List<DriverTrackingSession> findByDriverIdOrderByUpdatedAtDesc(Long driverId);

        List<DriverTrackingSession> findByDriverIdAndRevokedAtIsNullOrderByUpdatedAtDesc(Long driverId);
}
