import { CommonModule } from '@angular/common';
import type { OnInit } from '@angular/core';
import { Component, ViewChild } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { GoogleMapsModule, MapInfoWindow } from '@angular/google-maps';

import { DispatchStatus } from '../../models/dispatch-status.enum';
import type { Dispatch } from '../../models/dispatch.model';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { DispatchService } from '../../services/dispatch.service';

@Component({
  selector: 'app-dispatch-maps-view',
  standalone: true,
  templateUrl: './dispatch-maps-view.component.html',
  styleUrls: ['./dispatch-maps-view.component.css'],
  imports: [CommonModule, FormsModule, GoogleMapsModule],
})
export class DispatchMapsViewComponent implements OnInit {
  DispatchStatus = DispatchStatus; // already included
  dispatchStatusKeys = Object.values(DispatchStatus); //  Add this
  @ViewChild(MapInfoWindow) infoWindow!: MapInfoWindow;

  openInfoWindow(infoWindow: MapInfoWindow, dispatch: any) {
    this.selectedDispatch = dispatch;
    infoWindow.open();
  }
  dispatches: Dispatch[] = [];
  filteredDispatches: Dispatch[] = [];

  searchQuery = '';
  selectedStatus: string = 'All';
  selectedDispatch: Dispatch | null = null;

  sidebarCollapsed = false;

  mapCenter = { lat: 11.5564, lng: 104.9282 };
  mapZoom = 7;

  dropoffIcon = 'http://maps.google.com/mapfiles/ms/icons/red-dot.png';

  polylines: google.maps.LatLngLiteral[][] = [];

  constructor(private dispatchService: DispatchService) {}

  ngOnInit(): void {
    this.fetchDispatches();
  }

  fetchDispatches(): void {
    this.dispatchService.getAllDispatches().subscribe({
      next: (res) => {
        const raw = res?.data?.content ?? [];
        this.dispatches = raw;
        this.filteredDispatches = raw;
      },
      error: (err) => console.error('Failed to load dispatches', err),
    });
  }

  toggleSidebar(): void {
    this.sidebarCollapsed = !this.sidebarCollapsed;
  }

  filterDispatches(): void {
    this.filteredDispatches = this.dispatches.filter(
      (d) =>
        (this.selectedStatus === 'All' || d.status === this.selectedStatus) &&
        (this.searchQuery === '' ||
          d.routeCode?.toLowerCase().includes(this.searchQuery.toLowerCase())),
    );
  }

  searchDispatches(): void {
    this.filterDispatches();
  }

  selectDispatch(dispatch: Dispatch): void {
    this.selectedDispatch = dispatch;
    this.mapCenter = {
      lat: dispatch.pickupLat ?? 11.5564,
      lng: dispatch.pickupLng ?? 104.9282,
    };
    this.mapZoom = 10;

    this.polylines = [
      [
        { lat: dispatch.pickupLat ?? 0, lng: dispatch.pickupLng ?? 0 },
        { lat: dispatch.dropoffLat ?? 0, lng: dispatch.dropoffLng ?? 0 },
      ],
    ];
  }
}
