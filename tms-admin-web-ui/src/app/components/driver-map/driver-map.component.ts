/* eslint-disable @typescript-eslint/consistent-type-imports */
import { CommonModule } from '@angular/common';
import type { OnInit, OnDestroy } from '@angular/core';
import { Component, ViewChild } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { GoogleMap, GoogleMapsModule } from '@angular/google-maps';
import type { Subscription } from 'rxjs';

import type { Driver } from '../../models/driver.model';
import { DriverService } from '../../services/driver.service';
import { SocketService, type DriverLocation } from '../../services/socket.service';
import { DriverSidebarComponent } from '../driver-sidebar/driver-sidebar.component';

@Component({
  selector: 'app-driver-map',
  standalone: true,
  imports: [CommonModule, FormsModule, GoogleMapsModule, DriverSidebarComponent],
  templateUrl: './driver-map.component.html',
  styleUrls: ['./driver-map.component.css'],
})
export class DriverMapComponent implements OnInit, OnDestroy {
  @ViewChild(GoogleMap) map!: GoogleMap;

  driverLocations: DriverLocation[] = [];
  filteredDrivers: DriverLocation[] = [];
  selectedZone: string | null = null;
  selectedDriverId: string | null = null;
  private readonly socketContextId = 'driver-map';

  mapOptions = {
    center: { lat: 11.5564, lng: 104.9282 },
    zoom: 12,
  };

  private locationSub?: Subscription;
  private globaLocationsub?: Subscription;

  constructor(
    private readonly socketService: SocketService,
    private readonly driverService: DriverService,
  ) {}

  ngOnInit(): void {
    this.initializeDriversAndWebSocket();
  }

  ngOnDestroy(): void {
    this.locationSub?.unsubscribe();
    this.globaLocationsub?.unsubscribe();
    this.socketService.disconnectContext(this.socketContextId);
  }

  initializeDriversAndWebSocket(): void {
    this.driverService.getAllDrivers().subscribe({
      next: (response) => {
        const drivers: Driver[] = response.data.content; //  Correctly access the array

        const driverIds = drivers
          .map((driver) => driver.id?.toString())
          .filter((id): id is string => !!id);

        console.log(' Loaded drivers:', drivers);
        this.socketService.connect(driverIds, this.socketContextId);
        this.listenToLocationUpdates();
      },
      error: (err) => {
        console.error(' Error fetching drivers:', err);
      },
    });
  }

  private listenToLocationUpdates(): void {
    this.locationSub = this.socketService.driverLocation$.subscribe((location) => {
      if (location) this.upsertDriver(location);
    });

    this.globaLocationsub = this.socketService.globalLocation$.subscribe((location) => {
      if (location) this.upsertDriver(location);
    });
  }

  private upsertDriver(location: DriverLocation): void {
    const index = this.driverLocations.findIndex((d) => d.driverId === location.driverId);
    if (index > -1) {
      this.driverLocations[index] = { ...this.driverLocations[index], ...location };
    } else {
      this.driverLocations.push(location);
    }
    this.applyZoneFilter();
  }

  applyZoneFilter(): void {
    this.filteredDrivers = this.selectedZone
      ? this.driverLocations.filter((driver) => driver.zone === this.selectedZone)
      : [...this.driverLocations];
  }

  onFocusDriver(driver: DriverLocation): void {
    this.selectedDriverId = driver.driverId;
    const { latitude, longitude } = driver;
    if (latitude && longitude && this.map?.googleMap) {
      const position = { lat: latitude, lng: longitude };
      this.map.googleMap.panTo(position);
      this.mapOptions = { ...this.mapOptions, center: position, zoom: 16 };
    }
  }

  onZoneChange(event: Event): void {
    const selected = (event.target as HTMLSelectElement).value;
    this.selectedZone = selected || null;
    this.applyZoneFilter();
  }

  getMarkerIcon(driver: DriverLocation): google.maps.Icon {
    return {
      url: 'https://maps.gstatic.com/mapfiles/ms2/micons/red-dot.png',
      scaledSize: new google.maps.Size(32, 32),
    };
  }

  generateTooltip(driver: DriverLocation): string {
    return `Driver: ${driver.label ?? driver.driverId}\nZone: ${driver.zone ?? 'Unknown'}`;
  }
}
