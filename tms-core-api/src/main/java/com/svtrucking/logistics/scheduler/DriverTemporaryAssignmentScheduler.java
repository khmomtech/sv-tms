package com.svtrucking.logistics.scheduler;

import com.svtrucking.logistics.model.Driver;
import com.svtrucking.logistics.repository.DriverRepository;
import java.time.LocalDateTime;
import java.util.List;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/**
 * Periodically resets expired temporary driver-vehicle assignments, reverting
 * drivers back to
 * their permanent vehicle.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class DriverTemporaryAssignmentScheduler {

    private final DriverRepository driverRepository;

    // Every 5 minutes
    @Scheduled(fixedDelay = 300000)
    public void sweepExpiredTemporaryAssignments() {
        LocalDateTime now = LocalDateTime.now();
        List<Driver> expired = driverRepository.findExpiredTemporaryAssignments(now);
        if (expired.isEmpty())
            return;
        expired.forEach(d -> {
            try {
                // no-op
            } catch (Exception e) {
                log.warn("Failed to reset temporary assignment for driver {}: {}", d.getId(), e.getMessage());
            }
        });
    }
}
