import { ComponentFixture, TestBed } from '@angular/core/testing';
import { DriverAlertToastComponent } from './driver-alert-toast.component';
import type { DriverAlert } from '../../models/driver-alert.model';

describe('DriverAlertToastComponent', () => {
  let component: DriverAlertToastComponent;
  let fixture: ComponentFixture<DriverAlertToastComponent>;

  const mockAlert: DriverAlert = {
    id: '1:speeding:1234567890',
    driverId: 1,
    driverName: 'John Doe',
    type: 'speeding',
    severity: 'warning',
    timestamp: Date.now(),
    message: 'Driver 1 speeding: 95 km/h',
    value: 95,
    threshold: 80,
  };

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [DriverAlertToastComponent],
    }).compileComponents();

    fixture = TestBed.createComponent(DriverAlertToastComponent);
    component = fixture.componentInstance;
  });

  describe('Rendering', () => {
    it('should create', () => {
      expect(component).toBeTruthy();
    });

    it('should display alert message', () => {
      component.alert = mockAlert;
      fixture.detectChanges();

      const messageEl = fixture.nativeElement.querySelector('p');
      expect(messageEl.textContent).toContain('Driver 1 speeding: 95 km/h');
    });

    it('should display alert type in title', () => {
      component.alert = mockAlert;
      fixture.detectChanges();

      const titleEl = fixture.nativeElement.querySelector('h3');
      expect(titleEl.textContent).toContain('Speeding');
    });

    it('should display timestamp', () => {
      component.alert = mockAlert;
      fixture.detectChanges();

      const timestampEl = fixture.nativeElement.querySelector('.text-xs');
      expect(timestampEl).toBeTruthy();
      // Date pipe formats timestamp
      expect(timestampEl.textContent).toBeTruthy();
    });
  });

  describe('Severity-Based Styling', () => {
    it('should apply warning styles for warning severity', () => {
      component.alert = { ...mockAlert, severity: 'warning' };
      fixture.detectChanges();

      const container = fixture.nativeElement.querySelector('div');
      expect(container.classList.contains('bg-yellow-100')).toBe(true);
      expect(container.classList.contains('border-yellow-500')).toBe(true);

      const title = fixture.nativeElement.querySelector('h3');
      expect(title.classList.contains('text-yellow-800')).toBe(true);
    });

    it('should apply critical styles for critical severity', () => {
      component.alert = { ...mockAlert, severity: 'critical' };
      fixture.detectChanges();

      const container = fixture.nativeElement.querySelector('div');
      expect(container.classList.contains('bg-red-100')).toBe(true);
      expect(container.classList.contains('border-red-500')).toBe(true);

      const title = fixture.nativeElement.querySelector('h3');
      expect(title.classList.contains('text-red-800')).toBe(true);
    });

    it('should apply info styles for info severity', () => {
      component.alert = { ...mockAlert, severity: 'info' };
      fixture.detectChanges();

      const container = fixture.nativeElement.querySelector('div');
      expect(container.classList.contains('bg-blue-100')).toBe(true);
      expect(container.classList.contains('border-blue-500')).toBe(true);

      const title = fixture.nativeElement.querySelector('h3');
      expect(title.classList.contains('text-blue-800')).toBe(true);
    });
  });

  describe('Button Interactions', () => {
    it('should emit snoozed event on snooze button click', () => {
      spyOn(component.snoozed, 'emit');
      component.alert = mockAlert;
      fixture.detectChanges();

      const snoozeBtn = fixture.nativeElement.querySelectorAll('button')[0];
      snoozeBtn.click();

      expect(component.snoozed.emit).toHaveBeenCalledWith(mockAlert.id);
    });

    it('should emit dismissed event on dismiss button click', () => {
      spyOn(component.dismissed, 'emit');
      component.alert = mockAlert;
      fixture.detectChanges();

      const dismissBtn = fixture.nativeElement.querySelectorAll('button')[1];
      dismissBtn.click();

      expect(component.dismissed.emit).toHaveBeenCalledWith(mockAlert.id);
    });

    it('should have dismiss button with close icon', () => {
      component.alert = mockAlert;
      fixture.detectChanges();

      const buttons = fixture.nativeElement.querySelectorAll('button');
      const dismissBtn = buttons[1];
      expect(dismissBtn.textContent).toContain('✕');
    });

    it('should have snooze button with text', () => {
      component.alert = mockAlert;
      fixture.detectChanges();

      const buttons = fixture.nativeElement.querySelectorAll('button');
      const snoozeBtn = buttons[0];
      expect(snoozeBtn.textContent).toContain('Snooze');
    });
  });

  describe('CSS Classes', () => {
    it('should have fixed positioning', () => {
      component.alert = mockAlert;
      fixture.detectChanges();

      const container = fixture.nativeElement.querySelector('div');
      expect(container.classList.contains('fixed')).toBe(true);
      expect(container.classList.contains('top-4')).toBe(true);
      expect(container.classList.contains('right-4')).toBe(true);
    });

    it('should have animation class', () => {
      component.alert = mockAlert;
      fixture.detectChanges();

      const container = fixture.nativeElement.querySelector('div');
      expect(container.classList.contains('animate-slideInRight')).toBe(true);
    });

    it('should have z-index for layering', () => {
      component.alert = mockAlert;
      fixture.detectChanges();

      const container = fixture.nativeElement.querySelector('div');
      expect(container.classList.contains('z-50')).toBe(true);
    });

    it('should have max-width constraint', () => {
      component.alert = mockAlert;
      fixture.detectChanges();

      const container = fixture.nativeElement.querySelector('div');
      expect(container.classList.contains('max-w-sm')).toBe(true);
    });
  });

  describe('Accessibility', () => {
    it('should have descriptive button labels', () => {
      component.alert = mockAlert;
      fixture.detectChanges();

      const buttons = fixture.nativeElement.querySelectorAll('button');
      expect(buttons[0].textContent).toContain('Snooze');
      expect(buttons[1].textContent).toContain('✕');
    });

    it('should display all content in human-readable format', () => {
      component.alert = mockAlert;
      fixture.detectChanges();

      const text = fixture.nativeElement.textContent;
      expect(text).toContain('Speeding');
      expect(text).toContain('Driver 1 speeding: 95 km/h');
      expect(text).toContain('Snooze');
      expect(text).toContain('✕');
    });
  });

  describe('Different Alert Types', () => {
    it('should display harsh_braking alert', () => {
      component.alert = {
        ...mockAlert,
        type: 'harsh_braking',
        message: 'Harsh braking detected',
      };
      fixture.detectChanges();

      const title = fixture.nativeElement.querySelector('h3');
      expect(title.textContent).toContain('Harsh_braking');
    });

    it('should display battery_low alert', () => {
      component.alert = {
        ...mockAlert,
        type: 'battery_low',
        message: 'Battery low: 12%',
      };
      fixture.detectChanges();

      const title = fixture.nativeElement.querySelector('h3');
      expect(title.textContent).toContain('Battery_low');
    });
  });
});
