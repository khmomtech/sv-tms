import { ChangeDetectorRef, NgZone } from '@angular/core';
import { of } from 'rxjs';

import type { Driver } from '../models/driver.model';
import { LiveMapComponent } from './live-map.component';

describe('LiveMapComponent', () => {
  function createComponent(): LiveMapComponent {
    const driverLocationService = {
      getDriverLatestLocation: jasmine.createSpy('getDriverLatestLocation').and.returnValue(of(null)),
    };
    const router = { navigate: jasmine.createSpy('navigate') };
    const route = { snapshot: { queryParamMap: { get: () => null } } };
    const adminNotificationService = {};
    const driverChatService = {};
    const ngZone = new NgZone({ enableLongStackTrace: false });
    const cdr = { markForCheck: jasmine.createSpy('markForCheck') } as Partial<ChangeDetectorRef>;
    const confirm = {};
    const notify = {};
    const driverAlertService = {};
    const geofenceService = {};
    const authService = {};
    const translate = {
      instant: (key: string) =>
        (
          {
            'liveMap.address_unavailable': 'Address unavailable',
            'liveMap.resolving_address': 'Resolving address...',
            'liveMap.no_telemetry_yet': 'No telemetry yet',
          } as Record<string, string>
        )[key] ?? key,
    };

    return new LiveMapComponent(
      driverLocationService as any,
      router as any,
      route as any,
      adminNotificationService as any,
      driverChatService as any,
      ngZone,
      cdr as ChangeDetectorRef,
      confirm as any,
      notify as any,
      driverAlertService as any,
      geofenceService as any,
      authService as any,
      translate as any,
    );
  }

  function makeDriver(partial: Partial<Driver> = {}): Driver {
    return {
      id: 1,
      name: 'Test Driver',
      licenseNumber: '',
      phone: '',
      rating: 0,
      isActive: true,
      selected: false,
      logs: [],
      updatedFromSocket: false,
      status: 'offline',
      ...partial,
    } as Driver;
  }

  it('shows resolved address when location name exists', () => {
    const component = createComponent();
    const driver = makeDriver({
      locationName: 'Sangkat Boeung Kak, Phnom Penh',
      geocodeStatus: 'resolved',
      isOnline: true,
    });

    expect(component.getDriverGeocodeStatus(driver)).toBe('resolved');
    expect(component.getDriverLocationDisplay(driver)).toBe('Sangkat Boeung Kak, Phnom Penh');
    expect(component.getDriverLocationMuted(driver)).toBeFalse();
  });

  it('shows resolving state for online driver without resolved address', () => {
    const component = createComponent();
    const driver = makeDriver({
      locationName: '',
      geocodeStatus: 'pending',
      isOnline: true,
      lastUpdated: new Date().toISOString(),
    });

    expect(component.getDriverGeocodeStatus(driver)).toBe('pending');
    expect(component.getDriverLocationDisplay(driver)).toBe('Resolving address...');
    expect(component.getDriverLocationMuted(driver)).toBeTrue();
  });

  it('shows unavailable state for offline driver without address', () => {
    const component = createComponent();
    const driver = makeDriver({
      locationName: '',
      geocodeStatus: 'failed',
      isOnline: false,
      status: 'offline',
      lastUpdated: new Date(Date.now() - 10 * 60 * 1000).toISOString(),
    });

    expect(component.getDriverGeocodeStatus(driver)).toBe('failed');
    expect(component.getDriverLocationDisplay(driver)).toBe('Address unavailable');
    expect(component.getDriverLocationMuted(driver)).toBeTrue();
  });
});
