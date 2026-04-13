import { CommonModule } from '@angular/common';
import type { OnInit, OnDestroy, AfterViewInit } from '@angular/core';
import { Component, inject, ViewChild } from '@angular/core';
import { GoogleMap, GoogleMapsModule, MapInfoWindow } from '@angular/google-maps';
import { MatDialog } from '@angular/material/dialog';
import { MatSnackBar } from '@angular/material/snack-bar';
import { FormsModule } from '@angular/forms';
import { TranslateModule } from '@ngx-translate/core';
import { Subject } from 'rxjs';
import { takeUntil, debounceTime, distinctUntilChanged } from 'rxjs/operators';

import {
  AlertTypeEnum,
  GeofenceType,
  type Geofence,
  type GeofenceCreateRequest,
  type GeofenceEvent,
} from '../models/geofence.model';
import { AuthService } from '../services/auth.service';
import { PermissionGuardService } from '../services/permission-guard.service';
import { DriverLocationService } from '../services/driver-location.service';
import { GeofenceService } from '../services/geofence.service';
import { BASE_IMPORTS, BUTTON_IMPORTS, DIALOG_IMPORTS } from '../shared/common-imports';
import { ConfirmationDialogComponent } from '../shared/components/confirmation-dialog/confirmation-dialog.component';
import { FilterBarComponent } from '../shared/components/crud/filter-bar/filter-bar.component';
import { PERMISSIONS } from '../shared/permissions';

import { DrawingService } from './drawing.service';
import { GeofenceFormDialogComponent } from './geofence-form-dialog/geofence-form-dialog.component';
import { GeofenceImportExportService } from './geofence-import-export.service';
import { GeofenceImportDialogComponent } from './geofence-import-dialog/geofence-import-dialog.component';

interface GeofenceFilter {
  search: string;
  type: GeofenceType | '';
  status: 'all' | 'active' | 'inactive';
  alertType: AlertTypeEnum | '';
  tag: string;
}

@Component({
  selector: 'app-geofence-management',
  standalone: true,
  imports: [
    CommonModule,
    ...BASE_IMPORTS,
    ...DIALOG_IMPORTS,
    GoogleMapsModule,
    FormsModule,
    TranslateModule,
    FilterBarComponent,
  ],
  templateUrl: './geofence-management.component.html',
  styleUrls: ['./geofence-management.component.css'],
})
export class GeofenceManagementComponent implements OnInit, AfterViewInit, OnDestroy {
  @ViewChild(GoogleMap) googleMap!: GoogleMap;
  @ViewChild(MapInfoWindow) infoWindow!: MapInfoWindow;
  @ViewChild('eventsMap') eventsMapEl!: GoogleMap;

  // Expose for template
  google = google;
  AlertTypeEnum = AlertTypeEnum;
  GeofenceType = GeofenceType;

  geofences: Geofence[] = [];
  loading = false;

  // Filter and search
  filter: GeofenceFilter = {
    search: '',
    type: '',
    status: 'all',
    alertType: '',
    tag: '',
  };

  private searchSubject$ = new Subject<string>();

  // Bulk selection
  selectedGeofences = new Set<number>();
  selectAll = false;

  // Dropdown menu states
  importExportMenuOpen = false;
  exportSelectedMenuOpen = false;
  exportAllMenuOpen = false;
  openRowMenuId: number | null = null;
  showEventsPanel = false;
  showMapPanel = true;

  readonly permissions = PERMISSIONS;

  drawingMode: 'circle' | 'polygon' | 'rectangle' | null = null;
  editingGeofenceId: number | null = null;
  currentMeasurements: any = null;

  // Map properties
  mapCenter: google.maps.LatLngLiteral = { lat: 11.5564, lng: 104.8882 }; // Phnom Penh, Cambodia
  mapZoom = 13;
  mapInstance: google.maps.Map | null = null;
  mapMarkers: google.maps.Marker[] = [];
  mapCircles: google.maps.Circle[] = [];
  mapPolygons: google.maps.Polygon[] = [];
  clusterMarkers: google.maps.Marker[] = [];
  useClusterView = false;

  infoWindowContent: { geofence: Geofence; position: google.maps.LatLngLiteral } | null = null;

  /* ── Events Map ─────────────────────────────────────────────── */
  recentEvents: GeofenceEvent[] = [];
  eventTimeFilter: '1h' | '6h' | '24h' = '24h';
  selectedEventIdx: number | null = null;
  eventMapReady = false;
  readonly eventMapCenter: google.maps.LatLngLiteral = { lat: 11.5564, lng: 104.8882 };
  readonly eventMapOptions: google.maps.MapOptions = {
    disableDefaultUI: true,
    zoomControl: true,
    gestureHandling: 'cooperative',
    mapTypeId: 'roadmap',
  };
  private eventMarkers: google.maps.Marker[] = [];
  private eventInfoWindow: google.maps.InfoWindow | null = null;

  private readonly authService = inject(AuthService);
  private readonly permissionGuardService = inject(PermissionGuardService);
  private readonly geofenceService = inject(GeofenceService);
  private readonly driverLocationService = inject(DriverLocationService);
  private readonly drawingService = inject(DrawingService);
  private readonly importExportService = inject(GeofenceImportExportService);
  private readonly dialog = inject(MatDialog);
  private readonly snackBar = inject(MatSnackBar);
  private destroy$ = new Subject<void>();

  get companyId(): number {
    return this.authService.getCompanyId();
  }

  ngOnInit(): void {
    this.loadGeofences();
    this.setupDrawingSubscription();
    this.setupSearchDebounce();
    this.subscribeToGeofenceEvents();
  }

  ngAfterViewInit(): void {
    // Defer marker draw until the events map DOM is ready
    setTimeout(() => {
      this.eventMapReady = true;
      this.drawEventMarkers();
    }, 400);
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
    this.drawingService.destroy();
    this.clearMapOverlays();
    this.clearEventMarkers();
    this.eventInfoWindow?.close();
  }

  setupSearchDebounce(): void {
    this.searchSubject$
      .pipe(debounceTime(300), distinctUntilChanged(), takeUntil(this.destroy$))
      .subscribe((searchTerm) => {
        this.filter.search = searchTerm;
        this.selectedGeofences.clear();
        this.selectAll = false;
      });
  }

  onSearchChange(searchTerm: string): void {
    this.searchSubject$.next(searchTerm);
  }

  get filteredGeofences(): Geofence[] {
    return this.geofences.filter((g) => this.matchesFilter(g));
  }

  private matchesFilter(geofence: Geofence): boolean {
    // Search by name, description, or tags
    if (this.filter.search) {
      const search = this.filter.search.toLowerCase();
      const matchesSearch =
        geofence.name.toLowerCase().includes(search) ||
        (geofence.description && geofence.description.toLowerCase().includes(search)) ||
        (geofence.tags && geofence.tags.some((t) => t.toLowerCase().includes(search)));
      if (!matchesSearch) return false;
    }

    // Filter by type
    if (this.filter.type && geofence.type !== this.filter.type) {
      return false;
    }

    // Filter by status
    if (this.filter.status === 'active' && !geofence.active) return false;
    if (this.filter.status === 'inactive' && geofence.active) return false;

    // Filter by alert type
    if (this.filter.alertType && geofence.alertType !== this.filter.alertType) {
      return false;
    }

    // Filter by specific tag (click-to-filter)
    if (this.filter.tag) {
      const tagMatch =
        geofence.tags &&
        geofence.tags.some((t) => t.toLowerCase() === this.filter.tag.toLowerCase());
      if (!tagMatch) return false;
    }

    return true;
  }

  toggleSelectGeofence(id: number, event: Event): void {
    event.stopPropagation();
    if (this.selectedGeofences.has(id)) {
      this.selectedGeofences.delete(id);
    } else {
      this.selectedGeofences.add(id);
    }
    this.updateSelectAllCheckbox();
  }

  toggleSelectAll(event: Event): void {
    const isChecked = (event.target as HTMLInputElement).checked;
    this.selectAll = isChecked;

    if (isChecked) {
      this.filteredGeofences.forEach((g) => this.selectedGeofences.add(g.id));
    } else {
      this.selectedGeofences.clear();
    }
  }

  private updateSelectAllCheckbox(): void {
    const filtered = this.filteredGeofences;
    if (filtered.length === 0) {
      this.selectAll = false;
    } else {
      this.selectAll = filtered.every((g) => this.selectedGeofences.has(g.id));
    }
  }

  isGeofenceSelected(id: number): boolean {
    return this.selectedGeofences.has(id);
  }

  get hasSelectedGeofences(): boolean {
    return this.selectedGeofences.size > 0;
  }

  get selectedCount(): number {
    return this.selectedGeofences.size;
  }

  bulkActivate(): void {
    const ids = Array.from(this.selectedGeofences);
    if (ids.length === 0) return;

    const dialogRef = this.dialog.open(ConfirmationDialogComponent, {
      data: {
        title: 'Activate Geofences',
        message: `Activate ${ids.length} geofence(s)? These zones will start being monitored for events.`,
        confirmText: 'Activate',
        cancelText: 'Cancel',
      },
    });

    dialogRef.afterClosed().subscribe((confirmed: boolean) => {
      if (confirmed) {
        this.bulkUpdateStatus(ids, true);
      }
    });
  }

  bulkDeactivate(): void {
    const ids = Array.from(this.selectedGeofences);
    if (ids.length === 0) return;

    const dialogRef = this.dialog.open(ConfirmationDialogComponent, {
      data: {
        title: 'Deactivate Geofences',
        message: `Deactivate ${ids.length} geofence(s)? These zones will stop being monitored for events.`,
        confirmText: 'Deactivate',
        cancelText: 'Cancel',
      },
    });

    dialogRef.afterClosed().subscribe((confirmed: boolean) => {
      if (confirmed) {
        this.bulkUpdateStatus(ids, false);
      }
    });
  }

  private bulkUpdateStatus(ids: number[], active: boolean): void {
    let completed = 0;
    let failed = 0;

    ids.forEach((id) => {
      const geofence = this.geofences.find((g) => g.id === id);
      if (!geofence) return;

      const updated = { ...geofence, active };
      this.geofenceService.updateGeofence(id, this.geofenceToRequest(updated)).subscribe({
        next: () => {
          completed++;
          this.recordActivity('updated', geofence.name, id);
          if (completed + failed === ids.length) {
            this.onBulkOperationComplete(completed, failed, active ? 'activated' : 'deactivated');
          }
        },
        error: () => {
          failed++;
          if (completed + failed === ids.length) {
            this.onBulkOperationComplete(completed, failed, active ? 'activate' : 'deactivate');
          }
        },
      });
    });
  }

  bulkDelete(): void {
    const ids = Array.from(this.selectedGeofences);
    if (ids.length === 0) return;

    const dialogRef = this.dialog.open(ConfirmationDialogComponent, {
      data: {
        title: 'Delete Geofences',
        message: `Are you sure you want to delete ${ids.length} geofence(s)? This action cannot be undone.`,
        confirmText: 'Delete',
        cancelText: 'Cancel',
        confirmColor: 'warn',
      },
    });

    dialogRef.afterClosed().subscribe((confirmed: boolean) => {
      if (confirmed) {
        let completed = 0;
        let failed = 0;

        ids.forEach((id) => {
          const geofence = this.geofences.find((g) => g.id === id);
          this.geofenceService.deleteGeofence(id).subscribe({
            next: () => {
              completed++;
              if (geofence) {
                this.recordActivity('deleted', geofence.name, id);
              }
              if (completed + failed === ids.length) {
                this.onBulkOperationComplete(completed, failed, 'deleted');
              }
            },
            error: () => {
              failed++;
              if (completed + failed === ids.length) {
                this.onBulkOperationComplete(completed, failed, 'delete');
              }
            },
          });
        });
      }
    });
  }

  private onBulkOperationComplete(completed: number, failed: number, action: string): void {
    if (failed === 0) {
      this.notify(`Successfully ${action} ${completed} geofence(s)`, 'success');
    } else {
      this.notify(
        `${action} ${completed}/${this.selectedCount} geofences - ${failed} failed`,
        'error',
      );
    }

    this.selectedGeofences.clear();
    this.selectAll = false;
    this.loadGeofences();
  }

  clearFilters(): void {
    this.filter = {
      search: '',
      type: '',
      status: 'all',
      alertType: '',
      tag: '',
    };
    this.selectedGeofences.clear();
    this.selectAll = false;
  }

  onFilterRemove(chip: { key: string; value: any }): void {
    switch (chip.key) {
      case 'type':
        this.filter.type = '';
        break;
      case 'alertType':
        this.filter.alertType = '';
        break;
      case 'status':
        this.filter.status = 'all';
        break;
      case 'tag':
        this.filter.tag = '';
        break;
    }
    this.selectedGeofences.clear();
    this.selectAll = false;
  }

  /**
   * Filter geofences by status (active/inactive)
   */
  filterByStatus(status: 'all' | 'active' | 'inactive'): void {
    // Toggle: if clicking the same status, clear to 'all'
    if (this.filter.status === status && status !== 'all') {
      this.filter.status = 'all';
    } else {
      this.filter.status = status;
    }
    this.selectedGeofences.clear();
    this.selectAll = false;
  }

  /**
   * Filter geofences by type
   */
  filterByType(type: GeofenceType | ''): void {
    // Toggle: if clicking the same type, clear filter
    if (this.filter.type === type && type !== '') {
      this.filter.type = '';
    } else {
      this.filter.type = type;
    }
    this.selectedGeofences.clear();
    this.selectAll = false;
  }

  /**
   * Filter geofences by alert type
   */
  filterByAlertType(alertType: AlertTypeEnum | ''): void {
    // Toggle: if clicking the same alert type, clear filter
    if (this.filter.alertType === alertType && alertType !== '') {
      this.filter.alertType = '';
    } else {
      this.filter.alertType = alertType;
    }
    this.selectedGeofences.clear();
    this.selectAll = false;
  }

  /**
   * Filter geofences by a specific tag label (click-to-filter in table rows)
   */
  filterByTag(tag: string, event: Event): void {
    event.stopPropagation();
    // Toggle: clicking the same tag again clears it
    this.filter.tag = this.filter.tag === tag ? '' : tag;
    this.selectedGeofences.clear();
    this.selectAll = false;
  }

  get activeFilterChips(): Array<{ key: string; label: string; value: any }> {
    const chips: Array<{ key: string; label: string; value: any }> = [];

    if (this.filter.type) {
      chips.push({
        key: 'type',
        label: this.geofenceTypeLabel(this.filter.type),
        value: this.filter.type,
      });
    }

    if (this.filter.alertType) {
      chips.push({
        key: 'alertType',
        label: this.alertTypeLabel(this.filter.alertType),
        value: this.filter.alertType,
      });
    }

    if (this.filter.tag) {
      chips.push({
        key: 'tag',
        label: `Tag: ${this.filter.tag}`,
        value: this.filter.tag,
      });
    }

    if (this.filter.status !== 'all') {
      chips.push({
        key: 'status',
        label: this.filter.status === 'active' ? 'Active' : 'Inactive',
        value: this.filter.status,
      });
    }

    return chips;
  }

  /* ==================== STAT CARDS SECTION ==================== */

  get totalGeofences(): number {
    return this.geofences.length;
  }

  get activeGeofences(): number {
    return this.geofences.filter((g) => g.active).length;
  }

  get inactiveGeofences(): number {
    return this.geofences.filter((g) => !g.active).length;
  }

  get entryAlertCount(): number {
    return this.geofences.filter((g) => this.hasEntryAlert(g.alertType)).length;
  }

  get exitAlertCount(): number {
    return this.geofences.filter((g) => this.hasExitAlert(g.alertType)).length;
  }

  get circleCount(): number {
    return this.geofences.filter((g) => g.type === GeofenceType.CIRCLE).length;
  }

  get polygonCount(): number {
    return this.geofences.filter((g) => g.type === GeofenceType.POLYGON).length;
  }

  private hasEntryAlert(alertType: AlertTypeEnum): boolean {
    return [AlertTypeEnum.ENTER, AlertTypeEnum.BOTH].includes(alertType);
  }

  private hasExitAlert(alertType: AlertTypeEnum): boolean {
    return [AlertTypeEnum.EXIT, AlertTypeEnum.BOTH].includes(alertType);
  }

  /* ==================== ACTIVITY LOG SECTION ==================== */

  activityLog: Array<{
    timestamp: Date;
    action: 'created' | 'updated' | 'deleted';
    geofenceName: string;
    geofenceId?: number;
  }> = [];

  recordActivity(
    action: 'created' | 'updated' | 'deleted',
    geofenceName: string,
    geofenceId?: number,
  ): void {
    this.activityLog.unshift({
      timestamp: new Date(),
      action,
      geofenceName,
      geofenceId,
    });

    // Keep only the last 20 activities
    if (this.activityLog.length > 20) {
      this.activityLog = this.activityLog.slice(0, 20);
    }
  }

  /* ==================== GEOFENCE EVENTS MAP SECTION ==================== */

  private subscribeToGeofenceEvents(): void {
    this.driverLocationService
      .subscribeToGeofenceAlerts()
      .pipe(takeUntil(this.destroy$))
      .subscribe((event) => {
        // Prepend newest event and cap at 50
        this.recentEvents = [event, ...this.recentEvents].slice(0, 50);
        this.drawEventMarkers();
      });
  }

  get filteredEvents(): GeofenceEvent[] {
    const msMap = { '1h': 3_600_000, '6h': 21_600_000, '24h': 86_400_000 };
    const cutoff = Date.now() - msMap[this.eventTimeFilter];
    return this.recentEvents.filter((e) => new Date(e.eventTimestamp).getTime() >= cutoff);
  }

  setEventTimeFilter(filter: string): void {
    this.eventTimeFilter = filter as '1h' | '6h' | '24h';
    this.drawEventMarkers();
  }

  selectEvent(idx: number): void {
    this.selectedEventIdx = idx;
    const event = this.filteredEvents[idx];
    if (!event || !this.eventsMapEl?.googleMap) return;
    const pos = { lat: event.latitude, lng: event.longitude };
    this.eventsMapEl.googleMap.panTo(pos);
    this.eventsMapEl.googleMap.setZoom(15);
  }

  clearEventAlerts(): void {
    this.recentEvents = [];
    this.selectedEventIdx = null;
    this.clearEventMarkers();
    this.eventInfoWindow?.close();
  }

  onEventsMapInitialized(map: google.maps.Map): void {
    this.eventMapReady = true;
    this.drawEventMarkers();
  }

  private drawEventMarkers(): void {
    if (!this.eventMapReady || !this.eventsMapEl?.googleMap) return;
    this.clearEventMarkers();

    const map = this.eventsMapEl.googleMap;
    const events = this.filteredEvents;

    events.forEach((event, idx) => {
      const isEntry = event.eventType === 'ENTER';
      const pos = { lat: event.latitude, lng: event.longitude };

      const marker = new google.maps.Marker({
        position: pos,
        map,
        title: `${event.driverName} ${isEntry ? 'entered' : 'exited'} ${event.geofenceName}`,
        icon: {
          path: google.maps.SymbolPath.CIRCLE,
          scale: 9,
          fillColor: isEntry ? '#10b981' : '#ef4444',
          fillOpacity: 1,
          strokeColor: '#ffffff',
          strokeWeight: 2,
        },
        zIndex: events.length - idx,
      });

      marker.addListener('click', () => {
        this.selectedEventIdx = idx;
        this.eventInfoWindow?.close();
        this.eventInfoWindow = new google.maps.InfoWindow({
          content: `
            <div style="font-family:sans-serif;padding:4px 2px;min-width:160px">
              <p style="margin:0 0 4px;font-size:13px;font-weight:600;color:#111">
                ${isEntry ? '🟢 Entered' : '🔴 Exited'}
              </p>
              <p style="margin:0 0 2px;font-size:12px;color:#374151">
                <strong>Driver:</strong> ${event.driverName}
              </p>
              <p style="margin:0 0 2px;font-size:12px;color:#374151">
                <strong>Zone:</strong> ${event.geofenceName}
              </p>
              <p style="margin:0;font-size:11px;color:#6b7280">
                ${new Date(event.eventTimestamp).toLocaleString()}
              </p>
            </div>`,
        });
        this.eventInfoWindow.open(map, marker);
      });

      this.eventMarkers.push(marker);
    });

    // Auto-fit bounds if there are markers
    if (events.length > 0 && events.length <= 30) {
      const bounds = new google.maps.LatLngBounds();
      events.forEach((e) => bounds.extend({ lat: e.latitude, lng: e.longitude }));
      map.fitBounds(bounds, 40);
    }
  }

  private clearEventMarkers(): void {
    this.eventMarkers.forEach((m) => m.setMap(null));
    this.eventMarkers = [];
  }

  isEntryEvent(event: GeofenceEvent): boolean {
    return event.eventType === 'ENTER';
  }

  /* ==================== DROPDOWN MENU MANAGEMENT ==================== */

  toggleImportExportMenu(): void {
    this.importExportMenuOpen = !this.importExportMenuOpen;
    if (this.importExportMenuOpen) {
      this.exportSelectedMenuOpen = false;
      this.exportAllMenuOpen = false;
    }
  }

  toggleExportSelectedMenu(): void {
    this.exportSelectedMenuOpen = !this.exportSelectedMenuOpen;
  }

  toggleExportAllMenu(): void {
    this.exportAllMenuOpen = !this.exportAllMenuOpen;
  }

  toggleRowMenu(id: number): void {
    this.openRowMenuId = this.openRowMenuId === id ? null : id;
  }

  closeRowMenu(): void {
    this.openRowMenuId = null;
  }

  isRowMenuOpen(id: number): boolean {
    return this.openRowMenuId === id;
  }

  /** Show a toast notification using Angular Material SnackBar */
  private notify(message: string, type: 'success' | 'error' | 'info' = 'info'): void {
    const panelClass =
      type === 'success' ? ['snack-success'] : type === 'error' ? ['snack-error'] : ['snack-info'];
    this.snackBar.open(message, 'Dismiss', {
      duration: 4000,
      horizontalPosition: 'right',
      verticalPosition: 'bottom',
      panelClass,
    });
  }

  /* ==================== IMPORT/EXPORT SECTION ==================== */

  openImportDialog(): void {
    const dialogRef = this.dialog.open(GeofenceImportDialogComponent, {
      width: '600px',
      maxWidth: '90vw',
      data: {
        companyId: this.companyId,
      },
    });

    dialogRef.afterClosed().subscribe((result: GeofenceCreateRequest[] | undefined) => {
      if (result && result.length > 0) {
        this.bulkImportGeofences(result);
      }
    });
  }

  private bulkImportGeofences(requests: GeofenceCreateRequest[]): void {
    let completed = 0;
    let failed = 0;

    const dialogRef = this.dialog.open(ConfirmationDialogComponent, {
      data: {
        title: 'Import Geofences',
        message: `Ready to import ${requests.length} geofence(s). This may take a moment.`,
        confirmText: 'Start Import',
        cancelText: 'Cancel',
      },
    });

    dialogRef.afterClosed().subscribe((confirmed: boolean) => {
      if (confirmed) {
        requests.forEach((request) => {
          this.geofenceService.createGeofence(request).subscribe({
            next: () => {
              completed++;
              if (completed + failed === requests.length) {
                this.onImportComplete(completed, failed);
              }
            },
            error: () => {
              failed++;
              if (completed + failed === requests.length) {
                this.onImportComplete(completed, failed);
              }
            },
          });
        });
      }
    });
  }

  private onImportComplete(completed: number, failed: number): void {
    if (failed === 0) {
      this.notify(`Successfully imported ${completed} geofence(s)`, 'success');
    } else {
      this.notify(
        `Imported ${completed}/${completed + failed} geofences - ${failed} failed`,
        'error',
      );
    }
    this.loadGeofences();
  }

  exportSelectedToCSV(): void {
    if (this.selectedGeofences.size === 0) {
      this.notify('No geofences selected for export', 'info');
      return;
    }

    const selected = this.geofences.filter((g) => this.selectedGeofences.has(g.id));
    this.importExportService.exportToCSV(
      selected,
      `geofences-${new Date().toISOString().split('T')[0]}.csv`,
    );

    this.notify('Exported to CSV', 'success');
  }

  exportSelectedToGeoJSON(): void {
    if (this.selectedGeofences.size === 0) {
      this.notify('No geofences selected for export', 'info');
      return;
    }

    const selected = this.geofences.filter((g) => this.selectedGeofences.has(g.id));
    this.importExportService.exportToGeoJSON(
      selected,
      `geofences-${new Date().toISOString().split('T')[0]}.geojson`,
    );

    this.notify('Exported to GeoJSON', 'success');
  }

  exportAllToCSV(): void {
    if (this.filteredGeofences.length === 0) {
      this.notify('No geofences to export', 'info');
      return;
    }

    this.importExportService.exportToCSV(
      this.filteredGeofences,
      `geofences-${new Date().toISOString().split('T')[0]}.csv`,
    );

    this.notify('Exported to CSV', 'success');
  }

  exportAllToGeoJSON(): void {
    if (this.filteredGeofences.length === 0) {
      this.notify('No geofences to export', 'info');
      return;
    }

    this.importExportService.exportToGeoJSON(
      this.filteredGeofences,
      `geofences-${new Date().toISOString().split('T')[0]}.geojson`,
    );

    this.notify('Exported to GeoJSON', 'success');
  }

  private geofenceToRequest(geofence: Geofence): GeofenceCreateRequest {
    return {
      partnerCompanyId: this.companyId,
      name: geofence.name,
      description: geofence.description,
      type: geofence.type,
      centerLatitude: geofence.centerLatitude,
      centerLongitude: geofence.centerLongitude,
      radiusMeters: geofence.radiusMeters,
      geoJsonCoordinates: geofence.geoJsonCoordinates,
      alertType: geofence.alertType,
      speedLimitKmh: geofence.speedLimitKmh,
      active: geofence.active,
      tags: geofence.tags,
    };
  }

  setupDrawingSubscription(): void {
    this.drawingService.shapeComplete$.pipe(takeUntil(this.destroy$)).subscribe((drawnShape) => {
      this.openDialogWithDrawnShape(drawnShape);
    });

    // Subscribe to real-time measurements
    this.drawingService.measurement$.pipe(takeUntil(this.destroy$)).subscribe((measurements) => {
      this.currentMeasurements = measurements;
    });
  }

  onMapReady(map: google.maps.Map): void {
    this.mapInstance = map;
    this.drawingService.initializeDrawingManager(map);

    // Listen for zoom changes to toggle cluster view
    map.addListener('zoom_changed', () => {
      const zoom = map.getZoom() || 13;
      const shouldCluster = zoom < 11 && this.geofences.length > 20;

      if (shouldCluster !== this.useClusterView) {
        this.useClusterView = shouldCluster;
        this.renderGeofences(map);
      }
    });

    this.renderGeofences(map);
  }

  enableDrawingMode(mode: 'circle' | 'polygon' | 'rectangle'): void {
    this.drawingMode = mode;
    this.drawingService.enableDrawing(mode);
    const modeLabel = mode === 'rectangle' ? 'rectangle' : mode;
    this.notify(`Drawing mode enabled. Click on the map to draw a ${modeLabel}.`, 'info');
  }

  disableDrawingMode(): void {
    this.drawingMode = null;
    this.drawingService.disableDrawing();
  }

  /**
   * Start editing an existing geofence
   */
  startEditingGeofence(geofence: Geofence): void {
    if (!this.mapInstance) return;

    this.editingGeofenceId = geofence.id;

    // Find and animate the shape on the map
    if (geofence.type === GeofenceType.CIRCLE) {
      for (const circle of this.mapCircles) {
        const center = circle.getCenter();
        if (
          center &&
          center.lat() === geofence.centerLatitude &&
          center.lng() === geofence.centerLongitude
        ) {
          circle.setOptions({ fillOpacity: 0.5, strokeWeight: 3 });
          this.drawingService.startEditingShape(circle);
          break;
        }
      }
    } else if (geofence.type === GeofenceType.POLYGON) {
      for (const polygon of this.mapPolygons) {
        polygon.setOptions({ fillOpacity: 0.5, strokeWeight: 3 });
        this.drawingService.startEditingShape(polygon);
        break;
      }
    }

    this.notify('Edit mode: Drag vertices to adjust geofence shape', 'info');
  }

  /**
   * Stop editing and save changes
   */
  stopEditingGeofence(): void {
    this.drawingService.stopEditingShape();
    this.editingGeofenceId = null;
    this.currentMeasurements = null;

    // Reset shape opacity
    this.mapCircles.forEach((circle) => circle.setOptions({ fillOpacity: 0.3, strokeWeight: 2 }));
    this.mapPolygons.forEach((polygon) =>
      polygon.setOptions({ fillOpacity: 0.3, strokeWeight: 2 }),
    );
  }

  clearMapOverlays(): void {
    this.mapMarkers.forEach((marker) => marker.setMap(null));
    this.mapCircles.forEach((circle) => circle.setMap(null));
    this.mapPolygons.forEach((polygon) => polygon.setMap(null));
    this.clusterMarkers.forEach((marker) => marker.setMap(null));

    this.mapMarkers = [];
    this.mapCircles = [];
    this.mapPolygons = [];
    this.clusterMarkers = [];
  }

  renderGeofences(map: google.maps.Map): void {
    // Clear existing overlays
    this.clearMapOverlays();

    // Use cluster view for many geofences when zoomed out
    if (this.useClusterView) {
      this.renderGeofenceClusters(map);
      return;
    }

    // Add geofences to map
    for (const geofence of this.geofences) {
      if (
        geofence.type === GeofenceType.CIRCLE &&
        geofence.centerLatitude &&
        geofence.centerLongitude
      ) {
        this.renderCircleGeofence(map, geofence);
      } else if (geofence.type === GeofenceType.POLYGON && geofence.geoJsonCoordinates) {
        this.renderPolygonGeofence(map, geofence);
      }
    }
  }

  /**
   * Render geofences as clusters when zoomed out
   */
  private renderGeofenceClusters(map: google.maps.Map): void {
    const clusters = this.clusterGeofences(this.geofences, 0.1); // 0.1 degree grid

    clusters.forEach((cluster) => {
      const marker = new google.maps.Marker({
        position: cluster.center,
        map,
        icon: {
          path: google.maps.SymbolPath.CIRCLE,
          scale: Math.min(20 + cluster.count * 2, 40),
          fillColor: '#3b82f6',
          fillOpacity: 0.8,
          strokeColor: '#1e40af',
          strokeWeight: 2,
        },
        label: {
          text: cluster.count.toString(),
          color: 'white',
          fontSize: '14px',
          fontWeight: 'bold',
        },
        title: `${cluster.count} geofences`,
      });

      // Zoom in when cluster is clicked
      marker.addListener('click', () => {
        map.setCenter(cluster.center);
        map.setZoom((map.getZoom() || 10) + 3);
      });

      this.clusterMarkers.push(marker);
    });
  }

  /**
   * Cluster nearby geofences using grid-based clustering
   */
  private clusterGeofences(
    geofences: Geofence[],
    gridSize: number,
  ): Array<{ center: google.maps.LatLngLiteral; count: number; geofences: Geofence[] }> {
    const clusters = new Map<string, Geofence[]>();

    geofences.forEach((geofence) => {
      const lat = geofence.centerLatitude || 0;
      const lng = geofence.centerLongitude || 0;

      // Round to grid
      const gridLat = Math.floor(lat / gridSize) * gridSize;
      const gridLng = Math.floor(lng / gridSize) * gridSize;
      const key = `${gridLat},${gridLng}`;

      if (!clusters.has(key)) {
        clusters.set(key, []);
      }
      clusters.get(key)!.push(geofence);
    });

    return Array.from(clusters.entries()).map(([key, geofences]) => {
      const avgLat =
        geofences.reduce((sum, g) => sum + (g.centerLatitude || 0), 0) / geofences.length;
      const avgLng =
        geofences.reduce((sum, g) => sum + (g.centerLongitude || 0), 0) / geofences.length;

      return {
        center: { lat: avgLat, lng: avgLng },
        count: geofences.length,
        geofences,
      };
    });
  }

  private renderCircleGeofence(map: google.maps.Map, geofence: Geofence): void {
    const color = this.getColorForAlertType(geofence.alertType);

    // Add circle
    const circle = new google.maps.Circle({
      center: {
        lat: geofence.centerLatitude!,
        lng: geofence.centerLongitude!,
      },
      radius: geofence.radiusMeters || 500,
      map,
      fillColor: color,
      fillOpacity: 0.25,
      strokeColor: color,
      strokeOpacity: 0.8,
      strokeWeight: 2,
      clickable: true,
    });

    circle.addListener('click', () => {
      const center = circle.getCenter();
      if (center) this.showInfoWindow(geofence, center);
    });

    // Add hover effect
    circle.addListener('mouseover', () => {
      circle.setOptions({ fillOpacity: 0.4, strokeWeight: 3 });
    });

    circle.addListener('mouseout', () => {
      circle.setOptions({ fillOpacity: 0.25, strokeWeight: 2 });
    });

    this.mapCircles.push(circle);

    // Add center marker
    const marker = new google.maps.Marker({
      position: {
        lat: geofence.centerLatitude!,
        lng: geofence.centerLongitude!,
      },
      map,
      title: geofence.name,
      icon: this.getMarkerIcon(geofence),
    });

    marker.addListener('click', () => {
      const pos = marker.getPosition();
      if (pos) this.showInfoWindow(geofence, pos);
    });

    this.mapMarkers.push(marker);
  }

  private renderPolygonGeofence(map: google.maps.Map, geofence: Geofence): void {
    const path = this.getPolygonPath(geofence.geoJsonCoordinates);
    if (path.length === 0) return;

    const color = this.getColorForAlertType(geofence.alertType);

    // Add polygon with fill
    const polygon = new google.maps.Polygon({
      paths: path,
      map,
      fillColor: color,
      fillOpacity: 0.25,
      strokeColor: color,
      strokeOpacity: 0.8,
      strokeWeight: 2,
      clickable: true,
    });

    polygon.addListener('click', () => this.showInfoWindow(geofence, path[0]));

    // Add hover effect
    polygon.addListener('mouseover', () => {
      polygon.setOptions({ fillOpacity: 0.4, strokeWeight: 3 });
    });

    polygon.addListener('mouseout', () => {
      polygon.setOptions({ fillOpacity: 0.25, strokeWeight: 2 });
    });

    this.mapPolygons.push(polygon);

    // Add marker at first coordinate
    const marker = new google.maps.Marker({
      position: path[0],
      map,
      title: geofence.name,
      icon: this.getMarkerIcon(geofence),
    });

    marker.addListener('click', () => this.showInfoWindow(geofence, path[0]));
    this.mapMarkers.push(marker);
  }

  private getColorForAlertType(alertType: AlertTypeEnum): string {
    const colorMap: Record<AlertTypeEnum, string> = {
      [AlertTypeEnum.ENTER]: '#10b981', // Green
      [AlertTypeEnum.EXIT]: '#ef4444', // Red
      [AlertTypeEnum.BOTH]: '#3b82f6', // Blue
      [AlertTypeEnum.NONE]: '#6b7280', // Gray
    };
    return colorMap[alertType] || '#3b82f6';
  }

  loadGeofences(): void {
    this.loading = true;
    this.geofenceService.loadGeofences(this.companyId).subscribe({
      next: (data) => {
        this.geofences = data;
        this.loading = false;
        if (this.mapInstance) {
          this.renderGeofences(this.mapInstance);
        }
      },
      error: (error) => {
        console.error('Failed to load geofences', error);
        this.notify('Failed to load geofences', 'error');
        this.loading = false;
      },
    });
  }

  openCreateDialog(): void {
    if (!this.canCreate()) return;

    const dialogRef = this.dialog.open(GeofenceFormDialogComponent, {
      width: '600px',
      maxWidth: '90vw',
      data: {
        companyId: this.companyId,
      },
    });

    dialogRef.afterClosed().subscribe((result: GeofenceCreateRequest | undefined) => {
      if (result) {
        this.createGeofence(result);
      }
    });
  }

  openEditDialog(geofence: Geofence): void {
    if (!this.canUpdate()) return;

    const dialogRef = this.dialog.open(GeofenceFormDialogComponent, {
      width: '600px',
      maxWidth: '90vw',
      data: {
        geofence,
        companyId: this.companyId,
      },
    });

    dialogRef.afterClosed().subscribe((result: GeofenceCreateRequest | undefined) => {
      if (result) {
        this.updateGeofence(geofence.id, result);
      }
    });
  }

  private openDialogWithDrawnShape(drawnShape: any): void {
    if (!this.canCreate()) return;

    const data: any = {
      companyId: this.companyId,
      type: drawnShape.type === 'circle' ? GeofenceType.CIRCLE : GeofenceType.POLYGON,
    };

    if (drawnShape.type === 'circle') {
      data.centerLat = drawnShape.data.centerLat;
      data.centerLng = drawnShape.data.centerLng;
      data.radiusMeters = drawnShape.data.radiusMeters;
    } else if (drawnShape.type === 'polygon') {
      data.coordinates = drawnShape.data.coordinates;
    }

    const dialogRef = this.dialog.open(GeofenceFormDialogComponent, {
      width: '600px',
      maxWidth: '90vw',
      data,
    });

    dialogRef.afterClosed().subscribe((result: GeofenceCreateRequest | undefined) => {
      if (result) {
        this.createGeofence(result);
        // Remove the drawn shape
        if (drawnShape.circle) {
          this.drawingService.removeShape(drawnShape.circle);
        } else if (drawnShape.polygon) {
          this.drawingService.removeShape(drawnShape.polygon);
        }
      } else {
        // User cancelled, remove the drawn shape
        if (drawnShape.circle) {
          this.drawingService.removeShape(drawnShape.circle);
        } else if (drawnShape.polygon) {
          this.drawingService.removeShape(drawnShape.polygon);
        }
      }
      this.disableDrawingMode();
    });
  }

  private createGeofence(request: GeofenceCreateRequest): void {
    this.geofenceService.createGeofence(request).subscribe({
      next: (created) => {
        this.recordActivity('created', request.name);
        this.notify('Geofence created successfully', 'success');
        this.loadGeofences();
      },
      error: (error) => {
        console.error('Failed to create geofence', error);
        this.notify('Failed to create geofence', 'error');
      },
    });
  }

  private updateGeofence(id: number, request: GeofenceCreateRequest): void {
    this.geofenceService.updateGeofence(id, request).subscribe({
      next: () => {
        this.recordActivity('updated', request.name, id);
        this.notify('Geofence updated successfully', 'success');
        this.loadGeofences();
      },
      error: (error) => {
        console.error('Failed to update geofence', error);
        this.notify('Failed to update geofence', 'error');
      },
    });
  }

  toggleGeofenceActive(geofence: Geofence): void {
    if (!this.canUpdate()) return;

    const nextActive = !geofence.active;
    const actionLabel = nextActive ? 'Activate' : 'Deactivate';

    const dialogRef = this.dialog.open(ConfirmationDialogComponent, {
      data: {
        title: `${actionLabel} Geofence`,
        message: `${actionLabel} "${geofence.name}"?`,
        confirmText: actionLabel,
        cancelText: 'Cancel',
      },
    });

    dialogRef.afterClosed().subscribe((confirmed: boolean) => {
      if (!confirmed) return;

      this.geofenceService
        .updateGeofence(geofence.id, this.geofenceToRequest({ ...geofence, active: nextActive }))
        .subscribe({
          next: () => {
            this.recordActivity('updated', geofence.name, geofence.id);
            this.notify(`Geofence ${nextActive ? 'activated' : 'deactivated'} successfully`, 'success');
            this.loadGeofences();
            this.infoWindowContent = null;
          },
          error: (error) => {
            console.error(`Failed to ${nextActive ? 'activate' : 'deactivate'} geofence`, error);
            this.notify(`Failed to ${nextActive ? 'activate' : 'deactivate'} geofence`, 'error');
          },
        });
    });
  }

  deleteGeofence(geofence: Geofence): void {
    if (!this.canDelete()) return;

    const dialogRef = this.dialog.open(ConfirmationDialogComponent, {
      data: {
        title: 'Delete Geofence',
        message: `Are you sure you want to delete "${geofence.name}"? This action cannot be undone.`,
        confirmText: 'Delete',
        cancelText: 'Cancel',
        confirmColor: 'warn',
      },
    });

    dialogRef.afterClosed().subscribe((confirmed: boolean) => {
      if (confirmed) {
        this.geofenceService.deleteGeofence(geofence.id).subscribe({
          next: () => {
            this.recordActivity('deleted', geofence.name, geofence.id);
            this.notify('Geofence deleted successfully', 'success');
            this.loadGeofences();
            this.infoWindowContent = null;
          },
          error: (error) => {
            console.error('Failed to delete geofence', error);
            this.notify('Failed to delete geofence', 'error');
          },
        });
      }
    });
  }

  showInfoWindow(
    geofence: Geofence,
    position: google.maps.LatLng | google.maps.LatLngLiteral | null | undefined,
  ): void {
    if (!position) return;

    let lat: number;
    let lng: number;

    if (position instanceof google.maps.LatLng) {
      lat = position.lat();
      lng = position.lng();
    } else {
      lat = (position as google.maps.LatLngLiteral).lat;
      lng = (position as google.maps.LatLngLiteral).lng;
    }

    this.infoWindowContent = {
      geofence,
      position: { lat, lng },
    };
    this.infoWindow.open(undefined);
  }

  closeInfoWindow(): void {
    this.infoWindowContent = null;
  }

  openEditFromInfoWindow(geofence: Geofence): void {
    this.closeInfoWindow();
    this.openEditDialog(geofence);
  }

  fitGeofenceBounds(geofence: Geofence): void {
    if (!this.mapInstance) return;

    const bounds = new google.maps.LatLngBounds();

    if (
      geofence.type === GeofenceType.CIRCLE &&
      geofence.centerLatitude &&
      geofence.centerLongitude
    ) {
      const center = new google.maps.LatLng(geofence.centerLatitude, geofence.centerLongitude);
      const radius = geofence.radiusMeters || 500;

      // Extend bounds by circle radius
      bounds.extend(google.maps.geometry.spherical.computeOffset(center, radius, 0));
      bounds.extend(google.maps.geometry.spherical.computeOffset(center, radius, 90));
      bounds.extend(google.maps.geometry.spherical.computeOffset(center, radius, 180));
      bounds.extend(google.maps.geometry.spherical.computeOffset(center, radius, 270));
    } else if (geofence.type === GeofenceType.POLYGON && geofence.geoJsonCoordinates) {
      const path = this.getPolygonPath(geofence.geoJsonCoordinates);
      path.forEach((point) => bounds.extend(point));
    }

    this.mapInstance.fitBounds(bounds);
    this.closeInfoWindow();
  }

  getPolygonPath(coordinates: string | undefined): google.maps.LatLngLiteral[] {
    if (!coordinates) return [];

    try {
      const parsed = JSON.parse(coordinates);
      if (Array.isArray(parsed)) {
        return parsed.map((coord: [number, number]) => ({
          lat: coord[0],
          lng: coord[1],
        }));
      }
    } catch {
      console.error('Failed to parse polygon coordinates');
    }

    return [];
  }

  getMarkerIcon(geofence: Geofence): google.maps.Symbol {
    const color = this.getColorForAlertType(geofence.alertType);

    return {
      path: google.maps.SymbolPath.CIRCLE,
      scale: 8,
      fillColor: color,
      fillOpacity: 0.9,
      strokeColor: '#fff',
      strokeWeight: 2,
    };
  }

  geofenceTypeLabel(type: GeofenceType): string {
    return this.geofenceService.getGeofenceTypeLabel(type);
  }

  alertTypeLabel(alertType: AlertTypeEnum): string {
    return this.geofenceService.getAlertTypeLabel(alertType);
  }

  canCreate(): boolean {
    return this.canGeofencePermission(PERMISSIONS.GEOFENCE_CREATE);
  }

  canUpdate(): boolean {
    return this.canGeofencePermission(PERMISSIONS.GEOFENCE_UPDATE);
  }

  canDelete(): boolean {
    return this.canGeofencePermission(PERMISSIONS.GEOFENCE_DELETE);
  }

  private canGeofencePermission(permission: string): boolean {
    return this.permissionGuardService.hasAnyPermission([
      permission,
      PERMISSIONS.GEOFENCE_READ,
      PERMISSIONS.DRIVER_LIVE_READ,
    ]);
  }
}
