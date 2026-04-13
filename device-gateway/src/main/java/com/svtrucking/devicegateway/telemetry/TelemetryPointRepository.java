package com.svtrucking.devicegateway.telemetry;

import java.util.Collection;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface TelemetryPointRepository extends JpaRepository<TelemetryPoint, Long> {

    Optional<TelemetryPoint> findByDeviceIdAndSequenceNumber(String deviceId, Long sequenceNumber);

    List<TelemetryPoint> findTop200ByPublishStatusInOrderByReceivedAtAsc(Collection<TelemetryPublishStatus> statuses);

    long countByPublishStatusIn(Collection<TelemetryPublishStatus> statuses);

    Optional<TelemetryPoint> findFirstByPublishStatusInOrderByReceivedAtAsc(Collection<TelemetryPublishStatus> statuses);
}
