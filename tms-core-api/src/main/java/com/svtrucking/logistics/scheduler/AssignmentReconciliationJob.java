package com.svtrucking.logistics.scheduler;

import com.svtrucking.logistics.model.VehicleDriver;
import com.svtrucking.logistics.repository.VehicleDriverRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Slf4j
@Component
@RequiredArgsConstructor
public class AssignmentReconciliationJob {

    private final VehicleDriverRepository assignmentRepository;

    @Scheduled(cron = "0 0 2 * * *") // Daily at 2 AM
    public void reconcileAssignments() {
        log.info("Starting assignment reconciliation job");

        try {
            checkForDuplicates();
            checkForStaleAssignments();
            logAssignmentStats();

            log.info("Assignment reconciliation completed successfully");
        } catch (Exception e) {
            log.error("Assignment reconciliation failed", e);
            // In production: send alert to monitoring system
        }
    }

    private void checkForDuplicates() {
        List<VehicleDriver> active = assignmentRepository.findByRevokedAtIsNull();

        // Check for duplicate driver assignments
        Map<Long, List<VehicleDriver>> byDriver = active.stream()
                .filter(a -> a.getDriver() != null)
                .collect(Collectors.groupingBy(a -> a.getDriver().getId()));

        byDriver.forEach((driverId, assignments) -> {
            if (assignments.size() > 1) {
                log.error("CRITICAL: Driver {} has {} active assignments (expected 1): {}",
                        driverId, assignments.size(), assignments.stream()
                                .map(a -> String.format("ID=%d,Vehicle=%d", a.getId(),
                                        a.getVehicle() != null ? a.getVehicle().getId() : null))
                                .collect(Collectors.joining(", ")));
            }
        });

        // Check for duplicate vehicle assignments
        Map<Long, List<VehicleDriver>> byVehicle = active.stream()
                .filter(a -> a.getVehicle() != null)
                .collect(Collectors.groupingBy(a -> a.getVehicle().getId()));

        byVehicle.forEach((vehicleId, assignments) -> {
            if (assignments.size() > 1) {
                log.error("CRITICAL: Vehicle {} has {} active assignments (expected 1): {}",
                        vehicleId, assignments.size(), assignments.stream()
                                .map(a -> String.format("ID=%d,Driver=%d", a.getId(),
                                        a.getDriver() != null ? a.getDriver().getId() : null))
                                .collect(Collectors.joining(", ")));
            }
        });
    }

    private void checkForStaleAssignments() {
        LocalDateTime staleThreshold = LocalDateTime.now().minusDays(365);
        List<VehicleDriver> stale = assignmentRepository.findByRevokedAtIsNullAndAssignedAtBefore(staleThreshold);

        if (!stale.isEmpty()) {
            log.warn("Found {} assignments older than 1 year (may need review)", stale.size());
            stale.forEach(a -> log.debug("Stale assignment: ID={}, Driver={}, Vehicle={}, AssignedAt={}",
                    a.getId(),
                    a.getDriver() != null ? a.getDriver().getId() : null,
                    a.getVehicle() != null ? a.getVehicle().getId() : null,
                    a.getAssignedAt()));
        }
    }

    private void logAssignmentStats() {
        long activeCount = assignmentRepository.countByRevokedAtIsNull();
        long revokedCount = assignmentRepository.countByRevokedAtIsNotNull();
        long totalCount = assignmentRepository.count();

        log.info("Assignment statistics: active={}, revoked={}, total={}",
                activeCount, revokedCount, totalCount);
    }
}
