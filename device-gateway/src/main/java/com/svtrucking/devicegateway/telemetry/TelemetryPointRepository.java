package com.svtrucking.devicegateway.telemetry;

import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface TelemetryPointRepository extends JpaRepository<TelemetryPoint, Long> {

    Optional<TelemetryPoint> findByDeviceIdAndSequenceNumber(String deviceId, Long sequenceNumber);
}
