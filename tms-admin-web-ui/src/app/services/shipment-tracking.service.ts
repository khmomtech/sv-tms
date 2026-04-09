/**
 * Shipment Tracking Service
 * Handles real-time shipment tracking, location updates, and status management
 * Integrates with TrackingApiService for backend communication
 *
 * Real-world optimizations:
 * - Response caching with TTL (Time-To-Live)
 * - Exponential backoff retry strategy for resilience
 * - Request debouncing to prevent duplicate API calls
 * - Optimistic updates with rollback on failure
 * - Comprehensive error recovery and graceful degradation
 */

import { Injectable } from '@angular/core';
import { BehaviorSubject, Observable, interval, timer, throwError } from 'rxjs';
import { catchError, switchMap, tap, takeUntil, shareReplay, retry } from 'rxjs/operators';

import type {
  TrackingResponse,
  ShipmentSummary,
  StatusTimeline,
  GeoLocation,
  DriverInfo,
  ProofOfDelivery,
  TrackingError,
  OrderPoint,
  ShipmentItem,
  DispatchAssignment,
} from '../models/shipment-tracking.model';
import { TrackingApiService } from './tracking-api.service';
import { DispatchService } from './dispatch.service';

interface CacheEntry<T> {
  data: T;
  timestamp: number;
  ttl: number;
}

@Injectable({
  providedIn: 'root',
})
export class ShipmentTrackingService {
  // Current tracking data
  private currentTrackingSubject = new BehaviorSubject<TrackingResponse | null>(null);
  public currentTracking$ = this.currentTrackingSubject.asObservable();

  // Current location stream (updates every 10 seconds after dispatch)
  private locationUpdatesSubject = new BehaviorSubject<GeoLocation | null>(null);
  public locationUpdates$ = this.locationUpdatesSubject.asObservable();

  // Error handling
  private errorSubject = new BehaviorSubject<TrackingError | null>(null);
  public error$ = this.errorSubject.asObservable();

  // Loading state
  private loadingSubject = new BehaviorSubject<boolean>(false);
  public loading$ = this.loadingSubject.asObservable();

  // Active reference being tracked
  private activeReferenceSubject = new BehaviorSubject<string | null>(null);
  public activeReference$ = this.activeReferenceSubject.asObservable();

  // Pickup/Delivery points for map display
  private pickupPointsSubject = new BehaviorSubject<OrderPoint[]>([]);
  public pickupPoints$ = this.pickupPointsSubject.asObservable();

  private deliveryPointsSubject = new BehaviorSubject<OrderPoint[]>([]);
  public deliveryPoints$ = this.deliveryPointsSubject.asObservable();

  // Order items
  private itemsSubject = new BehaviorSubject<ShipmentItem[]>([]);
  public items$ = this.itemsSubject.asObservable();

  // Dispatch assignments
  private dispatchesSubject = new BehaviorSubject<DispatchAssignment[]>([]);
  public dispatches$ = this.dispatchesSubject.asObservable();

  // Caching and performance optimization
  private trackingCache = new Map<string, CacheEntry<TrackingResponse>>();
  private locationCache = new Map<string, CacheEntry<GeoLocation>>();
  private readonly TRACKING_CACHE_TTL = 30000; // 30 seconds
  private readonly LOCATION_CACHE_TTL = 5000; // 5 seconds
  private pendingRequests = new Map<string, Observable<TrackingResponse>>();

  constructor(
    private trackingApi: TrackingApiService,
    private dispatchService: DispatchService,
  ) {
    this.initializePolling();
  }

  /**
   * Check if cached entry is still valid
   */
  private isCacheValid<T>(entry: CacheEntry<T> | undefined): boolean {
    if (!entry) return false;
    return Date.now() - entry.timestamp < entry.ttl;
  }

  /**
   * Get from cache or null if expired
   */
  private getFromCache<T>(cache: Map<string, CacheEntry<T>>, key: string): T | null {
    const entry = cache.get(key);
    if (this.isCacheValid(entry)) {
      return entry!.data;
    }
    cache.delete(key);
    return null;
  }

  /**
   * Store in cache with TTL
   */
  private storeInCache<T>(
    cache: Map<string, CacheEntry<T>>,
    key: string,
    data: T,
    ttl: number,
  ): void {
    cache.set(key, { data, timestamp: Date.now(), ttl });
  }

  /**
   * Track a shipment by booking or order reference
   * Implements caching, request deduplication, and exponential backoff retry
   */
  trackShipment(reference: string): Observable<TrackingResponse> {
    if (!reference || reference.trim().length === 0) {
      this.setError({
        code: 'INVALID_REFERENCE',
        message: 'Please enter a valid booking or order reference',
      });
      throw new Error('Invalid reference');
    }

    const normalizedRef = reference.trim().toUpperCase();

    // Check cache first
    const cached = this.getFromCache(this.trackingCache, normalizedRef);
    if (cached) {
      console.log(`[Tracking] Using cached data for ${normalizedRef}`);
      this.currentTrackingSubject.next(cached);
      return new Observable((subscriber) => {
        subscriber.next(cached);
        subscriber.complete();
      });
    }

    // Check if request is already pending
    if (this.pendingRequests.has(normalizedRef)) {
      console.log(`[Tracking] Returning pending request for ${normalizedRef}`);
      return this.pendingRequests.get(normalizedRef)!;
    }

    this.loadingSubject.next(true);
    this.activeReferenceSubject.next(normalizedRef);

    // Create new request with retry logic and caching
    const request$ = this.trackingApi.trackShipment(normalizedRef).pipe(
      // Exponential backoff retry: 1s, 2s, 4s on failure
      retry({
        count: 3,
        delay: (error, retryCount) => {
          const backoff = Math.min(1000 * Math.pow(2, retryCount), 5000);
          console.warn(`[Tracking] Retry attempt ${retryCount + 1} in ${backoff}ms:`, error);
          return timer(backoff);
        },
      }),
      tap((response: TrackingResponse) => {
        // Cache the successful response
        this.storeInCache(this.trackingCache, normalizedRef, response, this.TRACKING_CACHE_TTL);

        this.currentTrackingSubject.next(response);
        this.errorSubject.next(null);

        // Populate all tracking data
        this.pickupPointsSubject.next(response.pickupPoints || []);
        this.deliveryPointsSubject.next(response.deliveryPoints || []);
        this.itemsSubject.next(response.items || []);
        this.dispatchesSubject.next(response.dispatches || []);

        // Fetch location immediately and start polling if there's a driver assigned
        if (response.driver) {
          this.trackingApi.getCurrentLocation(normalizedRef).subscribe({
            next: (location) => {
              if (location) {
                this.storeInCache(
                  this.locationCache,
                  normalizedRef,
                  location,
                  this.LOCATION_CACHE_TTL,
                );
                this.locationUpdatesSubject.next(location);
              }
            },
            error: (err) => console.error('Initial location fetch failed:', err),
          });

          this.startLocationPolling(normalizedRef);
        }

        // Prefer admin dispatch history when a dispatchId is available
        const dispatchIdStr =
          response.dispatches?.[0]?.dispatchId ||
          response.driver?.dispatchId ||
          (response as any)?.dispatch?.id?.toString();
        const dispatchId = dispatchIdStr ? Number(dispatchIdStr) : undefined;

        if (dispatchId && !Number.isNaN(dispatchId)) {
          this.dispatchService.getStatusHistory(dispatchId).subscribe({
            next: (apiResp) => {
              const history = apiResp.data || [];
              const enrichedTimeline = this.mapHistoryToTimeline(history, response);
              if (enrichedTimeline.length > 0) {
                const updated: TrackingResponse = { ...response, timeline: enrichedTimeline };
                this.currentTrackingSubject.next(updated);
              }
            },
            error: (err) => {
              console.warn('Dispatch status-history fetch error:', err);
              this.fetchPublicHistory(normalizedRef, response);
            },
          });
        } else {
          this.fetchPublicHistory(normalizedRef, response);
        }
      }),
      catchError((error) => {
        const trackingError: TrackingError = {
          code: error.status === 404 ? 'NOT_FOUND' : 'ERROR',
          message:
            error.status === 404
              ? 'Shipment not found. Please check your reference number.'
              : 'Failed to fetch tracking information. Please try again.',
          details: error.error?.message,
        };
        this.setError(trackingError);
        this.pendingRequests.delete(normalizedRef);
        return throwError(() => error);
      }),
      tap(
        () => this.loadingSubject.next(false),
        () => {
          this.loadingSubject.next(false);
          this.pendingRequests.delete(normalizedRef);
        },
      ),
      shareReplay(1), // Share result among multiple subscribers
    );

    // Store pending request
    this.pendingRequests.set(normalizedRef, request$);

    // Clean up after completion/error
    request$.subscribe({
      complete: () => this.pendingRequests.delete(normalizedRef),
      error: () => this.pendingRequests.delete(normalizedRef),
    });

    return request$;
  }

  private fetchPublicHistory(reference: string, response: TrackingResponse): void {
    this.trackingApi.getTrackingHistory(reference.toUpperCase()).subscribe({
      next: (history) => {
        const enrichedTimeline = this.mapHistoryToTimeline(history, response);
        if (enrichedTimeline.length > 0) {
          const updated: TrackingResponse = { ...response, timeline: enrichedTimeline };
          this.currentTrackingSubject.next(updated);
        }
      },
      error: (err) => {
        // History fetch failure should not break tracking; keep client-built timeline
        console.warn('Public tracking history fetch error:', err);
      },
    });
  }

  /**
   * Get current tracking data
   */
  getCurrentTracking(): TrackingResponse | null {
    return this.currentTrackingSubject.value;
  }

  /**
   * Get timeline sorted by order with completed status
   */
  getTimeline(response: TrackingResponse): StatusTimeline[] {
    const currentStatus = response.shipmentSummary.status;

    return response.timeline.map((item) => ({
      ...item,
      completed: this.isStatusCompleted(item.status, currentStatus),
    }));
  }

  /**
   * Get driver information for active shipment
   */
  getDriverInfo(): DriverInfo | undefined {
    return this.currentTrackingSubject.value?.driver;
  }

  /**
   * Get current location for map display
   */
  getCurrentLocation(): GeoLocation | null {
    return this.locationUpdatesSubject.value;
  }

  /**
   * Get proof of delivery details
   */
  getProofOfDelivery(): ProofOfDelivery | undefined {
    return this.currentTrackingSubject.value?.proofOfDelivery;
  }

  /**
   * Get estimated time of arrival
   */
  getETA(): string | undefined {
    return this.currentTrackingSubject.value?.estimatedTimeOfArrival;
  }

  /**
   * Get pickup points (loading locations)
   */
  getPickupPoints(): OrderPoint[] {
    return this.pickupPointsSubject.value || [];
  }

  /**
   * Get delivery points (unloading locations)
   */
  getDeliveryPoints(): OrderPoint[] {
    return this.deliveryPointsSubject.value || [];
  }

  /**
   * Get order items
   */
  getItems(): ShipmentItem[] {
    return this.itemsSubject.value || [];
  }

  /**
   * Get dispatch assignments
   */
  getDispatches(): DispatchAssignment[] {
    return this.dispatchesSubject.value || [];
  }

  /**
   * Clear current tracking data
   */
  clearTracking(): void {
    this.currentTrackingSubject.next(null);
    this.locationUpdatesSubject.next(null);
    this.activeReferenceSubject.next(null);
    this.errorSubject.next(null);
    this.pickupPointsSubject.next([]);
    this.deliveryPointsSubject.next([]);
    this.itemsSubject.next([]);
    this.dispatchesSubject.next([]);
  }

  /**
   * Private methods
   */

  private isStatusCompleted(status: string, currentStatus: string): boolean {
    const completedStatuses = [
      'BOOKING_CREATED',
      'ORDER_CONFIRMED',
      'PAYMENT_VERIFIED',
      'DISPATCHED',
      'IN_TRANSIT',
      'OUT_FOR_DELIVERY',
      'DELIVERED',
    ];

    const statusIndex = completedStatuses.indexOf(status);
    const currentIndex = completedStatuses.indexOf(currentStatus);

    return statusIndex !== -1 && currentIndex !== -1 && statusIndex <= currentIndex;
  }

  /**
   * Map backend history events to StatusTimeline[] with robust field handling
   */
  private mapHistoryToTimeline(history: any[], response: TrackingResponse): StatusTimeline[] {
    if (!Array.isArray(history) || history.length === 0) return [];

    const toIso = (value: any): string | undefined => {
      if (!value) return undefined;
      if (typeof value === 'string') return value;
      if (Array.isArray(value)) {
        const [y, m, d, hh = 0, mm = 0, ss = 0, nanos = 0] = value;
        try {
          const date = new Date(y, (m || 1) - 1, d || 1, hh, mm, ss);
          // Handle nanoseconds or milliseconds in the 7th element
          // Java LocalDateTime nanosecond precision (9 digits) vs JS millisecond (3 digits)
          const ms = nanos > 999999 ? Math.floor(nanos / 1000000) : nanos;
          date.setMilliseconds(ms);
          return date.toISOString();
        } catch {
          return undefined;
        }
      }
      if (typeof value === 'number') {
        return new Date(value).toISOString();
      }
      return undefined;
    };

    const prettify = (value: string): string =>
      value
        .toLowerCase()
        .split('_')
        .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
        .join(' ');

    const mapStatus = (
      status: string | undefined,
    ): { status: StatusTimeline['status']; displayName: string } => {
      const s = (status || '').toUpperCase();
      switch (s) {
        case 'PENDING':
        case 'CONFIRMED':
          return { status: 'BOOKING_CREATED', displayName: 'Pending Assignment' };
        case 'APPROVED':
          return { status: 'ORDER_CONFIRMED', displayName: 'Order Approved' };
        case 'ASSIGNED':
          return { status: 'DISPATCHED', displayName: 'Driver Assigned' };
        case 'DRIVER_CONFIRMED':
          return { status: 'DISPATCHED', displayName: 'Driver Confirmed' };
        case 'SCHEDULED':
          return { status: 'DISPATCHED', displayName: 'Trip Scheduled' };
        case 'IN_QUEUE':
          return { status: 'DISPATCHED', displayName: 'In Queue' };
        case 'ARRIVED_LOADING':
          return { status: 'DISPATCHED', displayName: 'Arrived at Loading Bay' };
        case 'LOADING':
          return { status: 'DISPATCHED', displayName: 'Loading in Progress' };
        case 'LOADED':
          return { status: 'IN_TRANSIT', displayName: 'Loaded & Departed' };
        case 'SAFETY_PASSED':
          return { status: 'DISPATCHED', displayName: 'Safety Check Passed' };
        case 'SAFETY_FAILED':
          return { status: 'FAILED_DELIVERY', displayName: 'Safety Check Failed' };
        case 'IN_TRANSIT':
          return { status: 'IN_TRANSIT', displayName: 'In Transit' };
        case 'ARRIVED_UNLOADING':
          return { status: 'OUT_FOR_DELIVERY', displayName: 'Arrived at Unloading Bay' };
        case 'UNLOADING':
          return { status: 'OUT_FOR_DELIVERY', displayName: 'Unloading in Progress' };
        case 'UNLOADED':
          return { status: 'DELIVERED', displayName: 'Unloaded' };
        case 'DELIVERED':
          return { status: 'DELIVERED', displayName: 'Delivered' };
        case 'COMPLETED':
          return { status: 'DELIVERED', displayName: 'Completed' };
        case 'CANCELLED':
          return { status: 'RETURNED', displayName: 'Cancelled' };
        case 'FAILED_DELIVERY':
          return { status: 'FAILED_DELIVERY', displayName: 'Delivery Failed' };
        case 'RETURNED':
          return { status: 'RETURNED', displayName: 'Returned' };
        default:
          return { status: 'BOOKING_CREATED', displayName: prettify(s || 'Unknown') };
      }
    };

    const entries: StatusTimeline[] = history.map((ev: any) => {
      const mapped = mapStatus(ev?.status || ev?.newStatus || ev?.state);
      const status = mapped.status;
      const timestamp = toIso(
        ev?.createdAt || ev?.updatedAt || ev?.eventTime || ev?.timestamp || ev?.time,
      );
      const by = ev?.updatedBy || ev?.actor || ev?.by;
      const baseNotes = ev?.message || ev?.note || ev?.description || ev?.remarks;
      // Only include baseNotes; updatedBy is displayed separately in timeline
      const notes = baseNotes && String(baseNotes).trim().length > 0 ? baseNotes : undefined;
      const location =
        ev?.latitude != null && ev?.longitude != null
          ? { latitude: ev.latitude, longitude: ev.longitude, address: undefined }
          : undefined;
      const displayNameMap: Record<StatusTimeline['status'], string> = {
        BOOKING_CREATED: mapped.displayName || 'Booking Created',
        ORDER_CONFIRMED: mapped.displayName || 'Order Confirmed',
        PAYMENT_VERIFIED: mapped.displayName || 'Payment Verified',
        DISPATCHED: mapped.displayName || 'Dispatched',
        IN_TRANSIT: mapped.displayName || 'In Transit',
        OUT_FOR_DELIVERY: mapped.displayName || 'Out for Delivery',
        DELIVERED: mapped.displayName || 'Delivered',
        FAILED_DELIVERY: mapped.displayName || 'Delivery Failed',
        RETURNED: mapped.displayName || 'Returned',
      };
      return {
        status,
        displayName: displayNameMap[status],
        timestamp,
        notes,
        location,
        completed: false, // computed later in getTimeline()
        rawStatus: (ev?.status || ev?.newStatus || ev?.state || '').toUpperCase(), // Store original dispatch enum
        updatedBy: by, // Store who made the update
      };
    });

    // Sort by timestamp descending (newest first) for better UX
    entries.sort((a, b) => {
      const ta = a.timestamp ? Date.parse(a.timestamp) : 0;
      const tb = b.timestamp ? Date.parse(b.timestamp) : 0;
      return tb - ta; // Reverse order for newest first
    });

    // Return all entries without deduplication to preserve complete audit trail
    // Each status change (even if status is same) represents an important event
    return entries;
  }

  private startLocationPolling(reference: string): void {
    // Poll for location updates every 10 seconds
    interval(10000)
      .pipe(
        switchMap(() => this.trackingApi.getCurrentLocation(reference)),
        tap((location) => this.locationUpdatesSubject.next(location)),
        catchError(() => {
          // Silent fail for location polling
          return new Observable<GeoLocation>();
        }),
        takeUntil(
          // Stop polling when reference changes
          this.activeReferenceSubject.pipe(
            switchMap((ref) => (ref !== reference ? interval(0) : new Observable())),
          ),
        ),
      )
      .subscribe();
  }

  private initializePolling(): void {
    // This can be extended for real-time updates via WebSocket
    // For now, manual refresh is handled in component
  }

  private setError(error: TrackingError): void {
    this.errorSubject.next(error);
    this.loadingSubject.next(false);
  }
}
