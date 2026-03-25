import { TestBed, fakeAsync, flushMicrotasks, tick } from '@angular/core/testing';
import type { IMessage } from '@stomp/stompjs';

import { AuthService } from './auth.service';
import { WebSocketService } from './websocket.service';

class MockWebSocket {
  static instances: MockWebSocket[] = [];

  onopen?: () => void;
  onclose?: () => void;
  onerror?: () => void;

  constructor(public readonly url: string) {
    MockWebSocket.instances.push(this);
  }

  open(): void {
    this.onopen?.();
  }

  close(): void {
    this.onclose?.();
  }

  error(): void {
    this.onerror?.();
  }

  static reset(): void {
    MockWebSocket.instances = [];
  }
}

describe('WebSocketService', () => {
  let service: WebSocketService;
  let mockAuthService: jasmine.SpyObj<AuthService>;
  let originalWebSocket: typeof WebSocket;

  beforeEach(() => {
    originalWebSocket = globalThis.WebSocket;
    MockWebSocket.reset();
    (globalThis as any).WebSocket = MockWebSocket;

    mockAuthService = jasmine.createSpyObj<AuthService>('AuthService', [
      'getToken',
      'isTokenExpired',
      'refreshToken',
      'logout',
    ]);
    mockAuthService.getToken.and.returnValue('test-token');
    mockAuthService.isTokenExpired.and.returnValue(false);
    mockAuthService.refreshToken.and.resolveTo('fresh-token');

    TestBed.configureTestingModule({
      providers: [WebSocketService, { provide: AuthService, useValue: mockAuthService }],
    });

    service = TestBed.inject(WebSocketService);
  });

  afterEach(() => {
    (globalThis as any).WebSocket = originalWebSocket;
    service.disconnectStomp();
  });

  it('creates a websocket URL with the bearer token', fakeAsync(() => {
    service.connect('http://localhost:8080', '/ws');
    flushMicrotasks();

    expect(MockWebSocket.instances.length).toBe(1);
    expect(MockWebSocket.instances[0].url).toBe('ws://localhost:8080/ws?token=test-token');
  }));

  it('emits CONNECTED when the native websocket opens', fakeAsync(() => {
    let state: string | undefined;
    service.getConnectionState().subscribe((value) => (state = value));

    service.connect('http://localhost:8080', '/ws');
    flushMicrotasks();
    MockWebSocket.instances[0].open();

    expect(state).toBe('CONNECTED');
  }));

  it('refreshes the token on websocket error', fakeAsync(() => {
    service.connect('http://localhost:8080', '/ws');
    flushMicrotasks();

    MockWebSocket.instances[0].error();
    flushMicrotasks();

    expect(mockAuthService.refreshToken).toHaveBeenCalled();
  }));

  it('logs out after exceeding max reconnect attempts', fakeAsync(() => {
    service.connect('http://localhost:8080', '/ws');
    flushMicrotasks();

    (service as any).reconnectAttempts = 5;
    MockWebSocket.instances[0].close();

    expect(mockAuthService.logout).toHaveBeenCalled();
  }));

  it('reuses the same underlying subject for duplicate subscriptions', () => {
    service.subscribe('/topic/drivers');
    service.subscribe('/topic/drivers');

    expect((service as any).subscriptions.size).toBe(1);
  });

  it('delivers STOMP messages to subscribers when connected', () => {
    let received: any;
    let callback: ((message: IMessage) => void) | undefined;
    const subscribeSpy = jasmine
      .createSpy('subscribe')
      .and.callFake((_destination: string, cb: (message: IMessage) => void) => {
        callback = cb;
        return { unsubscribe() {} };
      });

    (service as any).stompClient = { subscribe: subscribeSpy };
    (service as any).connectionState$.next('CONNECTED');

    service.subscribe('/topic/drivers').subscribe((message) => {
      received = message;
    });
    callback?.({ body: JSON.stringify({ type: 'UPDATE', payload: { id: 1 } }) } as IMessage);

    expect(subscribeSpy).toHaveBeenCalledWith('/topic/drivers', jasmine.any(Function));
    expect(received).toEqual({ type: 'UPDATE', payload: { id: 1 } });
  });

  it('publishes STOMP messages only when connected', () => {
    const publishSpy = jasmine.createSpy('publish');
    (service as any).stompClient = { publish: publishSpy };

    service.send('/app/driver/update', { id: 1 });
    expect(publishSpy).not.toHaveBeenCalled();

    (service as any).connectionState$.next('CONNECTED');
    service.send('/app/driver/update', { id: 1 });

    expect(publishSpy).toHaveBeenCalledWith({
      destination: '/app/driver/update',
      body: JSON.stringify({ id: 1 }),
    });
  });

  it('clears tracked subscriptions on stomp disconnect', () => {
    const deactivateSpy = jasmine.createSpy('deactivate');
    (service as any).subscriptions.set(
      '/topic/drivers',
      jasmine.createSpyObj('subject', ['complete']),
    );
    (service as any).stompClient = { active: true, deactivate: deactivateSpy };

    service.disconnectStomp();

    expect(deactivateSpy).toHaveBeenCalled();
    expect((service as any).subscriptions.size).toBe(0);
  });
});
