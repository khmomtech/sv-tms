import { CommonModule } from '@angular/common';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { HttpClient, HttpHeaders } from '@angular/common/http';
import type { OnInit } from '@angular/core';
import { Component, ViewChild } from '@angular/core';
import { FormsModule } from '@angular/forms';
import type { MapMarker } from '@angular/google-maps';
import { GoogleMap, MapInfoWindow, GoogleMapsModule } from '@angular/google-maps';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { ActivatedRoute } from '@angular/router';
import { MarkerClusterer } from '@googlemaps/markerclusterer';

import { environment } from '../../../environments/environment';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { AuthService } from '../../../services/auth.service';

interface DriverLocation {
  latitude: number;
  longitude: number;
  timestamp?: string;
  speed?: number;
  [key: string]: any;
}

@Component({
  selector: 'app-driver-location-history',
  standalone: true,
  imports: [CommonModule, FormsModule, GoogleMapsModule],
  templateUrl: './driver-location-history.component.html',
  styleUrls: ['./driver-location-history.component.css'],
})
export class DriverLocationHistoryComponent implements OnInit {
  @ViewChild(GoogleMap) mapComponent!: GoogleMap;
  @ViewChild(MapInfoWindow) infoWindow!: MapInfoWindow;

  map!: google.maps.Map;
  driverId: string = '';
  driver: any = null;
  allLocationHistory: DriverLocation[] = [];
  locationHistory: DriverLocation[] = [];
  selectedLocation?: DriverLocation;

  filterFromDate?: string;
  filterToDate?: string;

  mapCenter: google.maps.LatLngLiteral = { lat: 11.5564, lng: 104.9282 };
  zoom = 15;

  showMarkers = false;
  playbackSpeed = 1;
  isPlaying = false;
  sliderIndex = 0;
  playbackIndex = 0;
  playbackInterval: any;
  totalDistanceKm = 0;
  playbackMarker?: google.maps.Marker;

  // startMarkerIcon = {
  //   url: 'https://cdn-icons-png.flaticon.com/512/684/684908.png',
  //   scaledSize: new google.maps.Size(40, 40),
  // };

  endMarkerIcon = {
    url: 'https://cdn-icons-png.flaticon.com/512/684/684908.png',
    scaledSize: new google.maps.Size(40, 40),
  };

  // carIcon = {
  //   url: 'https://cdn-icons-png.flaticon.com/512/744/744465.png',
  //   scaledSize: new google.maps.Size(48, 48),
  //   anchor: new google.maps.Point(24, 24),
  //   rotation: 0,
  // };

  startMarkerIcon = {
    url: 'assets/icons/start-point.png',
    scaledSize: new google.maps.Size(48, 48),
    anchor: new google.maps.Point(24, 24),
    rotation: 0,
  };
  // endMarkerIcon = {
  //   url: 'assets/icons/end-point.png',
  //   scaledSize: new google.maps.Size(48, 48),
  //   anchor: new google.maps.Point(24, 24),
  //   rotation: 0,
  // };

  carIcon = {
    url: 'assets/icons/driver.png',
    scaledSize: new google.maps.Size(48, 48),
    anchor: new google.maps.Point(24, 24),
    rotation: 0,
  };

  directionsService!: google.maps.DirectionsService;
  directionsRenderer!: google.maps.DirectionsRenderer;

  polylineOptions: google.maps.PolylineOptions = {
    strokeColor: '#2196f3',
    strokeOpacity: 1.0,
    strokeWeight: 3,
  };

  isDirectionsVisible = true;

  constructor(
    private route: ActivatedRoute,
    private http: HttpClient,
    private authService: AuthService,
  ) {}

  ngOnInit(): void {
    this.route.paramMap.subscribe((params) => {
      const id = params.get('id');
      if (id) {
        this.driverId = id;
        this.loadDriver();
        this.loadLocationHistory();
      }
    });
  }

  private getHeaders(): HttpHeaders {
    return new HttpHeaders({
      'Content-Type': 'application/json',
      Authorization: `Bearer ${this.authService.getToken()}`,
    });
  }

  initMapHelpers(): void {
    if (!this.map && this.mapComponent?.googleMap) {
      this.map = this.mapComponent.googleMap;
    }

    if (!this.directionsService) {
      this.directionsService = new google.maps.DirectionsService();
    }

    if (!this.directionsRenderer && this.map) {
      this.directionsRenderer = new google.maps.DirectionsRenderer({
        suppressMarkers: true,
      });
      this.directionsRenderer.setMap(this.map);
    }
  }

  loadDriver(): void {
    this.http
      .get<any>(`${environment.baseUrl}/api/admin/drivers/${this.driverId}`, {
        headers: this.getHeaders(),
      })
      .subscribe({
        next: (res) => (this.driver = res.data),
        error: (err) => console.error(' Error loading driver info:', err),
      });
  }

  loadLocationHistory(): void {
    this.http
      .get<any>(`${environment.baseUrl}/api/admin/drivers/${this.driverId}/location-history`, {
        headers: this.getHeaders(),
      })
      .subscribe({
        next: (res) => {
          const rawLocations = res.data || [];
          this.allLocationHistory = rawLocations.filter(
            (loc: any) =>
              typeof loc.latitude === 'number' &&
              typeof loc.longitude === 'number' &&
              isFinite(loc.latitude) &&
              isFinite(loc.longitude),
          );
          this.applyDateFilter();
        },
        error: (err) => console.error(' Error loading location history:', err),
      });
  }

  applyDateFilter(): void {
    if (!this.filterFromDate && !this.filterToDate) {
      this.locationHistory = [...this.allLocationHistory];
    } else {
      const from = this.filterFromDate ? new Date(this.filterFromDate) : null;
      const to = this.filterToDate ? new Date(this.filterToDate + 'T23:59:59') : null;

      this.locationHistory = this.allLocationHistory.filter((loc) => {
        const locTime = new Date(loc.timestamp || '');
        return (!from || locTime >= from) && (!to || locTime <= to);
      });
    }

    if (this.locationHistory.length > 0) {
      this.mapCenter = {
        lat: this.locationHistory[0].latitude,
        lng: this.locationHistory[0].longitude,
      };
    }

    this.createClusterMarkers();
    this.calculateTotalDistance();

    setTimeout(() => {
      this.initMapHelpers();
      if (this.map) {
        this.map.panTo(this.mapCenter);
      }
      this.showDirections();
    }, 300);
  }

  resetFilter(): void {
    this.filterFromDate = '';
    this.filterToDate = '';
    this.applyDateFilter();
  }

  get locationPath(): google.maps.LatLngLiteral[] {
    return this.locationHistory.map((loc) => ({
      lat: loc.latitude,
      lng: loc.longitude,
    }));
  }

  convertToLabel(value: Date | string | null | undefined): string {
    if (!value) return '';
    const date = new Date(value);
    return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
  }

  openInfoWindow(mapMarker: MapMarker, location: DriverLocation): void {
    this.selectedLocation = location;
    this.infoWindow.open(mapMarker);
  }

  exportAsCSV(): void {
    const csvData = this.locationHistory
      .map((loc) => `${loc.timestamp},${loc.latitude},${loc.longitude}`)
      .join('\n');

    const blob = new Blob([`Timestamp,Latitude,Longitude\n${csvData}`], {
      type: 'text/csv',
    });
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `driver_${this.driverId}_location_history.csv`;
    a.click();
    window.URL.revokeObjectURL(url);
  }

  startPlayback(): void {
    this.initMapHelpers();
    if (this.locationHistory.length === 0 || this.isPlaying) return;

    this.playbackIndex = 0;
    this.isPlaying = true;

    if (!this.map) {
      console.error(' Map is not initialized.');
      return;
    }

    if (this.playbackMarker) {
      this.playbackMarker.setMap(null);
      this.playbackMarker = undefined;
    }

    const infoWindow = new google.maps.InfoWindow();

    this.playbackMarker = new google.maps.Marker({
      map: this.map,
      position: {
        lat: this.locationHistory[0].latitude,
        lng: this.locationHistory[0].longitude,
      },
      icon: this.carIcon,
      title: 'Vehicle',
    });

    this.playbackMarker.addListener('click', () => {
      const currentLoc = this.locationHistory[this.playbackIndex];
      const prevLoc = this.locationHistory[this.playbackIndex - 1] || currentLoc;

      const estSpeed = this.getSpeedBetweenPoints(prevLoc, currentLoc);

      const content = `
      <div style="min-width: 200px;">
        <p><strong>Time:</strong> ${new Date(currentLoc.timestamp ?? '').toLocaleString()}</p>
        <p><strong>GPS Speed:</strong> ${currentLoc.speed ?? 'N/A'} km/h</p>
        <p><strong>Est. Speed:</strong> ${estSpeed} km/h</p>
        <p><strong>Lat:</strong> ${currentLoc.latitude}</p>
        <p><strong>Lng:</strong> ${currentLoc.longitude}</p>
      </div>
    `;
      infoWindow.setContent(content);
      infoWindow.open(this.map, this.playbackMarker!);
    });

    this.playbackInterval = setInterval(() => {
      if (this.playbackIndex >= this.locationHistory.length) {
        this.stopPlayback();
        return;
      }

      const currentLoc = this.locationHistory[this.playbackIndex];
      const prevLoc = this.locationHistory[this.playbackIndex - 1] || currentLoc;
      const heading = this.getHeading(prevLoc, currentLoc);
      const newPosition = {
        lat: currentLoc.latitude,
        lng: currentLoc.longitude,
      };

      this.mapCenter = newPosition;
      this.sliderIndex = this.playbackIndex;

      if (this.playbackMarker) {
        this.playbackMarker.setPosition(newPosition);
        this.playbackMarker.setIcon({ ...this.carIcon, rotation: heading });
      }

      this.map.panTo(newPosition);
      this.playbackIndex++;
    }, 1000 / this.playbackSpeed);
  }

  stopPlayback(): void {
    if (this.playbackInterval) {
      clearInterval(this.playbackInterval);
      this.playbackInterval = null;
    }
    this.isPlaying = false;
  }

  onSliderChange(index: number): void {
    this.sliderIndex = index;
    const loc = this.locationHistory[index];
    if (loc) {
      this.mapCenter = { lat: loc.latitude, lng: loc.longitude };
      this.playbackMarker?.setPosition(this.mapCenter);
      this.map.panTo(this.mapCenter);
    }
  }

  getHeading(from: DriverLocation, to: DriverLocation): number {
    const lat1 = (from.latitude * Math.PI) / 180;
    const lat2 = (to.latitude * Math.PI) / 180;
    const dLng = ((to.longitude - from.longitude) * Math.PI) / 180;
    const y = Math.sin(dLng) * Math.cos(lat2);
    const x = Math.cos(lat1) * Math.sin(lat2) - Math.sin(lat1) * Math.cos(lat2) * Math.cos(dLng);
    return ((Math.atan2(y, x) * 180) / Math.PI + 360) % 360;
  }

  setPlaybackSpeed(speed: number): void {
    this.playbackSpeed = speed;
    if (this.isPlaying) {
      this.stopPlayback();
      this.startPlayback();
    }
  }

  calculateTotalDistance(): void {
    let total = 0;
    for (let i = 1; i < this.locationHistory.length; i++) {
      total += this.haversine(this.locationHistory[i - 1], this.locationHistory[i]);
    }
    this.totalDistanceKm = +(total / 1000).toFixed(2);
  }

  private haversine(a: DriverLocation, b: DriverLocation): number {
    const R = 6371e3;
    const φ1 = (a.latitude * Math.PI) / 180;
    const φ2 = (b.latitude * Math.PI) / 180;
    const Δφ = ((b.latitude - a.latitude) * Math.PI) / 180;
    const Δλ = ((b.longitude - a.longitude) * Math.PI) / 180;
    const x = Math.sin(Δφ / 2) ** 2 + Math.cos(φ1) * Math.cos(φ2) * Math.sin(Δλ / 2) ** 2;
    const c = 2 * Math.atan2(Math.sqrt(x), Math.sqrt(1 - x));
    return R * c;
  }

  showDirections(): void {
    if (this.locationHistory.length < 2) return;

    if (!this.directionsService || !this.directionsRenderer) {
      console.warn('⚠️ DirectionsService not initialized yet');
      return;
    }

    const origin = this.locationHistory[0];
    const destination = this.locationHistory[this.locationHistory.length - 1];

    if (origin.latitude === destination.latitude && origin.longitude === destination.longitude) {
      console.warn('⚠️ Origin and destination are the same — skipping route.');
      this.isDirectionsVisible = false;
      return;
    }

    const MAX_DISTANCE_KM = 200;
    const cleanedLocations = [origin];

    for (let i = 1; i < this.locationHistory.length; i++) {
      const prev = this.locationHistory[i - 1];
      const curr = this.locationHistory[i];
      const dist = this.haversine(prev, curr) / 1000;
      if (dist < MAX_DISTANCE_KM) {
        cleanedLocations.push(curr);
      } else {
        console.warn(`⚠️ Skipping point ${i} (${dist.toFixed(1)} km apart)`);
      }
    }

    const waypoints = cleanedLocations
      .slice(1, -1)
      .filter((loc) => isFinite(loc.latitude) && isFinite(loc.longitude))
      .slice(0, 23)
      .map((loc) => ({
        location: { lat: loc.latitude, lng: loc.longitude },
        stopover: false,
      }));

    if (this.locationHistory.length > 25) {
      console.warn('⚠️ Too many points for Google Directions API. Limiting to 25 total.');
    }

    this.directionsService.route(
      {
        origin: { lat: origin.latitude, lng: origin.longitude },
        destination: { lat: destination.latitude, lng: destination.longitude },
        waypoints,
        travelMode: google.maps.TravelMode.DRIVING,
        optimizeWaypoints: true,
      },
      (result, status) => {
        if (status === 'OK' && result) {
          this.isDirectionsVisible = true;
          this.directionsRenderer.setDirections(result);
        } else {
          console.error(' Directions failed:', status);

          switch (status) {
            case 'UNKNOWN_ERROR':
              console.warn('⚠️ Temporary backend error. Try again later.');
              break;
            case 'OVER_QUERY_LIMIT':
              console.warn('⚠️ Rate limit exceeded. Consider enabling billing.');
              break;
            case 'ZERO_RESULTS':
              console.warn('⚠️ No route found. Switching to polyline fallback.');
              break;
            default:
              console.warn('Google Maps API error:', status);
              break;
          }

          this.isDirectionsVisible = false;
        }
      },
    );
  }

  toggleMarkers(): void {
    this.showMarkers = !this.showMarkers;
    this.createClusterMarkers();
  }

  createClusterMarkers(): void {
    if (!this.map || !this.locationHistory.length || !this.showMarkers) return;

    const markers = this.locationHistory.map(
      (loc) =>
        new google.maps.Marker({
          position: { lat: loc.latitude, lng: loc.longitude },
          title: this.convertToLabel(loc.timestamp),
        }),
    );

    new MarkerClusterer({ markers, map: this.map });
  }

  getSpeedBetweenPoints(a: DriverLocation, b: DriverLocation): number {
    const distanceMeters = this.haversine(a, b);
    const timeA = new Date(a.timestamp || '').getTime();
    const timeB = new Date(b.timestamp || '').getTime();

    const deltaSeconds = (timeB - timeA) / 1000;
    if (deltaSeconds <= 0) return 0;

    const speedMps = distanceMeters / deltaSeconds;
    return +(speedMps * 3.6).toFixed(1); // convert to km/h
  }
}
