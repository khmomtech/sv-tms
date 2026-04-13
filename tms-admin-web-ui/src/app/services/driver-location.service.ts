// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { HttpClient } from '@angular/common/http';
import { HttpHeaders, HttpParams } from '@angular/common/http';
import type { OnDestroy } from '@angular/core';
import { Injectable } from '@angular/core';
import type { IMessage, IStompSocket, StompSubscription } from '@stomp/stompjs';
import { Client } from '@stomp/stompjs';
import type { Observable } from 'rxjs';
import { Subject, BehaviorSubject, ReplaySubject, interval, merge, fromEvent } from 'rxjs';
import { auditTime, shareReplay, startWith, map, distinctUntilChanged } from 'rxjs/operators';
import SockJS from 'sockjs-client';

import { environment } from '../environments/environment';
import type { ApiResponse } from '../models/api-response.model';
import type { Driver } from '../models/driver.model';
import type { GeofenceEvent } from '../models/geofence.model';

// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { AuthService } from './auth.service';

export type PresenceStatus = 'ONLINE' | 'IDLE' | 'OFFLINE';

export interface LiveDriverDto {
  driverId: number;
  driverName?: string;
  locationName?: string;
  geocodeStatus?: 'resolved' | 'pending' | 'failed' | string;

  // Coordinates: support both pairs
  latitude?: number;
  longitude?: number;
  lat?: number;
  lng?: number;

  speed?: number | null;
  heading?: number | null;
  battery?: number | null;
  accuracy?: number | null;

  // Timestamps
  serverTime?: number;
  clientTime?: number;
  lastSeen?: number;
  lastSeenEpochMs?: number;
  lastSeenSeconds?: number;
  ingestLagSeconds?: number;
  lastUpdated?: number;
  updatedAt?: string;

  // Presence
  presenceStatus?: PresenceStatus;
  isOnline?: boolean;
  wsConnected?: boolean;

  // Misc
  netType?: string | null;
  source?: string | null;
}

export interface HistoryPoint {
  id?: number;
  driverId?: number;
  latitude: number;
  longitude: number;
  timestamp: string;
  eventTime?: string;
  speed?: number | null;
  heading?: number | null;
  batteryLevel?: number | null;
  locationName?: string | null;
  locationSource?: string | null;
  source?: string | null;
  sessionId?: string | null;
  seq?: number | null;
  isOnline?: boolean;
}

// moved above to satisfy import/order for type imports

type SubscribeRecord = {
  topic: string;
  handler: (msg: IMessage) => void;
  sub?: StompSubscription;
};

@Injectable({
  providedIn: 'root',
})
export class DriverLocationService implements OnDestroy {
  private stompClient!: Client;
  private connected = false;

  // ---- Presence windows (align with backend + small grace) ----
  private readonly ONLINE_WINDOW_MS = 35_000; // online if now - lastSeen <= 35s
  private readonly IDLE_WINDOW_MS = 180_000; // idle if <= 180s else OFFLINE

  // ---- Emit throttle to coalesce presence+location bursts per driver ----
  private readonly lastEmitTs = new Map<number, number>();
  private readonly MIN_EMIT_INTERVAL_MS = 400; // don't emit more than once per 400ms per driver

  // progressive reconnect backoff
  private baseDelay = 4000;
  private backoff = this.baseDelay;
  private maxReconnectAttempts = 6; // budget within a session
  private reconnectAttempts = 0;

  // circuit breaker for auth failures
  private authFailureCount = 0;
  private wsCircuitOpen = false;
  private restFallbackUntil = 0;
  private readonly MAX_AUTH_FAILURES = 2;
  private readonly CIRCUIT_OPEN_DURATION_MS = 5 * 60 * 1000; // 5 minutes

  // de-dupe last seen per driver to reduce churn
  private lastByDriver = new Map<number, LiveDriverDto>();
  private lastByDriverAccessTime = new Map<number, number>(); // track last access time for LRU
  private readonly MAX_DRIVER_CACHE_SIZE = 1000;
  private readonly SUBJECT_CLEANUP_INTERVAL_MS = 5 * 60 * 1000; // 5 minutes

  // memory management cleanup timers
  private cleanupTimer?: number;

  // prevent multiple pending subscribe timers per topic
  private pendingSubscribe = new Set<string>();

  // per-driver live subjects
  private locationSubjects: { [driverId: number]: ReplaySubject<any> } = {};
  private locationSubjectAccessTime: { [driverId: number]: number } = {}; // track access times for cleanup
  // global live stream (all drivers)
  private globalSubject = new Subject<any>();
  private global$ = this.globalSubject
    .asObservable()
    .pipe(auditTime(200), shareReplay({ bufferSize: 1, refCount: true }));
  // connection status
  private status$ = new BehaviorSubject<
    'init' | 'connecting' | 'connected' | 'error' | 'disconnected'
  >('init');

  // geofence alerts
  private geofenceAlerts$ = new Subject<any>();

  // track topic subscriptions so we can re-subscribe on reconnect
  private subscriptions: Map<string, SubscribeRecord> = new Map();

  // teardown
  private destroyed$ = new ReplaySubject<void>(1);
  // Re-evaluate presence every second and when tab comes back or network changes
  private readonly tick$ = interval(1000).pipe(startWith(0));

  constructor(
    private readonly authService: AuthService,
    private readonly http: HttpClient,
  ) {
    this.connect();

    // Reconnect if token refreshes (optional if AuthService exposes token$)
    (this.authService as any).token$?.subscribe((t: any) => {
      if (t) this.reconnect();
    });

    // Start cleanup timer for unused subjects and cache eviction
    this.cleanupTimer = window.setInterval(
      () => this.cleanupUnusedSubjects(),
      this.SUBJECT_CLEANUP_INTERVAL_MS,
    );

    // Recompute presence ages periodically and when app becomes visible / network returns
    merge(
      fromEvent(document, 'visibilitychange').pipe(map(() => 0)),
      fromEvent(window, 'online').pipe(
        map(() => {
          // If circuit is open and 5 minutes have passed, attempt reconnect
          if (this.wsCircuitOpen && Date.now() >= this.restFallbackUntil) {
            console.log(
              '[DriverLocationService] Circuit was open, attempting reconnect after 5min...',
            );
            this.wsCircuitOpen = false;
            this.authFailureCount = 0;
            this.reconnect();
          }
          return 0;
        }),
      ),
      this.tick$,
    ).subscribe(() => this.reemitPresenceAges());
  }

  // ============ REST: Drivers list ============
  getAllDrivers(): Observable<{ success: boolean; data: Driver[] }> {
    return this.http.get<{ success: boolean; data: Driver[] }>(
      `${environment.baseUrl}/api/admin/drivers/all`,
      { headers: this.authHeaders() },
    );
  }

  /**
   * REST: Live map endpoint with optional bbox + ONLINE window
   * GET /api/admin/drivers/live-drivers?onlyOnline=true&south=...&west=...&north=...&east=...&onlineSeconds=120
   */
  getLiveDrivers(
    params: {
      onlyONLINE?: boolean;
      onlyOnline?: boolean;
      south?: number;
      west?: number;
      north?: number;
      east?: number;
      ONLINESeconds?: number;
      onlineSeconds?: number;
    } = {},
  ): Observable<ApiResponse<LiveDriverDto[]>> {
    const onlyOnline = params.onlyONLINE ?? params.onlyOnline;
    const onlineSeconds = params.ONLINESeconds ?? params.onlineSeconds;

    const hp = new HttpParams({
      fromObject: {
        ...(onlyOnline !== undefined ? { onlyOnline: String(onlyOnline) } : {}),
        ...(params.south !== undefined ? { south: String(params.south) } : {}),
        ...(params.west !== undefined ? { west: String(params.west) } : {}),
        ...(params.north !== undefined ? { north: String(params.north) } : {}),
        ...(params.east !== undefined ? { east: String(params.east) } : {}),
        ...(onlineSeconds !== undefined ? { onlineSeconds: String(onlineSeconds) } : {}),
      },
    });

    return this.http.get<ApiResponse<LiveDriverDto[]>>(
      `${environment.baseUrl}/api/admin/drivers/live-drivers`,
      { headers: this.authHeaders(), params: hp },
    );
  }

  /** REST: Latest location for a single driver (WS fallback / debugging) */
  getDriverLatestLocation(driverId: number): Observable<ApiResponse<any>> {
    return this.http.get<ApiResponse<any>>(
      `${environment.baseUrl}/api/admin/drivers/${driverId}/latest-location`,
      { headers: this.authHeaders() },
    );
  }

  /**
   * REST: Location history from telematics service (port 8082).
   * Points returned oldest-first, ready for playback animation.
   * @param from ISO-8601 string e.g. '2024-01-15T00:00:00'
   * @param to   ISO-8601 string e.g. '2024-01-15T23:59:59'
   * @param size max points to return (capped at 2000 by backend)
   */
  getDriverHistory(
    driverId: number,
    from?: string,
    to?: string,
    size = 500,
  ): Observable<HistoryPoint[]> {
    let params = new HttpParams().set('size', String(size));
    if (from) params = params.set('from', from);
    if (to) params = params.set('to', to);
    return this.http.get<HistoryPoint[]>(
      `${environment.baseUrl}/api/admin/drivers/${driverId}/history`,
      { headers: this.authHeaders(), params },
    );
  }

  // ============ WebSocket / STOMP ============

  connect(): void {
    const token = this.authService.getToken();
    if (!token) {
      console.warn('[DriverLocationService] No JWT token. Skipping WebSocket connect.');
      this.status$.next('disconnected');
      return;
    }

    // Token freshness pre-check: avoid opening WS with stale/expiring token
    const exp = this.getJwtExp(token);
    const nowSec = Math.floor(Date.now() / 1000);
    const aboutToExpire = exp != null && exp - nowSec <= 60; // less than 60s left
    if (aboutToExpire) {
      try {
        // Attempt a silent refresh if supported; otherwise skip WS
        const refreshed = (this.authService as any).refreshToken?.();
        // If refresh is async Observable/Promise, we can bail early and let token$ trigger reconnect
      } catch {}
      console.warn('[DriverLocationService] JWT expiring soon. Pausing WS connect.');
      this.status$.next('disconnected');
      return;
    }

    // Respect reconnect budget
    if (this.reconnectAttempts >= this.maxReconnectAttempts) {
      console.warn('[DriverLocationService] Reconnect budget exhausted. Using REST fallback.');
      this.status$.next('disconnected');
      return;
    }

    // build URLs
    const wsUrl = `${environment.telematicsWsSocketUrl}?token=${encodeURIComponent(token)}`;
    const sockJsUrl = `${environment.telematicsSockJsUrl}?token=${encodeURIComponent(token)}`;

    // instantiate
    this.stompClient = new Client({
      // Include auth headers in STOMP CONNECT so backends that don't read query params can auth
      connectHeaders: {
        Authorization: `Bearer ${token}`,
        'X-Client': 'sv-admin-ui',
        'X-Auth-Token': token,
      },
      webSocketFactory: () =>
        environment.useSockJs
          ? (new SockJS(sockJsUrl) as unknown as IStompSocket)
          : new WebSocket(wsUrl),

      reconnectDelay: this.backoff, // ms (progressive backoff)
      heartbeatIncoming: 20000,
      heartbeatOutgoing: 20000,

      debug: (str) => {
        // comment out in prod if too noisy
        // console.log('🧩 STOMP:', str);
      },

      beforeConnect: () => {
        this.status$.next('connecting');
      },

      onConnect: () => {
        this.connected = true;
        this.status$.next('connected');
        // reset backoff on successful connect
        this.backoff = this.baseDelay;
        this.stompClient.reconnectDelay = this.baseDelay;
        this.reconnectAttempts = 0;
        // re-subscribe all topics after reconnect
        this.resubscribeAll();
        console.log('Connected to WebSocket');
      },

      onStompError: async (frame) => {
        console.error('💥 STOMP error:', frame);
        const msg = (frame && (frame.headers?.['message'] || frame.body)) || '';
        const isAuthFailure = /401|403|unauth|expired|invalid|revoked/i.test(String(msg));
        if (isAuthFailure) {
          this.authFailureCount++;
          if (this.authFailureCount >= this.MAX_AUTH_FAILURES) {
            this.wsCircuitOpen = true;
            this.restFallbackUntil = Date.now() + this.CIRCUIT_OPEN_DURATION_MS;
            console.warn(
              `[DriverLocationService] Circuit breaker activated after ${this.authFailureCount} auth failures. Using REST fallback for 5 minutes.`,
            );
            this.status$.next('disconnected');
            return;
          }
          try {
            const refreshed = await (this.authService.refreshToken?.() as Promise<string | null>);
            if (refreshed) {
              // Update headers with fresh token and reconnect
              this.stompClient.connectHeaders = {
                ...(this.stompClient.connectHeaders || {}),
                Authorization: `Bearer ${refreshed}`,
                'X-Auth-Token': refreshed,
              } as any;
              this.reconnect();
              this.authFailureCount = 0; // reset on successful refresh
              return;
            }
          } catch (e) {
            console.warn('[DriverLocationService] Token refresh failed after STOMP error');
          }
        }
        this.status$.next('error');
      },

      onWebSocketError: async (evt) => {
        console.error('💥 WebSocket error:', evt);
        // If the server indicates auth issues, try a one-time refresh before escalating
        try {
          const txt = (evt as any)?.message || (evt as any)?.reason || '';
          const authish = /401|403|unauth|expired|invalid|revoked/i.test(String(txt));
          if (authish) {
            this.authFailureCount++;
            if (this.authFailureCount >= this.MAX_AUTH_FAILURES) {
              this.wsCircuitOpen = true;
              this.restFallbackUntil = Date.now() + this.CIRCUIT_OPEN_DURATION_MS;
              console.warn(
                `[DriverLocationService] Circuit breaker activated after ${this.authFailureCount} auth failures. Using REST fallback for 5 minutes.`,
              );
              return;
            }
            const refreshed = await (this.authService.refreshToken?.() as Promise<string | null>);
            if (refreshed) {
              this.stompClient.connectHeaders = {
                ...(this.stompClient.connectHeaders || {}),
                Authorization: `Bearer ${refreshed}`,
                'X-Auth-Token': refreshed,
              } as any;
              this.reconnect();
              this.authFailureCount = 0; // reset on successful refresh
              return;
            }
          }
        } catch {}
        // increase backoff on failures (cap at 30s)
        // FIX: Apply jitter within the cap, not after
        this.backoff = Math.min(this.backoff * 1.5 + Math.floor(Math.random() * 2000), 30000);
        this.stompClient.reconnectDelay = this.backoff;
        this.reconnectAttempts++;
        if (this.reconnectAttempts >= this.maxReconnectAttempts) {
          console.warn('[DriverLocationService] Reconnect attempts exceeded. Deactivating WS.');
          try {
            this.stompClient.deactivate();
          } catch {}
          this.connected = false;
          this.status$.next('disconnected');
          return;
        }
        this.status$.next('error');
      },

      onWebSocketClose: async () => {
        console.warn('🔌 WebSocket closed');
        this.connected = false;
        this.status$.next('disconnected');
        // keep subscriptions map; they’ll be re-bound on next connect
      },
    });

    this.stompClient.activate();
  }

  reconnect(): void {
    try {
      this.stompClient?.deactivate();
    } catch {}
    this.connected = false;
    // allow budget to continue for this session
    // subscriptions map is preserved; they will be rebound on next connect
    this.connect();
  }

  /** Subscribe to a driver-specific topic; auto re-subscribes on reconnect. */
  subscribeToDriver(driverId: number): Observable<any> {
    if (!this.locationSubjects[driverId]) {
      this.locationSubjects[driverId] = new ReplaySubject<any>(1);
    }

    // Track access time for cleanup purposes
    this.locationSubjectAccessTime[driverId] = Date.now();

    const topic = `/topic/driver-location/${driverId}`;

    const handler = (msg: IMessage) => {
      try {
        const data = this.normalizeAndDecorate(JSON.parse(msg.body));
        this.ingest(data);
        // Also emit to the per-driver subject to keep backward compatibility
        this.locationSubjects[driverId].next(this.lastByDriver.get(driverId) as LiveDriverDto);
      } catch (err) {
        console.error(`🚫 Failed parsing message for driver ${driverId}:`, err);
      }
    };

    this.ensureSubscribed(topic, handler);
    return this.locationSubjects[driverId].asObservable();
  }

  /** Subscribe to the aggregate stream of all driver updates. */
  subscribeToAll(): Observable<any> {
    const topic = `/topic/driver-location/all`;
    const presenceTopic = `/topic/driver-presence/all`;

    const handler = (msg: IMessage) => {
      try {
        const data = this.normalizeAndDecorate(JSON.parse(msg.body));
        this.ingest(data);
      } catch (err) {
        console.error('🚫 Failed parsing global location/presence data:', err);
      }
    };

    this.ensureSubscribed(topic, handler);
    this.ensureSubscribed(presenceTopic, handler);
    return this.global$;
  }

  /** Subscribe to connection status: 'init' | 'connecting' | 'connected' | 'error' | 'disconnected' */
  subscribeToStatus(): Observable<'init' | 'connecting' | 'connected' | 'error' | 'disconnected'> {
    return this.status$.asObservable();
  }

  /** Subscribe to geofence crossing alerts */
  subscribeToGeofenceAlerts(): Observable<GeofenceEvent> {
    // Ensure subscription to the WebSocket topic
    const topic = '/user/queue/geofence-alerts';
    this.ensureSubscribed(topic, (msg: IMessage) => {
      try {
        const event = JSON.parse(msg.body) as GeofenceEvent;
        this.geofenceAlerts$.next(event);
      } catch (err) {
        console.error('Failed to parse geofence alert:', err);
      }
    });

    return this.geofenceAlerts$.asObservable();
  }

  /** Read-only connection status Observable for consumers that prefer a method name */
  connectionStatus$(): Observable<'init' | 'connecting' | 'connected' | 'error' | 'disconnected'> {
    return this.status$.asObservable();
  }

  /** Explicit unsubscribe for a driver topic (frees server & client resources). */
  unsubscribeDriver(driverId: number): void {
    const topic = `/topic/driver-location/${driverId}`;
    const rec = this.subscriptions.get(topic);
    if (rec?.sub) {
      try {
        rec.sub.unsubscribe();
      } catch {}
    }
    this.subscriptions.delete(topic);
    if (this.locationSubjects[driverId]) {
      this.locationSubjects[driverId].complete();
      delete this.locationSubjects[driverId];
    }
  }

  /** Disconnect and cleanup everything. */
  disconnect(): void {
    // unsubscribe all topics
    for (const [topic, rec] of this.subscriptions) {
      try {
        rec.sub?.unsubscribe();
      } catch {}
    }
    this.subscriptions.clear();

    // close stomp
    if (this.stompClient?.active) {
      this.stompClient.deactivate();
      console.log('🛑 WebSocket disconnected');
    }

    // complete subjects
    Object.values(this.locationSubjects).forEach((s) => s.complete());
    this.locationSubjects = {};

    this.status$.next('disconnected');

    this.connected = false;
  }

  /** Public accessor for throttled global live stream */
  public live$(): Observable<any> {
    return this.global$;
  }

  ngOnDestroy(): void {
    this.destroyed$.next();
    this.destroyed$.complete();
    // Clean up timers before disconnecting
    if (this.cleanupTimer) {
      window.clearInterval(this.cleanupTimer);
    }
    this.disconnect();
  }

  // ============ Helpers ============

  private ensureSubscribed(topic: string, handler: (msg: IMessage) => void) {
    // If already tracked and has a live subscription, do nothing.
    const existing = this.subscriptions.get(topic);
    if (existing?.sub) return;

    // Track record (so we can resubscribe on reconnect)
    this.subscriptions.set(topic, { topic, handler, sub: undefined });

    const trySub = () => {
      if (this.connected) {
        try {
          const sub = this.stompClient.subscribe(topic, handler);
          const rec = this.subscriptions.get(topic);
          if (rec) rec.sub = sub;
          this.pendingSubscribe.delete(topic);
        } catch (e) {
          console.error(`Failed to subscribe ${topic}`, e);
        }
      } else if (!this.pendingSubscribe.has(topic)) {
        // retry shortly until connected (but avoid spawning many timers)
        this.pendingSubscribe.add(topic);
        setTimeout(trySub, 500);
      }
    };

    trySub();
  }

  private resubscribeAll() {
    for (const [topic, rec] of this.subscriptions) {
      // Unsubscribe old if any (safety)
      try {
        rec.sub?.unsubscribe();
      } catch {}
      // Re-subscribe
      try {
        rec.sub = this.stompClient.subscribe(topic, rec.handler);
      } catch (e) {
        console.error(`Failed to re-subscribe ${topic}`, e);
      }
    }
  }

  /** Normalize inputs, mirror coordinate fields, coerce numbers, clamp, and fill timestamps. */
  private normalizeAndDecorate(obj: any): LiveDriverDto {
    const o: any = typeof obj === 'object' && obj ? { ...obj } : {};
    // coordinates aliasing
    if (o.latitude === undefined && o.lat !== undefined) o.latitude = o.lat;
    if (o.longitude === undefined && o.lng !== undefined) o.longitude = o.lng;
    if (o.lat === undefined && o.latitude !== undefined) o.lat = o.latitude;
    if (o.lng === undefined && o.longitude !== undefined) o.lng = o.longitude;
    // accuracy / battery aliasing
    if (o.accuracy === undefined && o.accuracyMeters !== undefined) o.accuracy = o.accuracyMeters;
    if (o.battery === undefined && o.batteryLevel !== undefined) o.battery = o.batteryLevel;

    const toNum = (v: any) => (typeof v === 'string' ? Number(v) : v);
    [
      'latitude',
      'longitude',
      'lat',
      'lng',
      'accuracy',
      'battery',
      'speed',
      'heading',
      'serverTime',
      'clientTime',
      'lastSeen',
    ].forEach((k) => {
      if (o[k] != null) o[k] = toNum(o[k]);
    });

    // clamp sanity
    if (typeof o.latitude === 'number') {
      if (!Number.isFinite(o.latitude)) o.latitude = 0;
      o.latitude = Math.max(-90, Math.min(90, o.latitude));
    }
    if (typeof o.longitude === 'number') {
      if (!Number.isFinite(o.longitude)) o.longitude = 0;
      o.longitude = Math.max(-180, Math.min(180, o.longitude));
    }

    // fill timestamps
    const lastSeen = this.pickLastSeen(o);
    o.lastSeen = lastSeen;
    o.lastUpdated = lastSeen;

    // compute presence if missing
    if (typeof o.isOnline !== 'boolean' || !o.presenceStatus) {
      const { status, online } = this.computePresence(lastSeen, Date.now());
      if (o.isOnline === undefined) o.isOnline = online;
      o.presenceStatus = o.presenceStatus || status;
    }

    return o as LiveDriverDto;
  }

  private pickLastSeen(d: Partial<LiveDriverDto>): number {
    const v = d.lastSeen ?? d.serverTime ?? d.clientTime ?? Date.now();
    return typeof v === 'string' ? Number(v) : v;
  }

  private computePresence(
    lastSeenMs: number,
    now: number,
  ): { status: PresenceStatus; online: boolean; ageMs: number } {
    const age = Math.max(0, now - (Number(lastSeenMs) || 0));
    if (age <= this.ONLINE_WINDOW_MS) return { status: 'ONLINE', online: true, ageMs: age };
    if (age <= this.IDLE_WINDOW_MS) return { status: 'IDLE', online: false, ageMs: age };
    return { status: 'OFFLINE', online: false, ageMs: age };
  }

  /** Merge a new packet into cache, recompute presence, and fan out to per-driver + global streams. */
  private ingest(dto: LiveDriverDto) {
    const id = Number(dto.driverId);
    if (!id) return;

    // prefer latitude/longitude downstream
    if (dto.lat != null && dto.latitude == null) dto.latitude = dto.lat;
    if (dto.lng != null && dto.longitude == null) dto.longitude = dto.lng;

    const lastSeen = this.pickLastSeen(dto);
    const now = Date.now();
    const { status, online, ageMs } = this.computePresence(lastSeen, now);

    const prev = this.lastByDriver.get(id) || {};
    const merged: LiveDriverDto = {
      ...prev,
      ...dto,
      lastSeen,
      lastUpdated: lastSeen,
      presenceStatus: dto.presenceStatus ?? status,
      isOnline: dto.isOnline ?? online,
      // keep battery/locationName if incoming is undefined
    };

    this.lastByDriver.set(id, merged);
    this.lastByDriverAccessTime.set(id, now); // Track access time for LRU

    // Enforce max cache size (LRU eviction)
    if (this.lastByDriver.size > this.MAX_DRIVER_CACHE_SIZE) {
      this.enforceMaxCacheSize();
    }

    // per-driver legacy subject (if present)
    if (this.locationSubjects[id]) {
      this.locationSubjects[id].next(merged);
    }

    // global stream (throttled upstream)
    this.globalSubject.next(merged);
  }

  /** Re-emit cached drivers with recomputed presence/age (called on tick/visibility/network). */
  private reemitPresenceAges() {
    // Guard: Only perform expensive recalculation if there are subscribers
    const hasSubscribers =
      Object.keys(this.locationSubjects).length > 0 || this.globalSubject.observers.length > 0;
    if (!hasSubscribers || this.lastByDriver.size === 0) return;

    const now = Date.now();
    for (const [id, d] of this.lastByDriver.entries()) {
      const lastSeen = this.pickLastSeen(d);
      const { status, online, ageMs } = this.computePresence(lastSeen, now);
      const updated: LiveDriverDto = {
        ...d,
        presenceStatus: status,
        isOnline: online,
        lastSeen,
        lastUpdated: lastSeen,
      };
      this.lastByDriver.set(id, updated);
      if (this.locationSubjects[id]) this.locationSubjects[id].next(updated);
      this.globalSubject.next(updated);
    }
  }

  private authHeaders(): HttpHeaders {
    const token = this.authService.getToken() || localStorage.getItem('token') || '';
    const base: Record<string, string> = { 'X-Client': 'sv-admin-ui' };
    if (token) base['Authorization'] = `Bearer ${token}`;
    return new HttpHeaders(base);
  }

  /** Extract JWT exp (seconds since epoch) without validating signature. */
  private getJwtExp(token: string): number | null {
    try {
      const parts = token.split('.');
      if (parts.length !== 3) return null;
      const payload = JSON.parse(atob(parts[1].replace(/-/g, '+').replace(/_/g, '/')));
      const exp = payload?.exp;
      return typeof exp === 'number' ? exp : null;
    } catch {
      return null;
    }
  }

  /**
   * Cleanup: Remove ReplaySubjects not accessed in 5 minutes
   * Called automatically every SUBJECT_CLEANUP_INTERVAL_MS
   */
  private cleanupUnusedSubjects(): void {
    const now = Date.now();
    const expiredIds: number[] = [];

    for (const [driverId, lastAccess] of Object.entries(this.locationSubjectAccessTime)) {
      const id = Number(driverId);
      if (now - lastAccess > this.SUBJECT_CLEANUP_INTERVAL_MS) {
        expiredIds.push(id);
      }
    }

    for (const id of expiredIds) {
      if (this.locationSubjects[id]) {
        try {
          this.locationSubjects[id].complete();
        } catch {}
        delete this.locationSubjects[id];
      }
      delete this.locationSubjectAccessTime[id];
      console.log(`[DriverLocationService] Cleaned up unused subject for driver ${id}`);
    }
  }

  /**
   * Enforce max cache size: Remove least-recently-accessed driver when cache exceeds limit
   * Preserves the 1000 most-recently-accessed drivers in lastByDriver map
   */
  private enforceMaxCacheSize(): void {
    if (this.lastByDriver.size <= this.MAX_DRIVER_CACHE_SIZE) {
      return;
    }

    // Find the least-recently-accessed driver
    let lruDriverId: number | null = null;
    let oldestAccessTime = Date.now();

    for (const driverId of this.lastByDriver.keys()) {
      const accessTime = this.lastByDriverAccessTime.get(driverId) ?? 0;
      if (accessTime < oldestAccessTime) {
        oldestAccessTime = accessTime;
        lruDriverId = driverId;
      }
    }

    if (lruDriverId !== null) {
      this.lastByDriver.delete(lruDriverId);
      this.lastByDriverAccessTime.delete(lruDriverId);
      console.log(
        `[DriverLocationService] Evicted LRU driver ${lruDriverId} (cache size now ${this.lastByDriver.size})`,
      );
    }
  }
}
