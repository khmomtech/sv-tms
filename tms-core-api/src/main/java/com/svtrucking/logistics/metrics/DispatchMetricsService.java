package com.svtrucking.logistics.metrics;

import com.svtrucking.logistics.enums.DispatchStatus;
import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

/**
 * Micrometer-based metrics for dispatch lifecycle events.
 *
 * <p>
 * Counters are exposed via the Prometheus scrape endpoint at
 * {@code /actuator/prometheus} (enabled in application.yml).
 *
 * <p>
 * All methods are safe to call from {@code @Transactional} code —
 * counter increments are non-transactional and never throw.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class DispatchMetricsService {

  private static final String METRIC_TRANSITIONS = "dispatch.transitions.total";
  private static final String METRIC_SAFETY = "dispatch.safety.checks.total";
  private static final String METRIC_SLA = "dispatch.sla.breaches.total";

  private final MeterRegistry meterRegistry;

  /**
   * Records a dispatch status transition.
   *
   * @param from the previous status (may be {@code null} for initial creation)
   * @param to   the new status
   */
  public void recordTransition(DispatchStatus from, DispatchStatus to) {
    if (to == null)
      return;
    try {
      Counter.builder(METRIC_TRANSITIONS)
          .description("Total dispatch status transitions")
          .tag("from", from != null ? from.name() : "NONE")
          .tag("to", to.name())
          .register(meterRegistry)
          .increment();
    } catch (Exception ex) {
      log.debug("Metrics recordTransition failed: {}", ex.getMessage());
    }
  }

  /**
   * Records a safety check result.
   *
   * @param result e.g. "PASSED" or "FAILED"
   */
  public void recordSafetyCheck(String result) {
    if (result == null)
      return;
    try {
      Counter.builder(METRIC_SAFETY)
          .description("Total pre-loading safety check results")
          .tag("result", result)
          .register(meterRegistry)
          .increment();
    } catch (Exception ex) {
      log.debug("Metrics recordSafetyCheck failed: {}", ex.getMessage());
    }
  }

  /**
   * Records an SLA breach event.
   *
   * @param routeCode the route code of the breached dispatch (may be
   *                  {@code null})
   */
  public void recordSLABreach(String routeCode) {
    try {
      Counter.builder(METRIC_SLA)
          .description("Total SLA breaches by route")
          .tag("routeCode", routeCode != null ? routeCode : "UNKNOWN")
          .register(meterRegistry)
          .increment();
    } catch (Exception ex) {
      log.debug("Metrics recordSLABreach failed: {}", ex.getMessage());
    }
  }
}
