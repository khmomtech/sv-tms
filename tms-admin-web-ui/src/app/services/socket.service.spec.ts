import { TestBed, fakeAsync, tick } from '@angular/core/testing';
import { HttpClientTestingModule } from '@angular/common/http/testing';
import { BehaviorSubject } from 'rxjs';

import { AuthService } from './auth.service';
import { ConnectionMonitorService } from './connection-monitor.service';
import { SocketService } from './socket.service';

describe('SocketService', () => {
  let service: SocketService;
  const tokenRefreshed$ = new BehaviorSubject<string | null>(null);
  const authService = jasmine.createSpyObj('AuthService', [
    'getToken',
    'isAuthenticated',
    'isTokenExpired',
    'refreshToken',
  ]);
  (authService as any).tokenRefreshed$ = tokenRefreshed$.asObservable();

  const connectionMonitor = {
    setStatus: jasmine.createSpy('setStatus'),
  };

  beforeEach(() => {
    authService.getToken.calls.reset();
    authService.isAuthenticated.calls.reset();
    authService.isTokenExpired.calls.reset();
    authService.refreshToken.calls.reset();
    connectionMonitor.setStatus.calls.reset();

    TestBed.configureTestingModule({
      imports: [HttpClientTestingModule],
      providers: [
        SocketService,
        { provide: AuthService, useValue: authService },
        { provide: ConnectionMonitorService, useValue: connectionMonitor },
      ],
    });

    service = TestBed.inject(SocketService);
  });

  afterEach(() => {
    clearInterval((service as any).healthWatchTimer);
    if ((service as any).fallbackPollTimer) {
      clearInterval((service as any).fallbackPollTimer);
    }
  });

  it('skips connect when token is missing', () => {
    authService.getToken.and.returnValue(null);

    service.connect(['101'], 'test');

    expect(connectionMonitor.setStatus).toHaveBeenCalledWith('disconnected');
  });

  it('skips connect on public route', () => {
    authService.getToken.and.returnValue('token');
    authService.isAuthenticated.and.returnValue(true);
    authService.isTokenExpired.and.returnValue(false);
    spyOn<any>(service, 'isPublicRoute').and.returnValue(true);

    service.connect(['101'], 'test');

    expect(connectionMonitor.setStatus).toHaveBeenCalledWith('disconnected');
  });

  it('attempts one token refresh when access token is expired', fakeAsync(() => {
    authService.getToken.and.returnValue('expired-token');
    authService.isAuthenticated.and.returnValue(true);
    authService.isTokenExpired.and.returnValue(true);
    authService.refreshToken.and.returnValue(Promise.resolve(null));
    spyOn<any>(service, 'isPublicRoute').and.returnValue(false);

    service.connect(['101'], 'test');
    tick();

    expect(authService.refreshToken).toHaveBeenCalledTimes(1);
    expect(connectionMonitor.setStatus).toHaveBeenCalledWith('disconnected');
  }));

  it('marks connection monitor disconnected when websocket is open but realtime events are stale', () => {
    (service as any).isConnected = true;
    (service as any).contextDriverIds.set('driver-map', new Set(['101']));
    (service as any).lastRealtimeEventMs = Date.now() - 45_000;
    connectionMonitor.setStatus.calls.reset();

    (service as any).refreshConnectionHealth();

    expect((service as any).realtimeStateSubject.value).toBe('DISCONNECTED');
    expect(connectionMonitor.setStatus).toHaveBeenCalledWith('disconnected');
  });

  it('marks degraded fallback data as connection-monitor error', () => {
    connectionMonitor.setStatus.calls.reset();

    (service as any).processHealthMessage({
      body: JSON.stringify({ status: 'degraded' }),
    });

    expect((service as any).realtimeStateSubject.value).toBe('DEGRADED');
    expect(connectionMonitor.setStatus).toHaveBeenCalledWith('error');
  });
});
