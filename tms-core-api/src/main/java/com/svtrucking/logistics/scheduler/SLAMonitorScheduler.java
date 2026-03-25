package com.svtrucking.logistics.scheduler;

import com.svtrucking.logistics.metrics.DispatchMetricsService;
import com.svtrucking.logistics.model.DispatchApprovalSLA;
import com.svtrucking.logistics.model.DispatchApprovalSLA.SLAStatus;
import com.svtrucking.logistics.repository.DispatchApprovalSLARepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.InvalidDataAccessResourceUsageException;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.List;

/**
 * Scheduler that periodically scans for SLA breaches among pending approvals.
 *
 * <p>
 * Runs every 5 minutes. For each SLA record still in PENDING status,
 * calculates elapsed minutes since delivery. If it exceeds the target,
 * marks the record as BREACHED and records a Micrometer metric.
 *
 * <p>
 * This catches cases where a dispatch was not formally approved (so
 * {@code updateSLAOnApproval()} never ran) but the SLA window has already
 * elapsed.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class SLAMonitorScheduler {

    private final DispatchApprovalSLARepository approvalSLARepository;
    private final DispatchMetricsService dispatchMetricsService;

    /**
     * Check pending SLAs for breaches every 5 minutes.
     */
    @Scheduled(fixedDelay = 300_000)
    @Transactional
    public void checkSLABreaches() {
        List<DispatchApprovalSLA> pending;
        try {
            pending = approvalSLARepository.findPendingApprovals();
        } catch (InvalidDataAccessResourceUsageException ex) {
            log.warn("SLA monitor skipped because approval workflow tables are not ready yet: {}", ex.getMostSpecificCause() != null
                    ? ex.getMostSpecificCause().getMessage()
                    : ex.getMessage());
            return;
        } catch (RuntimeException ex) {
            log.error("SLA monitor failed while loading pending approvals", ex);
            return;
        }
        if (pending.isEmpty()) {
            log.debug("SLA monitor: no pending SLA records to check");
            return;
        }

        LocalDateTime now = LocalDateTime.now();
        int breachCount = 0;

        for (DispatchApprovalSLA sla : pending) {
            if (sla.getDeliveredAt() == null || sla.getSlaTargetMinutes() == null) {
                continue;
            }
            long elapsedMinutes = ChronoUnit.MINUTES.between(sla.getDeliveredAt(), now);
            if (elapsedMinutes <= sla.getSlaTargetMinutes()) {
                continue;
            }

            try {
                sla.setSlaStatus(SLAStatus.BREACHED);
                approvalSLARepository.save(sla);
                breachCount++;

                String routeCode = (sla.getDispatch() != null && sla.getDispatch().getRouteCode() != null)
                        ? sla.getDispatch().getRouteCode()
                        : (sla.getDispatch() != null ? String.valueOf(sla.getDispatch().getId()) : "UNKNOWN");

                dispatchMetricsService.recordSLABreach(routeCode);

                log.warn(
                        "SLA breach detected by scheduler: dispatchId={}, routeCode={}, elapsedMinutes={}, targetMinutes={}",
                        sla.getDispatch() != null ? sla.getDispatch().getId() : "?",
                        routeCode,
                        elapsedMinutes,
                        sla.getSlaTargetMinutes());
            } catch (InvalidDataAccessResourceUsageException ex) {
                log.warn("SLA monitor stopped because approval workflow tables are not ready yet: {}", ex.getMostSpecificCause() != null
                        ? ex.getMostSpecificCause().getMessage()
                        : ex.getMessage());
                return;
            } catch (RuntimeException ex) {
                log.error("SLA monitor failed while processing dispatch {}", sla.getDispatch() != null ? sla.getDispatch().getId() : "?", ex);
                return;
            }
        }

        if (breachCount > 0) {
            log.warn("SLA monitor completed: {} new breach(es) recorded out of {} pending SLAs checked",
                    breachCount, pending.size());
        } else {
            log.debug("SLA monitor completed: {} pending SLAs checked, no new breaches", pending.size());
        }
    }
}
