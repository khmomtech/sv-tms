import { CommonModule } from '@angular/common';
import { Component, EventEmitter, Input, Output } from '@angular/core';
import { FormsModule } from '@angular/forms';

type RouteStop = {
  contactPerson: string;
  phone: string;
  address: string;
  plannedTime: string;
  long?: string;
  leng?: string;
};

@Component({
  selector: 'app-loading-unloading-section',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './loading-unloading-section.component.html',
  styleUrls: ['./loading-unloading-section.component.css'],
})
export class LoadingUnloadingSectionComponent {
  @Input() loadingLocations: RouteStop[] = [];
  @Input() unloadingLocations: RouteStop[] = [];
  @Input() locationErrors: { loading: string[]; unloading: string[] } = {
    loading: [],
    unloading: [],
  };
  @Input() isSubmitting = false;
  @Output() addLoading = new EventEmitter<void>();
  @Output() removeLoading = new EventEmitter<number>();
  @Output() addUnloading = new EventEmitter<void>();
  @Output() removeUnloading = new EventEmitter<number>();

  trackByIndex(index: number): number {
    return index;
  }

  hasAddress(address: string | null | undefined): boolean {
    return !!address?.trim();
  }

  hasCoordinates(
    longitude: string | null | undefined,
    latitude: string | null | undefined,
  ): boolean {
    if (!longitude?.trim() || !latitude?.trim()) return false;
    const lon = Number(longitude);
    const lat = Number(latitude);
    return Number.isFinite(lon) && Number.isFinite(lat);
  }

  private buildMapQuery(
    address: string,
    longitude?: string | null | undefined,
    latitude?: string | null | undefined,
  ): string | null {
    if (this.hasCoordinates(longitude, latitude)) {
      return `${latitude!.trim()},${longitude!.trim()}`;
    }
    if (this.hasAddress(address)) {
      return address.trim();
    }
    return null;
  }

  canOpenMap(
    address: string,
    longitude?: string | null | undefined,
    latitude?: string | null | undefined,
  ): boolean {
    return this.buildMapQuery(address, longitude, latitude) !== null;
  }

  openGoogleMaps(
    address: string,
    longitude?: string | null | undefined,
    latitude?: string | null | undefined,
  ): void {
    if (typeof window === 'undefined') return;
    const mapQuery = this.buildMapQuery(address, longitude, latitude);
    if (!mapQuery) return;
    const query = encodeURIComponent(mapQuery);
    window.open(
      `https://www.google.com/maps/search/?api=1&query=${query}`,
      '_blank',
      'noopener,noreferrer',
    );
  }

  getGoogleMapsLink(
    address: string,
    longitude?: string | null | undefined,
    latitude?: string | null | undefined,
  ): string {
    const mapQuery = this.buildMapQuery(address, longitude, latitude) || '';
    const query = encodeURIComponent(mapQuery);
    return `https://www.google.com/maps/search/?api=1&query=${query}`;
  }
}
