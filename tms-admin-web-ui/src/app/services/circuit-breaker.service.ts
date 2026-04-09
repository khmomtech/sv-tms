import { Injectable } from '@angular/core';
import { Observable, throwError, timer } from 'rxjs';
import { catchError, tap } from 'rxjs/operators';

/**
 * Circuit Breaker pattern implementation for preventing cascade failures
 * when backend services are degraded or down.
 *
 * States:
 * - CLOSED: Normal operation, requests pass through
 * - OPEN: Too many failures, requests immediately fail
 * - HALF_OPEN: Testing if service recovered, allow limited requests
 *
 * Production features:
 * - Automatic state transitions based on failure thresholds
 * - Configurable timeout and failure count
 * - Monitoring hooks for alerting
 * - Per-service circuit breakers
 */
@Injectable({
  providedIn: 'root',
})
export class CircuitBreakerService {
  private circuits = new Map<string, CircuitState>();

  // Default configuration
  private readonly DEFAULT_CONFIG: CircuitConfig = {
    failureThreshold: 5, // Open after 5 failures
    successThreshold: 2, // Close after 2 successes in half-open
    timeout: 60000, // Reset to half-open after 60s
    monitoringWindow: 120000, // Track failures in last 2 minutes
  };

  /**
   * Execute request with circuit breaker protection
   *
   * @param serviceName Unique identifier for the service/endpoint
   * @param request Observable to execute
   * @param config Optional circuit breaker configuration
   */
  execute<T>(
    serviceName: string,
    request: Observable<T>,
    config: Partial<CircuitConfig> = {},
  ): Observable<T> {
    const circuit = this.getOrCreateCircuit(serviceName, config);
    const state = this.getState(circuit);

    // OPEN: Circuit is open, fail fast
    if (state === CircuitBreakerState.OPEN) {
      console.warn(`[Circuit Breaker] ${serviceName} is OPEN, failing fast`);
      this.notifyStateChange(serviceName, state);
      return throwError(
        () =>
          new Error(`Service ${serviceName} is temporarily unavailable. Circuit breaker is OPEN.`),
      );
    }

    // CLOSED or HALF_OPEN: Allow request
    return request.pipe(
      tap(() => this.onSuccess(circuit, serviceName)),
      catchError((error) => {
        this.onFailure(circuit, serviceName);
        return throwError(() => error);
      }),
    );
  }

  /**
   * Get current state of circuit breaker
   */
  getCircuitState(serviceName: string): CircuitBreakerState {
    const circuit = this.circuits.get(serviceName);
    return circuit ? this.getState(circuit) : CircuitBreakerState.CLOSED;
  }

  /**
   * Manually reset circuit breaker
   */
  reset(serviceName: string): void {
    const circuit = this.circuits.get(serviceName);
    if (circuit) {
      if (circuit.monitoringWindowTimer) {
        clearTimeout(circuit.monitoringWindowTimer);
        circuit.monitoringWindowTimer = null;
      }
      circuit.state = CircuitBreakerState.CLOSED;
      circuit.failureCount = 0;
      circuit.successCount = 0;
      circuit.lastFailureTime = null;
      console.info(`[Circuit Breaker] ${serviceName} manually reset to CLOSED`);
    }
  }

  /**
   * Get statistics for all circuit breakers
   */
  getStats(): Map<string, CircuitStats> {
    const stats = new Map<string, CircuitStats>();

    for (const [serviceName, circuit] of this.circuits.entries()) {
      stats.set(serviceName, {
        state: this.getState(circuit),
        failureCount: circuit.failureCount,
        successCount: circuit.successCount,
        lastFailureTime: circuit.lastFailureTime,
        lastStateChange: circuit.lastStateChange,
      });
    }

    return stats;
  }

  /**
   * Get or create circuit breaker for service
   */
  private getOrCreateCircuit(serviceName: string, config: Partial<CircuitConfig>): CircuitState {
    let circuit = this.circuits.get(serviceName);

    if (!circuit) {
      const normalizedConfig = this.normalizeConfig(config);
      circuit = {
        state: CircuitBreakerState.CLOSED,
        failureCount: 0,
        successCount: 0,
        lastFailureTime: null,
        lastStateChange: Date.now(),
        monitoringWindowTimer: null,
        config: normalizedConfig,
      };
      this.circuits.set(serviceName, circuit);
      console.info(`[Circuit Breaker] Created new circuit for ${serviceName}`);
    }

    return circuit;
  }

  private normalizeConfig(config: Partial<CircuitConfig>): CircuitConfig {
    const merged = { ...this.DEFAULT_CONFIG, ...config };
    if (!merged.failureThreshold || merged.failureThreshold < 1) {
      merged.failureThreshold = this.DEFAULT_CONFIG.failureThreshold;
    }
    if (!merged.successThreshold || merged.successThreshold < 1) {
      merged.successThreshold = this.DEFAULT_CONFIG.successThreshold;
    }
    if (!merged.timeout || merged.timeout < 1) {
      merged.timeout = this.DEFAULT_CONFIG.timeout;
    }
    if (!merged.monitoringWindow || merged.monitoringWindow < 1) {
      merged.monitoringWindow = this.DEFAULT_CONFIG.monitoringWindow;
    }
    return merged;
  }

  /**
   * Get current state with automatic transitions
   */
  getState(circuit: CircuitState | string): CircuitBreakerState {
    // If string provided (service name), get the circuit first
    if (typeof circuit === 'string') {
      const circuitState = this.circuits.get(circuit);
      if (!circuitState) {
        return CircuitBreakerState.CLOSED;
      }
      circuit = circuitState;
    }

    // OPEN -> HALF_OPEN transition after timeout
    if (
      circuit.state === CircuitBreakerState.OPEN &&
      circuit.lastFailureTime &&
      Date.now() - circuit.lastFailureTime >= circuit.config.timeout
    ) {
      circuit.state = CircuitBreakerState.HALF_OPEN;
      circuit.successCount = 0;
      circuit.lastStateChange = Date.now();
      console.info(`[Circuit Breaker] Transitioning to HALF_OPEN (timeout expired)`);
    }

    return circuit.state;
  }

  /**
   * Handle successful request
   */
  private onSuccess(circuit: CircuitState, serviceName: string): void {
    if (circuit.state === CircuitBreakerState.HALF_OPEN) {
      circuit.successCount++;

      // HALF_OPEN -> CLOSED transition after success threshold
      if (circuit.successCount >= circuit.config.successThreshold) {
        circuit.state = CircuitBreakerState.CLOSED;
        circuit.failureCount = 0;
        circuit.successCount = 0;
        circuit.lastStateChange = Date.now();
        console.info(`[Circuit Breaker] ${serviceName} transitioned to CLOSED (service recovered)`);
        this.notifyStateChange(serviceName, CircuitBreakerState.CLOSED);
      }
    } else if (circuit.state === CircuitBreakerState.CLOSED) {
      // Reset failure count on success in CLOSED state
      circuit.failureCount = 0;
    }
  }

  /**
   * Handle failed request
   */
  private onFailure(circuit: CircuitState, serviceName: string): void {
    const now = Date.now();
    // Schedule a reset of the failure window so bursts don't linger forever.
    this.scheduleFailureWindowReset(circuit);
    circuit.failureCount++;
    circuit.lastFailureTime = now;

    // CLOSED -> OPEN transition after failure threshold
    if (circuit.state === CircuitBreakerState.CLOSED) {
      if (circuit.failureCount >= circuit.config.failureThreshold) {
        circuit.state = CircuitBreakerState.OPEN;
        circuit.lastStateChange = Date.now();
        console.error(
          `[Circuit Breaker] ${serviceName} transitioned to OPEN (${circuit.failureCount} failures)`,
        );
        this.notifyStateChange(serviceName, CircuitBreakerState.OPEN);
      }
    }
    // HALF_OPEN -> OPEN transition on any failure
    else if (circuit.state === CircuitBreakerState.HALF_OPEN) {
      circuit.state = CircuitBreakerState.OPEN;
      circuit.successCount = 0;
      circuit.lastStateChange = Date.now();
      console.warn(
        `[Circuit Breaker] ${serviceName} transitioned back to OPEN (half-open test failed)`,
      );
      this.notifyStateChange(serviceName, CircuitBreakerState.OPEN);
    }
  }

  /**
   * Clean failures outside monitoring window
   */
  private scheduleFailureWindowReset(circuit: CircuitState): void {
    if (circuit.monitoringWindowTimer) return;
    circuit.monitoringWindowTimer = setTimeout(() => {
      circuit.failureCount = 0;
      circuit.monitoringWindowTimer = null;
    }, circuit.config.monitoringWindow);
  }

  /**
   * Notify monitoring system of state changes (override for custom alerts)
   */
  private notifyStateChange(serviceName: string, newState: CircuitBreakerState): void {
    // Emit event for monitoring/alerting
    const event = {
      service: serviceName,
      state: newState,
      timestamp: new Date().toISOString(),
    };

    // In production, send to monitoring service
    console.warn(`[Circuit Breaker] State change notification:`, event);

    // Could integrate with:
    // - Sentry for error tracking
    // - Datadog for metrics
    // - PagerDuty for critical alerts
    // - Custom webhook for Slack notifications
  }
}

export enum CircuitBreakerState {
  CLOSED = 'CLOSED',
  OPEN = 'OPEN',
  HALF_OPEN = 'HALF_OPEN',
}

interface CircuitConfig {
  failureThreshold: number;
  successThreshold: number;
  timeout: number;
  monitoringWindow: number;
}

interface CircuitState {
  state: CircuitBreakerState;
  failureCount: number;
  successCount: number;
  lastFailureTime: number | null;
  lastStateChange: number;
  monitoringWindowTimer: ReturnType<typeof setTimeout> | null;
  config: CircuitConfig;
}

interface CircuitStats {
  state: CircuitBreakerState;
  failureCount: number;
  successCount: number;
  lastFailureTime: number | null;
  lastStateChange: number;
}
