/* eslint-disable @typescript-eslint/consistent-type-imports */
import { CommonModule } from '@angular/common';
import { OnInit } from '@angular/core';
import { ChangeDetectorRef } from '@angular/core';
import { Component, ViewChild } from '@angular/core';
import { FormsModule } from '@angular/forms';
import type { MapMarker } from '@angular/google-maps';
import { GoogleMapsModule, GoogleMap, MapInfoWindow } from '@angular/google-maps';

import { PagedResponse } from '../../models/api-response-page.model';
import { ApiResponse } from '../../models/api-response.model';
import type { Driver } from '../../models/driver.model';
import { DriverService } from '../../services/driver.service';

interface Marker {
  position: google.maps.LatLngLiteral;
  title: string;
  iconUrl: string;
  driver: Driver;
  icon: google.maps.Icon;
}

@Component({
  selector: 'app-google-map',
  standalone: true,
  imports: [CommonModule, GoogleMapsModule, FormsModule],
  templateUrl: './google-map.component.html',
  styleUrls: ['./google-map.component.css'],
  providers: [GoogleMap],
})
export class GoogleMapComponent implements OnInit {
  zoom = 12;
  center: google.maps.LatLngLiteral = { lat: 11.5564, lng: 104.9282 };
  markers: Marker[] = [];
  drivers: Driver[] = [];
  selectedDriver?: Driver;

  @ViewChild(GoogleMap) map!: GoogleMap;
  @ViewChild(MapInfoWindow) infoWindow!: MapInfoWindow;
  activeMarker?: MapMarker;

  sidebarCollapsed = false;
  searchTerm = '';
  selectedStatus = 'all';
  selectedType = 'all';

  constructor(
    private driverService: DriverService,
    private cdRef: ChangeDetectorRef,
  ) {}

  ngOnInit(): void {
    this.loadDrivers();
    this.fetchDriverLocations();
    setInterval(() => this.fetchDriverLocations(), 5000);
  }

  /** Load full driver list for sidebar filtering */
  loadDrivers(): void {
    this.driverService.getAllDrivers().subscribe({
      next: (res) => {
        this.drivers = res.data.content ?? [];
      },
      error: (err) => console.error('❌ Failed to load drivers:', err),
    });
  }

  /** Fetch live driver locations and update map markers */
  fetchDriverLocations(): void {
    this.driverService.getAllDrivers().subscribe({
      next: (res) => {
        if (!res?.success || !Array.isArray(res.data?.content)) {
          console.error('❌ Invalid API Response:', res);
          return;
        }

        const updatedMarkers: Marker[] = res.data.content.map((driver: Driver) => {
          const isMoving = !!driver.speed && driver.speed > 0;
          const status = driver.isActive ? (isMoving ? 'busy' : 'online') : 'offline';

          const enrichedDriver: Driver = {
            ...driver,
            isMoving,
            status,
          };

          return {
            position: {
              lat: enrichedDriver.latitude ?? 0,
              lng: enrichedDriver.longitude ?? 0,
            },
            title: enrichedDriver.name || 'Unknown',
            iconUrl: this.getTruckIcon(enrichedDriver),
            driver: enrichedDriver,
            icon: {
              url: this.getTruckIcon(enrichedDriver),
              scaledSize: this.getIconSize(),
              anchor: new google.maps.Point(10, 20),
            },
          };
        });

        if (JSON.stringify(this.markers) !== JSON.stringify(updatedMarkers)) {
          this.markers = updatedMarkers;
          this.cdRef.detectChanges();
        }
      },
      error: (err) => console.error('❌ Failed to fetch driver locations:', err),
    });
  }

  /** 🎨 Get truck icon based on driver status */
  getTruckIcon(driver: Driver): string {
    if (!driver.isActive) return 'assets/truck-red.png';
    if (driver.isMoving) return 'assets/truck-blue.png';
    return 'assets/truck-green.png';
  }

  /** 📏 Adjust icon size based on zoom level */
  getIconSize(): google.maps.Size {
    if (this.zoom >= 15) return new google.maps.Size(30, 30);
    if (this.zoom >= 12) return new google.maps.Size(24, 24);
    return new google.maps.Size(20, 20);
  }

  /** Zoom changed event handler */
  onZoomChanged(): void {
    const currentZoom = this.map?.getZoom();
    if (currentZoom !== undefined && currentZoom !== this.zoom) {
      this.zoom = currentZoom;
      this.updateIconSizes();
    }
  }

  /**  Resize all marker icons */
  updateIconSizes(): void {
    this.markers = this.markers.map((marker) => ({
      ...marker,
      icon: {
        ...marker.icon,
        scaledSize: this.getIconSize(),
      },
    }));
  }

  /** ℹ️ Open info popup for driver */
  openInfoWindow(marker: Marker, markerRef: MapMarker): void {
    if (this.infoWindow && markerRef) {
      this.selectedDriver = marker.driver;
      this.activeMarker = markerRef;
      this.infoWindow.open(markerRef);
      this.cdRef.detectChanges();
    }
  }

  /** 🧠 Derive driver status */
  getDriverStatus(driver: Driver): string {
    if (!driver.isActive) return 'offline';
    if (driver.isMoving) return 'moving';
    return 'online';
  }

  /**  Filter sidebar list */
  get filteredDrivers(): Driver[] {
    return this.drivers.filter((driver) => {
      const nameMatch = driver.name?.toLowerCase().includes(this.searchTerm.toLowerCase()) ?? false;
      const statusMatch =
        this.selectedStatus === 'all' || this.getDriverStatus(driver) === this.selectedStatus;
      const typeMatch =
        this.selectedType === 'all' || driver.assignedVehicle?.type === this.selectedType;
      return nameMatch && statusMatch && typeMatch;
    });
  }

  /** 🎯 Zoom to a selected driver */
  zoomToDriver(driver: Driver): void {
    if (driver.latitude !== undefined && driver.longitude !== undefined) {
      this.center = { lat: driver.latitude, lng: driver.longitude };
      this.zoom = 17;
      this.selectedDriver = driver;
    }
  }

  /** 📂 Collapse/expand the sidebar */
  toggleSidebar(): void {
    this.sidebarCollapsed = !this.sidebarCollapsed;
  }
}
