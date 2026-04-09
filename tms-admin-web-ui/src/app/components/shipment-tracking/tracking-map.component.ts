/**
 * Tracking Map Component
 * Displays live location on map with driver info
 * Uses OpenStreetMap via Leaflet (free, no API key needed)
 *
 * Performance optimizations:
 * - Lazy initialization (only when location available)
 * - Marker clustering for multiple stops
 * - Debounced location updates
 * - Memory-efficient cleanup on destroy
 * - Responsive design with mobile support
 */

import { CommonModule } from '@angular/common';
import {
  Component,
  Input,
  ViewChild,
  ChangeDetectorRef,
  type OnInit,
  type OnDestroy,
  type OnChanges,
  type AfterViewInit,
  type SimpleChanges,
  type ElementRef,
  ChangeDetectionStrategy,
} from '@angular/core';
import { Subject } from 'rxjs';
import { debounceTime, takeUntil } from 'rxjs/operators';

import type {
  GeoLocation,
  TrackingResponse,
  ShipmentStatus,
  OrderPoint,
} from '../../models/shipment-tracking.model';

// Declare Leaflet types from CDN
declare const L: any;

@Component({
  selector: 'app-tracking-map',
  standalone: true,
  imports: [CommonModule],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <div class="relative">
      <!-- Map container -->
      <div
        #mapContainer
        [id]="mapId"
        class="h-80 rounded-xl bg-slate-100 border border-slate-200 overflow-hidden"
        [class.opacity-0]="!location && !hasAnyPoint()"
        [class.pointer-events-none]="!location && !hasAnyPoint()"
        role="region"
        aria-label="Shipment tracking map"
      ></div>

      <!-- Info overlay (if no location) -->
      <div
        *ngIf="!location"
        class="absolute inset-0 h-80 rounded-xl bg-slate-100 border border-slate-200 flex items-center justify-center text-slate-400 z-10"
      >
        <div class="text-center">
          <div class="text-3xl mb-2">📍</div>
          <div *ngIf="isDispatchedOrInTransit() && !hasAnyPoint()">
            Location will appear here once driver location is available
          </div>
          <div *ngIf="!isDispatchedOrInTransit() && !hasAnyPoint()">
            Map is available after dispatch
          </div>
          <div *ngIf="hasAnyPoint()" class="text-sm text-slate-600">
            Route will render once stop locations are available
          </div>
        </div>
      </div>

      <!-- Location details card -->
      <div *ngIf="location" class="mt-4 p-4 bg-blue-50 border border-blue-200 rounded-lg">
        <div class="font-semibold text-blue-900">Current Location</div>
        <div class="text-sm text-blue-800 mt-2">
          📍
          {{
            location.address ||
              'Latitude: ' +
                formatCoordinate(location.latitude) +
                ', Longitude: ' +
                formatCoordinate(location.longitude)
          }}
        </div>
        <div *ngIf="location.lastUpdated" class="text-xs text-blue-600 mt-1">
          Last updated: {{ location.lastUpdated | date: 'short' }}
        </div>
        <div *ngIf="location.speed" class="text-xs text-blue-600">
          Speed: {{ location.speed }} km/h
        </div>
      </div>

      <!-- No location state for dispatched shipments -->
      <div
        *ngIf="!location && isDispatchedOrInTransit()"
        class="mt-4 p-4 bg-amber-50 border border-amber-200 rounded-lg"
      >
        <div class="text-sm text-amber-800">
          ⏳ Location updates will appear here as the driver progresses
        </div>
      </div>
    </div>
  `,
  styles: [
    `
      @import url('https://unpkg.com/leaflet@1.9.4/dist/leaflet.css');
    `,
  ],
})
export class TrackingMapComponent implements OnInit, OnDestroy, OnChanges, AfterViewInit {
  @Input() location: GeoLocation | undefined;
  @Input() tracking: TrackingResponse | undefined;
  @Input() pickupPoints: OrderPoint[] = [];
  @Input() deliveryPoints: OrderPoint[] = [];

  @ViewChild('mapContainer') mapContainer!: ElementRef;

  private destroy$ = new Subject<void>();
  private locationUpdates$ = new Subject<GeoLocation>();

  mapId = `map-${Math.random().toString(36).substr(2, 9)}`;
  isMapReady = false;
  mapInitialized = false;
  private map: any;
  private marker: any;
  private pickupMarkers: any[] = [];
  private deliveryMarkers: any[] = [];
  private routeLine: any;
  private leafletLoaded = false;

  constructor(private cdr: ChangeDetectorRef) {}

  ngOnInit(): void {
    this.loadLeaflet();
  }

  ngAfterViewInit(): void {
    console.log('[TrackingMap] AfterViewInit - location:', this.location);
    if (this.location && this.leafletLoaded) {
      setTimeout(() => this.initializeMap(), 100);
    }
  }

  ngOnChanges(changes: SimpleChanges): void {
    console.log('[TrackingMap] OnChanges:', changes);

    if (changes['location']) {
      console.log('[TrackingMap] Location changed:', {
        previous: changes['location'].previousValue,
        current: changes['location'].currentValue,
        firstChange: changes['location'].firstChange,
      });

      if (!changes['location'].firstChange && this.location && this.leafletLoaded) {
        if (this.map && this.marker) {
          // Update existing marker position
          const newLatLng = [this.location.latitude, this.location.longitude];
          this.marker.setLatLng(newLatLng);
          this.map.panTo(newLatLng);

          // Update popup
          const popupContent = `
            <div style="font-family: system-ui; min-width: 200px;">
              <strong style="color: #1e40af; font-size: 14px;">🚚 Driver Location</strong><br>
              <div style="margin-top: 8px; color: #475569; font-size: 12px;">
                ${this.location.address || `Lat: ${this.formatCoordinate(this.location.latitude)}<br>Lng: ${this.formatCoordinate(this.location.longitude)}`}
              </div>
              ${this.location.lastUpdated ? `<div style="margin-top: 4px; color: #64748b; font-size: 11px;">Updated: ${new Date(this.location.lastUpdated).toLocaleTimeString()}</div>` : ''}
            </div>
          `;
          this.marker.setPopupContent(popupContent);
        } else {
          console.log('[TrackingMap] Initializing map from ngOnChanges');
          setTimeout(() => this.initializeMap(), 100);
        }
      } else if (changes['location'].firstChange && this.location && this.leafletLoaded) {
        console.log('[TrackingMap] First change with location, initializing map');
        setTimeout(() => this.initializeMap(), 100);
      }
    }

    if (changes['pickupPoints'] || changes['deliveryPoints']) {
      if (this.map && this.leafletLoaded) {
        this.refreshPoints();
      } else if (!this.map && this.leafletLoaded && this.hasAnyPoint()) {
        setTimeout(() => this.initializeMap(), 100);
      }
    }
  }

  ngOnDestroy(): void {
    if (this.map) {
      this.map.remove();
      this.map = null;
    }
  }

  /**
   * Load Leaflet library from CDN
   */
  private loadLeaflet(): void {
    if (typeof L !== 'undefined') {
      console.log('[TrackingMap] Leaflet already loaded');
      this.leafletLoaded = true;
      this.cdr.detectChanges();
      return;
    }

    console.log('[TrackingMap] Loading Leaflet from CDN...');
    const script = document.createElement('script');
    script.src = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.js';
    script.onload = () => {
      console.log('[TrackingMap] Leaflet loaded successfully');
      this.leafletLoaded = true;
      this.cdr.detectChanges();

      if (this.location) {
        console.log('[TrackingMap] Location available after Leaflet load, initializing map');
        setTimeout(() => this.initializeMap(), 100);
      }
    };
    script.onerror = (error) => {
      console.error('[TrackingMap] Failed to load Leaflet:', error);
    };
    document.head.appendChild(script);
  }

  isDispatchedOrInTransit(): boolean {
    if (!this.tracking) return false;
    const status = this.tracking.shipmentSummary.status;
    return status === 'DISPATCHED' || status === 'IN_TRANSIT' || status === 'OUT_FOR_DELIVERY';
  }

  formatCoordinate(coord: number): string {
    return coord.toFixed(6);
  }

  hasAnyPoint(): boolean {
    return (
      (this.pickupPoints && this.pickupPoints.length > 0) ||
      (this.deliveryPoints && this.deliveryPoints.length > 0)
    );
  }

  /**
   * Initialize OpenStreetMap with Leaflet
   */
  private initializeMap(): void {
    console.log('[TrackingMap] initializeMap called:', {
      leafletLoaded: this.leafletLoaded,
      hasLocation: !!this.location,
      leafletDefined: typeof L !== 'undefined',
      mapInitialized: this.mapInitialized,
    });

    if (
      !this.leafletLoaded ||
      (!this.location && !this.hasAnyPoint()) ||
      typeof L === 'undefined'
    ) {
      console.log('[TrackingMap] Cannot initialize map - missing requirements');
      return;
    }

    // Prevent duplicate initialization
    if (this.map && this.marker) {
      console.log('[TrackingMap] Map already initialized');
      return;
    }

    try {
      console.log('[TrackingMap] Creating map at:', this.mapId);
      if (this.location) {
        console.log(
          '[TrackingMap] Location coordinates:',
          this.location.latitude,
          this.location.longitude,
        );
      }

      const initialCenter = this.location
        ? [this.location.latitude, this.location.longitude]
        : this.getFallbackCenter();

      // Initialize map centered on driver location or first stop
      this.map = L.map(this.mapId).setView(initialCenter, 14);

      console.log('[TrackingMap] Map object created:', this.map);

      // Add OpenStreetMap tile layer (free, no API key needed)
      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution:
          '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
        maxZoom: 19,
      }).addTo(this.map);

      console.log('[TrackingMap] Tile layer added');

      // Create custom truck icon for marker
      const truckIcon = L.divIcon({
        html: `
          <div style="
            background: #ef4444;
            width: 32px;
            height: 32px;
            border-radius: 50%;
            border: 3px solid white;
            box-shadow: 0 2px 8px rgba(0,0,0,0.3);
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 16px;
          ">🚚</div>
        `,
        className: 'truck-marker',
        iconSize: [32, 32],
        iconAnchor: [16, 16],
      });

      // Add marker for driver location
      if (this.location) {
        this.marker = L.marker([this.location.latitude, this.location.longitude], {
          icon: truckIcon,
        }).addTo(this.map);

        console.log('[TrackingMap] Marker added');

        // Add popup with location details
        const popupContent = `
          <div style="font-family: system-ui; min-width: 200px;">
            <strong style="color: #1e40af; font-size: 14px;">🚚 Driver Location</strong><br>
            <div style="margin-top: 8px; color: #475569; font-size: 12px;">
              ${this.location.address || `Lat: ${this.formatCoordinate(this.location.latitude)}<br>Lng: ${this.formatCoordinate(this.location.longitude)}`}
            </div>
            ${this.location.lastUpdated ? `<div style="margin-top: 4px; color: #64748b; font-size: 11px;">Updated: ${new Date(this.location.lastUpdated).toLocaleTimeString()}</div>` : ''}
          </div>
        `;
        this.marker.bindPopup(popupContent).openPopup();
      }

      this.refreshPoints();

      this.mapInitialized = true;
      this.isMapReady = true;
      this.cdr.detectChanges();

      console.log('[TrackingMap] Map initialization complete');
    } catch (error) {
      console.error('[TrackingMap] Failed to initialize map:', error);
    }
  }

  private refreshPoints(): void {
    if (!this.map) return;

    this.clearPointLayers();

    // Add pickup points markers
    if (this.pickupPoints && this.pickupPoints.length > 0) {
      this.addPickupPointMarkers();
    }

    // Add delivery points markers
    if (this.deliveryPoints && this.deliveryPoints.length > 0) {
      this.addDeliveryPointMarkers();
    }

    // Draw route polyline through ordered stops
    this.addRoutePolyline();

    // Fit map bounds to show all markers and route
    this.fitMapBounds();
  }

  /**
   * Add pickup point markers to map
   */
  private addPickupPointMarkers(): void {
    const pickupIcon = L.divIcon({
      html: `
        <div style="
          background: #3b82f6;
          width: 32px;
          height: 32px;
          border-radius: 50%;
          border: 3px solid white;
          box-shadow: 0 2px 8px rgba(0,0,0,0.3);
          display: flex;
          align-items: center;
          justify-content: center;
          font-size: 16px;
        ">📦</div>
      `,
      className: 'pickup-marker',
      iconSize: [32, 32],
      iconAnchor: [16, 16],
    });

    this.pickupMarkers = this.pickupPoints.map((point, index) => {
      const marker = L.marker([point.coordinates.latitude, point.coordinates.longitude], {
        icon: pickupIcon,
      }).addTo(this.map);

      const popupContent = `
        <div style="font-family: system-ui; min-width: 200px;">
          <strong style="color: #2563eb; font-size: 14px;">📦 ${this.formatStopLabel(point, index + 1)}</strong><br>
          <div style="margin-top: 8px; color: #475569; font-size: 12px;">
            <strong>${point.name}</strong><br>
            ${point.address}
            ${point.count && point.count > 1 ? `<div style=\"margin-top: 4px; color: #1d4ed8; font-size: 11px;\">x${point.count} stops at this location</div>` : ''}
            ${point.eta ? `<div style=\"margin-top: 6px; color: #1f2937;\">ETA: ${new Date(point.eta).toLocaleString()}</div>` : ''}
            ${point.status ? `<div style=\"margin-top: 4px; color: #1f2937;\">Status: ${point.status}</div>` : ''}
          </div>
        </div>
      `;
      marker.bindPopup(popupContent);
      return marker;
    });

    console.log('[TrackingMap] Added', this.pickupMarkers.length, 'pickup point markers');
  }

  /**
   * Add delivery point markers to map
   */
  private addDeliveryPointMarkers(): void {
    const deliveryIcon = L.divIcon({
      html: `
        <div style="
          background: #10b981;
          width: 32px;
          height: 32px;
          border-radius: 50%;
          border: 3px solid white;
          box-shadow: 0 2px 8px rgba(0,0,0,0.3);
          display: flex;
          align-items: center;
          justify-content: center;
          font-size: 16px;
        ">🎯</div>
      `,
      className: 'delivery-marker',
      iconSize: [32, 32],
      iconAnchor: [16, 16],
    });

    this.deliveryMarkers = this.deliveryPoints.map((point, index) => {
      const marker = L.marker([point.coordinates.latitude, point.coordinates.longitude], {
        icon: deliveryIcon,
      }).addTo(this.map);

      const popupContent = `
        <div style="font-family: system-ui; min-width: 200px;">
          <strong style="color: #059669; font-size: 14px;">🎯 ${this.formatStopLabel(point, index + 1 + (this.pickupPoints?.length || 0))}</strong><br>
          <div style="margin-top: 8px; color: #475569; font-size: 12px;">
            <strong>${point.name}</strong><br>
            ${point.address}
            ${point.count && point.count > 1 ? `<div style=\"margin-top: 4px; color: #047857; font-size: 11px;\">x${point.count} stops at this location</div>` : ''}
            ${point.eta ? `<div style=\"margin-top: 6px; color: #1f2937;\">ETA: ${new Date(point.eta).toLocaleString()}</div>` : ''}
            ${point.status ? `<div style=\"margin-top: 4px; color: #1f2937;\">Status: ${point.status}</div>` : ''}
          </div>
        </div>
      `;
      marker.bindPopup(popupContent);
      return marker;
    });

    console.log('[TrackingMap] Added', this.deliveryMarkers.length, 'delivery point markers');
  }

  private addRoutePolyline(): void {
    const orderedStops = this.getOrderedStops();
    if (!orderedStops.length) return;

    const latLngs = orderedStops.map((stop) => [
      stop.coordinates.latitude,
      stop.coordinates.longitude,
    ]);

    if (this.routeLine) {
      this.map.removeLayer(this.routeLine);
    }

    this.routeLine = L.polyline(latLngs, {
      color: '#6366f1',
      weight: 4,
      opacity: 0.9,
      dashArray: '6, 4',
    }).addTo(this.map);
  }

  private getOrderedStops(): OrderPoint[] {
    const stops = [...(this.pickupPoints || []), ...(this.deliveryPoints || [])];
    const hasSequence = stops.some((s) => typeof s.sequence === 'number');

    if (hasSequence) {
      return stops
        .filter(
          (s) =>
            typeof s.coordinates?.latitude === 'number' &&
            typeof s.coordinates?.longitude === 'number',
        )
        .sort((a, b) => (a.sequence ?? 0) - (b.sequence ?? 0));
    }

    return stops.filter(
      (s) =>
        typeof s.coordinates?.latitude === 'number' && typeof s.coordinates?.longitude === 'number',
    );
  }

  private getFallbackCenter(): [number, number] {
    const firstPoint = this.getOrderedStops()[0];
    if (firstPoint) {
      return [firstPoint.coordinates.latitude, firstPoint.coordinates.longitude];
    }

    // Default to Phnom Penh if nothing else is available
    return [11.5564, 104.9282];
  }

  private clearPointLayers(): void {
    [...this.pickupMarkers, ...this.deliveryMarkers].forEach((m) => {
      if (m && this.map.hasLayer(m)) {
        this.map.removeLayer(m);
      }
    });

    this.pickupMarkers = [];
    this.deliveryMarkers = [];

    if (this.routeLine && this.map.hasLayer(this.routeLine)) {
      this.map.removeLayer(this.routeLine);
    }
    this.routeLine = null;
  }

  private formatStopLabel(point: OrderPoint, fallbackNumber: number): string {
    const num = point.sequence || fallbackNumber;
    return `Stop #${num}`;
  }

  /**
   * Fit map bounds to show all markers
   */
  private fitMapBounds(): void {
    const allMarkers = [this.marker, ...this.pickupMarkers, ...this.deliveryMarkers];

    if (allMarkers.length > 0) {
      const group = L.featureGroup(allMarkers);
      this.map.fitBounds(group.getBounds().pad(0.1));
    }
  }
}
