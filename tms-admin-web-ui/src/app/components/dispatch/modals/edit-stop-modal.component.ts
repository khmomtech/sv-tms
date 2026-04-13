import { CommonModule } from '@angular/common';
import type { AfterViewInit, ElementRef, OnChanges, OnDestroy, SimpleChanges } from '@angular/core';
import { ChangeDetectorRef, Component, EventEmitter, Input, Output, ViewChild } from '@angular/core';
import type { FormGroup } from '@angular/forms';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';
import mapboxgl from 'mapbox-gl';

import { environment } from '../../../environments/environment';

type LatLng = {
  lat: number;
  lng: number;
};

@Component({
  selector: 'app-edit-stop-modal',
  templateUrl: './edit-stop-modal.component.html',
  styleUrls: ['./edit-stop-modal.component.css'],
  standalone: true,
  imports: [CommonModule, FormsModule, ReactiveFormsModule],
})
export class EditStopModalComponent implements AfterViewInit, OnChanges, OnDestroy {
  @Input() visible = false;
  @Input() form!: FormGroup;

  @Output() save = new EventEmitter<void>();
  @Output() close = new EventEmitter<void>();

  @ViewChild('mapContainer') mapContainer?: ElementRef<HTMLDivElement>;

  mapCenter: LatLng = { lat: 11.5564, lng: 104.9282 };
  mapsReady = false;
  mapsError = '';
  searchQuery = '';

  private map: mapboxgl.Map | null = null;
  private marker: mapboxgl.Marker | null = null;

  constructor(private readonly cdRef: ChangeDetectorRef) {}

  ngAfterViewInit(): void {
    this.trySetupMap();
  }

  ngOnChanges(changes: SimpleChanges): void {
    if (changes['visible']?.currentValue === true) {
      const currentLocation = this.form?.get('location')?.value;
      this.searchQuery = typeof currentLocation === 'string' ? currentLocation : '';
      setTimeout(() => {
        this.cdRef.detectChanges();
        this.trySetupMap();
      }, 0);
    }
  }

  ngOnDestroy(): void {
    this.marker?.remove();
    this.map?.remove();
  }

  async onSearchLocation(): Promise<void> {
    const query = this.searchQuery.trim();
    if (!query) {
      return;
    }
    if (!environment.mapboxAccessToken) {
      this.mapsError = 'Mapbox access token is missing.';
      return;
    }

    const url = `https://api.mapbox.com/geocoding/v5/mapbox.places/${encodeURIComponent(query)}.json?access_token=${encodeURIComponent(environment.mapboxAccessToken)}&limit=1`;
    try {
      const response = await fetch(url);
      if (!response.ok) {
        throw new Error(`Geocoding request failed: ${response.status}`);
      }
      const payload = await response.json();
      const feature = payload?.features?.[0];
      const center = feature?.center;
      if (!Array.isArray(center) || center.length < 2) {
        this.mapsError = 'No matching location found.';
        return;
      }

      const location = this.toLatLng(center[1], center[0]);
      if (!location) {
        this.mapsError = 'Selected location is invalid.';
        return;
      }

      const label = feature.place_name || query;
      this.applyLocation(location, label);
      this.mapsError = '';
    } catch (err) {
      console.error('[EditStopModal] Mapbox geocoding failed', err);
      this.mapsError = 'Failed to search location.';
    }
  }

  onSave(): void {
    if (this.form.valid) {
      this.save.emit();
    } else {
      this.form.markAllAsTouched();
    }
  }

  onClose(): void {
    this.close.emit();
  }

  private trySetupMap(): void {
    if (!this.visible) {
      return;
    }
    if (!environment.mapboxAccessToken) {
      this.mapsError = 'Mapbox access token is missing.';
      return;
    }

    const container = this.mapContainer?.nativeElement;
    if (!container) {
      return;
    }

    const currentCoords = this.parseCoordinates(this.form?.get('coordinates')?.value);
    if (currentCoords) {
      this.mapCenter = currentCoords;
    }

    if (!this.map) {
      mapboxgl.accessToken = environment.mapboxAccessToken;
      this.map = new mapboxgl.Map({
        container,
        style: 'mapbox://styles/mapbox/streets-v12',
        center: [this.mapCenter.lng, this.mapCenter.lat],
        zoom: 14,
      });
      this.map.on('load', () => {
        this.mapsReady = true;
        this.syncMarkerFromForm();
      });
      this.map.on('click', (event) => {
        this.applyLocation(
          { lat: event.lngLat.lat, lng: event.lngLat.lng },
          this.form?.get('location')?.value || 'Map selection',
        );
      });
    } else {
      this.map.resize();
      this.mapsReady = true;
      this.syncMarkerFromForm();
    }
  }

  private syncMarkerFromForm(): void {
    const location = this.parseCoordinates(this.form?.get('coordinates')?.value);
    if (!location) {
      return;
    }
    this.setMarker(location);
    this.map?.easeTo({ center: [location.lng, location.lat], zoom: 14 });
  }

  private applyLocation(location: LatLng, label: string): void {
    this.mapCenter = location;
    this.searchQuery = label;
    this.form.patchValue({
      latitude: location.lat,
      longitude: location.lng,
      coordinates: `${location.lat},${location.lng}`,
      location: label,
      note: this.form.get('note')?.value || `Selected: ${label}`,
    });
    this.setMarker(location);
    this.map?.easeTo({ center: [location.lng, location.lat], zoom: 14 });
  }

  private setMarker(location: LatLng): void {
    if (!this.map) {
      return;
    }
    if (!this.marker) {
      this.marker = new mapboxgl.Marker({ color: '#2563eb' })
        .setLngLat([location.lng, location.lat])
        .addTo(this.map);
      return;
    }
    this.marker.setLngLat([location.lng, location.lat]);
  }

  private parseCoordinates(raw: unknown): LatLng | null {
    const [lat, lng] = String(raw || '')
      .split(',')
      .map((value) => Number(value.trim()));
    return this.toLatLng(lat, lng);
  }

  private toLatLng(latValue: unknown, lngValue: unknown): LatLng | null {
    const lat = Number(latValue);
    const lng = Number(lngValue);
    if (!Number.isFinite(lat) || !Number.isFinite(lng)) {
      return null;
    }
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
      return null;
    }
    return { lat, lng };
  }
}
