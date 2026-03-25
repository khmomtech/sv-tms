import { TestBed } from '@angular/core/testing';
import { HttpClientTestingModule } from '@angular/common/http/testing';
import { DriverAlertService } from './driver-alert.service';
import { AuthService } from './auth.service';

describe('DriverAlertService - Core Functionality', () => {
  let service: DriverAlertService;

  beforeEach(() => {
    const authServiceSpy = jasmine.createSpyObj('AuthService', ['getToken']);
    authServiceSpy.getToken.and.returnValue('test-token');

    TestBed.configureTestingModule({
      imports: [HttpClientTestingModule],
      providers: [DriverAlertService, { provide: AuthService, useValue: authServiceSpy }],
    });

    service = TestBed.inject(DriverAlertService);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });

  it('should emit speeding alert', (done) => {
    const sub = service.activeAlerts$.subscribe((alerts) => {
      if (alerts.size === 1) {
        const alert = Array.from(alerts.values())[0];
        expect(alert.type).toBe('speeding');
        expect(alert.severity).toBe('warning');
        sub.unsubscribe();
        done();
      }
    });

    service.checkAndEmitAlerts(1, { speed: 95 });
  });

  it('should emit battery low alert', (done) => {
    const sub = service.activeAlerts$.subscribe((alerts) => {
      if (alerts.size === 1) {
        const alert = Array.from(alerts.values())[0];
        expect(alert.type).toBe('battery_low');
        sub.unsubscribe();
        done();
      }
    });

    service.checkAndEmitAlerts(1, { batteryLevel: 12 });
  });

  it('should support alert dismissal', (done) => {
    service.checkAndEmitAlerts(1, { speed: 95 });

    setTimeout(() => {
      const activeAlerts = service.getActiveAlerts();
      expect(activeAlerts.size).toBe(1);

      const alertId = Array.from(activeAlerts.keys())[0];
      service.dismissAlert(alertId);

      expect(service.getActiveAlerts().size).toBe(0);
      done();
    }, 50);
  });

  it('should support alert snoozing', (done) => {
    service.checkAndEmitAlerts(1, { speed: 95 });

    setTimeout(() => {
      const alertId = Array.from(service.getActiveAlerts().keys())[0];
      service.snoozeAlert(alertId);

      const alert = service.getActiveAlerts().get(alertId);
      expect(alert?.snoozedUntil).toBeGreaterThan(Date.now());
      done();
    }, 50);
  });
});
