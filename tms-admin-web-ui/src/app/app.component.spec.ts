import { TestBed } from '@angular/core/testing';
import { NavigationEnd, Router } from '@angular/router';
import { BehaviorSubject } from 'rxjs';

import { AppComponent } from './app.component';
import { AuthService } from './services/auth.service';
import { ConnectionMonitorService } from './services/connection-monitor.service';
import { SocketService } from './services/socket.service';

describe('AppComponent', () => {
  const status$ = new BehaviorSubject<string>('disconnected');
  const routeEvents$ = new BehaviorSubject<NavigationEnd>(new NavigationEnd(1, '/login', '/login'));

  const routerStub = {
    url: '/login',
    events: routeEvents$.asObservable(),
  };
  const socketService = jasmine.createSpyObj('SocketService', [
    'connect',
    'disconnectContext',
    'disconnect',
  ]);
  const connectionMonitor = {
    status$,
    setStatus: jasmine.createSpy('setStatus'),
  };
  const authService = jasmine.createSpyObj('AuthService', ['isAuthenticated', 'logout']);

  beforeEach(() => {
    socketService.connect.calls.reset();
    socketService.disconnectContext.calls.reset();
    socketService.disconnect.calls.reset();
    authService.isAuthenticated.calls.reset();
    authService.logout.calls.reset();
    routerStub.url = '/login';

    TestBed.configureTestingModule({
      providers: [
        { provide: Router, useValue: routerStub },
        { provide: SocketService, useValue: socketService },
        { provide: ConnectionMonitorService, useValue: connectionMonitor },
        { provide: AuthService, useValue: authService },
      ],
    });
  });

  it('does not connect websocket on public route', () => {
    authService.isAuthenticated.and.returnValue(true);

    const component = TestBed.runInInjectionContext(() => new AppComponent());
    component.ngOnInit();

    expect(socketService.disconnect).toHaveBeenCalled();
    expect(socketService.connect).not.toHaveBeenCalled();
    component.ngOnDestroy();
  });

  it('does not connect websocket during initial root redirect before login navigation completes', () => {
    routerStub.url = '/';
    authService.isAuthenticated.and.returnValue(true);

    const component = TestBed.runInInjectionContext(() => new AppComponent());
    component.ngOnInit();

    expect(socketService.disconnect).toHaveBeenCalled();
    expect(socketService.connect).not.toHaveBeenCalled();
    component.ngOnDestroy();
  });

  it('connects websocket on protected route when authenticated', () => {
    routerStub.url = '/dashboard';
    authService.isAuthenticated.and.returnValue(true);

    const component = TestBed.runInInjectionContext(() => new AppComponent());
    component.ngOnInit();

    expect(socketService.connect).toHaveBeenCalledWith([], 'app-root');
    component.ngOnDestroy();
  });

  it('logs out on protected route when not authenticated', () => {
    routerStub.url = '/dashboard';
    authService.isAuthenticated.and.returnValue(false);

    const component = TestBed.runInInjectionContext(() => new AppComponent());
    component.ngOnInit();

    expect(authService.logout).toHaveBeenCalled();
    expect(socketService.disconnect).toHaveBeenCalled();
    expect(socketService.connect).not.toHaveBeenCalled();
    component.ngOnDestroy();
  });
});
