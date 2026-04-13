import { HttpHeaders, HttpParams, HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Client } from '@stomp/stompjs';
import type { IMessage, StompSubscription } from '@stomp/stompjs';
import type { IStompSocket } from '@stomp/stompjs';
import { BehaviorSubject } from 'rxjs';
import SockJS from 'sockjs-client';

import { environment } from '../environments/environment';

import type { AdminNotification } from './admin-notification.service';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { AuthService } from './auth.service';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { ConnectionMonitorService } from './connection-monitor.service';

export type PresenceStatus = 'ONLINE' | 'IDLE' | 'OFFLINE';
export type TelematicsConnectionState = 'LIVE' | 'DEGRADED' | 'DISCONNECTED';

export interface DriverLocation {
  driverId: string;
  latitude: number;
  longitude: number;
  label?: string;
  zone?: string;

  // timing/presence
  lastSeen?: number; // epoch ms from server
  serverTime?: number; // epoch ms
  clientTime?: number; // epoch ms
  presenceStatus?: PresenceStatus;
  isONLINE?: boolean;

  // UI helpers
  timestamp?: string;
  lastUpdated?: Date;

  // optional telemetry
  speed?: number;
  heading?: number;
  batteryLevel?: number;
  locationName?: string;
}

@Injectable({ providedIn: 'root' })
export class SocketService {
  private stompClient!: Client;
  private isConnected = false;
  private currentToken: string | null = null;
  private readonly reconnectDelayMs = 3000;
  private readonly logThrottleMs = 15000;
  private readonly logTimestamps = new Map<string, number>();
  private tokenRefreshInProgress = false;
  private readonly sockJsTransports = ['websocket', 'xhr-streaming', 'xhr-polling'];
  private fallbackPollTimer: ReturnType<typeof setInterval> | null = null;
  private healthWatchTimer: ReturnType<typeof setInterval>;
  private disconnectedAtMs = 0;
  private lastRealtimeEventMs = 0;

  // Track which consumers (contexts) requested which driver topics
  private readonly contextDriverIds = new Map<string, Set<string>>();
  private driverTopicSubscriptions = new Map<
    string,
    { location?: StompSubscription; presence?: StompSubscription }
  >();
  private globalSubscriptions: StompSubscription[] = [];

  // ---- Presence windows (match backend config + small grace) ----
  private readonly ONLINE_WINDOW_MS = 120_000; // online if now - lastSeen <= 120s
  private readonly IDLE_WINDOW_MS = 180_000; // idle if <= 180s else OFFLINE

  // ---- Emit throttle to coalesce presence+location bursts ----
  private readonly lastEmitTs = new Map<string, number>();
  private readonly MIN_EMIT_INTERVAL_MS = 400; // don't emit more than once per 400ms per driver

  // ---- Connection health / fallback controls ----
  private readonly DEGRADED_AFTER_MS = 15_000;
  private readonly DISCONNECTED_AFTER_MS = 30_000;
  private readonly FALLBACK_POLL_MS = 10_000;
  private readonly MAX_WS_FAILURES_BEFORE_COOLDOWN = 4;
  private readonly WS_FAILURE_COOLDOWN_MS = 60_000;
  private readonly MAX_FALLBACK_POLL_FAILURES = 3;
  private readonly FALLBACK_POLL_COOLDOWN_MS = 60_000;

  // merge cache so presence + location fold into one object per driver
  private readonly cache = new Map<string, DriverLocation>();
  private fallbackPollInFlight = false;
  private fallbackPollFailureCount = 0;
  private fallbackPollSuppressedUntilMs = 0;
  private wsFailureCount = 0;
  private wsReconnectSuppressedUntilMs = 0;

  // streams for UI
  private readonly driverLocationSubject = new BehaviorSubject<DriverLocation | null>(null);
  public readonly driverLocation$ = this.driverLocationSubject.asObservable();

  private readonly globaLocationsubject = new BehaviorSubject<DriverLocation | null>(null);
  public readonly globalLocation$ = this.globaLocationsubject.asObservable();

  private readonly statusSubject = new BehaviorSubject<string>('disconnected');
  public readonly status$ = this.statusSubject.asObservable();

  private readonly realtimeStateSubject = new BehaviorSubject<TelematicsConnectionState>(
    'DISCONNECTED',
  );
  public readonly realtimeState$ = this.realtimeStateSubject.asObservable();

  private readonly disconnectedDurationMsSubject = new BehaviorSubject<number>(0);
  public readonly disconnectedDurationMs$ = this.disconnectedDurationMsSubject.asObservable();

  private readonly staleDriverCountSubject = new BehaviorSubject<number>(0);
  public readonly staleDriverCount$ = this.staleDriverCountSubject.asObservable();

  private readonly reconnectAttemptsSubject = new BehaviorSubject<number>(0);
  public readonly reconnectAttempts$ = this.reconnectAttemptsSubject.asObservable();
  private readonly activeDemandSubject = new BehaviorSubject<boolean>(false);
  public readonly activeDemand$ = this.activeDemandSubject.asObservable();

  public readonly connectionStatus$ = new BehaviorSubject<boolean>(false);

  private readonly _notification$ = new BehaviorSubject<AdminNotification | null>(null);
  public readonly notification$ = this._notification$.asObservable();

  private setSocketStatus(status: string): void {
    if (this.statusSubject.value !== status) {
      this.statusSubject.next(status);
    }
  }

  private setRealtimeState(state: TelematicsConnectionState): void {
    if (this.realtimeStateSubject.value !== state) {
      this.realtimeStateSubject.next(state);
    }
  }

  private setConnectionStatus(connected: boolean): void {
    if (this.connectionStatus$.value !== connected) {
      this.connectionStatus$.next(connected);
    }
  }

  constructor(
    private readonly http: HttpClient,
    private readonly authService: AuthService,
    private readonly connectionMonitor: ConnectionMonitorService,
  ) {
    // Listen for token refresh events and reconnect with new token
    this.authService.tokenRefreshed$.subscribe((newToken) => {
      if (newToken && this.contextDriverIds.size > 0) {
        console.log('[WebSocket] Token refreshed, reconnecting with new token...');
        this.reconnect();
      }
    });

    this.healthWatchTimer = setInterval(() => this.refreshConnectionHealth(), 1000);
  }

  /** Register/refresh a context and ensure the WebSocket connection is active. */
  connect(driverIds: string[], contextId = 'default'): void {
    const token = this.authService.getToken();
    if (!token) {
      this.warnOnce('[WebSocket] JWT token missing. Cannot connect.', 'missing-token');
      this.setDisconnected('Missing token');
      return;
    }
    if (!this.authService.isAuthenticated()) {
      this.warnOnce(
        '[WebSocket] User is not authenticated. Skipping websocket connection.',
        'unauthenticated',
      );
      this.setDisconnected('Unauthenticated');
      return;
    }
    if (this.isPublicRoute()) {
      this.warnOnce(
        '[WebSocket] Public route detected. Skipping websocket connection.',
        'public-route',
      );
      this.setDisconnected('Public route');
      return;
    }

    const normalizedIds = (driverIds ?? []).filter((id): id is string => !!id);
    this.contextDriverIds.set(contextId, new Set(normalizedIds));
    this.updateActiveDemand();

    this.ensureClient(token);

    if (this.isConnected) {
      this.syncDriverSubscriptions();
    }
  }

  /** Release a context and unsubscribe driver topics no longer needed. */
  disconnectContext(contextId: string): void {
    if (!this.contextDriverIds.has(contextId)) {
      return;
    }
    this.contextDriverIds.delete(contextId);
    this.updateActiveDemand();
    if (this.contextDriverIds.size === 0) {
      this.disconnect(false);
      return;
    }
    if (this.isConnected) {
      this.syncDriverSubscriptions();
    }
  }

  hasActiveDemand(): boolean {
    return this.activeDemandSubject.value;
  }

  private updateActiveDemand(): void {
    this.activeDemandSubject.next(this.contextDriverIds.size > 0);
  }

  private ensureClient(token: string): void {
    const now = Date.now();
    if (this.wsReconnectSuppressedUntilMs > now) {
      this.warnOnce(
        '[WebSocket] Reconnect paused while backend is unstable. Using degraded mode.',
        'ws-reconnect-cooldown',
      );
      this.setDisconnected('Realtime temporarily paused');
      return;
    }

    // Don't connect with expired token
    if (this.authService.isTokenExpired(token)) {
      this.warnOnce(
        '[WebSocket] Access token expired. Attempting one refresh before connect.',
        'expired-token',
      );
      if (!this.tokenRefreshInProgress) {
        this.tokenRefreshInProgress = true;
        this.authService
          .refreshToken()
          .then((refreshedToken) => {
            if (!refreshedToken) {
              this.warnOnce(
                '[WebSocket] Token refresh failed. Connection will remain disconnected.',
                'refresh-failed',
              );
              this.setDisconnected('Token refresh failed');
              return;
            }
            this.ensureClient(refreshedToken);
          })
          .finally(() => {
            this.tokenRefreshInProgress = false;
          });
      }
      return;
    }
    if (this.stompClient) {
      if (!this.stompClient.active) {
        this.stompClient.reconnectDelay = this.reconnectDelayMs;
        this.stompClient.activate();
      }
      return;
    }

    this.stompClient = new Client({
      // comment out to silence STOMP traces (helps perf/flicker)
      // debug: (msg) => console.debug('[STOMP]', msg),
      reconnectDelay: this.reconnectDelayMs,
      heartbeatIncoming: 20000,
      heartbeatOutgoing: 20000,
      beforeConnect: async () => {
        if (!this.authService.isAuthenticated() || this.isPublicRoute()) {
          this.stompClient.reconnectDelay = 0;
          throw new Error('Skip websocket connect on public route or unauthenticated session');
        }
        let connectToken = this.authService.getToken();
        if (!connectToken || this.authService.isTokenExpired(connectToken)) {
          connectToken = await this.authService.refreshToken();
        }
        if (!connectToken) {
          this.stompClient.reconnectDelay = 0;
          throw new Error('Token refresh failed before websocket connect');
        }
        this.stompClient.reconnectDelay = this.reconnectDelayMs;
        this.currentToken = connectToken;
        this.stompClient.connectHeaders = { Authorization: `Bearer ${connectToken}` };
      },
      onConnect: () => this.onConnect(),
      onStompError: (frame) => this.setDisconnected(`[STOMP ERROR] ${frame.headers['message']}`),
      onWebSocketClose: () => {
        this.noteWebSocketFailure('websocket close');
        this.setDisconnected('WebSocket closed');
      },
      onWebSocketError: (err) => {
        this.noteWebSocketFailure('websocket error');
        this.setDisconnected(`WebSocket error: ${err?.message ?? 'unknown'}`);
        this.warnOnce(
          '[WebSocket] Error occurred, connection will retry automatically',
          'ws-error',
        );
      },
    });

    this.stompClient.webSocketFactory = () => {
      const latestToken = this.authService.getToken() ?? token;
      const encodedToken = encodeURIComponent(latestToken);
      if (environment.useSockJs) {
        const sockJsUrl = `${environment.sockJsUrl}?token=${encodedToken}`;
        return new SockJS(sockJsUrl, undefined, {
          transports: this.sockJsTransports,
        }) as unknown as IStompSocket;
      }

      const wsUrl = `${environment.wsSocketUrl}?token=${encodedToken}`;
      return new WebSocket(wsUrl) as unknown as IStompSocket;
    };

    this.stompClient.activate();
    this.reconnectAttemptsSubject.next(this.reconnectAttemptsSubject.value + 1);
  }

  /** Handle successful broker connect: subscribe to all topics we need. */
  private onConnect(): void {
    this.isConnected = true;
    this.disconnectedAtMs = 0;
    this.lastRealtimeEventMs = Date.now();
    this.wsFailureCount = 0;
    this.wsReconnectSuppressedUntilMs = 0;
    this.fallbackPollFailureCount = 0;
    this.fallbackPollSuppressedUntilMs = 0;
    this.disconnectedDurationMsSubject.next(0);
    this.reconnectAttemptsSubject.next(0);
    this.setConnectionStatus(true);
    this.setSocketStatus('connected');
    this.setRealtimeState('LIVE');
    this.connectionMonitor.setStatus('connected');
    this.stopFallbackPolling();

    console.log('[WebSocket] Connected. Subscribing…');

    this.clearGlobalSubscriptions();
    this.subscribeGlobalTopics();

    this.teardownDriverSubscriptions();
    this.syncDriverSubscriptions();
  }

  private clearGlobalSubscriptions(): void {
    this.globalSubscriptions.forEach((sub) => {
      try {
        sub.unsubscribe();
      } catch {
        /* noop */
      }
    });
    this.globalSubscriptions = [];
  }

  private subscribeGlobalTopics(): void {
    if (!this.stompClient) {
      return;
    }

    this.globalSubscriptions.push(
      this.stompClient.subscribe('/topic/driver-location/all', (msg) =>
        this.processMessage(this.globaLocationsubject, msg, 'all-location'),
      ),
    );
    this.globalSubscriptions.push(
      this.stompClient.subscribe('/topic/driver-presence/all', (msg) =>
        this.processMessage(this.globaLocationsubject, msg, 'all-presence'),
      ),
    );
    this.globalSubscriptions.push(
      this.stompClient.subscribe('/topic/admin-notifications', (msg) => {
        this.lastRealtimeEventMs = Date.now();
        try {
          const data: AdminNotification = JSON.parse(msg.body);
          this._notification$.next(data);
          console.log('[🔔 Notification]', data.title);
        } catch (e: any) {
          console.error('[Admin Notification] Parse Error:', e?.message ?? e);
        }
      }),
    );
    this.globalSubscriptions.push(
      this.stompClient.subscribe('/topic/telematics-health', (msg) =>
        this.processHealthMessage(msg),
      ),
    );
  }

  private teardownDriverSubscriptions(): void {
    for (const subs of this.driverTopicSubscriptions.values()) {
      try {
        subs.location?.unsubscribe();
      } catch {
        /* noop */
      }
      try {
        subs.presence?.unsubscribe();
      } catch {
        /* noop */
      }
    }
    this.driverTopicSubscriptions.clear();
  }

  private syncDriverSubscriptions(): void {
    if (!this.isConnected || !this.stompClient) {
      return;
    }

    const required = new Set<string>();
    this.contextDriverIds.forEach((ids) => {
      ids.forEach((id) => required.add(id));
    });

    // Subscribe new drivers
    required.forEach((driverId) => {
      if (!this.driverTopicSubscriptions.has(driverId)) {
        this.driverTopicSubscriptions.set(driverId, this.subscribeDriverTopics(driverId));
      }
    });

    // Unsubscribe drivers no longer referenced
    for (const driverId of Array.from(this.driverTopicSubscriptions.keys())) {
      if (!required.has(driverId)) {
        this.unsubscribeDriverTopics(driverId);
      }
    }
  }

  private subscribeDriverTopics(driverId: string): {
    location?: StompSubscription;
    presence?: StompSubscription;
  } {
    if (!this.stompClient) {
      return {};
    }

    const location = this.stompClient.subscribe(`/topic/driver-location/${driverId}`, (msg) =>
      this.processMessage(this.driverLocationSubject, msg, `driver:${driverId}`),
    );
    const presence = this.stompClient.subscribe(`/topic/driver-presence/${driverId}`, (msg) =>
      this.processMessage(this.driverLocationSubject, msg, `presence:${driverId}`),
    );

    return { location, presence };
  }

  private unsubscribeDriverTopics(driverId: string): void {
    const subs = this.driverTopicSubscriptions.get(driverId);
    if (subs) {
      try {
        subs.location?.unsubscribe();
      } catch {
        /* noop */
      }
      try {
        subs.presence?.unsubscribe();
      } catch {
        /* noop */
      }
      this.driverTopicSubscriptions.delete(driverId);
    }
    this.lastEmitTs.delete(driverId);
  }

  /** Publish a driver location (rarely used from admin, but available). */
  sendLocationUpdate(driverId: string, latitude: number, longitude: number): void {
    this.send('/app/location.update', { driverId, latitude, longitude });
  }

  private send<T>(destination: string, payload: T): void {
    if (!this.isConnected) {
      console.warn('[WebSocket] Not connected. Cannot send.');
      return;
    }
    this.stompClient.publish({ destination, body: JSON.stringify(payload) });
  }

  /** Cleanly disconnect and clear subscriptions. */
  disconnect(clearContexts: boolean = true): void {
    console.log('[WebSocket] Disconnecting…');
    if (clearContexts) {
      this.contextDriverIds.clear();
    }
    this.updateActiveDemand();
    this.teardownDriverSubscriptions();
    this.clearGlobalSubscriptions();

    if (this.stompClient?.active) {
      this.stompClient.deactivate();
    }

    this.setDisconnected('manual');
  }

  /** Force reconnect while preserving existing context driver subscriptions. */
  reconnect(): void {
    const now = Date.now();
    if (this.wsReconnectSuppressedUntilMs > now) {
      this.warnOnce(
        '[WebSocket] Manual reconnect ignored during cooldown window.',
        'ws-manual-reconnect-cooldown',
      );
      return;
    }
    console.log('[WebSocket] Reconnecting…');
    const contextsSnapshot = new Map<string, Set<string>>();
    this.contextDriverIds.forEach((set, key) => contextsSnapshot.set(key, new Set(set)));

    // Disconnect without clearing contexts
    this.disconnect(false);

    // Restore contexts
    contextsSnapshot.forEach((set, key) => this.contextDriverIds.set(key, set));

    const token = this.authService.getToken();
    if (!token) {
      console.warn('[WebSocket] Reconnect aborted: missing token');
      return;
    }

    this.ensureClient(token);
    if (this.isConnected) {
      this.syncDriverSubscriptions();
    }
  }

  private setDisconnected(reason: string): void {
    this.isConnected = false;
    this.setSocketStatus('disconnected');
    this.setConnectionStatus(false);
    this.connectionMonitor.setStatus('disconnected');
    if (this.disconnectedAtMs <= 0) {
      this.disconnectedAtMs = Date.now();
    }
    this.teardownDriverSubscriptions();
    this.clearGlobalSubscriptions();
    this.refreshConnectionHealth();
    this.startFallbackPolling();
    // keep cache so UI can still show last known positions if desired
    this.warnOnce(`[WebSocket] Disconnected: ${reason}`, `disconnected:${reason}`);
  }

  private noteWebSocketFailure(reason: string): void {
    this.wsFailureCount += 1;
    if (this.wsFailureCount < this.MAX_WS_FAILURES_BEFORE_COOLDOWN) {
      return;
    }

    this.wsReconnectSuppressedUntilMs = Date.now() + this.WS_FAILURE_COOLDOWN_MS;
    this.wsFailureCount = 0;
    try {
      if (this.stompClient) {
        this.stompClient.reconnectDelay = 0;
        if (this.stompClient.active) {
          this.stompClient.deactivate();
        }
      }
    } catch {
      /* noop */
    }
    this.warnOnce(
      `[WebSocket] Pausing reconnect attempts for ${Math.round(this.WS_FAILURE_COOLDOWN_MS / 1000)}s after repeated ${reason}.`,
      `ws-cooldown:${reason}`,
    );
  }

  private processHealthMessage(message: IMessage): void {
    try {
      const payload: any = JSON.parse(message.body);
      this.lastRealtimeEventMs = Date.now();
      const status = String(payload?.status ?? '').toLowerCase();
      if (status === 'degraded') {
        this.setRealtimeState('DEGRADED');
        this.setSocketStatus('degraded');
        this.connectionMonitor.setStatus('error');
      } else if (status === 'ok' || status === 'heartbeat') {
        this.setRealtimeState('LIVE');
        this.setSocketStatus('connected');
        this.connectionMonitor.setStatus('connected');
      }
    } catch (e: any) {
      console.warn('[telematics-health] Parse error:', e?.message ?? e);
    }
  }

  private refreshConnectionHealth(): void {
    const now = Date.now();
    if (this.disconnectedAtMs > 0) {
      this.disconnectedDurationMsSubject.next(now - this.disconnectedAtMs);
    } else {
      this.disconnectedDurationMsSubject.next(0);
    }

    if (!this.isConnected) {
      this.setRealtimeState('DISCONNECTED');
      this.setSocketStatus('disconnected');
      this.connectionMonitor.setStatus('disconnected');
      this.computeStaleDriverCount(now);
      return;
    }

    const hasTrackedDrivers = Array.from(this.contextDriverIds.values()).some(
      (driverIds) => driverIds.size > 0,
    );

    // When no driver topics are being tracked, keep state as LIVE while socket is connected.
    // This avoids false error/degraded transitions caused by sparse global traffic.
    if (!hasTrackedDrivers) {
      this.setRealtimeState('LIVE');
      this.setSocketStatus('connected');
      this.connectionMonitor.setStatus('connected');
      this.computeStaleDriverCount(now);
      return;
    }

    const age = this.lastRealtimeEventMs > 0 ? now - this.lastRealtimeEventMs : 0;
    if (age >= this.DISCONNECTED_AFTER_MS) {
      this.setRealtimeState('DISCONNECTED');
      this.setSocketStatus('disconnected');
      this.connectionMonitor.setStatus('disconnected');
      this.startFallbackPolling();
    } else if (age >= this.DEGRADED_AFTER_MS) {
      this.setRealtimeState('DEGRADED');
      this.setSocketStatus('degraded');
      this.connectionMonitor.setStatus('error');
    } else {
      this.setRealtimeState('LIVE');
      this.setSocketStatus('connected');
      this.connectionMonitor.setStatus('connected');
    }
    this.computeStaleDriverCount(now);
  }

  private startFallbackPolling(): void {
    if (this.fallbackPollTimer != null) {
      return;
    }
    this.fallbackPollTimer = setInterval(() => {
      if (this.isConnected) {
        return;
      }
      const now = Date.now();
      if (this.disconnectedAtMs > 0 && now - this.disconnectedAtMs < this.DISCONNECTED_AFTER_MS) {
        return;
      }
      if (this.fallbackPollSuppressedUntilMs > now) {
        return;
      }
      this.pollLatestDrivers();
    }, this.FALLBACK_POLL_MS);
  }

  private stopFallbackPolling(): void {
    if (this.fallbackPollTimer != null) {
      clearInterval(this.fallbackPollTimer);
      this.fallbackPollTimer = null;
    }
  }

  private pollLatestDrivers(): void {
    if (this.fallbackPollInFlight) {
      return;
    }

    const now = Date.now();
    if (this.fallbackPollSuppressedUntilMs > now) {
      return;
    }

    const token = this.authService.getToken();
    if (!token) {
      return;
    }
    const params = new HttpParams().set('onlyOnline', 'true').set('onlineSeconds', '120');
    const headers = new HttpHeaders({ Authorization: `Bearer ${token}` });
    this.fallbackPollInFlight = true;
    this.http
      .get<any>(`${environment.baseUrl}/api/admin/drivers/live-drivers`, {
        params,
        headers,
      })
      .subscribe({
        next: (response) => {
          this.fallbackPollInFlight = false;
          this.fallbackPollFailureCount = 0;
          const items = this.extractResponseItems(response);
          if (items.length === 0) {
            this.refreshConnectionHealth();
            return;
          }
          const now = Date.now();
          this.lastRealtimeEventMs = now;
          for (const item of items) {
            this.upsertFromPayload(item, this.globaLocationsubject, 'rest-fallback', false);
          }
          this.setRealtimeState('DEGRADED');
          this.setSocketStatus('degraded');
          this.connectionMonitor.setStatus('error');
        },
        error: (err) => {
          this.fallbackPollInFlight = false;
          this.fallbackPollFailureCount += 1;
          if (this.fallbackPollFailureCount >= this.MAX_FALLBACK_POLL_FAILURES) {
            this.fallbackPollFailureCount = 0;
            this.fallbackPollSuppressedUntilMs = Date.now() + this.FALLBACK_POLL_COOLDOWN_MS;
            this.warnOnce(
              `[WebSocket fallback] Pausing live-driver polling for ${Math.round(this.FALLBACK_POLL_COOLDOWN_MS / 1000)}s after repeated failures.`,
              'fallback-poll-cooldown',
            );
          }
          this.warnOnce(
            `[WebSocket fallback] live-drivers poll failed: ${err?.status ?? err}`,
            'fallback-poll-failed',
          );
        },
      });
  }

  private extractResponseItems(response: any): any[] {
    if (Array.isArray(response)) {
      return response;
    }
    if (Array.isArray(response?.data)) {
      return response.data;
    }
    return [];
  }

  /**
   * Unified message handler for both location and presence payloads.
   * It merges fields into a per-driver cache, computes presence,
   * emits both the specific subject (per-driver) and global subject.
   */
  private processMessage(
    subject: BehaviorSubject<DriverLocation | null>,
    message: IMessage,
    label: string,
  ): void {
    try {
      const raw: any = JSON.parse(message.body);
      this.lastRealtimeEventMs = Date.now();
      this.upsertFromPayload(raw, subject, label, true);
    } catch (err: any) {
      console.error(`[${label}] Parse error:`, err?.message ?? err);
    }
  }

  private warnOnce(message: string, key: string): void {
    const now = Date.now();
    const previous = this.logTimestamps.get(key) ?? 0;
    if (now - previous < this.logThrottleMs) {
      return;
    }
    this.logTimestamps.set(key, now);
    console.warn(message);
  }

  private upsertFromPayload(
    raw: any,
    subject: BehaviorSubject<DriverLocation | null>,
    label: string,
    throttle: boolean,
  ): void {
    const driverId = String(raw?.driverId ?? '');
    if (!driverId) {
      console.warn(`[${label}] Missing driverId`, raw);
      return;
    }

    const prev = this.cache.get(driverId) ?? ({ driverId } as DriverLocation);
    const merged: DriverLocation = {
      ...prev,
      ...raw,
      driverId,
    };

    const lat = raw?.latitude ?? raw?.lat;
    const lng = raw?.longitude ?? raw?.lng;
    if (typeof lat === 'number' && typeof lng === 'number') {
      merged.latitude = lat;
      merged.longitude = lng;
    } else if (raw?.latitude === undefined || raw?.longitude === undefined) {
      merged.latitude = prev.latitude!;
      merged.longitude = prev.longitude!;
    }

    const now = Date.now();
    const lastSeen =
      typeof raw?.lastSeen === 'number'
        ? raw.lastSeen
        : typeof raw?.serverTime === 'number'
          ? raw.serverTime
          : typeof merged.lastSeen === 'number'
            ? merged.lastSeen
            : now;
    merged.lastSeen = lastSeen;
    merged.lastUpdated = new Date(lastSeen);

    const status = (raw?.presenceStatus ?? merged.presenceStatus) as PresenceStatus | undefined;
    if (status) {
      merged.presenceStatus = status;
      merged.isONLINE = status === 'ONLINE';
    } else {
      const age = now - lastSeen;
      if (age <= this.ONLINE_WINDOW_MS) {
        merged.isONLINE = true;
        merged.presenceStatus = 'ONLINE';
      } else if (age <= this.IDLE_WINDOW_MS) {
        merged.isONLINE = false;
        merged.presenceStatus = 'IDLE';
      } else {
        merged.isONLINE = false;
        merged.presenceStatus = 'OFFLINE';
      }
    }

    this.cache.set(driverId, merged);

    if (throttle) {
      const lastEmit = this.lastEmitTs.get(driverId) ?? 0;
      if (now - lastEmit < this.MIN_EMIT_INTERVAL_MS) {
        this.computeStaleDriverCount(now);
        return;
      }
      this.lastEmitTs.set(driverId, now);
    }

    subject.next(merged);
    this.globaLocationsubject.next(merged);
    this.computeStaleDriverCount(now);
  }

  private computeStaleDriverCount(now: number): void {
    let stale = 0;
    for (const location of this.cache.values()) {
      const lastSeen = location.lastSeen ?? location.lastUpdated?.getTime() ?? 0;
      if (lastSeen > 0 && now - lastSeen > this.ONLINE_WINDOW_MS) {
        stale++;
      }
    }
    this.staleDriverCountSubject.next(stale);
  }

  private isPublicRoute(): boolean {
    if (typeof window === 'undefined' || !window.location) {
      return false;
    }
    const path = window.location.pathname || '';
    return path === '/login' || path.startsWith('/tracking');
  }
}
