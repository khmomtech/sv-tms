import { environment } from '../../environments/environment';
import { CommonModule } from '@angular/common';
import {
  Component,
  ElementRef,
  HostListener,
  ViewChild,
  type OnDestroy,
  type OnInit,
} from '@angular/core';
import { FormsModule } from '@angular/forms';
import { GoogleMap, GoogleMapsModule } from '@angular/google-maps';
import { finalize, forkJoin, Subject, takeUntil } from 'rxjs';

import type { Dispatch } from '../../models/dispatch.model';
import type { Driver } from '../../models/driver.model';
import type { TransportOrder } from '../../models/transport-order.model';
import { DispatchService } from '../../services/dispatch.service';
import { ConfirmService } from '../../services/confirm.service';
import { NotificationService } from '../../services/notification.service';
import { ToastrService } from 'ngx-toastr';
import { GoogleMapsLoaderService } from '../../services/google-maps-loader.service';
import { TransportOrderService } from '../../services/transport-order.service';

interface OrderRow {
  source: 'unassigned' | 'assigned';
  orderId?: number;
  dispatchId?: number;
  fromLat?: number | null;
  fromLng?: number | null;
  toLat?: number | null;
  toLng?: number | null;
  orderNo: string;
  orderDate?: string;
  deliveryDate?: string;
  eta?: string;
  deliveryDateValue?: Date | null;
  customer?: string;
  from?: string;
  to?: string;
  fromFull?: string; // Full address for tooltip
  toFull?: string; // Full address for tooltip
  driver?: string;
  truck?: string;
  status?: string;
  routeCode?: string;
  // Unassigned order specific
  transportOrderStatus?: string; // e.g., PENDING, CONFIRMED, CANCELLED
  fileProofUrl?: string; // URL for viewing order files/attachments
  fileCount?: number; // Number of attached files
}

type MapLayer = 'drivers' | 'orders' | 'depots';

interface MapPoint {
  id: string;
  type: MapLayer;
  position: google.maps.LatLngLiteral;
  label?: string;
  title?: string;
  options?: google.maps.MarkerOptions;
}

@Component({
  selector: 'app-dispatch-board',
  standalone: true,
  imports: [CommonModule, FormsModule, GoogleMapsModule],
  templateUrl: './dispatch-board.component.html',
  styleUrls: ['./dispatch-board.component.css'],
})
export class DispatchBoardComponent implements OnInit, OnDestroy {
  private readonly destroy$ = new Subject<void>();
  @ViewChild(GoogleMap) map?: GoogleMap;
  @ViewChild('leftPanel') leftPanelRef?: ElementRef<HTMLDivElement>;

  leftWidthPx = 420;
  isDragging = false;
  isVerticalDragging = false;
  topSectionHeightPx = 320;
  leftPanelTop = 0;

  searchOrders = '';
  searchDrivers = '';
  deliveryFrom = '';
  deliveryTo = '';

  // Pre-Loading section: Orders pending dispatch that need to pass pre-loading safety checks
  loadingOrders = false;
  // Loading section: Orders from Loading status to Loaded status
  loadingAssigned = false;
  loadingDrivers = false;
  ordersError = '';
  assignedError = '';
  driversError = '';
  mapsError = '';
  assignBusy = false;

  // Track which order's menu is open
  openMenuOrderId: number | null = null;

  unassignedOrders: OrderRow[] = [];
  assignedOrders: OrderRow[] = [];
  assignedDispatches: Dispatch[] = [];
  drivers: Driver[] = [];
  unassignedOrderMap = new Map<number, TransportOrder>();

  selectedDriver: Driver | null = null;

  selectedOrderIds = new Set<number>(); // order ids (unassigned)
  selectedDispatchIds = new Set<number>(); // dispatch ids (assigned)

  // Map state
  hasMapsKey = !!environment.googleMapsApiKey;
  showDrivers = true;
  showOrders = true;
  showDepots = false;
  mapCenter: google.maps.LatLngLiteral = { lat: 11.5564, lng: 104.9282 };
  mapOptions: google.maps.MapOptions = {
    mapTypeControl: false,
    streetViewControl: false,
    fullscreenControl: false,
    zoomControl: true,
    maxZoom: 18,
    minZoom: 4,
  };
  zoom = 7;
  driverMarkers: MapPoint[] = [];
  orderMarkers: MapPoint[] = [];
  depotMarkers: MapPoint[] = [];

  // Driver table pagination
  driverPage = 0;
  driverPageSize = 6;
  Math = Math;

  constructor(
    private readonly dispatchService: DispatchService,
    private readonly transportOrderService: TransportOrderService,
    private readonly googleMapsLoader: GoogleMapsLoaderService,
    private readonly toastr: ToastrService,
    private readonly confirm: ConfirmService,
    private readonly notification: NotificationService,
  ) {}

  ngOnInit(): void {
    this.refreshAll();
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  refreshAll(): void {
    this.loadMaps();
    this.loadUnassignedOrders();
    this.loadAssignedOrders();
    this.loadDrivers();
  }

  loadUnassignedOrders(): void {
    this.loadingOrders = true;
    this.ordersError = '';

    const query = this.searchOrders.trim();
    const obs = query
      ? this.transportOrderService.searchOrders(query, 0, 50)
      : this.transportOrderService.getUnscheduledOrders();

    obs
      .pipe(
        takeUntil(this.destroy$),
        finalize(() => (this.loadingOrders = false)),
      )
      .subscribe({
        next: (res) => {
          const list: TransportOrder[] = (res.data?.content || res.data || []) as TransportOrder[];
          const unscheduled = list.filter((o) => !o.dispatches || !o.dispatches.length);
          this.unassignedOrderMap.clear();
          unscheduled.forEach((o) => this.unassignedOrderMap.set(o.id, o));
          this.unassignedOrders = unscheduled.map((o) => this.mapOrderToRow(o));
          this.refreshMapMarkers();
        },
        error: (err) => (this.ordersError = err?.message || 'Failed to load orders'),
      });
  }

  loadAssignedOrders(): void {
    this.loadingAssigned = true;
    this.assignedError = '';

    this.dispatchService
      .filterDispatches({ status: 'ASSIGNED', page: 0, size: 50 })
      .pipe(
        takeUntil(this.destroy$),
        finalize(() => (this.loadingAssigned = false)),
      )
      .subscribe({
        next: (res) => {
          const list: Dispatch[] = res.data?.content || [];
          this.assignedDispatches = list;
          this.assignedOrders = list.map((d) => this.mapDispatchToRow(d));
          this.refreshMapMarkers();
        },
        error: (err) => (this.assignedError = err?.message || 'Failed to load loading orders'),
      });
  }

  loadDrivers(): void {
    this.loadingDrivers = true;
    this.driversError = '';

    this.dispatchService
      .getAvailableDrivers()
      .pipe(
        takeUntil(this.destroy$),
        finalize(() => (this.loadingDrivers = false)),
      )
      .subscribe({
        next: (res) => {
          this.drivers = res.data || [];
          if (!this.selectedDriver && this.drivers.length) {
            this.selectedDriver = this.drivers[0];
          }
          this.refreshMapMarkers();
        },
        error: (err) => (this.driversError = err?.message || 'Failed to load drivers'),
      });
  }

  get filteredUnassignedOrders(): OrderRow[] {
    return this.filterOrders(this.unassignedOrders, this.searchOrders);
  }

  get filteredAssignedOrders(): OrderRow[] {
    return this.filterOrders(this.assignedOrders, this.searchOrders);
  }

  get filteredDrivers(): Driver[] {
    const q = this.searchDrivers.trim().toLowerCase();
    if (!q) return this.drivers;
    const tokens = q.split(/\s+/).filter(Boolean);
    return this.drivers.filter((d) => {
      const haystack = [
        d.name,
        d.fullName,
        d.licenseNumber,
        d.currentVehiclePlate || d.assignedVehicle?.licensePlate,
        d.assignedVehicle?.manufacturer,
        d.assignedVehicle?.model,
        d.assignedVehicle?.type,
      ]
        .filter(Boolean)
        .map((s) => String(s).toLowerCase());
      return tokens.every((t) => haystack.some((h) => h.includes(t)));
    });
  }

  get pagedDrivers(): Driver[] {
    const start = this.driverPage * this.driverPageSize;
    const end = start + this.driverPageSize;
    const list = this.filteredDrivers;
    if (start >= list.length && list.length) this.driverPage = 0;
    return list.slice(
      this.driverPage * this.driverPageSize,
      this.driverPage * this.driverPageSize + this.driverPageSize,
    );
  }

  get driverPageCount(): number {
    return Math.max(1, Math.ceil(this.filteredDrivers.length / this.driverPageSize || 1));
  }

  selectDriver(driver: Driver): void {
    this.selectedDriver = driver;
    const lat = this.toNumber(driver.latitude ?? driver.currentLatitude);
    const lng = this.toNumber(driver.longitude ?? driver.currentLongitude);
    if (lat != null && lng != null) this.mapCenter = { lat, lng };
  }

  quickPickDriver(): void {
    const [firstMatch] = this.filteredDrivers;
    if (firstMatch) this.selectDriver(firstMatch);
    else this.toastr.info('No driver found for that search.');
  }

  onDriverSearchChange(term: string): void {
    this.searchDrivers = term;
    this.driverPage = 0;
  }

  get allDriversSelected(): boolean {
    if (!this.selectedDriver) return false;
    return this.filteredDrivers.every((driver) => driver.id === this.selectedDriver?.id);
  }

  selectFirstFilteredDriver(): void {
    const first = this.filteredDrivers[0];
    if (first) this.selectDriver(first);
  }

  private filterOrders(list: OrderRow[], query: string): OrderRow[] {
    const q = query.trim().toLowerCase();
    const from = this.parseDate(this.deliveryFrom || null);
    const to = this.parseDate(this.deliveryTo || null);

    return list.filter((o) => {
      const matchesText =
        !q ||
        o.orderNo.toLowerCase().includes(q) ||
        o.customer?.toLowerCase().includes(q) ||
        o.from?.toLowerCase().includes(q) ||
        o.to?.toLowerCase().includes(q);

      if (!matchesText) return false;

      if (!from && !to) return true;
      const dt = o.deliveryDateValue;
      if (!dt) return true;
      if (from && dt < from) return false;
      if (to) {
        const end = new Date(to);
        end.setHours(23, 59, 59, 999);
        if (dt > end) return false;
      }
      return true;
    });
  }

  private mapOrderToRow(order: TransportOrder): OrderRow {
    // Debug logging
    console.log('🔍 Mapping order:', {
      id: order.id,
      orderReference: order.orderReference,
      orderDate: order.orderDate,
      deliveryDate: order.deliveryDate,
      createdAt: order.createdAt,
      stops: order.stops,
      pickupAddress: order.pickupAddress,
      dropAddress: order.dropAddress,
    });

    // Note: TransportOrder model doesn't have files/attachments yet
    const fileCount = 0;
    const fileProofUrl = undefined;

    // Use stops array if available, otherwise fallback to pickupAddress/dropAddress
    let fromFull = '';
    let toFull = '';
    let fromShort = '';
    let toShort = '';
    let fromLat: number | null = null;
    let fromLng: number | null = null;
    let toLat: number | null = null;
    let toLng: number | null = null;

    if (order.stops && order.stops.length > 0) {
      console.log('Using stops array, count:', order.stops.length);

      // Sort stops by sequence to ensure correct order
      const sortedStops = [...order.stops].sort((a, b) => {
        const seqA = (a as any).stopSequence || a.sequence || 0;
        const seqB = (b as any).stopSequence || b.sequence || 0;
        return seqA - seqB;
      });

      // First stop is FROM
      const firstStop = sortedStops[0];
      const locationName = (firstStop as any).locationName || firstStop.address?.name || '';
      const address = (firstStop as any).address || firstStop.address?.address || '';
      fromShort = locationName || (typeof address === 'string' ? address.split(',')[0] : '') || '—';
      fromFull = typeof address === 'string' ? address : this.buildFullAddress(firstStop.address);

      console.log('📍 First stop FROM:', { locationName, address, fromShort, fromFull });

      // Parse coordinates
      const coords = (firstStop as any).coordinates;
      if (coords && typeof coords === 'string') {
        const [lat, lng] = coords.split(',').map((s) => parseFloat(s.trim()));
        fromLat = isNaN(lat) ? null : lat;
        fromLng = isNaN(lng) ? null : lng;
      } else if (firstStop.address) {
        fromLat = this.toNumber(firstStop.address.latitude);
        fromLng = this.toNumber(firstStop.address.longitude);
      }

      // Last stop is TO
      const lastStop = sortedStops[sortedStops.length - 1];
      const lastLocationName = (lastStop as any).locationName || lastStop.address?.name || '';
      const lastAddress = (lastStop as any).address || lastStop.address?.address || '';
      toShort =
        lastLocationName ||
        (typeof lastAddress === 'string' ? lastAddress.split(',')[0] : '') ||
        '—';
      toFull =
        typeof lastAddress === 'string' ? lastAddress : this.buildFullAddress(lastStop.address);

      console.log('📍 Last stop TO:', { lastLocationName, lastAddress, toShort, toFull });

      // Parse coordinates
      const lastCoords = (lastStop as any).coordinates;
      if (lastCoords && typeof lastCoords === 'string') {
        const [lat, lng] = lastCoords.split(',').map((s) => parseFloat(s.trim()));
        toLat = isNaN(lat) ? null : lat;
        toLng = isNaN(lng) ? null : lng;
      } else if (lastStop.address) {
        toLat = this.toNumber(lastStop.address.latitude);
        toLng = this.toNumber(lastStop.address.longitude);
      }
    } else {
      console.log('⚠️ No stops array, using fallback addresses');

      // Fallback to header-level addresses
      fromFull = this.buildFullAddress(order.pickupAddress);
      toFull = this.buildFullAddress(order.dropAddress);
      fromShort = order.pickupAddress?.city || order.pickupAddress?.name || fromFull;
      toShort = order.dropAddress?.city || order.dropAddress?.name || toFull;
      fromLat = this.toNumber(order.pickupAddress?.latitude);
      fromLng = this.toNumber(order.pickupAddress?.longitude);
      toLat = this.toNumber(order.dropAddress?.latitude);
      toLng = this.toNumber(order.dropAddress?.longitude);

      console.log('📍 Fallback addresses:', { fromShort, toShort, fromFull, toFull });
    }

    const orderDateFormatted = this.formatDateTime(order.orderDate || order.createdAt);
    const deliveryDateFormatted = this.formatDateTime(order.deliveryDate);

    console.log('📅 Dates formatted:', {
      orderDate: orderDateFormatted,
      deliveryDate: deliveryDateFormatted,
    });

    const result = {
      source: 'unassigned' as const,
      orderId: order.id,
      fromLat: fromLat,
      fromLng: fromLng,
      toLat: toLat,
      toLng: toLng,
      orderNo: order.orderReference || order.tripNo || String(order.id),
      orderDate: orderDateFormatted,
      deliveryDate: deliveryDateFormatted,
      deliveryDateValue: this.parseDate(order.deliveryDate),
      customer: order.customerName,
      from: fromShort,
      to: toShort,
      fromFull: fromFull,
      toFull: toFull,
      transportOrderStatus: order.status || 'PENDING',
      fileProofUrl: fileProofUrl,
      fileCount: fileCount,
    };

    console.log('✨ Final mapped row:', result);
    return result;
  }

  private mapDispatchToRow(dispatch: Dispatch): OrderRow {
    // Use stops array if available, otherwise fallback to pickup/dropoff fields
    let fromFull = '';
    let toFull = '';
    let fromShort = '';
    let toShort = '';
    let fromLat: number | null = null;
    let fromLng: number | null = null;
    let toLat: number | null = null;
    let toLng: number | null = null;

    if (dispatch.stops && dispatch.stops.length > 0) {
      // Sort stops by sequence to ensure correct order
      const sortedStops = [...dispatch.stops].sort((a, b) => {
        const seqA = (a as any).stopSequence || (a as any).sequence || 0;
        const seqB = (b as any).stopSequence || (b as any).sequence || 0;
        return seqA - seqB;
      });

      // First stop is FROM
      const firstStop = sortedStops[0];
      const locationName = (firstStop as any).locationName || (firstStop as any).location || '';
      const address = (firstStop as any).address || '';
      fromShort = locationName || (typeof address === 'string' ? address.split(',')[0] : '') || '—';
      fromFull = typeof address === 'string' ? address : '—';

      // Parse coordinates if available
      const coords = (firstStop as any).coordinates;
      if (coords && typeof coords === 'string') {
        const [lat, lng] = coords.split(',').map((s) => parseFloat(s.trim()));
        fromLat = isNaN(lat) ? null : lat;
        fromLng = isNaN(lng) ? null : lng;
      }

      // Last stop is TO
      const lastStop = sortedStops[sortedStops.length - 1];
      const lastLocationName = (lastStop as any).locationName || (lastStop as any).location || '';
      const lastAddress = (lastStop as any).address || '';
      toShort =
        lastLocationName ||
        (typeof lastAddress === 'string' ? lastAddress.split(',')[0] : '') ||
        '—';
      toFull = typeof lastAddress === 'string' ? lastAddress : '—';

      // Parse coordinates if available
      const lastCoords = (lastStop as any).coordinates;
      if (lastCoords && typeof lastCoords === 'string') {
        const [lat, lng] = lastCoords.split(',').map((s) => parseFloat(s.trim()));
        toLat = isNaN(lat) ? null : lat;
        toLng = isNaN(lng) ? null : lng;
      }
    } else {
      // Fallback to header-level pickup/dropoff fields
      fromShort = dispatch.pickupName || dispatch.pickupLocation || '—';
      toShort = dispatch.dropoffName || dispatch.dropoffLocation || '—';
      fromFull = dispatch.pickupLocation || dispatch.pickupName || '—';
      toFull = dispatch.dropoffLocation || dispatch.dropoffName || '—';
      fromLat = this.toNumber(dispatch.pickupLat);
      fromLng = this.toNumber(dispatch.pickupLng);
      toLat = this.toNumber(dispatch.dropoffLat);
      toLng = this.toNumber(dispatch.dropoffLng);
    }

    return {
      source: 'assigned',
      dispatchId: dispatch.id,
      orderId: dispatch.transportOrderId,
      fromLat: fromLat,
      fromLng: fromLng,
      toLat: toLat,
      toLng: toLng,
      orderNo: dispatch.routeCode || dispatch.tripNo || `DISP-${dispatch.id}`,
      deliveryDate: this.formatDateTime(dispatch.expectedDelivery),
      deliveryDateValue: this.parseDate(dispatch.expectedDelivery),
      eta: this.formatDateTime(dispatch.estimatedArrival),
      customer: dispatch.customerName,
      from: fromShort,
      to: toShort,
      fromFull: fromFull,
      toFull: toFull,
      driver: dispatch.driverName,
      truck: dispatch.licensePlate,
      status: dispatch.status,
      routeCode: dispatch.routeCode,
    };
  }

  startDrag(): void {
    this.isDragging = true;
  }

  stopDrag(): void {
    this.isDragging = false;
  }

  @HostListener('document:mouseup')
  onMouseUp(): void {
    this.isDragging = false;
    this.isVerticalDragging = false;
  }

  @HostListener('document:mousemove', ['$event'])
  onMouseMove(event: MouseEvent): void {
    if (this.isDragging) {
      let width = event.clientX;
      if (width < 300) width = 300;
      if (width > window.innerWidth - 400) width = window.innerWidth - 400;
      this.leftWidthPx = width;
    }

    if (this.isVerticalDragging) {
      const panel = this.leftPanelRef?.nativeElement;
      const panelHeight = panel?.clientHeight ?? window.innerHeight;
      const y = event.clientY - this.leftPanelTop;
      const min = 180;
      const max = panelHeight - 240;
      this.topSectionHeightPx = Math.max(min, Math.min(max, y));
    }
  }

  toggleOrderSelection(orderId: number, checked: boolean): void {
    if (checked) this.selectedOrderIds.add(orderId);
    else this.selectedOrderIds.delete(orderId);
  }

  toggleDispatchSelection(dispatchId: number, checked: boolean): void {
    if (checked) this.selectedDispatchIds.add(dispatchId);
    else this.selectedDispatchIds.delete(dispatchId);
  }

  toggleSelectAllOrders(list: OrderRow[], checked: boolean): void {
    if (checked) list.forEach((o) => o.orderId && this.selectedOrderIds.add(o.orderId));
    else list.forEach((o) => o.orderId && this.selectedOrderIds.delete(o.orderId));
  }

  toggleSelectAllDispatches(list: OrderRow[], checked: boolean): void {
    if (checked) list.forEach((o) => o.dispatchId && this.selectedDispatchIds.add(o.dispatchId));
    else list.forEach((o) => o.dispatchId && this.selectedDispatchIds.delete(o.dispatchId));
  }

  assignSelected(): void {
    if (!this.selectedDriver) {
      this.toastr.info('Select a driver before assigning.');
      return;
    }
    const totalSelected = this.selectedOrderIds.size + this.selectedDispatchIds.size;
    if (!totalSelected) {
      this.toastr.info('Select at least one order/dispatch to assign.');
      return;
    }
    const driverId = this.selectedDriver.id;
    const vehicleId =
      this.selectedDriver.currentVehicleId ||
      this.selectedDriver.assignedVehicleId ||
      this.selectedDriver.assignedVehicle?.id;
    if (!vehicleId) {
      this.toastr.info(
        'Selected driver has no assigned truck. Please select a driver with a truck.',
      );
      return;
    }

    const dispatchCalls = Array.from(this.selectedDispatchIds).map((dispatchId) =>
      this.dispatchService.assignDispatch(dispatchId, driverId, vehicleId),
    );

    const createCalls = Array.from(this.selectedOrderIds)
      .map((orderId) => this.unassignedOrderMap.get(orderId))
      .filter((o): o is TransportOrder => !!o)
      .map((order) => this.dispatchService.createDispatch(this.buildDispatchPayload(order)));

    if (!dispatchCalls.length && !createCalls.length) {
      this.toastr.info('Nothing to assign. Select dispatches or pre-loading orders.');
      return;
    }

    this.assignBusy = true;
    forkJoin([...dispatchCalls, ...createCalls])
      .pipe(finalize(() => (this.assignBusy = false)))
      .subscribe({
        next: () => {
          this.toastr.success('Assignments completed successfully.');
          this.selectedDispatchIds.clear();
          this.selectedOrderIds.clear();
          this.loadAssignedOrders();
          this.loadUnassignedOrders();
          this.loadDrivers();
        },
        error: (err) => {
          console.error('Failed to assign', err);
          this.toastr.error('Failed to assign. Please try again.');
        },
      });
  }

  // ===== Map helpers =====
  private mapsLoadPromise: Promise<void> | null = null;

  private loadMaps(): void {
    if (!this.hasMapsKey) {
      this.mapsError = 'Google Maps API key is missing.';
      return;
    }
    if (!this.mapsLoadPromise) {
      this.mapsError = '';
      this.mapsLoadPromise = this.googleMapsLoader.load().catch((err) => {
        console.error('[DispatchBoard] Failed to load Google Maps', err);
        this.mapsError = 'Google Maps failed to load. Check API key/billing.';
      });
    }
  }

  onLayerToggle(layer: MapLayer, checked: boolean): void {
    if (layer === 'drivers') this.showDrivers = checked;
    if (layer === 'orders') this.showOrders = checked;
    if (layer === 'depots') this.showDepots = checked;
    this.fitMapToMarkers();
  }

  get visibleMarkers(): MapPoint[] {
    const markers: MapPoint[] = [];
    if (this.showDrivers) markers.push(...this.driverMarkers);
    if (this.showOrders) markers.push(...this.orderMarkers);
    if (this.showDepots) markers.push(...this.depotMarkers);
    return markers;
  }

  private refreshMapMarkers(): void {
    this.driverMarkers = this.drivers
      .map((d) => this.buildDriverMarker(d))
      .filter((m): m is MapPoint => !!m);

    this.orderMarkers = [
      ...this.unassignedOrders
        .map((o) => this.buildOrderMarkerFromOrder(o))
        .filter((m): m is MapPoint => !!m),
      ...this.assignedDispatches
        .map((d) => this.buildOrderMarkerFromDispatch(d))
        .filter((m): m is MapPoint => !!m),
    ];

    // Depots placeholder: none for now, but keep array for future.
    this.depotMarkers = [];

    this.fitMapToMarkers();
  }

  private buildDriverMarker(driver: Driver): MapPoint | null {
    const maps = this.getMaps();
    const lat = this.toNumber(driver.latitude ?? driver.currentLatitude);
    const lng = this.toNumber(driver.longitude ?? driver.currentLongitude);
    if (lat == null || lng == null) return null;
    const color = this.driverColor(driver.status);
    return {
      id: `driver-${driver.id}`,
      type: 'drivers',
      position: { lat, lng },
      label:
        driver.currentVehiclePlate ||
        driver.assignedVehicle?.licensePlate ||
        driver.name?.slice(0, 3) ||
        'DRV',
      title: `${driver.name || 'Driver'} • ${driver.currentVehiclePlate || driver.assignedVehicle?.licensePlate || 'No truck'}`,
      options: {
        icon: maps
          ? {
              path: maps.SymbolPath.CIRCLE,
              scale: 8,
              fillColor: color,
              fillOpacity: 0.9,
              strokeWeight: 1,
              strokeColor: '#ffffff',
            }
          : undefined,
      },
    };
  }

  private buildOrderMarkerFromOrder(order: OrderRow): MapPoint | null {
    const maps = this.getMaps();
    const lat = this.toNumber(order?.fromLat) ?? this.toNumber(order?.toLat);
    const lng = this.toNumber(order?.fromLng) ?? this.toNumber(order?.toLng);
    if (lat == null || lng == null) return null;
    const idBase = order.orderId ?? order.dispatchId ?? order.orderNo;
    return {
      id: `order-${idBase}`,
      type: 'orders',
      position: { lat, lng },
      label: 'ORD',
      title: order.orderNo,
      options: {
        icon: maps
          ? {
              url:
                'data:image/svg+xml;charset=UTF-8,' +
                encodeURIComponent(
                  `<svg xmlns="http://www.w3.org/2000/svg" width="28" height="34" viewBox="0 0 28 34"><path d="M14 0C6.27 0 0 6.27 0 14c0 10.5 14 20 14 20s14-9.5 14-20C28 6.27 21.73 0 14 0z" fill="%23f97316"/><text x="14" y="18" font-size="10" text-anchor="middle" fill="white" font-family="Arial" font-weight="700">ORD</text></svg>`,
                ),
              scaledSize: new maps.Size(28, 34),
            }
          : undefined,
      },
    };
  }

  private buildOrderMarkerFromDispatch(dispatch: Dispatch): MapPoint | null {
    const maps = this.getMaps();
    const lat = this.toNumber(dispatch.pickupLat) ?? this.toNumber(dispatch.dropoffLat);
    const lng = this.toNumber(dispatch.pickupLng) ?? this.toNumber(dispatch.dropoffLng);
    if (lat == null || lng == null) return null;
    return {
      id: `dispatch-${dispatch.id}`,
      type: 'orders',
      position: { lat, lng },
      label: 'DSP',
      title: dispatch.routeCode || dispatch.tripNo || `Dispatch ${dispatch.id}`,
      options: {
        icon: maps
          ? {
              url:
                'data:image/svg+xml;charset=UTF-8,' +
                encodeURIComponent(
                  `<svg xmlns="http://www.w3.org/2000/svg" width="28" height="34" viewBox="0 0 28 34"><path d="M14 0C6.27 0 0 6.27 0 14c0 10.5 14 20 14 20s14-9.5 14-20C28 6.27 21.73 0 14 0z" fill="%230EA5E9"/><text x="14" y="18" font-size="10" text-anchor="middle" fill="white" font-family="Arial" font-weight="700">DSP</text></svg>`,
                ),
              scaledSize: new maps.Size(28, 34),
            }
          : undefined,
      },
    };
  }

  fitMapToMarkers(): void {
    if (!this.map || !this.visibleMarkers.length) return;
    const bounds = new google.maps.LatLngBounds();
    this.visibleMarkers.forEach((m) => bounds.extend(m.position));
    this.map.fitBounds(bounds, 40);
  }

  private driverColor(status?: string): string {
    const s = (status || '').toUpperCase();
    if (s.includes('TRANSIT')) return '#2563eb';
    if (s.includes('ASSIGNED')) return '#f59e0b';
    if (s.includes('IDLE') || s.includes('AVAILABLE')) return '#16a34a';
    return '#6b7280';
  }

  private toNumber(value: number | string | undefined | null): number | null {
    if (value === null || value === undefined) return null;
    const n = typeof value === 'string' ? Number(value) : value;
    return Number.isFinite(n) ? n : null;
  }

  /**
   * Build a full address string from address object
   */
  private buildFullAddress(address: any): string {
    if (!address) return '—';
    const parts: string[] = [];
    if (address.name) parts.push(address.name);
    if (address.address) parts.push(address.address);
    if (address.city) parts.push(address.city);
    if (address.country) parts.push(address.country);
    return parts.length > 0 ? parts.join(', ') : '—';
  }

  /**
   * Get relative date label (Today, Tomorrow, Yesterday, etc.)
   */
  getRelativeDate(dateStr?: string): string {
    if (!dateStr) return '';
    const date = this.parseDate(dateStr);
    if (!date) return '';

    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const targetDate = new Date(date);
    targetDate.setHours(0, 0, 0, 0);

    const diffTime = targetDate.getTime() - today.getTime();
    const diffDays = Math.round(diffTime / (1000 * 60 * 60 * 24));

    if (diffDays === 0) return 'Today';
    if (diffDays === 1) return 'Tomorrow';
    if (diffDays === -1) return 'Yesterday';
    if (diffDays > 1 && diffDays <= 7) return `In ${diffDays} days`;
    if (diffDays < -1 && diffDays >= -7) return `${Math.abs(diffDays)} days ago`;
    if (diffDays < -7) return 'Overdue';
    return '';
  }

  /**
   * Get CSS class for date urgency
   */
  getDateClass(dateStr?: string): string {
    if (!dateStr) return '';
    const date = this.parseDate(dateStr);
    if (!date) return '';

    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const targetDate = new Date(date);
    targetDate.setHours(0, 0, 0, 0);

    const diffTime = targetDate.getTime() - today.getTime();
    const diffDays = Math.round(diffTime / (1000 * 60 * 60 * 24));

    if (diffDays < 0) return 'date-overdue';
    if (diffDays === 0) return 'date-today';
    if (diffDays === 1) return 'date-tomorrow';
    if (diffDays <= 3) return 'date-soon';
    return '';
  }

  private getMaps(): typeof google.maps | null {
    return typeof google !== 'undefined' && (google as any).maps ? (google as any).maps : null;
  }

  private buildDispatchPayload(order: TransportOrder): Dispatch {
    const pickup = order.pickupAddress;
    const dropoff = order.dropAddress;
    const driver = this.selectedDriver!;
    const vehicle = driver.assignedVehicle;
    const nowIso = new Date().toISOString();
    return {
      showMenu: false,
      transportOrder: order,
      id: undefined,
      routeCode: order.orderReference || order.tripNo || `ORDER-${order.id}`,
      tripNo: order.tripNo || order.orderReference,
      startTime: nowIso,
      estimatedArrival: this.asDateString(order.deliveryDate || order.createDate || nowIso),
      expectedDelivery: this.asDateString(order.deliveryDate || nowIso),
      status: 'ASSIGNED' as any,
      tripType: 'STANDARD',
      transportOrderId: order.id,
      orderReference: order.orderReference || String(order.id),
      customerId: (order.customerId as unknown as number) || undefined,
      customerName: order.customerName,
      driverId: driver.id,
      driverName: driver.name || driver.fullName || '',
      driverPhone: driver.phone || '',
      vehicleId: vehicle?.id || driver.assignedVehicleId || 0,
      licensePlate: vehicle?.licensePlate || driver.assignedVehicle?.licensePlate || '',
      createdBy: 0,
      createdByUsername: 'dispatcher',
      createdDate: nowIso,
      updatedDate: nowIso,
      pickupName: pickup?.address || '',
      pickupLocation: pickup?.address || '',
      pickupLat: pickup?.latitude || undefined,
      pickupLng: pickup?.longitude || undefined,
      dropoffName: dropoff?.address || '',
      dropoffLocation: dropoff?.address || '',
      dropoffLat: dropoff?.latitude || undefined,
      dropoffLng: dropoff?.longitude || undefined,
      stops: [],
      items: [],
    };
  }

  private asDateString(value: string | number | Date | undefined | null): string {
    if (!value) return new Date().toISOString();
    const parsed = this.parseDate(value);
    if (!parsed) return new Date().toISOString();
    return parsed.toISOString();
  }

  private parseDate(value: string | number | Date | undefined | null): Date | null {
    if (value === null || value === undefined) return null;
    if (value instanceof Date) return Number.isNaN(value.getTime()) ? null : value;
    if (typeof value === 'number') {
      const d = new Date(value);
      return Number.isNaN(d.getTime()) ? null : d;
    }
    const s = String(value);
    const parts = s.split(',').map((p) => Number(p.trim()));
    if (parts.length >= 3 && parts.every((n) => Number.isFinite(n))) {
      const [year, month, day, hour = 0, minute = 0, second = 0] = parts;
      const d = new Date(year, month - 1, day, hour, minute, second);
      return Number.isNaN(d.getTime()) ? null : d;
    }
    const d = new Date(s);
    return Number.isNaN(d.getTime()) ? null : d;
  }

  private formatDateTime(value?: string | number | Date | null): string {
    const d = this.parseDate(value ?? null);
    if (!d) return '';
    return d.toLocaleString(undefined, {
      year: 'numeric',
      month: 'short',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
    });
  }

  startVerticalDrag(event: MouseEvent): void {
    this.isVerticalDragging = true;
    this.leftPanelTop = this.leftPanelRef?.nativeElement.getBoundingClientRect().top ?? 0;
    event.preventDefault();
  }

  // ===== File Action Methods =====

  /**
   * View/open order files in a new window or modal
   */
  viewOrderFiles(order: OrderRow): void {
    if (!order.orderId) {
      this.toastr.error('Order ID not found');
      return;
    }

    if (!order.fileCount || order.fileCount === 0) {
      this.toastr.info('No files attached to this order.');
      return;
    }

    // Navigate to order detail page to view files
    window.open(`/orders/${order.orderId}`, '_blank');
  }

  /**
   * Download order proof/attachment
   */
  downloadProof(order: OrderRow, event: Event): void {
    event.stopPropagation();

    if (!order.fileProofUrl) {
      this.toastr.info('No proof file available for download.');
      return;
    }

    // Create download link and trigger
    const link = document.createElement('a');
    link.href = order.fileProofUrl;
    link.target = '_blank';
    link.download = `proof-${order.orderNo}.pdf`;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  }

  /**
   * Upload proof/attachment for order
   */
  uploadProof(order: OrderRow, event: Event): void {
    event.stopPropagation();

    if (!order.orderId) {
      this.toastr.error('Order ID not found');
      return;
    }

    // Navigate to order detail page to upload proof
    window.open(`/orders/${order.orderId}?tab=proofs`, '_blank');
  }

  /**
   * Get status badge CSS class for styling
   */
  getStatusClass(status?: string): string {
    if (!status) return 'status-default';
    const s = status.toUpperCase();
    switch (s) {
      case 'PENDING':
        return 'status-pending';
      case 'CONFIRMED':
        return 'status-confirmed';
      case 'CANCELLED':
        return 'status-cancelled';
      case 'COMPLETED':
        return 'status-completed';
      default:
        return 'status-default';
    }
  }

  /**
   * Toggle action menu dropdown
   */
  toggleActionMenu(orderId: number, event: Event): void {
    event.stopPropagation();
    this.openMenuOrderId = this.openMenuOrderId === orderId ? null : orderId;
  }

  /**
   * Close action menu when clicking outside
   */
  @HostListener('document:click', ['$event'])
  closeActionMenu(event: Event): void {
    this.openMenuOrderId = null;
  }

  /**
   * Update Status action
   */
  updateStatus(order: OrderRow, event: Event): void {
    event.stopPropagation();
    this.openMenuOrderId = null;

    if (!order.orderId) {
      this.toastr.error('Order ID not found');
      return;
    }

    // Navigate to order detail page to update status
    window.open(`/orders/${order.orderId}`, '_blank');
  }

  /**
   * Safety Check action
   */
  safetyCheck(order: OrderRow, event: Event): void {
    event.stopPropagation();
    this.openMenuOrderId = null;

    if (!order.orderId) {
      this.toastr.error('Order ID not found');
      return;
    }

    // Navigate to safety check page/modal
    // TODO: Implement safety check workflow
    window.open(`/orders/${order.orderId}?tab=safety-check`, '_blank');
  }

  /**
   * Update order action
   */
  updateOrder(order: OrderRow, event: Event): void {
    event.stopPropagation();
    this.openMenuOrderId = null;

    if (!order.orderId) {
      this.toastr.error('Order ID not found');
      return;
    }

    // Navigate to order edit page
    window.open(`/orders/${order.orderId}/edit`, '_blank');
  }

  /**
   * Picking List action
   */
  pickingList(order: OrderRow, event: Event): void {
    event.stopPropagation();
    this.openMenuOrderId = null;

    if (!order.orderId) {
      this.notification.simulateNotification('Notice', 'Order ID not found');
      return;
    }

    // Navigate to picking list page or download PDF
    window.open(`/orders/${order.orderId}/picking-list`, '_blank');
  }
}
