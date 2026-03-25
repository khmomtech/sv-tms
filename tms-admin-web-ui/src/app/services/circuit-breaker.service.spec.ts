import { TestBed, fakeAsync, tick } from '@angular/core/testing';
import { of, throwError } from 'rxjs';

import { CircuitBreakerService, CircuitBreakerState } from './circuit-breaker.service';

describe('CircuitBreakerService', () => {
  let service: CircuitBreakerService;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [CircuitBreakerService],
    });
    service = TestBed.inject(CircuitBreakerService);
  });

  describe('Circuit Breaker States', () => {
    it('should be created in CLOSED state', () => {
      expect(service).toBeTruthy();
      expect(service.getState('test-service')).toBe(CircuitBreakerState.CLOSED);
    });

    it('should transition to OPEN after failure threshold', fakeAsync(() => {
      const serviceName = 'failing-service';
      const failingObservable = throwError(() => new Error('Service error'));

      // Execute until threshold (default 5 failures)
      for (let i = 0; i < 5; i++) {
        service.execute(serviceName, failingObservable).subscribe({
          error: () => {}, // Ignore errors
        });
        tick(100);
      }

      expect(service.getState(serviceName)).toBe(CircuitBreakerState.OPEN);
    }));

    it('should fail fast when OPEN', fakeAsync(() => {
      const serviceName = 'open-circuit';
      const failingObservable = throwError(() => new Error('Service error'));

      // Trigger circuit to open
      for (let i = 0; i < 5; i++) {
        service.execute(serviceName, failingObservable).subscribe({
          error: () => {},
        });
      }

      expect(service.getState(serviceName)).toBe(CircuitBreakerState.OPEN);

      // Next call should fail immediately
      const startTime = Date.now();
      service.execute(serviceName, of('test')).subscribe({
        error: (err) => {
          const duration = Date.now() - startTime;
          expect(err.message).toContain('Circuit breaker is OPEN');
          expect(duration).toBeLessThan(10); // Should fail instantly
        },
      });
    }));

    it('should transition to HALF_OPEN after timeout', fakeAsync(() => {
      const serviceName = 'timeout-circuit';
      const config = { timeout: 1000, failureThreshold: 3 }; // 1 second timeout
      const failingObservable = throwError(() => new Error('Service error'));

      // Open the circuit
      for (let i = 0; i < 3; i++) {
        service.execute(serviceName, failingObservable, config).subscribe({
          error: () => {},
        });
      }

      expect(service.getState(serviceName)).toBe(CircuitBreakerState.OPEN);

      // Wait for timeout
      tick(1100);

      // Next call should transition to HALF_OPEN
      service.execute(serviceName, of('test'), config).subscribe();

      expect(service.getState(serviceName)).toBe(CircuitBreakerState.HALF_OPEN);
    }));

    it('should transition back to CLOSED after success threshold in HALF_OPEN', fakeAsync(() => {
      const serviceName = 'recovery-circuit';
      const config = {
        timeout: 1000,
        failureThreshold: 3,
        successThreshold: 2,
      };
      const failingObservable = throwError(() => new Error('Error'));
      const successObservable = of('success');

      // Open circuit
      for (let i = 0; i < 3; i++) {
        service.execute(serviceName, failingObservable, config).subscribe({
          error: () => {},
        });
      }

      expect(service.getState(serviceName)).toBe(CircuitBreakerState.OPEN);

      // Wait for timeout to enter HALF_OPEN
      tick(1100);

      // Execute successful requests to meet success threshold
      service.execute(serviceName, successObservable, config).subscribe();
      tick(100);

      service.execute(serviceName, successObservable, config).subscribe();
      tick(100);

      expect(service.getState(serviceName)).toBe(CircuitBreakerState.CLOSED);
    }));

    it('should return to OPEN if failure occurs in HALF_OPEN', fakeAsync(() => {
      const serviceName = 'fail-halfopen';
      const config = { timeout: 1000, failureThreshold: 3 };
      const failingObservable = throwError(() => new Error('Error'));

      // Open circuit
      for (let i = 0; i < 3; i++) {
        service.execute(serviceName, failingObservable, config).subscribe({
          error: () => {},
        });
      }

      tick(1100); // Enter HALF_OPEN

      // Fail in HALF_OPEN
      service.execute(serviceName, failingObservable, config).subscribe({
        error: () => {},
      });

      expect(service.getState(serviceName)).toBe(CircuitBreakerState.OPEN);
    }));
  });

  describe('Configuration', () => {
    it('should use custom failure threshold', fakeAsync(() => {
      const serviceName = 'custom-threshold';
      const config = { failureThreshold: 2 }; // Only 2 failures needed
      const failingObservable = throwError(() => new Error('Error'));

      service.execute(serviceName, failingObservable, config).subscribe({
        error: () => {},
      });
      tick(100);

      expect(service.getState(serviceName)).toBe(CircuitBreakerState.CLOSED);

      service.execute(serviceName, failingObservable, config).subscribe({
        error: () => {},
      });
      tick(100);

      expect(service.getState(serviceName)).toBe(CircuitBreakerState.OPEN);
    }));

    it('should use custom success threshold', fakeAsync(() => {
      const serviceName = 'custom-success';
      const config = {
        failureThreshold: 2,
        successThreshold: 3, // Need 3 successes
        timeout: 1000,
      };
      const failingObservable = throwError(() => new Error('Error'));
      const successObservable = of('success');

      // Open circuit
      for (let i = 0; i < 2; i++) {
        service.execute(serviceName, failingObservable, config).subscribe({
          error: () => {},
        });
      }

      tick(1100); // Enter HALF_OPEN

      // 2 successes shouldn't close it
      service.execute(serviceName, successObservable, config).subscribe();
      tick(100);
      service.execute(serviceName, successObservable, config).subscribe();
      tick(100);

      expect(service.getState(serviceName)).toBe(CircuitBreakerState.HALF_OPEN);

      // 3rd success should close it
      service.execute(serviceName, successObservable, config).subscribe();
      tick(100);

      expect(service.getState(serviceName)).toBe(CircuitBreakerState.CLOSED);
    }));

    it('should use custom timeout', fakeAsync(() => {
      const serviceName = 'custom-timeout';
      const config = { timeout: 500, failureThreshold: 2 }; // 500ms timeout
      const failingObservable = throwError(() => new Error('Error'));

      // Open circuit
      for (let i = 0; i < 2; i++) {
        service.execute(serviceName, failingObservable, config).subscribe({
          error: () => {},
        });
      }

      expect(service.getState(serviceName)).toBe(CircuitBreakerState.OPEN);

      // After 400ms, should still be OPEN
      tick(400);
      service.execute(serviceName, of('test'), config).subscribe({
        error: () => {},
      });
      expect(service.getState(serviceName)).toBe(CircuitBreakerState.OPEN);

      // After 600ms total (>500ms timeout), should be HALF_OPEN
      tick(200);
      service.execute(serviceName, of('test'), config).subscribe();
      expect(service.getState(serviceName)).toBe(CircuitBreakerState.HALF_OPEN);
    }));
  });

  describe('Multiple Services', () => {
    it('should maintain separate state for different services', fakeAsync(() => {
      const service1 = 'service-1';
      const service2 = 'service-2';
      const failingObservable = throwError(() => new Error('Error'));
      const successObservable = of('success');

      // Fail service1
      for (let i = 0; i < 5; i++) {
        service.execute(service1, failingObservable).subscribe({
          error: () => {},
        });
      }

      // Success for service2
      service.execute(service2, successObservable).subscribe();

      expect(service.getState(service1)).toBe(CircuitBreakerState.OPEN);
      expect(service.getState(service2)).toBe(CircuitBreakerState.CLOSED);
    }));

    it('should reset one service without affecting others', () => {
      const service1 = 'service-1';
      const service2 = 'service-2';

      service.reset(service1);

      expect(service.getState(service1)).toBe(CircuitBreakerState.CLOSED);
      expect(service.getState(service2)).toBe(CircuitBreakerState.CLOSED);
    });
  });

  describe('Monitoring Window', () => {
    it('should only count failures within monitoring window', fakeAsync(() => {
      const serviceName = 'window-test';
      const config = {
        failureThreshold: 3,
        monitoringWindow: 1000, // 1 second window
      };
      const failingObservable = throwError(() => new Error('Error'));

      // First 2 failures
      service.execute(serviceName, failingObservable, config).subscribe({
        error: () => {},
      });
      tick(100);

      service.execute(serviceName, failingObservable, config).subscribe({
        error: () => {},
      });
      tick(100);

      // Wait beyond monitoring window
      tick(1100);

      // These failures should not be counted with the old ones
      service.execute(serviceName, failingObservable, config).subscribe({
        error: () => {},
      });
      tick(100);

      service.execute(serviceName, failingObservable, config).subscribe({
        error: () => {},
      });
      tick(100);

      // Should still be CLOSED (old failures expired)
      expect(service.getState(serviceName)).toBe(CircuitBreakerState.CLOSED);

      // One more failure within window should open it
      service.execute(serviceName, failingObservable, config).subscribe({
        error: () => {},
      });
      tick(100);

      expect(service.getState(serviceName)).toBe(CircuitBreakerState.OPEN);
    }));
  });

  describe('Error Handling', () => {
    it('should propagate original error when circuit is closed', (done) => {
      const serviceName = 'error-prop';
      const errorMessage = 'Original error';
      const failingObservable = throwError(() => new Error(errorMessage));

      service.execute(serviceName, failingObservable).subscribe({
        error: (err) => {
          expect(err.message).toBe(errorMessage);
          done();
        },
      });
    });

    it('should provide circuit breaker error when open', (done) => {
      const serviceName = 'cb-error';
      const failingObservable = throwError(() => new Error('Error'));

      // Open circuit
      for (let i = 0; i < 5; i++) {
        service.execute(serviceName, failingObservable).subscribe({
          error: () => {},
        });
      }

      // Try to execute when open
      service.execute(serviceName, of('test')).subscribe({
        error: (err) => {
          expect(err.message).toContain('Circuit breaker is OPEN');
          expect(err.message).toContain(serviceName);
          done();
        },
      });
    });
  });

  describe('Reset Functionality', () => {
    it('should reset circuit to CLOSED state', fakeAsync(() => {
      const serviceName = 'reset-test';
      const failingObservable = throwError(() => new Error('Error'));

      // Open circuit
      for (let i = 0; i < 5; i++) {
        service.execute(serviceName, failingObservable).subscribe({
          error: () => {},
        });
      }

      expect(service.getState(serviceName)).toBe(CircuitBreakerState.OPEN);

      service.reset(serviceName);

      expect(service.getState(serviceName)).toBe(CircuitBreakerState.CLOSED);
    }));

    it('should allow execution after reset', (done) => {
      const serviceName = 'reset-execute';
      const failingObservable = throwError(() => new Error('Error'));
      const successObservable = of('success');

      // Open circuit
      for (let i = 0; i < 5; i++) {
        service.execute(serviceName, failingObservable).subscribe({
          error: () => {},
        });
      }

      service.reset(serviceName);

      service.execute(serviceName, successObservable).subscribe({
        next: (value) => {
          expect(value).toBe('success');
          done();
        },
      });
    });
  });

  describe('Edge Cases', () => {
    it('should handle rapid successive calls', fakeAsync(() => {
      const serviceName = 'rapid-calls';
      const failingObservable = throwError(() => new Error('Error'));

      // Make 100 rapid calls
      for (let i = 0; i < 100; i++) {
        service.execute(serviceName, failingObservable).subscribe({
          error: () => {},
        });
      }

      expect(service.getState(serviceName)).toBe(CircuitBreakerState.OPEN);
    }));

    it('should handle zero failure threshold gracefully', fakeAsync(() => {
      const serviceName = 'zero-threshold';
      const config = { failureThreshold: 0 }; // Invalid config
      const failingObservable = throwError(() => new Error('Error'));

      // Should use default threshold instead of 0
      service.execute(serviceName, failingObservable, config).subscribe({
        error: () => {},
      });

      // Should not open immediately with 1 failure
      expect(service.getState(serviceName)).toBe(CircuitBreakerState.CLOSED);
    }));
  });
});
