/* eslint-disable @typescript-eslint/consistent-type-imports */
import { ScrollingModule } from '@angular/cdk/scrolling';
import { CommonModule } from '@angular/common';
import type { OnInit, OnDestroy, AfterViewInit } from '@angular/core';
import {
  Component,
  HostListener,
  ViewChild,
  ElementRef,
  ChangeDetectionStrategy,
  NgZone,
  ChangeDetectorRef,
} from '@angular/core';
import { FormsModule } from '@angular/forms';
import { TranslateModule, TranslateService } from '@ngx-translate/core';
import { ActivatedRoute, Router, RouterModule } from '@angular/router';
import type { Subscription } from 'rxjs';
import { interval, of, Subject } from 'rxjs';
import { catchError, map, auditTime } from 'rxjs/operators';
import * as L from 'leaflet';
import 'leaflet.markercluster';

import type { Driver } from '../models/driver.model';
import { ConfirmService } from '../services/confirm.service';
import { AdminNotificationService } from '../services/admin-notification.service';
import { NotificationService } from '../services/notification.service';
import type { LiveDriverDto } from '../services/driver-location.service';
import { DriverLocationService } from '../services/driver-location.service';
import type { HistoryPoint } from '../services/driver-location.service';
import type { DriverAlert } from '../models/driver-alert.model';
import { DriverAlertService } from '../services/driver-alert.service';
import { DriverAlertToastComponent } from '../components/driver-alert-toast/driver-alert-toast.component';
import { GeofenceService } from '../services/geofence.service';
import type { Geofence, GeofenceEvent, GeofenceAlert } from '../models/geofence.model';
import { AuthService } from '../services/auth.service';
import { GeofenceType, GeofenceEventType } from '../models/geofence.model';
import { DriverChatService } from '../features/drivers/driver-messages/driver-chat.service';

type MapLatLngLiteral = { lat: number; lng: number };

// ---- Status typing helpers (keep in sync with Driver model) ----
export type DriverStatusLiteral = 'online' | 'offline' | 'busy' | 'idle' | 'on-trip';

const SERVER_TO_CLIENT_STATUS: Record<string, DriverStatusLiteral> = {
  ONLINE: 'online',
  OFFLINE: 'offline',
  BUSY: 'busy',
  IDLE: 'idle',
  ON_TRIP: 'on-trip',
  ONTRIP: 'on-trip',
};

function serverStatusToClientStatus(input?: string): DriverStatusLiteral | undefined {
  if (!input) return undefined;
  const key = input
    .trim()
    .replace(/[\s-]+/g, '_')
    .toUpperCase();
  return SERVER_TO_CLIENT_STATUS[key];
}

// ---- Normalize helpers ----
type Ms = number;
const toMs = (v: any): Ms | 0 => {
  if (v == null) return 0;
  if (typeof v === 'number') return v;
  const t = Date.parse(String(v));
  return Number.isFinite(t) ? t : 0;
};
const coalesceBool = (...vals: any[]): boolean | undefined => {
  for (const v of vals) if (typeof v === 'boolean') return v;
  return undefined;
};

@Component({
  selector: 'app-live-map',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    RouterModule,
    ScrollingModule,
    DriverAlertToastComponent,
    TranslateModule,
  ],
  templateUrl: './live-map.component.html',
  styleUrls: ['./live-map.component.css'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class LiveMapComponent implements OnInit, OnDestroy, AfterViewInit {
  @ViewChild('leafletMap') mapElement?: ElementRef<HTMLDivElement>;

  // ---- Map state ----
  zoom = 12;
  mapCenter: MapLatLngLiteral = { lat: 11.556, lng: 104.928 };
  private leafletMap: L.Map | null = null;
  private driverClusterGroup?: L.MarkerClusterGroup;
  private dispatchLayerGroup?: L.LayerGroup;
  private selectedDriverLayerGroup?: L.LayerGroup;
  private historyEndpointMarkers: L.Marker[] = [];

  // ---- Tunables / thresholds ----
  private readonly MIN_REST_REFRESH_MS = 10_000; // throttle REST refreshes
  private readonly MAX_LOGS = 200; // cap per-driver log length

  // ---- Data ----
  allDrivers: Driver[] = [];
  filteredDrivers: Driver[] = [];
  selectedDriver: Driver | null = null;
  hoveredDriver: Driver | null = null;
  activeMenuDriverId: number | null = null;

  // ---- UI filters / state ----
  searchTerm = '';
  selectedStatus: 'all' | 'online' | 'offline' | 'idle' | 'on-trip' = 'all';
  selectedType: 'all' | 'truck' | 'van' | 'bike' | string = 'all';
  selectedTelemetry: 'all' | 'healthy' | 'delayed' | 'stale' = 'all';
  selectedGroup: string = 'all';
  selectedZone: string = 'all';
  availableGroups: string[] = [];
  availableZones: string[] = [];
  readonly UNASSIGNED_GROUP = '__ungrouped__';
  readonly UNASSIGNED_ZONE = '__unzoned__';
  hasUngroupedDrivers = false;
  hasUnzonedDrivers = false;
  sidebarCollapsed = false;
  autoTrackEnabled = false;
  advancedControlsVisible = false;
  proximityControlsVisible = false;

  // ---- WS status / debug ----
  lastSocketMessage = '';
  loadingSocket = true;
  socketConnected = false;
  debugLogs: string[] = [];
  mapsReady = false;
  mapsLoadError = '';

  // ---- Replay / simulation ----
  isReplayMode = false;
  replayStep = 0;
  maxReplaySteps = 0;
  playbackPaused = false;

  // ---- History playback ----
  historyMode = false;
  historyDriver: Driver | null = null;
  historyPoints: HistoryPoint[] = [];
  historyLoading = false;
  historyError = '';
  historyFromDate = '';
  historyToDate = '';
  historyPlaybackIndex = 0;
  historyIsPlaying = false;
  historyPlaybackSpeed = 1;
  historyTotalDistanceKm = 0;
  private historyPlaybackInterval: ReturnType<typeof setInterval> | null = null;
  private historyPolyline: L.Polyline | null = null;
  private historyPlaybackMarker: L.Marker | null = null;

  // ---- Subscriptions ----
  private simulationSub?: Subscription;
  private websocketSub?: Subscription;
  private playbackSub?: Subscription;
  private refreshSub?: Subscription; // 30s REST fallback
  private statusSub?: Subscription;
  private staleSweepSub?: Subscription;
  private mapIdleSub?: Subscription; // debounced map idle
  private lastRestRefreshAt = 0;
  private didInitialAutoCenter = false; // one-time center-on-first-online
  private filtersPending = false; // batch applyFilters within a microtask

  // ---- Sidebar resize ----
  sidebarWidth: number = 450;
  isResizing: boolean = false;

  // ---- Messaging modal ----
  showMessageModal = false;
  messageTitle = '';
  messageContent = '';
  isSendingMessage = false;
  sendMessageError = '';
  bulkMode = false; // when true, message modal sends to selectedIds

  // ---- Markers ----
  markerMap: { [driverId: number]: L.Marker } = {};
  /** Only render text labels when zoomed-in or for the selected driver (perf). */

  private t(key: string, params?: Record<string, unknown>): string {
    return this.translate.instant(key, params);
  }
  readonly labelZoom = 14;

  // ---- Marker clustering ----
  private readonly CLUSTER_THRESHOLD_ZOOM = 13; // cluster when zoom < 13
  private clusteringEnabled = true;

  // ---- Active alerts ----
  activeAlerts: Map<string, DriverAlert> = new Map();

  // ---- Geofences ----
  geofences: Geofence[] = [];
  geofenceMap: Map<number, L.Polygon | L.Circle> = new Map();
  selectedGeofenceId: number | null = null; // Track selected geofence for zoom
  showGeofences = true; // Toggle to show/hide geofence overlays on map
  showTrips = false; // Toggle to show/hide trip/dispatch overlays on map
  private geofenceSubscription?: Subscription;
  private geofenceAlertSubscription?: Subscription;

  // ---- Proximity filter ----
  proximityFilterEnabled = false;
  proximityFilterLat: string = ''; // Filter: latitude
  proximityFilterLng: string = ''; // Filter: longitude
  proximityFilterRadius: number = 10; // Filter: radius in km
  proximityFilterMarker?: L.Marker; // Visual marker for filter point
  proximityFilterCircle?: L.Circle; // Visual circle for filter radius
  proximityClickMode = false; // Click-on-map mode to set filter point
  filteredDriversCount: number = 0;

  // ---- Presence tracking (online/offline) ----
  private lastSeenByDriver: Record<number, number> = {};
  private readonly PRESENCE_TIMEOUT_MS = 65_000; // 65s without update => offline
  private readonly STALE_LOCATION_MS = 120_000; // 2m without update => stale/offline fallback
  // Unified online window (should match backend presence.query.default + small grace)
  private readonly ONLINE_WINDOW_MS = 120_000;

  // ---- Debounce for map idle ----
  private mapIdle$ = new Subject<void>();

  /** Single source of truth for ONLINE/OFFLINE on the client. */
  // make it public so the template can use it
  isOnline(d: Driver): boolean {
    // accept backend glitches: isOnline / isONLINE
    const flag = coalesceBool((d as any).isOnline, (d as any).isONLINE);
    if (typeof flag === 'boolean') return flag;

    const byPresence = this.lastSeenByDriver[d.id!] ?? 0;
    const byUpdated = toMs(d.lastUpdated);
    const t = Math.max(byPresence, byUpdated);
    return !!t && Date.now() - t <= this.ONLINE_WINDOW_MS;
  }

  heartbeatAgeSeconds(d: Driver): number | null {
    const byPresence = this.lastSeenByDriver[d.id!] ?? 0;
    const byUpdated = toMs(d.lastUpdated);
    const byServer = toMs((d as any).lastSeenEpochMs);
    const t = Math.max(byPresence, byUpdated, byServer);
    if (!t) return null;
    return Math.max(0, Math.floor((Date.now() - t) / 1000));
  }

  ingestLagSeconds(d: Driver): number | null {
    const lag = Number((d as any).ingestLagSeconds);
    if (Number.isFinite(lag) && lag >= 0) return Math.floor(lag);
    return this.heartbeatAgeSeconds(d);
  }

  telemetryHealthState(d: Driver): 'healthy' | 'delayed' | 'stale' {
    const lag = this.ingestLagSeconds(d);
    if (lag == null) return 'stale';
    if (lag <= 45) return 'healthy';
    if (lag <= 120) return 'delayed';
    return 'stale';
  }

  telemetryHealthLabel(d: Driver): string {
    const state = this.telemetryHealthState(d);
    if (state === 'healthy') return this.translate.instant('liveMap.healthy');
    if (state === 'delayed') return this.translate.instant('liveMap.delayed');
    return this.translate.instant('liveMap.stale');
  }

  telemetryHealthClass(d: Driver): string {
    const state = this.telemetryHealthState(d);
    if (state === 'healthy') return 'bg-green-50 text-green-700 border-green-200';
    if (state === 'delayed') return 'bg-amber-50 text-amber-700 border-amber-200';
    return 'bg-red-50 text-red-700 border-red-200';
  }

  constructor(
    private driverLocationService: DriverLocationService,
    private router: Router,
    private route: ActivatedRoute,
    private adminNotificationService: AdminNotificationService,
    private driverChatService: DriverChatService,
    private ngZone: NgZone,
    private cdr: ChangeDetectorRef,
    private readonly confirm: ConfirmService,
    private readonly notify: NotificationService,
    public readonly driverAlertService: DriverAlertService,
    private readonly geofenceService: GeofenceService,
    private readonly authService: AuthService,
    private readonly translate: TranslateService,
  ) {}

  // ===================== Lifecycle =====================

  ngOnInit(): void {
    // Update page/tab title to new name
    try {
      document.title = this.t('liveMap.title');
    } catch {}

    this.loadTelemetryFilterFromUrl();

    // 2) Background timers (outside of change detection churn)
    this.startAutoRefresh();
    this.startStaleSweep();

    // 3) Debounced viewport-driven refreshes
    this.mapIdleSub = this.mapIdle$.pipe(auditTime(400)).subscribe(() => {
      this.refreshFromLiveMap();
      this.cdr.markForCheck();
    });

    // 4) Live updates via WS
    if (!this.isReplayMode) this.initWebSocket();

    // 5) Observe WS status and nudge UI (OnPush)
    this.statusSub = this.driverLocationService.subscribeToStatus().subscribe((s) => {
      this.socketConnected = s === 'connected';
      this.loadingSocket = s === 'connecting' || s === 'init';
      this.cdr.markForCheck();
    });

    // 6) Subscribe to active alerts
    this.driverAlertService.activeAlerts$.subscribe((alerts) => {
      this.activeAlerts = alerts;
      this.cdr.markForCheck();
    });

    // 7) Load and subscribe to geofences
    const companyId = this.authService.getCompanyId();
    this.geofenceSubscription = this.geofenceService.loadGeofences(companyId).subscribe({
      next: (geofences) => {
        this.geofences = geofences;
        this.cdr.markForCheck();
      },
      error: (err) => console.error('Failed to load geofences:', err),
    });

    // 8) Subscribe to geofence alert events from WebSocket
    this.geofenceAlertSubscription = this.driverLocationService
      .subscribeToGeofenceAlerts()
      .subscribe({
        next: (event: GeofenceEvent) => {
          this.handleGeofenceEvent(event);
        },
        error: (err) => console.error('Geofence alert subscription error:', err),
      });
  }

  ngAfterViewInit(): void {
    this.initLeafletMap();
    this.fetchDriversFromBackend();
    this.tryInitialAutoCenter();
    this.refreshFromLiveMap();
    this.renderGeofences();
    this.cdr.markForCheck();
  }

  private initLeafletMap(): void {
    if (this.leafletMap || !this.mapElement?.nativeElement) return;

    this.mapsLoadError = '';

    try {
      this.leafletMap = L.map(this.mapElement.nativeElement, {
        center: [this.mapCenter.lat, this.mapCenter.lng],
        zoom: this.zoom,
        zoomControl: false,
        preferCanvas: true,
      });

      L.control
        .zoom({
          position: 'bottomright',
        })
        .addTo(this.leafletMap);

      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '&copy; OpenStreetMap contributors',
        maxZoom: 19,
      }).addTo(this.leafletMap);

      this.driverClusterGroup = L.markerClusterGroup({
        disableClusteringAtZoom: this.CLUSTER_THRESHOLD_ZOOM,
        showCoverageOnHover: false,
        spiderfyOnMaxZoom: true,
      });
      this.driverClusterGroup.addTo(this.leafletMap);

      this.dispatchLayerGroup = L.layerGroup().addTo(this.leafletMap);
      this.selectedDriverLayerGroup = L.layerGroup().addTo(this.leafletMap);

      this.leafletMap.on('moveend', () => this.ngZone.run(() => this.onMapIdle()));
      this.leafletMap.on('zoomend', () =>
        this.ngZone.run(() => {
          this.zoom = this.leafletMap?.getZoom() ?? this.zoom;
          this.onMapZoomChanged();
        }),
      );
      this.leafletMap.on('click', (event: L.LeafletMouseEvent) =>
        this.ngZone.run(() => this.onMapClickForProximity(event)),
      );

      this.mapsReady = true;
    } catch (err) {
      this.mapsLoadError = 'Leaflet map failed to load';
      console.error('[LiveMap] Leaflet failed to load', err);
    }
  }

  ngOnDestroy(): void {
    // Cleanup geofences
    this.clearGeofenceOverlays();
    this.geofenceSubscription?.unsubscribe();
    this.geofenceAlertSubscription?.unsubscribe();

    // Cleanup history playback
    this.stopHistoryPlayback();
    this.clearHistoryOverlays();

    this.simulationSub?.unsubscribe();
    this.websocketSub?.unsubscribe();
    this.playbackSub?.unsubscribe();
    this.refreshSub?.unsubscribe();
    this.statusSub?.unsubscribe();
    this.staleSweepSub?.unsubscribe();
    this.mapIdleSub?.unsubscribe();
    this.driverLocationService.disconnect();
    this.leafletMap?.remove();
    this.leafletMap = null;
    this.mapIdle$.complete();
    if (this.isResizing) {
      document.removeEventListener('mousemove', this.resizeSidebar);
      document.removeEventListener('mouseup', this.stopResizing);
    }
  }

  /** Try a one-time auto-center on the first online driver. Safe to call multiple times. */
  private tryInitialAutoCenter(): void {
    if (this.didInitialAutoCenter) return;
    const d = this.filteredDrivers.find(
      (x) => x.currentLatitude && x.currentLongitude && this.isOnline(x),
    );
    if (d) {
      this.mapCenter = { lat: d.currentLatitude!, lng: d.currentLongitude! };
      this.selectedDriver = d;
      if (this.zoom < 14) this.zoom = 14;
      this.didInitialAutoCenter = true;
      this.cdr.markForCheck();
    }
  }

  /** Base info (names, dispatch etc.). Then immediately pull live locations within bbox. */
  fetchDriversFromBackend(): void {
    this.driverLocationService
      .getAllDrivers()
      .pipe(
        map((res) => res.data as Driver[]),
        catchError((error) => {
          this.logDebug(' Failed to fetch drivers: ' + JSON.stringify(error));
          return of([]);
        }),
      )
      .subscribe((drivers: Driver[]) => {
        this.allDrivers = drivers.map((d) => ({
          ...d,
          currentLatitude: d.latitude ?? 0,
          currentLongitude: d.longitude ?? 0,
          logs: d.logs ?? [],
          updatedFromSocket: false,
          isOnline: d.isOnline ?? false,
          selected: false,
          status: (d.isOnline ?? false) ? 'online' : (d.status ?? 'offline'),
        }));

        this.refreshFilterOptions();
        this.applyFilters();
        this.tryInitialAutoCenter();
        this.logDebug(` Loaded ${this.allDrivers.length} drivers`);

        this.refreshFromLiveMap();

        if (this.autoTrackEnabled) this.autoCenterOnFirstOnlineDriver();
      });
  }

  /** Pulls live locations from the REST live-map using current map bounds (bbox). */
  refreshFromLiveMap(): void {
    const now = Date.now();
    if (now - this.lastRestRefreshAt < this.MIN_REST_REFRESH_MS) return;
    this.lastRestRefreshAt = now;

    const rawBbox = this.getCurrentBounds();
    const bbox = this.isUsableLiveBounds(rawBbox) ? rawBbox : null;
    const params = bbox
      ? {
          onlyOnline: true,
          south: bbox.south,
          west: bbox.west,
          north: bbox.north,
          east: bbox.east,
          onlineSeconds: 120,
        }
      : { onlyOnline: true, onlineSeconds: 120 };

    this.driverLocationService
      .getLiveDrivers(params)
      .pipe(
        map((res) => (res?.data ?? []) as LiveDriverDto[]),
        catchError((err) => {
          this.logDebug(' Live map fetch failed: ' + JSON.stringify(err));
          return of([]);
        }),
      )
      .subscribe((liveRows) => {
        for (const r of liveRows) {
          const d = this.allDrivers.find((x) => x.id === r.driverId);
          if (!d) continue;
          const update = {
            latitude: (r as any).latitude ?? (r as any).lat,
            longitude: (r as any).longitude ?? (r as any).lng,
            speed: (r as any).speed,
            online: coalesceBool((r as any).isOnline, (r as any).online, (r as any).isONLINE),
            lastUpdated: (r as any).lastUpdated ?? (r as any).updatedAt ?? (r as any).serverTime,
            lastSeenEpochMs: (r as any).lastSeenEpochMs ?? (r as any).lastSeen,
            lastSeenSeconds: (r as any).lastSeenSeconds,
            ingestLagSeconds: (r as any).ingestLagSeconds,
            source: (r as any).source,
            locationName: (r as any).locationName,
            batteryLevel: (r as any).batteryLevel,
          } as any;

          const seen = toMs((r as any).lastSeen ?? (r as any).serverTime);
          if (seen) this.lastSeenByDriver[r.driverId] = seen;

          this.applyLiveUpdate(d, update);
        }
        this.refreshFilterOptions();
        this.applyFilters();
        this.tryInitialAutoCenter();
        this.cdr.markForCheck();
      });
  }

  /** 30s auto-refresh for REST live map (useful when WS is not connected). */
  startAutoRefresh(): void {
    this.ngZone.runOutsideAngular(() => {
      this.refreshSub = interval(30000).subscribe(() => {
        if (!this.socketConnected) {
          this.ngZone.run(() => this.refreshFromLiveMap());
        }
      });
    });
  }

  getPolylinePath(driver: Driver): google.maps.LatLngLiteral[] {
    return (
      driver.logs
        ?.filter((log) => log.lat != null && log.lng != null)
        .map((log) => ({ lat: log.lat, lng: log.lng })) || []
    );
  }

  private distanceMeters(aLat: number, aLng: number, bLat: number, bLng: number): number {
    const toRad = (d: number) => (d * Math.PI) / 180;
    const R = 6371000;
    const dLat = toRad(bLat - aLat);
    const dLng = toRad(bLng - aLng);
    const s =
      Math.sin(dLat / 2) ** 2 +
      Math.cos(toRad(aLat)) * Math.cos(toRad(bLat)) * Math.sin(dLng / 2) ** 2;
    return 2 * R * Math.asin(Math.sqrt(s));
  }

  /**
   * Merge a live update into a Driver (location, telemetry, logs, animation, presence).
   * Accepts latitude/longitude or lat/lng.
   */
  private applyLiveUpdate(driver: Driver, update: any): void {
    const lat = update?.latitude ?? update?.lat ?? driver.currentLatitude ?? 0;
    const lng = update?.longitude ?? update?.lng ?? driver.currentLongitude ?? 0;

    const prevLat = driver.currentLatitude ?? lat;
    const prevLng = driver.currentLongitude ?? lng;

    const tinyMove = this.distanceMeters(prevLat, prevLng, lat, lng);
    const reportedSpeed = typeof update?.speed === 'number' ? update.speed : (driver.speed ?? 0);
    if (tinyMove < 8 && reportedSpeed <= 1) {
      driver.lastUpdated = update?.lastUpdated ?? driver.lastUpdated ?? new Date().toISOString();
      if (update?.batteryLevel != null) (driver as any).batteryLevel = update.batteryLevel;
      const mk = this.markerMap[driver.id!];
      if (mk) mk.setOpacity((driver.isOnline ?? false) ? 1.0 : 0.6);
      return;
    }

    const online = coalesceBool(update?.online, (update as any).isOnline, (update as any).isONLINE);
    if (typeof online === 'boolean') driver.isOnline = online;
    driver.status = driver.isOnline ? 'online' : driver.status || 'offline';
    driver.lastUpdated = update?.lastUpdated ?? update?.updatedAt ?? new Date().toISOString();
    if (typeof update?.speed === 'number') driver.speed = update.speed;
    if (update?.locationName) driver.locationName = update.locationName;
    if (update?.batteryLevel != null) (driver as any).batteryLevel = update.batteryLevel;
    if (update?.lastSeenEpochMs != null) (driver as any).lastSeenEpochMs = update.lastSeenEpochMs;
    if (update?.lastSeenSeconds != null) (driver as any).lastSeenSeconds = update.lastSeenSeconds;
    if (update?.ingestLagSeconds != null)
      (driver as any).ingestLagSeconds = update.ingestLagSeconds;
    if (update?.source != null) (driver as any).source = update.source;

    driver.currentLatitude = lat;
    driver.currentLongitude = lng;
    driver.latitude = lat;
    driver.longitude = lng;

    driver.logs = driver.logs || [];
    const last = driver.logs[driver.logs.length - 1];
    if (!last || last.lat !== lat || last.lng !== lng) {
      driver.logs.push({ lat, lng, time: driver.lastUpdated! });
    }
    if (driver.logs.length > this.MAX_LOGS) driver.logs.shift();

    const marker = this.markerMap[driver.id!];
    if (marker) {
      marker.setOpacity(driver.isOnline ? 1.0 : 0.6);
      const moved = prevLat !== lat || prevLng !== lng;
      if (moved) {
        const dist = this.distanceMeters(prevLat, prevLng, lat, lng);
        if (dist < 500) {
          this.animateMarkerTransition(marker, { lat: prevLat, lng: prevLng }, { lat, lng });
        } else {
          marker.setLatLng([lat, lng]);
        }
      }
      marker.setIcon(this.createDriverIcon(driver));
    }

    // Check for alerts on location update
    this.driverAlertService.checkAndEmitAlerts(driver.id!, {
      speed: driver.speed,
      batteryLevel: (driver as any).batteryLevel,
      acceleration: (update as any).acceleration,
    });
  }

  // ===================== WebSocket =====================

  initWebSocket(): void {
    this.loadingSocket = true;

    this.websocketSub = this.driverLocationService.subscribeToAll().subscribe({
      next: (update) => {
        this.socketConnected = true;
        this.loadingSocket = false;

        let driver = this.allDrivers.find((d) => d.id === update.driverId);
        if (!driver) {
          driver = this.ensureDriverRow(update);
          this.allDrivers.push(driver);
          this.applyFilters();
        }

        const seenMs = toMs((update as any).lastSeen ?? (update as any).serverTime);
        if (seenMs) this.lastSeenByDriver[update.driverId] = seenMs;
        else this.lastSeenByDriver[update.driverId] = Date.now();

        if (!driver) return;

        const presenceStatus = (update as any).presenceStatus as string | undefined;
        const isOnlineFromPresence = presenceStatus
          ? presenceStatus.toLowerCase() === 'online'
          : undefined;
        const isOnlineFromFlag = coalesceBool((update as any).isOnline, (update as any).isONLINE);
        const resolvedOnline = isOnlineFromPresence ?? isOnlineFromFlag ?? driver.isOnline ?? false;

        driver.isOnline = resolvedOnline;
        const presenceStatusClient = serverStatusToClientStatus(presenceStatus);
        driver.status =
          presenceStatusClient ?? (resolvedOnline ? 'online' : (driver.status ?? 'offline'));

        const merged = {
          latitude: (update as any).latitude ?? (update as any).lat,
          longitude: (update as any).longitude ?? (update as any).lng,
          speed: (update as any).speed ?? (update as any).clientSpeedKmh,
          online: resolvedOnline,
          lastUpdated:
            (update as any).lastUpdated ??
            ((update as any).timestamp
              ? new Date((update as any).timestamp).toISOString()
              : undefined) ??
            new Date().toISOString(),
          locationName: (update as any).locationName,
          batteryLevel: (update as any).batteryLevel,
        } as any;

        const hasCoords = merged.latitude != null && merged.longitude != null;
        if (!hasCoords) {
          driver.lastUpdated = merged.lastUpdated;
          const mk = this.markerMap[driver.id!];
          if (mk) mk.setOpacity(driver.isOnline ? 1.0 : 0.6);
          this.applyFilters();
          return;
        }

        this.applyLiveUpdate(driver, merged);
        driver.updatedFromSocket = true;

        driver.dispatchId = (update as any).dispatchId ?? driver.dispatchId;
        if ((update as any).dispatch) {
          const u = (update as any).dispatch;
          driver.dispatch = {
            id: u.id,
            routeCode: u.routeCode,
            status: u.status,
            tripType: u.tripType,
            pickup: u.pickup,
            dropoff: u.dropoff,
          };
        }

        if (this.autoTrackEnabled && this.selectedDriver?.id === driver.id) {
          this.mapCenter = {
            lat: driver.currentLatitude ?? merged.latitude,
            lng: driver.currentLongitude ?? merged.longitude,
          };
        }
        this.cdr.markForCheck();
      },
      error: () => {
        this.socketConnected = false;
        this.logDebug(' WebSocket connection error.');
        this.cdr.markForCheck();
      },
      complete: () => {
        this.socketConnected = false;
        this.logDebug('⚠️ WebSocket connection closed.');
        this.cdr.markForCheck();
      },
    });
  }

  onMapIdle(): void {
    this.mapIdle$.next();
  }

  animateMarkerTransition(marker: L.Marker, from: MapLatLngLiteral, to: MapLatLngLiteral) {
    const durationMs = 450;
    const start = performance.now();
    const fromLat = from.lat;
    const fromLng = from.lng;
    const dLat = to.lat - fromLat;
    const dLng = to.lng - fromLng;

    const ease = (t: number) => (t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t);

    const step = (now: number) => {
      const p = Math.min(1, (now - start) / durationMs);
      const e = ease(p);
      const lat = fromLat + dLat * e;
      const lng = fromLng + dLng * e;
      marker.setLatLng([lat, lng]);
      if (p < 1) requestAnimationFrame(step);
    };
    requestAnimationFrame(step);
  }

  /**
   * Update marker clustering based on zoom level.
   * Clusters markers when zoom < CLUSTER_THRESHOLD_ZOOM (13) and count > 20.
   */
  updateClustering(): void {
    if (!this.clusteringEnabled || !this.leafletMap || !this.driverClusterGroup) {
      return;
    }
    this.zoom = this.leafletMap.getZoom();
  }

  /**
   * Handle map zoom change events for clustering updates.
   */
  onMapZoomChanged(): void {
    this.updateClustering();
    this.cdr.markForCheck();
  }

  /**
   * Calculate distance between two LatLng points in meters.
   */
  getCurrentBounds(): {
    south: number;
    west: number;
    north: number;
    east: number;
  } | null {
    if (!this.leafletMap) return null;
    const b = this.leafletMap.getBounds();
    return { south: b.getSouth(), west: b.getWest(), north: b.getNorth(), east: b.getEast() };
  }

  private isUsableLiveBounds(
    bbox: { south: number; west: number; north: number; east: number } | null,
  ): bbox is { south: number; west: number; north: number; east: number } {
    if (!bbox) return false;

    const values = [bbox.south, bbox.west, bbox.north, bbox.east];
    if (values.some((value) => !Number.isFinite(value))) return false;
    if (bbox.south >= bbox.north || bbox.west >= bbox.east) return false;

    const centerLat = (bbox.south + bbox.north) / 2;
    const centerLng = (bbox.west + bbox.east) / 2;
    const latSpan = bbox.north - bbox.south;
    const lngSpan = bbox.east - bbox.west;

    // Ignore bogus near-origin bounds observed during early map lifecycle.
    if (Math.abs(centerLat) < 1 && Math.abs(centerLng) < 1 && latSpan < 1 && lngSpan < 1) {
      this.logDebug(` Ignoring suspicious map bbox near origin: ${JSON.stringify(bbox)}`);
      return false;
    }

    return true;
  }

  applyFilters(): void {
    this.filteredDrivers = this.allDrivers.filter((driver) => {
      const matchesStatus =
        this.selectedStatus === 'all'
          ? true
          : this.selectedStatus === 'online'
            ? this.isOnline(driver)
            : this.selectedStatus === 'offline'
              ? !this.isOnline(driver)
              : (driver.status || '').toLowerCase() === this.selectedStatus;

      const matchesType =
        this.selectedType === 'all' ||
        (driver.vehicleType || '').toLowerCase() === this.selectedType;

      const driverGroup = this.normalizeFilterToken(this.getDriverGroupValue(driver));
      const selectedGroup = this.normalizeFilterToken(this.selectedGroup);
      const matchesGroup =
        this.selectedGroup === 'all'
          ? true
          : this.selectedGroup === this.UNASSIGNED_GROUP
            ? !driverGroup
            : driverGroup === selectedGroup;

      const driverZone = this.normalizeFilterToken(this.getDriverZoneValue(driver));
      const selectedZone = this.normalizeFilterToken(this.selectedZone);
      const matchesZone =
        this.selectedZone === 'all'
          ? true
          : this.selectedZone === this.UNASSIGNED_ZONE
            ? !driverZone
            : driverZone === selectedZone;

      const s = (this.searchTerm || '').toLowerCase();
      const matchesSearch =
        !s ||
        (driver.name || '').toLowerCase().includes(s) ||
        (driver.phone || '').includes(s) ||
        (driver.locationName || '').toLowerCase().includes(s) ||
        (driver.currentVehiclePlate || '').toLowerCase().includes(s) ||
        (driver.assignedVehicle?.licensePlate || '').toLowerCase().includes(s);

      const matchesTelemetry =
        this.selectedTelemetry === 'all' ||
        this.telemetryHealthState(driver) === this.selectedTelemetry;

      // Apply proximity filter if enabled
      let matchesProximity = true;
      if (this.proximityFilterEnabled) {
        if (driver.currentLatitude == null || driver.currentLongitude == null) {
          matchesProximity = false; // Exclude drivers without coordinates
        } else {
          const lat = parseFloat(this.proximityFilterLat);
          const lng = parseFloat(this.proximityFilterLng);
          if (!isNaN(lat) && !isNaN(lng)) {
            const distance = this.calculateDistance(
              lat,
              lng,
              driver.currentLatitude,
              driver.currentLongitude,
            );
            matchesProximity = distance <= this.proximityFilterRadius;
          } else {
            matchesProximity = false; // Invalid filter coordinates
          }
        }
      }

      return (
        matchesStatus &&
        matchesType &&
        matchesTelemetry &&
        matchesGroup &&
        matchesZone &&
        matchesSearch &&
        matchesProximity
      );
    });

    this.syncTelemetryFilterToUrl();
    this.syncMapLayers();
  }

  private loadTelemetryFilterFromUrl(): void {
    const raw = (this.route.snapshot.queryParamMap.get('telemetry') || '').toLowerCase();
    const allowed = new Set(['all', 'healthy', 'delayed', 'stale']);
    if (allowed.has(raw)) {
      this.selectedTelemetry = raw as 'all' | 'healthy' | 'delayed' | 'stale';
    }
  }

  private syncTelemetryFilterToUrl(): void {
    const current = (this.route.snapshot.queryParamMap.get('telemetry') || '').toLowerCase();
    const selected = this.selectedTelemetry.toLowerCase();
    const normalizedCurrent = current || 'all';
    if (normalizedCurrent === selected) return;

    void this.router.navigate([], {
      relativeTo: this.route,
      queryParams: { telemetry: selected === 'all' ? null : selected },
      queryParamsHandling: 'merge',
      replaceUrl: true,
    });
  }

  resetFilters(): void {
    this.searchTerm = '';
    this.selectedStatus = 'all';
    this.selectedType = 'all';
    this.selectedTelemetry = 'all';
    this.selectedGroup = 'all';
    this.selectedZone = 'all';
    if (this.proximityFilterEnabled) {
      this.clearProximityFilter();
    }
    if (this.selectedGeofenceId) {
      this.clearSelectedGeofence();
    }
    this.applyFilters();
  }

  get activeFilterCount(): number {
    let count = 0;
    if ((this.searchTerm || '').trim().length > 0) count++;
    if (this.selectedStatus !== 'all') count++;
    if (this.selectedType !== 'all') count++;
    if (this.selectedTelemetry !== 'all') count++;
    if (this.selectedGroup !== 'all') count++;
    if (this.selectedZone !== 'all') count++;
    if (this.proximityFilterEnabled) count++;
    if (this.selectedGeofenceId != null) count++;
    return count;
  }

  private refreshFilterOptions(): void {
    const groups = new Map<string, string>();
    const zones = new Map<string, string>();
    this.hasUngroupedDrivers = false;
    this.hasUnzonedDrivers = false;

    for (const driver of this.allDrivers) {
      const group = this.getDriverGroupValue(driver);
      const zone = this.getDriverZoneValue(driver);
      const groupKey = this.normalizeFilterToken(group);
      const zoneKey = this.normalizeFilterToken(zone);

      if (groupKey) {
        if (!groups.has(groupKey)) groups.set(groupKey, group);
      } else {
        this.hasUngroupedDrivers = true;
      }

      if (zoneKey) {
        if (!zones.has(zoneKey)) zones.set(zoneKey, zone);
      } else {
        this.hasUnzonedDrivers = true;
      }
    }

    this.availableGroups = Array.from(groups.values()).sort((a, b) => a.localeCompare(b));
    this.availableZones = Array.from(zones.values()).sort((a, b) => a.localeCompare(b));

    if (
      this.selectedGroup !== 'all' &&
      this.selectedGroup !== this.UNASSIGNED_GROUP &&
      !this.availableGroups.includes(this.selectedGroup)
    ) {
      this.selectedGroup = 'all';
    }
    if (
      this.selectedZone !== 'all' &&
      this.selectedZone !== this.UNASSIGNED_ZONE &&
      !this.availableZones.includes(this.selectedZone)
    ) {
      this.selectedZone = 'all';
    }

    if (this.selectedGroup === this.UNASSIGNED_GROUP && !this.hasUngroupedDrivers) {
      this.selectedGroup = 'all';
    }
    if (this.selectedZone === this.UNASSIGNED_ZONE && !this.hasUnzonedDrivers) {
      this.selectedZone = 'all';
    }
  }

  private normalizeFilterToken(value: string): string {
    return String(value || '')
      .trim()
      .toLowerCase()
      .replace(/\s+/g, ' ');
  }

  private getDriverGroupValue(driver: Driver): string {
    const d = driver as any;
    return String(
      driver.driverGroupName ?? d.groupName ?? d.group?.name ?? d.driverGroup?.name ?? '',
    ).trim();
  }

  private getDriverZoneValue(driver: Driver): string {
    const d = driver as any;
    return String(driver.zone ?? d.zoneName ?? d.currentZone ?? '').trim();
  }

  get allSelected(): boolean {
    return this.filteredDrivers.length > 0 && this.filteredDrivers.every((d) => d.selected);
  }
  toggleSelectAll(checked: boolean): void {
    this.filteredDrivers.forEach((d) => (d.selected = checked));
  }

  toggleSelectAllEvent(event: Event): void {
    const target = event.target as HTMLInputElement | null;
    this.toggleSelectAll(!!target?.checked);
  }
  get selectedCount(): number {
    return this.allDrivers.filter((d) => d.selected).length;
  }

  get selectedIds(): number[] {
    return this.allDrivers.filter((d) => d.selected && d.id != null).map((d) => d.id!);
  }

  clearSelection(): void {
    this.allDrivers.forEach((d) => (d.selected = false));
  }

  bulkMessage(): void {
    if (this.selectedIds.length === 0) return;
    this.bulkMode = true;
    this.showMessageModal = true;
    this.messageContent = '';
  }

  bulkForceOpen(): void {
    const ids = this.selectedIds;
    if (!ids.length) return;
    ids.forEach((id) => {
      this.adminNotificationService
        .sendNotificationToDriver({
          driverId: id,
          title: this.t('liveMap.force_open'),
          message: this.t('liveMap.force_open_message'),
          type: 'force-track',
          severity: 'high',
          sender: 'ADMIN_UI',
        })
        .subscribe({
          next: () => this.logDebug(`🚀 FORCE_OPEN sent to #${id}`),
          error: (err) => this.logDebug(`❌ FORCE_OPEN failed for #${id}: ${JSON.stringify(err)}`),
        });
    });
  }

  async bulkDisable(): Promise<void> {
    const ids = this.selectedIds;
    if (!ids.length) return;
    const ok = await this.confirm.confirm(this.t('liveMap.disable_selected_confirm', { count: ids.length }));
    if (!ok) return;
    ids.forEach((id) => this.logDebug(`🚫 Driver #${id} disabled (bulk)`));
  }

  bulkAssignRoute(): void {
    const ids = this.selectedIds;
    if (!ids.length) return;
    this.router.navigate(['/dispatch/create'], { queryParams: { driverIds: ids.join(',') } });
  }

  toggleSidebar(): void {
    this.sidebarCollapsed = !this.sidebarCollapsed;
  }

  zoomToDriver(driver: Driver): void {
    if (driver.currentLatitude != null && driver.currentLongitude != null) {
      this.mapCenter = {
        lat: driver.currentLatitude ?? 0,
        lng: driver.currentLongitude ?? 0,
      };
      this.selectedDriver = driver;
      this.zoom = 16;
      this.leafletMap?.setView([this.mapCenter.lat, this.mapCenter.lng], this.zoom, {
        animate: true,
      });
    }
  }

  toggleCardMenu(driverId: number, event: MouseEvent): void {
    event.stopPropagation();
    this.activeMenuDriverId = this.activeMenuDriverId === driverId ? null : driverId;
  }

  @HostListener('document:click')
  closeCardMenu(): void {
    this.activeMenuDriverId = null;
  }

  recenterMap(): void {
    this.mapCenter = { lat: 11.556, lng: 104.928 };
    this.zoom = 12;
    this.leafletMap?.setView([this.mapCenter.lat, this.mapCenter.lng], this.zoom, {
      animate: true,
    });
  }

  getDriverStatus(driver: Driver): string {
    const online = this.isOnline(driver);
    const status = (driver.status || '').toLowerCase();

    if (status === 'idle' || status === 'on-trip' || status === 'busy') {
      return online
        ? status === 'on-trip'
          ? `🟠 ${this.t('liveMap.on_trip')}`
          : status === 'idle'
            ? `🟡 ${this.t('liveMap.idle')}`
            : `🟠 ${this.t('liveMap.busy')}`
        : `🔴 ${this.t('common.offline')}`;
    }

    return online ? `🟢 ${this.t('common.online')}` : `🔴 ${this.t('common.offline')}`;
  }

  toggleAutoTracking(): void {
    this.autoTrackEnabled = !this.autoTrackEnabled;
    if (this.autoTrackEnabled) this.autoCenterOnFirstOnlineDriver();
  }

  autoCenterOnFirstOnlineDriver(): void {
    const driver = this.filteredDrivers.find(
      (d) => d.currentLatitude && d.currentLongitude && this.isOnline(d),
    );
    if (driver) {
      this.mapCenter = {
        lat: driver.currentLatitude ?? 0,
        lng: driver.currentLongitude ?? 0,
      };
      this.selectedDriver = driver;
      this.leafletMap?.panTo([this.mapCenter.lat, this.mapCenter.lng], { animate: true });
    }
  }

  toggleGeofences(): void {
    this.showGeofences = !this.showGeofences;
    if (this.showGeofences) {
      this.renderGeofences();
    } else {
      this.clearGeofenceOverlays();
    }
    this.cdr.markForCheck();
  }

  toggleTrips(): void {
    this.showTrips = !this.showTrips;
    // TODO: Implement trip/dispatch overlay rendering when data is available
    this.cdr.markForCheck();
  }

  logDebug(message: string): void {
    const timestamp = new Date().toLocaleTimeString();
    this.debugLogs.unshift(`[${timestamp}] ${message}`);
    if (this.debugLogs.length > 50) this.debugLogs.pop();
  }

  get onlineCount(): number {
    return this.filteredDrivers.filter((d) => this.isOnline(d)).length;
  }

  get offlineCount(): number {
    return this.filteredDrivers.filter((d) => !this.isOnline(d)).length;
  }

  get healthyCount(): number {
    return this.filteredDrivers.filter((d) => this.telemetryHealthState(d) === 'healthy').length;
  }

  get delayedCount(): number {
    return this.filteredDrivers.filter((d) => this.telemetryHealthState(d) === 'delayed').length;
  }

  get staleCount(): number {
    return this.filteredDrivers.filter((d) => this.telemetryHealthState(d) === 'stale').length;
  }

  toggleReplayMode(): void {
    this.isReplayMode = !this.isReplayMode;
    this.replayStep = 0;
    this.simulationSub?.unsubscribe();
    this.websocketSub?.unsubscribe();

    if (this.isReplayMode) {
      this.maxReplaySteps = Math.max(...this.filteredDrivers.map((d) => d.logs?.length || 0));
      this.playbackSub = interval(2000).subscribe(() => {
        if (!this.playbackPaused && this.replayStep < this.maxReplaySteps) {
          this.updateReplayPosition();
          this.replayStep++;
        }
      });
    } else {
      this.playbackSub?.unsubscribe();
      this.startSimulation();
      this.initWebSocket();
    }
  }

  updateReplayPosition(): void {
    this.filteredDrivers.forEach((driver) => {
      const log = driver.logs?.[this.replayStep];
      if (log) {
        driver.currentLatitude = log.lat;
        driver.currentLongitude = log.lng;
      }
    });
  }

  startSimulation(): void {
    if (this.isReplayMode) return;
    this.simulationSub = interval(3000).subscribe(() => {
      this.filteredDrivers.forEach((driver) => {
        const latDelta = (Math.random() - 0.5) * 0.002;
        const lngDelta = (Math.random() - 0.5) * 0.002;
        driver.currentLatitude = (driver.currentLatitude ?? this.mapCenter.lat) + latDelta;
        driver.currentLongitude = (driver.currentLongitude ?? this.mapCenter.lng) + lngDelta;
        driver.logs = driver.logs || [];
        driver.logs.push({
          lat: driver.currentLatitude,
          lng: driver.currentLongitude,
          time: new Date().toISOString(),
        });
        if (driver.logs.length > 100) driver.logs.shift();
      });
    });
  }

  /** Compute bearing (0–360°) from the last two GPS log entries. Returns 0 when unavailable. */
  private computeHeading(driver: Driver): number {
    const logs = driver.logs;
    if (!logs || logs.length < 2) return 0;
    const prev = logs[logs.length - 2];
    const curr = logs[logs.length - 1];
    if (prev.lat === curr.lat && prev.lng === curr.lng) return 0;
    const lat1 = prev.lat * (Math.PI / 180);
    const lat2 = curr.lat * (Math.PI / 180);
    const dLng = (curr.lng - prev.lng) * (Math.PI / 180);
    const y = Math.sin(dLng) * Math.cos(lat2);
    const x = Math.cos(lat1) * Math.sin(lat2) - Math.sin(lat1) * Math.cos(lat2) * Math.cos(dLng);
    return (Math.atan2(y, x) * (180 / Math.PI) + 360) % 360;
  }

  /** Returns 1–2 uppercase initials from the driver's name. */
  getInitials(driver: Driver): string {
    const name = (driver.name || driver.fullName || '?').trim();
    const parts = name.split(/\s+/);
    const raw = parts.length >= 2 ? parts[0][0] + parts[parts.length - 1][0] : name.substring(0, 2);
    return raw
      .toUpperCase()
      .replace(
        /[<>&"']/g,
        (c) => ({ '<': '&lt;', '>': '&gt;', '&': '&amp;', '"': '&quot;', "'": '&apos;' })[c] ?? c,
      );
  }

  /** Derives a consistent HSL color from the driver's name. */
  getAvatarColor(driver: Driver): string {
    const name = driver.name || '';
    let hash = 0;
    for (let i = 0; i < name.length; i++) {
      hash = name.charCodeAt(i) + ((hash << 5) - hash);
      hash |= 0;
    }
    const hue = ((Math.abs(hash) % 12) * 30) % 360;
    return `hsl(${hue},60%,42%)`;
  }

  private syncMapLayers(): void {
    if (!this.leafletMap || !this.driverClusterGroup) return;
    this.syncDriverMarkers();
    this.syncDispatchOverlays();
    this.syncSelectedDriverTrail();
    if (this.showGeofences) {
      this.renderGeofences();
    }
  }

  private syncDriverMarkers(): void {
    if (!this.driverClusterGroup) return;

    this.driverClusterGroup.clearLayers();
    this.markerMap = {};

    for (const driver of this.filteredDrivers) {
      if (driver.currentLatitude == null || driver.currentLongitude == null) continue;

      const marker = L.marker([driver.currentLatitude, driver.currentLongitude], {
        icon: this.createDriverIcon(driver),
        opacity: this.isOnline(driver) ? 1 : 0.6,
      });

      marker.on('click', () => {
        this.ngZone.run(() => this.openInfoWindow(driver));
      });

      marker.bindTooltip(driver.name || this.t('liveMap.driver'), {
        direction: 'top',
        offset: [0, -48],
        opacity: 0.95,
      });

      this.markerMap[driver.id!] = marker;
      this.driverClusterGroup.addLayer(marker);
    }
  }

  private syncDispatchOverlays(): void {
    if (!this.dispatchLayerGroup) return;
    this.dispatchLayerGroup.clearLayers();

    for (const driver of this.filteredDrivers) {
      const pickup = driver.dispatch?.pickup;
      const dropoff = driver.dispatch?.dropoff;

      if (pickup) {
        this.dispatchLayerGroup.addLayer(
          L.marker([pickup.lat, pickup.lng], {
            icon: this.createStopIcon('P', '#22c55e'),
          }).bindTooltip(
            `${this.t('liveMap.pickup')}: ${pickup.locationName || this.t('liveMap.unknown')}`,
          ),
        );
      }

      if (dropoff) {
        this.dispatchLayerGroup.addLayer(
          L.marker([dropoff.lat, dropoff.lng], {
            icon: this.createStopIcon('D', '#ef4444'),
          }).bindTooltip(
            `${this.t('liveMap.dropoff')}: ${dropoff.locationName || this.t('liveMap.unknown')}`,
          ),
        );
      }

      if (pickup && dropoff) {
        this.dispatchLayerGroup.addLayer(
          L.polyline(
            [
              [pickup.lat, pickup.lng],
              [dropoff.lat, dropoff.lng],
            ],
            {
              color: '#FF9800',
              weight: 4,
              opacity: 0.95,
            },
          ),
        );
      }
    }
  }

  private syncSelectedDriverTrail(): void {
    if (!this.selectedDriverLayerGroup) return;
    this.selectedDriverLayerGroup.clearLayers();

    if (!(this.isReplayMode || this.autoTrackEnabled) || !this.selectedDriver) return;

    const path = this.getPolylinePath(this.selectedDriver);
    if (path.length < 2) return;

    this.selectedDriverLayerGroup.addLayer(
      L.polyline(
        path.map((point) => [point.lat, point.lng] as [number, number]),
        {
          color: '#2196F3',
          weight: 3,
          opacity: 0.85,
          dashArray: '8 8',
        },
      ),
    );
  }

  private createDriverIcon(driver: Driver): L.DivIcon {
    const online = this.isOnline(driver);
    const initials = this.getInitials(driver);
    const label = this.zoom >= this.labelZoom || this.selectedDriver?.id === driver.id ? driver.name : '';

    return L.divIcon({
      className: 'leaflet-driver-marker',
      html: `
        <div class="driver-marker-shell ${online ? 'online' : 'offline'} ${this.selectedDriver?.id === driver.id ? 'selected' : ''}">
          <div class="driver-marker-pin">
            <div class="driver-marker-avatar" style="background:${this.getAvatarColor(driver)}">${initials}</div>
            <span class="driver-marker-presence ${online ? 'online' : 'offline'}"></span>
          </div>
          ${label ? `<div class="driver-marker-label">${label}</div>` : ''}
        </div>
      `,
      iconSize: [44, 56],
      iconAnchor: [22, 54],
      tooltipAnchor: [0, -48],
    });
  }

  private createStopIcon(label: string, color: string): L.DivIcon {
    return L.divIcon({
      className: 'leaflet-stop-marker',
      html: `<div class="stop-marker" style="background:${color}">${label}</div>`,
      iconSize: [26, 26],
      iconAnchor: [13, 13],
    });
  }

  getMarkerIcon(driver: Driver): google.maps.Icon {
    const online = this.isOnline(driver);
    const pinColor = online ? '#15803d' : '#64748b';
    const dotColor = online ? '#22c55e' : '#94a3b8';
    const initials = this.getInitials(driver);
    const avatarBg = this.getAvatarColor(driver);

    const svg = [
      '<svg xmlns="http://www.w3.org/2000/svg" width="44" height="56" viewBox="0 0 44 56">',
      // drop shadow
      '<ellipse cx="22" cy="54" rx="8" ry="2.5" fill="rgba(0,0,0,0.2)"/>',
      // teardrop pin shape
      `<path d="M22 2 C11.5 2 3 10.5 3 21 C3 32 22 54 22 54 C22 54 41 32 41 21 C41 10.5 32.5 2 22 2Z" fill="${pinColor}"/>`,
      // white avatar ring
      '<circle cx="22" cy="21" r="15.5" fill="white"/>',
      // avatar background (unique color per driver)
      `<circle cx="22" cy="21" r="13.5" fill="${avatarBg}"/>`,
      // initials text
      `<text x="22" y="26" text-anchor="middle" dominant-baseline="auto" `,
      `font-size="12" font-weight="700" font-family="Arial,sans-serif" fill="white">${initials}</text>`,
      // online / offline badge (top-right)
      `<circle cx="35" cy="9" r="5.5" fill="${dotColor}" stroke="white" stroke-width="2"/>`,
      '</svg>',
    ].join('');

    return {
      url: 'data:image/svg+xml;charset=UTF-8,' + encodeURIComponent(svg),
      scaledSize: new google.maps.Size(44, 56),
      anchor: new google.maps.Point(22, 54),
      labelOrigin: new google.maps.Point(22, 21),
    };
  }

  getMarkerLabel(driver: Driver): google.maps.Icon {
    const label = `${driver.name || 'Driver'}`;
    const safeLabel = label && label.trim().length > 0 ? label : 'Driver';

    const svg = `
      <svg xmlns="http://www.w3.org/2000/svg" width="120" height="40">
        <text x="10" y="25"
              font-size="14"
              font-weight="bold"
              stroke="black"
              stroke-width="2px"
              fill="white">
          ${safeLabel}
        </text>
      </svg>`;

    return {
      url: 'data:image/svg+xml;charset=UTF-8,' + encodeURIComponent(svg),
      scaledSize: new google.maps.Size(120, 40),
      anchor: new google.maps.Point(60, 40),
    };
  }

  startStaleSweep(): void {
    this.ngZone.runOutsideAngular(() => {
      this.staleSweepSub = interval(15_000).subscribe(() => {
        const now = Date.now();
        let anyChange = false;
        this.allDrivers.forEach((d) => {
          const byPresence = this.lastSeenByDriver[d.id!] ?? 0;
          const byUpdated = toMs(d.lastUpdated);

          const isStale =
            (byPresence ? now - byPresence : 1e12) > this.PRESENCE_TIMEOUT_MS ||
            (byUpdated ? now - byUpdated : 1e12) > this.STALE_LOCATION_MS;

          if (isStale && (d.isOnline || (d.status ?? '') !== 'offline')) {
            d.isOnline = false;
            d.status = 'offline';
            anyChange = true;
          }
          const marker = this.markerMap[d.id!];
          if (marker) marker.setOpacity(d.isOnline ? 1.0 : 0.6);
        });
        if (anyChange) {
          this.ngZone.run(() => {
            this.applyFilters();
            this.cdr.markForCheck();
          });
        }
      });
    });
  }

  forceOpenDriverApp(driver: Driver): void {
    if (!driver?.id) return;
    this.adminNotificationService
      .sendNotificationToDriver({
        driverId: driver.id,
          title: this.t('liveMap.force_open'),
          message: this.t('liveMap.force_open_message'),
        type: 'force-track',
        severity: 'high',
        sender: 'ADMIN_UI',
      })
      .subscribe({
        next: () => this.logDebug(` 🚀 FORCE_OPEN sent to ${driver.name} (#${driver.id})`),
        error: (err) => {
          console.error(' Error sending FORCE_OPEN:', err);
          this.notify.error(this.t('liveMap.force_open_failed'));
        },
      });
  }

  getDriverStatusText(status: string): string {
    switch ((status || '').toLowerCase()) {
      case 'online':
        return `🟢 ${this.t('common.online')}`;
      case 'offline':
        return `🔴 ${this.t('common.offline')}`;
      case 'idle':
        return `🟡 ${this.t('liveMap.idle')}`;
      case 'on-trip':
        return `🟠 ${this.t('liveMap.trips')}`;
      default:
        return '❓';
    }
  }

  getStatusColor(status: string): string {
    switch ((status || '').toLowerCase()) {
      case 'online':
        return 'black';
      case 'offline':
        return 'red';
      case 'idle':
        return 'orange';
      case 'on-trip':
        return 'blue';
      default:
        return 'gray';
    }
  }

  getDispatchLineColor(driver: Driver): string {
    if (!driver.dispatch) return '#ccc';
    return this.isOnline(driver) ? '#FF9800' : '#999';
  }

  openInfoWindow(driver: Driver): void {
    if (driver.currentLatitude != null && driver.currentLongitude != null) {
      this.selectedDriver = driver;
      if (driver.locationName) {
        this.logDebug('Location: ' + driver.locationName);
      }
      this.mapCenter = {
        lat: driver.currentLatitude ?? 0,
        lng: driver.currentLongitude ?? 0,
      };
      this.leafletMap?.panTo([this.mapCenter.lat, this.mapCenter.lng], { animate: true });
      this.syncMapLayers();
    }
  }

  onMouseOut(): void {
    // No-op for Leaflet overlay card flow.
  }

  async disableDriver(driver: Driver): Promise<void> {
    if (!driver?.id) return;
    const confirmed = await this.confirm.confirm(this.t('liveMap.disable_driver_confirm', { name: driver.name }));
    if (confirmed) this.logDebug(`🚫 Driver #${driver.id} (${driver.name}) disabled`);
  }

  sendMessage(driver: Driver): void {
    this.bulkMode = false;
    this.selectedDriver = driver;
    this.messageTitle = this.t('liveMap.message_to_driver', { name: driver.name });
    this.messageContent = '';
    this.showMessageModal = true;
  }

  closeMessageModal(): void {
    this.showMessageModal = false;
    this.messageTitle = '';
    this.messageContent = '';
    this.selectedDriver = null;
    this.bulkMode = false;
  }

  sendMessageToDriver(): void {
    const msg = this.messageContent.trim();
    if (!msg) {
      this.notify.error(this.t('liveMap.enter_message_required'));
      return;
    }

    const title = this.messageTitle.trim() || this.t('liveMap.message_from_admin');

    if (this.isSendingMessage) {
      this.notify.info(this.t('liveMap.sending_in_progress'));
      return;
    }

    this.isSendingMessage = true;
    this.sendMessageError = '';

    if (this.bulkMode) {
      const ids = this.selectedIds;
      if (!ids.length) {
        this.notify.error(this.t('liveMap.no_drivers_selected'));
        return;
      }
      ids.forEach((id) => {
        // Send chat message and push notification to each driver.
        this.driverChatService.sendMessage(id, msg).subscribe({
          next: () => this.logDebug(`💬 Chat message sent to #${id}`),
          error: (err) => this.logDebug(`❌ Chat message failed for #${id}: ${JSON.stringify(err)}`),
        });

        this.adminNotificationService
          .sendNotificationToDriver({
            driverId: id,
            title,
            message: msg,
            type: 'message',
            severity: 'info',
            sender: 'ADMIN_UI',
            referenceId: String(id),
          })
          .subscribe({
            next: () => this.logDebug(`✉️ Notification sent to #${id}`),
            error: (err) => this.logDebug(`❌ Notification failed for #${id}: ${JSON.stringify(err)}`),
          });
      });
      this.closeMessageModal();
      this.isSendingMessage = false;
      return;
    }

    if (!this.selectedDriver) {
      this.notify.error(this.t('liveMap.no_driver_selected'));
      this.isSendingMessage = false;
      return;
    }

    this.driverChatService.sendMessage(this.selectedDriver.id, msg).subscribe({
      next: () => {
        this.logDebug(`💬 Chat message sent to ${this.selectedDriver?.name}`);
      },
      error: (err) => {
        console.error(' Chat message failed:', err);
      },
    });

    this.adminNotificationService
      .sendNotificationToDriver({
        driverId: this.selectedDriver.id,
        title,
        message: msg,
        type: 'message',
        severity: 'info',
        sender: 'ADMIN_UI',
        referenceId: String(this.selectedDriver.id),
      })
      .subscribe({
        next: () => {
          this.logDebug(`✉️ Notification sent to ${this.selectedDriver?.name}`);
          this.notify.success(this.t('liveMap.message_sent'));
          this.closeMessageModal();
        },
        error: (err) => {
          console.error(' Error sending notification:', err);
          this.sendMessageError = this.t('liveMap.message_send_failed');
          this.notify.error(this.t('liveMap.message_send_failed'));
        },
        complete: () => {
          this.isSendingMessage = false;
        },
      });
  }

  startResizing(event: MouseEvent): void {
    this.isResizing = true;
    document.addEventListener('mousemove', this.resizeSidebar);
    document.addEventListener('mouseup', this.stopResizing);
  }

  resizeSidebar = (event: MouseEvent): void => {
    if (this.isResizing) {
      const minWidth = 240;
      const maxWidth = 600;
      const newWidth = Math.min(Math.max(event.clientX, minWidth), maxWidth);
      this.sidebarWidth = newWidth;
    }
  };

  stopResizing = (): void => {
    this.isResizing = false;
    document.removeEventListener('mousemove', this.resizeSidebar);
    document.removeEventListener('mouseup', this.stopResizing);
  };

  getSafeDriver(driver: Driver | null): Driver {
    return (
      driver ?? {
        updatedFromSocket: false,
        logs: [],
        id: 0,
        name: this.t('liveMap.unknown'),
        licenseNumber: '',
        phone: '',
        rating: 0,
        isActive: false,
        latitude: 0,
        longitude: 0,
        currentLatitude: 0,
        currentLongitude: 0,
        status: 'offline',
        vehicleType: 'TRUCK',
        selected: false,
      }
    );
  }

  viewHistory(driver: Driver): void {
    if (!driver?.id) return;
    this.historyDriver = driver;
    this.historyMode = true;
    this.historyPoints = [];
    this.historyError = '';
    // Default: today
    const today = new Date();
    const pad = (n: number) => String(n).padStart(2, '0');
    const ymd = `${today.getFullYear()}-${pad(today.getMonth() + 1)}-${pad(today.getDate())}`;
    this.historyFromDate = `${ymd}T00:00`;
    this.historyToDate = `${ymd}T23:59`;
    this.cdr.markForCheck();
  }

  loadHistory(): void {
    if (!this.historyDriver?.id) return;
    this.stopHistoryPlayback();
    this.clearHistoryOverlays();
    this.historyLoading = true;
    this.historyError = '';
    this.historyPoints = [];
    this.cdr.markForCheck();

    const from = this.historyFromDate ? this.historyFromDate + ':00' : undefined;
    const to = this.historyToDate ? this.historyToDate + ':59' : undefined;

    this.driverLocationService.getDriverHistory(this.historyDriver.id!, from, to, 1000).subscribe({
      next: (points) => {
        this.historyPoints = points.filter((p) => isFinite(p.latitude) && isFinite(p.longitude));
        this.historyLoading = false;
        this.historyPlaybackIndex = 0;
        this.historyTotalDistanceKm = this.calcHistoryDistance(this.historyPoints);
        this.drawHistoryPolyline();
        if (this.historyPoints.length > 0) {
          const first = this.historyPoints[0];
          this.leafletMap?.panTo([first.latitude, first.longitude], { animate: true });
        }
        this.cdr.markForCheck();
      },
      error: (err) => {
        this.historyLoading = false;
        this.historyError = err?.message ?? this.t('liveMap.failed_to_load_history');
        this.cdr.markForCheck();
      },
    });
  }

  closeHistoryMode(): void {
    this.stopHistoryPlayback();
    this.clearHistoryOverlays();
    this.historyMode = false;
    this.historyDriver = null;
    this.historyPoints = [];
    this.historyError = '';
    this.cdr.markForCheck();
  }

  startHistoryPlayback(): void {
    if (this.historyPoints.length === 0 || this.historyIsPlaying) return;
    if (this.historyPlaybackIndex >= this.historyPoints.length - 1) {
      this.historyPlaybackIndex = 0;
    }
    this.historyIsPlaying = true;

    if (!this.leafletMap) return;

    if (!this.historyPlaybackMarker) {
      const current = this.historyPoints[this.historyPlaybackIndex];
      this.historyPlaybackMarker = L.marker([current.latitude, current.longitude], {
        icon: this.createStopIcon('D', '#2563eb'),
        zIndexOffset: 999,
      });
      this.historyPlaybackMarker.addTo(this.leafletMap);
    }

    this.historyPlaybackMarker.on('click', () => {
      const p = this.historyPoints[Math.max(0, this.historyPlaybackIndex - 1)];
      if (!p) return;
      this.historyPlaybackMarker?.bindPopup(`
        <div style="min-width:190px;font-size:12px">
          <strong>${this.historyDriver?.name ?? this.t('liveMap.driver')}</strong><br>
          ${this.t('liveMap.time')}: ${new Date(p.timestamp).toLocaleString()}<br>
          ${this.t('liveMap.speed')}: ${p.speed != null ? p.speed + ' ' + this.t('liveMap.km_h') : this.t('liveMap.not_available')}<br>
          ${this.t('liveMap.battery')}: ${p.batteryLevel != null ? p.batteryLevel + '%' : this.t('liveMap.not_available')}<br>
          ${this.t('liveMap.source')}: ${p.locationSource ?? p.source ?? this.t('liveMap.not_available')}
        </div>
      `);
      this.historyPlaybackMarker?.openPopup();
    });

    const intervalMs = Math.max(50, 1000 / this.historyPlaybackSpeed);
    this.historyPlaybackInterval = setInterval(() => {
      this.ngZone.run(() => {
        if (this.historyPlaybackIndex >= this.historyPoints.length) {
          this.stopHistoryPlayback();
          return;
        }
        const p = this.historyPoints[this.historyPlaybackIndex];
        this.historyPlaybackMarker?.setLatLng([p.latitude, p.longitude]);
        this.leafletMap?.panTo([p.latitude, p.longitude], { animate: true });
        this.historyPlaybackIndex++;
        this.cdr.markForCheck();
      });
    }, intervalMs);
  }

  pauseHistoryPlayback(): void {
    if (this.historyPlaybackInterval) {
      clearInterval(this.historyPlaybackInterval);
      this.historyPlaybackInterval = null;
    }
    this.historyIsPlaying = false;
    this.cdr.markForCheck();
  }

  stopHistoryPlayback(): void {
    if (this.historyPlaybackInterval) {
      clearInterval(this.historyPlaybackInterval);
      this.historyPlaybackInterval = null;
    }
    this.historyIsPlaying = false;
    this.historyPlaybackIndex = 0;
    this.historyPlaybackMarker?.closePopup();
    this.cdr.markForCheck();
  }

  setHistorySpeed(speed: number): void {
    this.historyPlaybackSpeed = speed;
    if (this.historyIsPlaying) {
      this.pauseHistoryPlayback();
      this.startHistoryPlayback();
    }
  }

  onHistorySliderChange(event: Event): void {
    const idx = Number((event.target as HTMLInputElement).value);
    this.historyPlaybackIndex = idx;
    const p = this.historyPoints[idx];
    if (p) {
      this.historyPlaybackMarker?.setLatLng([p.latitude, p.longitude]);
      this.leafletMap?.panTo([p.latitude, p.longitude], { animate: true });
    }
    this.cdr.markForCheck();
  }

  get historyCurrentPoint(): HistoryPoint | null {
    return this.historyPoints[this.historyPlaybackIndex] ?? null;
  }

  private drawHistoryPolyline(): void {
    if (!this.leafletMap || this.historyPoints.length === 0) return;
    this.clearHistoryOverlays();
    const path = this.historyPoints.map((p) => [p.latitude, p.longitude] as [number, number]);
    this.historyPolyline = L.polyline(path, {
      color: '#1976D2',
      opacity: 0.85,
      weight: 4,
    }).addTo(this.leafletMap);

    const startMarker = L.marker(path[0], {
      icon: this.createStopIcon('S', '#4CAF50'),
    }).addTo(this.leafletMap);
    const endMarker = L.marker(path[path.length - 1], {
      icon: this.createStopIcon('E', '#F44336'),
    }).addTo(this.leafletMap);
    this.historyEndpointMarkers = [startMarker, endMarker];
  }

  private clearHistoryOverlays(): void {
    this.historyPolyline?.remove();
    this.historyPolyline = null;
    this.historyPlaybackMarker?.remove();
    this.historyPlaybackMarker = null;
    this.historyEndpointMarkers.forEach((marker) => marker.remove());
    this.historyEndpointMarkers = [];
  }

  private calcHistoryDistance(points: HistoryPoint[]): number {
    let total = 0;
    for (let i = 1; i < points.length; i++) {
      total += this.haversineMeters(points[i - 1], points[i]);
    }
    return +(total / 1000).toFixed(2);
  }

  private haversineMeters(
    a: { latitude: number; longitude: number },
    b: { latitude: number; longitude: number },
  ): number {
    const R = 6371e3;
    const φ1 = (a.latitude * Math.PI) / 180;
    const φ2 = (b.latitude * Math.PI) / 180;
    const Δφ = ((b.latitude - a.latitude) * Math.PI) / 180;
    const Δλ = ((b.longitude - a.longitude) * Math.PI) / 180;
    const x = Math.sin(Δφ / 2) ** 2 + Math.cos(φ1) * Math.cos(φ2) * Math.sin(Δλ / 2) ** 2;
    return R * 2 * Math.atan2(Math.sqrt(x), Math.sqrt(1 - x));
  }

  trackByDriverId(index: number, driver: Driver): number {
    return driver?.id ?? index;
  }

  getDispatchPolyline(driver: Driver): google.maps.LatLngLiteral[] {
    const dispatch = driver.dispatch;
    if (dispatch?.pickup && dispatch?.dropoff) {
      return [
        { lat: dispatch.pickup.lat, lng: dispatch.pickup.lng },
        { lat: dispatch.dropoff.lat, lng: dispatch.dropoff.lng },
      ];
    }
    return [];
  }

  getPickupMarker(driver: Driver): google.maps.MarkerOptions | null {
    const pickup = driver.dispatch?.pickup;
    if (!pickup) return null;
    return {
      position: { lat: pickup.lat, lng: pickup.lng },
      icon: 'http://maps.google.com/mapfiles/ms/icons/green-dot.png',
      title: `Pickup: ${pickup.locationName}`,
    };
  }

  getDropoffMarker(driver: Driver): google.maps.MarkerOptions | null {
    const dropoff = driver.dispatch?.dropoff;
    if (!dropoff) return null;
    return {
      position: { lat: dropoff.lat, lng: dropoff.lng },
      icon: 'http://maps.google.com/mapfiles/ms/icons/red-dot.png',
      title: `Drop-off: ${dropoff.locationName}`,
    };
  }

  getPresenceAgeMs(driver: Driver): number | null {
    const ts = this.lastSeenByDriver[driver.id!];
    return ts ? Date.now() - ts : null;
  }

  isDriverOnlineByPresence(driver: Driver): boolean {
    const age = this.getPresenceAgeMs(driver);
    return age != null && age <= this.PRESENCE_TIMEOUT_MS;
  }

  getMarkerLabelFor(driver: Driver): string | google.maps.MarkerLabel {
    const show = this.zoom >= this.labelZoom || this.selectedDriver?.id === driver.id;
    if (!show) return '';
    return {
      text: driver.name || '',
      color: 'black',
      fontSize: '12px',
      fontWeight: 'bold',
    } as google.maps.MarkerLabel;
  }

  private ensureDriverRow(update: any): Driver {
    return {
      id: update.driverId,
      name: update.driverName || 'Driver #' + update.driverId,
      licenseNumber: '',
      phone: '',
      rating: 0,
      isActive: true,
      latitude: (update.latitude ?? update.lat) || 0,
      longitude: (update.longitude ?? update.lng) || 0,
      currentLatitude: (update.latitude ?? update.lat) || 0,
      currentLongitude: (update.longitude ?? update.lng) || 0,
      status: 'offline',
      vehicleType: 'TRUCK',
      selected: false,
      logs: [],
      updatedFromSocket: true,
      isOnline: !!update.isOnline,
    } as Driver;
  }

  /**
   * Render all active geofences on the map as Polygon or Circle overlays.
   * Colors are based on alert type (ENTER/EXIT/BOTH/NONE).
   */
  private renderGeofences(): void {
    if (!this.leafletMap || !this.showGeofences) return;

    // Clear existing geofence overlays
    this.clearGeofenceOverlays();

    // Render each geofence
    this.geofences.forEach((geofence) => {
      try {
        if (
          geofence.type === GeofenceType.CIRCLE &&
          geofence.centerLatitude &&
          geofence.centerLongitude
        ) {
          this.renderCircleGeofence(geofence);
        } else if (geofence.type === GeofenceType.POLYGON && geofence.geoJsonCoordinates) {
          this.renderPolygonGeofence(geofence);
        }
      } catch (err) {
        console.error(`Error rendering geofence ${geofence.id}:`, err);
      }
    });
  }

  /**
   * Render a circular geofence on the map.
   */
  private renderCircleGeofence(geofence: Geofence): void {
    if (!this.leafletMap) return;

    const isSelected = this.selectedGeofenceId === geofence.id;
    const baseColor = this.geofenceService.getCircleColor(geofence);

    const circle = L.circle([geofence.centerLatitude!, geofence.centerLongitude!], {
      radius: geofence.radiusMeters || 1000,
      fillColor: baseColor,
      fillOpacity: isSelected ? 0.4 : 0.2,
      color: isSelected ? '#FFD700' : baseColor,
      opacity: isSelected ? 1.0 : 0.8,
      weight: isSelected ? 4 : 2,
    }).addTo(this.leafletMap);

    // Add click listener to show geofence details and zoom
    circle.on('click', () => {
      this.showGeofenceInfo(geofence);
    });

    this.geofenceMap.set(geofence.id, circle);
  }

  /**
   * Render a polygon geofence on the map.
   */
  /**
   * Render a polygon geofence on the map.
   */
  private renderPolygonGeofence(geofence: Geofence): void {
    if (!this.leafletMap) return;

    const coordinates = this.geofenceService.parseGeoJsonCoordinates(
      geofence.geoJsonCoordinates || '',
    );
    if (coordinates.length < 3) {
      console.warn(`Polygon geofence ${geofence.id} has less than 3 vertices`);
      return;
    }

    const isSelected = this.selectedGeofenceId === geofence.id;
    const baseColor = this.geofenceService.getPolygonColor(geofence);

    const polygon = L.polygon(
      coordinates.map((c) => [c[0], c[1]] as [number, number]),
      {
        fillColor: baseColor,
        fillOpacity: isSelected ? 0.4 : 0.2,
        color: isSelected ? '#FFD700' : baseColor,
        opacity: isSelected ? 1.0 : 0.8,
        weight: isSelected ? 4 : 2,
      },
    ).addTo(this.leafletMap);

    // Add click listener to show geofence details and zoom
    polygon.on('click', () => {
      this.showGeofenceInfo(geofence);
    });

    this.geofenceMap.set(geofence.id, polygon);
  }

  /**
   * Clear all geofence overlays from the map.
   */
  private clearGeofenceOverlays(): void {
    this.geofenceMap.forEach((overlay) => {
      overlay.remove();
    });
    this.geofenceMap.clear();
  }

  /**
   * Check if a driver point is within a circle geofence.
   * Uses Haversine formula to calculate distance from center.
   */
  private isDriverInCircleGeofence(
    driverLat: number,
    driverLng: number,
    geofence: Geofence,
  ): boolean {
    if (!geofence.centerLatitude || !geofence.centerLongitude) return false;

    const R = 6371000; // Earth's radius in meters
    const lat1 = (geofence.centerLatitude * Math.PI) / 180;
    const lat2 = (driverLat * Math.PI) / 180;
    const deltaLat = ((driverLat - geofence.centerLatitude) * Math.PI) / 180;
    const deltaLng = ((driverLng - geofence.centerLongitude) * Math.PI) / 180;

    const a =
      Math.sin(deltaLat / 2) * Math.sin(deltaLat / 2) +
      Math.cos(lat1) * Math.cos(lat2) * Math.sin(deltaLng / 2) * Math.sin(deltaLng / 2);

    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    const distance = R * c; // Distance in meters

    const radiusMeters = geofence.radiusMeters || 0;
    return distance <= radiusMeters;
  }

  /**
   * Check if a driver point is within a polygon geofence using ray casting algorithm.
   */
  private isDriverInPolygonGeofence(
    driverLat: number,
    driverLng: number,
    geofence: Geofence,
  ): boolean {
    if (!geofence.geoJsonCoordinates) return false;

    const coordinates = this.geofenceService.parseGeoJsonCoordinates(geofence.geoJsonCoordinates);
    if (coordinates.length < 3) return false; // Polygon must have at least 3 points

    // Ray casting algorithm: count intersections of ray from point to infinity
    let inside = false;
    let p1Lat = coordinates[0][0];
    let p1Lng = coordinates[0][1];

    for (let i = 1; i <= coordinates.length; i++) {
      const p2Lat = coordinates[i % coordinates.length][0];
      const p2Lng = coordinates[i % coordinates.length][1];

      // Check if ray crosses edge
      if (
        (driverLng > Math.min(p1Lng, p2Lng) && driverLng <= Math.max(p1Lng, p2Lng)) ||
        (driverLng <= Math.min(p1Lng, p2Lng) && driverLng > Math.max(p1Lng, p2Lng))
      ) {
        if (
          driverLat <=
          Math.max(p1Lat, p2Lat) + ((driverLng - p1Lng) / (p2Lng - p1Lng)) * (p2Lat - p1Lat)
        ) {
          inside = !inside;
        }
      }
      p1Lat = p2Lat;
      p1Lng = p2Lng;
    }

    return inside;
  }

  /**
   * Count how many drivers are currently within a geofence.
   */
  countDriversInGeofence(geofence: Geofence): number {
    let count = 0;

    for (const driver of this.allDrivers) {
      if (driver.currentLatitude == null || driver.currentLongitude == null) continue;

      const isInside =
        geofence.type === GeofenceType.CIRCLE
          ? this.isDriverInCircleGeofence(driver.currentLatitude, driver.currentLongitude, geofence)
          : this.isDriverInPolygonGeofence(
              driver.currentLatitude,
              driver.currentLongitude,
              geofence,
            );

      if (isInside) count++;
    }

    return count;
  }

  /**
   * Show geofence info in a popup/toast and zoom/pan map to the geofence.
   */
  private showGeofenceInfo(geofence: Geofence): void {
    this.selectedGeofenceId = geofence.id;
    const alertTypeLabel = this.geofenceService.getAlertTypeLabel(geofence.alertType);
    const driversInGeofence = this.countDriversInGeofence(geofence);

    const message = `
Geofence: ${geofence.name}
Type: ${geofence.type}
Alert Type: ${alertTypeLabel}
Drivers Inside: ${driversInGeofence}
${geofence.speedLimitKmh ? `Speed Limit: ${geofence.speedLimitKmh} km/h` : ''}
    `.trim();

    // Show notification
    console.info(message);
    this.notify.info(message);

    // Zoom map to this geofence
    if (
      geofence.type === GeofenceType.CIRCLE &&
      geofence.centerLatitude &&
      geofence.centerLongitude
    ) {
      this.zoomToCircleGeofence(geofence);
    } else if (geofence.type === GeofenceType.POLYGON && geofence.geoJsonCoordinates) {
      this.zoomToPolygonGeofence(geofence);
    }

    // Re-render geofences to highlight the selected one
    this.renderGeofences();
    this.cdr.markForCheck();
  }

  /**
   * Zoom and pan map to show a circle geofence centered with appropriate zoom level.
   */
  private zoomToCircleGeofence(geofence: Geofence): void {
    if (!this.leafletMap || !geofence.centerLatitude || !geofence.centerLongitude) return;

    const center = { lat: geofence.centerLatitude, lng: geofence.centerLongitude };
    const radiusMeters = geofence.radiusMeters || 1000;

    // Pan map to center of circle
    this.leafletMap.panTo([center.lat, center.lng], { animate: true });

    // Calculate appropriate zoom level based on radius
    // Formula: zoom = log2(circumference / (width * sin(latitude)))
    // Simplified: zoom = 21 - log2(radius in meters)
    const zoom = Math.max(12, 21 - Math.log2(radiusMeters));
    this.leafletMap.setZoom(Math.round(zoom));
  }

  /**
   * Zoom and pan map to show a polygon geofence with all vertices visible.
   */
  private zoomToPolygonGeofence(geofence: Geofence): void {
    if (!this.leafletMap || !geofence.geoJsonCoordinates) return;

    const coordinates = this.geofenceService.parseGeoJsonCoordinates(geofence.geoJsonCoordinates);
    if (coordinates.length < 2) return;

    // Create bounds that include all polygon vertices
    const bounds = L.latLngBounds(
      coordinates.map((coord) => [coord[0], coord[1]] as [number, number]),
    );

    this.leafletMap.fitBounds(bounds, { padding: [100, 100] });
  }

  /**
   * Clear selected geofence selection.
   */
  clearSelectedGeofence(): void {
    this.selectedGeofenceId = null;
    this.renderGeofences(); // Re-render to remove highlight
    this.cdr.markForCheck();
  }

  /**
   * Calculate distance between two points using Haversine formula (returns km).
   */
  private calculateDistance(lat1: number, lng1: number, lat2: number, lng2: number): number {
    const R = 6371; // Earth radius in km
    const dLat = ((lat2 - lat1) * Math.PI) / 180;
    const dLng = ((lng2 - lng1) * Math.PI) / 180;
    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos((lat1 * Math.PI) / 180) *
        Math.cos((lat2 * Math.PI) / 180) *
        Math.sin(dLng / 2) *
        Math.sin(dLng / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
  }

  /**
   * Get distance from a driver to the proximity filter point (returns km or null).
   */
  getDistanceToFilterPoint(driver: Driver): number | null {
    if (
      !this.proximityFilterEnabled ||
      driver.currentLatitude == null ||
      driver.currentLongitude == null
    )
      return null;

    const lat = parseFloat(this.proximityFilterLat);
    const lng = parseFloat(this.proximityFilterLng);

    if (isNaN(lat) || isNaN(lng)) return null;

    return this.calculateDistance(lat, lng, driver.currentLatitude, driver.currentLongitude);
  }

  /**
   * Filter drivers that are within proximity radius from filter point.
   */
  getFilteredDrivers(): Driver[] {
    if (!this.proximityFilterEnabled) return this.allDrivers;

    const lat = parseFloat(this.proximityFilterLat);
    const lng = parseFloat(this.proximityFilterLng);

    if (isNaN(lat) || isNaN(lng)) return this.allDrivers;

    const filtered = this.allDrivers.filter((driver) => {
      if (driver.currentLatitude == null || driver.currentLongitude == null) return false;
      const distance = this.calculateDistance(
        lat,
        lng,
        driver.currentLatitude,
        driver.currentLongitude,
      );
      return distance <= this.proximityFilterRadius;
    });

    this.filteredDriversCount = filtered.length;
    return filtered;
  }

  /**
   * Apply proximity filter and zoom to show filtered drivers.
   */
  applyProximityFilter(): void {
    const lat = parseFloat(this.proximityFilterLat);
    const lng = parseFloat(this.proximityFilterLng);

    if (isNaN(lat) || isNaN(lng) || !this.leafletMap) {
      this.notify.error('Please enter valid latitude and longitude');
      return;
    }

    this.proximityFilterEnabled = true;
    this.proximityClickMode = false; // Exit click mode when filter applied
    this.filteredDriversCount = 0;

    // Clean up existing marker and circle
    if (this.proximityFilterMarker) {
      this.proximityFilterMarker.remove();
    }
    if (this.proximityFilterCircle) {
      this.proximityFilterCircle.remove();
    }

    // Add visual marker for filter point (draggable)
    this.proximityFilterMarker = L.marker([lat, lng], {
      icon: this.createStopIcon('F', '#4F46E5'),
      draggable: true,
    }).addTo(this.leafletMap);
    this.proximityFilterMarker.bindTooltip(
      `Filter Point (${this.proximityFilterRadius}km radius) - Drag to move`,
    );

    // Add drag listener to update filter on drag
    this.proximityFilterMarker.on('dragend', () => {
      const position = this.proximityFilterMarker?.getLatLng();
      if (!position) return;
      this.proximityFilterLat = position.lat.toFixed(6);
      this.proximityFilterLng = position.lng.toFixed(6);
      this.updateProximityFilterVisuals();
      this.applyFilters();
      this.cdr.markForCheck();
    });

    // Draw circle showing filter radius
    this.proximityFilterCircle = L.circle([lat, lng], {
      radius: this.proximityFilterRadius * 1000, // Convert km to meters
      fillColor: '#4F46E5',
      fillOpacity: 0.1,
      color: '#4F46E5',
      opacity: 0.5,
      weight: 2,
    }).addTo(this.leafletMap);

    // Zoom to show filter area
    this.leafletMap.panTo([lat, lng], { animate: true });
    const zoom = Math.max(10, 21 - Math.log2(this.proximityFilterRadius * 1000));
    this.leafletMap.setZoom(Math.round(zoom));

    this.applyFilters();
    this.cdr.markForCheck();
    this.notify.success(
      `Found ${this.filteredDriversCount} drivers within ${this.proximityFilterRadius}km`,
    );
  }

  /**
   * Update proximity filter circle and marker visuals (after drag or radius change).
   */
  private updateProximityFilterVisuals(): void {
    const lat = parseFloat(this.proximityFilterLat);
    const lng = parseFloat(this.proximityFilterLng);

    if (isNaN(lat) || isNaN(lng) || !this.leafletMap) return;

    // Update circle position and radius
    if (this.proximityFilterCircle) {
      this.proximityFilterCircle.setLatLng([lat, lng]);
      this.proximityFilterCircle.setRadius(this.proximityFilterRadius * 1000);
    }

    if (this.proximityFilterMarker) {
      this.proximityFilterMarker.setLatLng([lat, lng]);
      this.proximityFilterMarker.bindTooltip(
        `Filter Point (${this.proximityFilterRadius}km radius) - Drag to move`,
      );
    }
  }

  /**
   * Clear proximity filter.
   */
  clearProximityFilter(): void {
    this.proximityFilterEnabled = false;
    this.proximityClickMode = false;
    this.proximityFilterLat = '';
    this.proximityFilterLng = '';
    this.proximityFilterRadius = 10;
    this.filteredDriversCount = 0;

    if (this.proximityFilterMarker) {
      this.proximityFilterMarker.remove();
      this.proximityFilterMarker = undefined;
    }

    if (this.proximityFilterCircle) {
      this.proximityFilterCircle.remove();
      this.proximityFilterCircle = undefined;
    }

    this.applyFilters();
    this.cdr.markForCheck();
  }

  /**
   * Toggle click-on-map mode to set proximity filter point.
   */
  toggleProximityClickMode(): void {
    this.proximityClickMode = !this.proximityClickMode;

    if (this.proximityClickMode) {
      this.notify.info('Click anywhere on the map to set filter point');
    }

    this.cdr.markForCheck();
  }

  /**
   * Handle map click when in proximity click mode.
   */
  onMapClickForProximity(event: L.LeafletMouseEvent): void {
    if (!this.proximityClickMode) return;

    this.proximityFilterLat = event.latlng.lat.toFixed(6);
    this.proximityFilterLng = event.latlng.lng.toFixed(6);
    this.applyProximityFilter();
  }

  /**
   * Use browser geolocation to set proximity filter to current location.
   */
  useMyLocation(): void {
    if (!navigator.geolocation) {
      this.notify.error('Geolocation is not supported by your browser');
      return;
    }

    this.notify.info('Getting your location...');

    navigator.geolocation.getCurrentPosition(
      (position) => {
        this.proximityFilterLat = position.coords.latitude.toFixed(6);
        this.proximityFilterLng = position.coords.longitude.toFixed(6);
        this.notify.success('Location set to your current position');
        this.cdr.markForCheck();
      },
      (error) => {
        let message = 'Could not get your location';
        if (error.code === error.PERMISSION_DENIED) {
          message = 'Location permission denied. Please enable location access.';
        }
        this.notify.error(message);
      },
      {
        enableHighAccuracy: true,
        timeout: 10000,
        maximumAge: 0,
      },
    );
  }

  /**
   * Update proximity filter when radius changes.
   */
  onProximityRadiusChange(): void {
    if (this.proximityFilterEnabled) {
      this.updateProximityFilterVisuals();
      this.applyFilters();
      this.cdr.markForCheck();
    }
  }

  /**
   * Handle a geofence crossing event from WebSocket.
   */
  private handleGeofenceEvent(geofenceEvent: GeofenceEvent): void {
    const driver = this.allDrivers.find((d: Driver) => d.id === geofenceEvent.driverId);
    const geofence = this.geofences.find((g) => g.id === geofenceEvent.geofenceId);

    if (!driver || !geofence) return;

    // Show notification toast
    const action = geofenceEvent.eventType === 'ENTER' ? 'entered' : 'exited';
    const messageText = `Driver ${geofenceEvent.driverName} ${action} zone "${geofenceEvent.geofenceName}"`;

    this.notify.info(messageText);

    // Record geofence alert in service (for historical view)
    const eventType: GeofenceEventType =
      geofenceEvent.eventType === 'ENTER' ? GeofenceEventType.ENTER : GeofenceEventType.EXIT;

    const alert: GeofenceAlert = {
      id: 0,
      driverId: geofenceEvent.driverId,
      driverName: geofenceEvent.driverName,
      geofenceId: geofenceEvent.geofenceId,
      geofenceName: geofenceEvent.geofenceName,
      eventType,
      eventLatitude: geofenceEvent.latitude,
      eventLongitude: geofenceEvent.longitude,
      eventTimestamp: geofenceEvent.eventTimestamp,
      notificationSent: true,
      createdAt: geofenceEvent.eventTimestamp,
    };

    this.geofenceService.recordGeofenceAlert(alert);
    this.cdr.markForCheck();
  }
}
