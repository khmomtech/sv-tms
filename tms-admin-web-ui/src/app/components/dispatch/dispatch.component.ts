import { CommonModule } from '@angular/common';
import type { OnInit } from '@angular/core';
import { Component, ViewChild } from '@angular/core';
import type {
  FormGroup,
  FormArray,
  AbstractControl,
  ValidatorFn,
  ValidationErrors,
} from '@angular/forms';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { FormBuilder } from '@angular/forms';
import { Validators, FormsModule, ReactiveFormsModule } from '@angular/forms';
import { GoogleMap, GoogleMapsModule } from '@angular/google-maps';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { ActivatedRoute } from '@angular/router';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { ToastrService } from 'ngx-toastr';

import type { Dispatch } from '../../models/dispatch.model';
import type { Driver } from '../../models/driver.model';
import type { TransportOrder } from '../../models/transport-order.model';
import type { Vehicle } from '../../models/vehicle.model';
import { SvSafeDatePipe } from '../../pipes/sv-safe-date.pipe';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { ConfirmService } from '../../services/confirm.service';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { DispatchService } from '../../services/dispatch.service';
import { AppDriverModalComponent } from '../app-driver-modal/app-driver-modal.component';
import { AppOrderModalComponent } from '../app-order-modal/app-order-modal.component';
import { AppVehicleModalComponent } from '../app-vehicle-modal/app-vehicle-modal.component';

import { DispatchFormComponent } from './dispatch-form.component';

@Component({
  selector: 'app-dispatch',
  templateUrl: './dispatch.component.html',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    ReactiveFormsModule,
    GoogleMapsModule,
    AppOrderModalComponent,
    AppDriverModalComponent,
    AppVehicleModalComponent,
    DispatchFormComponent,
    SvSafeDatePipe,
  ],
  styleUrls: ['./dispatch.component.css'],
})
export class DispatchComponent implements OnInit {
  @ViewChild(GoogleMap) map!: GoogleMap;
  mapReady = false;
  pendingZoomToFit = false;

  dispatchForm!: FormGroup;
  selectedOrder: TransportOrder | null = null;
  selectedDriver: Driver | null = null;
  selectedVehicle: Vehicle | null = null;
  existingDispatch: Dispatch | null = null;
  isFormReady: boolean = false;

  showOrderModal = false;
  showDriverModal = false;
  showVehicleModal = false;
  showTripForm = false;

  mapCenter: google.maps.LatLngLiteral = { lat: 11.5564, lng: 104.9282 };
  stops: any[] = [];
  directions: google.maps.DirectionsResult | null = null;
  fallbackPath: google.maps.LatLngLiteral[] = [];
  routeDistanceText = '-';
  routeDurationText = '-';
  routeLegSummaries: Array<{
    from: string;
    to: string;
    distance: string;
    duration: string;
  }> = [];
  infoWindowContent = '';
  infoWindowPosition?: google.maps.LatLngLiteral;
  showInfoWindow = false;

  panelWidth = 800;
  isResizing = false;

  allDispatchMarkers: {
    coordinates: string;
    type: string;
    label: string;
    info: string;
  }[] = [];

  constructor(
    private fb: FormBuilder,
    private dispatchService: DispatchService,
    private route: ActivatedRoute,
    private readonly toastr: ToastrService,
    private readonly confirm: ConfirmService,
  ) {}

  ngOnInit(): void {
    this.initForm();
    this.route.queryParams.subscribe((params) => {
      const orderId = +params['orderId'];
      if (orderId) this.loadOrder(orderId);
    });
  }

  initForm(): void {
    this.dispatchForm = this.fb.group({
      manualRouteCode: [''],
      tripType: ['STANDARD', Validators.required],
      startTime: ['', Validators.required],
      estimatedArrival: ['', Validators.required],
      status: ['PLANNED', Validators.required],
      transportOrderId: [null, Validators.required],
      driverId: [null, Validators.required],
      vehicleId: [null, Validators.required],
      cancelReason: [''],
      stops: this.fb.array([]),
    });
  }

  get stopsFormArray(): FormArray {
    return this.dispatchForm.get('stops') as FormArray;
  }

  minStopsValidator(min: number): ValidatorFn {
    return (control: AbstractControl): ValidationErrors | null => {
      const formArray = control as FormArray;
      return formArray.length >= min ? null : { minStops: true };
    };
  }

  openNewTripForm(): void {
    this.resetForm();
    this.stopsFormArray.clear();
    this.stops = [];

    const defaultStop = {
      coordinates: '11.5564,104.9282',
      stopSequence: `S1`,
      label: `Stop 1`,
      type: 'dropoff',
      location: 'Default Location',
      note: '',
    };

    // this.stops.push(defaultStop);
    // this.addStop(defaultStop);

    this.showTripForm = true;
    setTimeout(() => {
      this.isFormReady = true;
    }, 0);
  }

  handleSubmit(data: any): void {
    // Validate required fields before submission
    if (!data.transportOrderId) {
      this.toastr.error('Please select a transport order');
      return;
    }
    if (!data.driverId) {
      this.toastr.error('Please select a driver');
      return;
    }
    if (!data.vehicleId) {
      this.toastr.error('Please select a vehicle');
      return;
    }
    if (!data.startTime) {
      this.toastr.error('Please set start time');
      return;
    }
    if (!data.estimatedArrival) {
      this.toastr.error('Please set estimated arrival time');
      return;
    }

    // Transform stops data to match backend DTO structure
    const payload = {
      ...data,
      stops:
        data.stops?.map((stop: any, index: number) => ({
          stopSequence: index + 1,
          locationName: stop.label || stop.location || `Stop ${index + 1}`,
          address: stop.location || '',
          coordinates: stop.coordinates || '',
          arrivalTime: null,
          departureTime: null,
          isCompleted: false,
        })) || [],
    };

    const isEditing = !!this.existingDispatch?.id;
    const request$ = isEditing
      ? this.dispatchService.updateDispatch(this.existingDispatch!.id!, payload)
      : this.dispatchService.createDispatch(payload);

    request$.subscribe({
      next: () => {
        this.toastr.success(
          isEditing ? 'Dispatch updated successfully!' : 'Dispatch created successfully!',
        );
        this.handleCancel();
      },
      error: (err) => {
        console.error(isEditing ? 'Dispatch update failed:' : 'Dispatch creation failed:', err);
        let errorMessage = isEditing ? 'Failed to update dispatch' : 'Failed to create dispatch';

        const fieldErrors = err.error?.fieldErrors || err.error?.errors;
        if (fieldErrors) {
          const errors = Object.entries(fieldErrors)
            .map(([field, msg]) => `${field}: ${msg}`)
            .join(', ');
          errorMessage = errors;
        } else if (err.error?.message) {
          errorMessage = err.error.message;
        } else if (err.status === 400) {
          errorMessage = 'Invalid data provided. Please check all fields.';
        }

        this.toastr.error(errorMessage);
      },
    });
  }

  handleCancel(): void {
    this.resetForm();
    this.showTripForm = false;
    this.isFormReady = false;
    this.refreshCurrentOrder();
  }

  resetForm(): void {
    this.initForm();
    this.selectedDriver = null;
    this.selectedVehicle = null;
    this.existingDispatch = null;
    this.stops = [];
    this.directions = null;
    this.fallbackPath = [];
    this.resetRouteSummary();
  }

  addStop(stop: any): void {
    // Parse coordinates to get latitude and longitude if not already provided
    let latitude = stop.latitude;
    let longitude = stop.longitude;

    if (!latitude || !longitude) {
      if (stop.coordinates) {
        const [lat, lng] = stop.coordinates.split(',').map(Number);
        if (!isNaN(lat) && !isNaN(lng)) {
          latitude = lat;
          longitude = lng;
        }
      }
    }

    this.stopsFormArray.push(
      this.fb.group({
        coordinates: [stop.coordinates, Validators.required],
        stopSequence: [stop.stopSequence],
        label: [stop.label],
        type: [stop.type || 'dropoff'],
        location: [stop.location],
        latitude: [latitude],
        longitude: [longitude],
        note: [stop.note || ''],
      }),
    );
    this.updateStopOrder();
    this.loadRoutePath();
  }

  updateStopOrder(): void {
    this.stops.forEach((s, i) => (s.stopSequence = `S${i + 1}`));
  }

  onMapClick(event: google.maps.MapMouseEvent): void {
    const latLng = event.latLng?.toJSON();
    if (!latLng) return;

    const stop = {
      coordinates: `${latLng.lat},${latLng.lng}`,
      latitude: latLng.lat,
      longitude: latLng.lng,
      stopSequence: `S${this.stops.length + 1}`,
      label: `Stop ${this.stops.length + 1}`,
      type: 'dropoff',
      location: 'Map Selection',
    };
    this.stops.push(stop);
    this.addStop(stop);
  }

  parseCoordinates(coords: string): google.maps.LatLngLiteral {
    return this.parseCoordinatesSafe(coords) || this.mapCenter;
  }

  getStopPosition(stop: any): google.maps.LatLngLiteral | null {
    if (!stop) return null;
    return (
      this.parseCoordinatesSafe(stop.coordinates) ||
      this.toValidLatLng(stop.latitude, stop.longitude)
    );
  }

  getDispatchMarkerPosition(marker: any): google.maps.LatLngLiteral | null {
    if (!marker) return null;
    return this.parseCoordinatesSafe(marker.coordinates);
  }

  loadRoutePath(): void {
    if (!(window as any).google?.maps?.DirectionsService) {
      this.directions = null;
      this.fallbackPath = [];
      this.resetRouteSummary();
      return;
    }

    if (this.stops.length < 2) {
      this.directions = null;
      this.fallbackPath = [];
      this.resetRouteSummary();
      return;
    }

    const validStops = this.stops
      .map((stop) => ({ stop, pos: this.getStopPosition(stop) }))
      .filter((x) => !!x.pos) as Array<{ stop: any; pos: google.maps.LatLngLiteral }>;

    if (validStops.length < 2) {
      console.warn('Cannot calculate route: Some stops have invalid or missing coordinates');
      this.directions = null;
      this.fallbackPath = [];
      this.resetRouteSummary();
      return;
    }

    // Always keep a fallback polyline across all stops (in order).
    this.fallbackPath = validStops.map((x) => x.pos);

    const origin = validStops[0].pos;
    const destination = validStops[validStops.length - 1].pos;
    const waypoints = validStops.slice(1, -1).map((x) => ({
      location: x.pos,
      stopover: true,
    }));

    const service = new google.maps.DirectionsService();
    service.route(
      {
        origin: origin!,
        destination: destination!,
        waypoints,
        travelMode: google.maps.TravelMode.DRIVING,
      },
      (res, status) => {
        if (status === 'OK') {
          this.directions = res;
          if (res) {
            this.updateRouteSummary(res);
          } else {
            this.resetRouteSummary();
          }
        } else {
          console.warn(
            `Directions API returned ${status} - this is normal if coordinates are not routable by car`,
          );
          this.directions = null;
          // Keep fallbackPath visible when street routing is unavailable.
          this.resetRouteSummary();
        }
      },
    );
  }

  selectStop(stop: any): void {
    const coords = this.getStopPosition(stop);
    if (coords) {
      this.infoWindowContent = `${stop.label}: ${stop.location}`;
      this.infoWindowPosition = coords;
      this.showInfoWindow = true;
    }
  }

  getMarkerOptions(type: string): google.maps.MarkerOptions {
    return {
      icon: {
        url:
          type === 'pickup'
            ? 'https://maps.google.com/mapfiles/ms/icons/green-dot.png'
            : 'https://maps.google.com/mapfiles/ms/icons/red-dot.png',
        scaledSize: new google.maps.Size(32, 32),
      },
    };
  }

  zoomToFit(): void {
    if (!this.stops.length && !this.allDispatchMarkers.length) return;

    if (!this.mapReady || !this.map?.googleMap) {
      this.pendingZoomToFit = true;
      return;
    }

    const bounds = new google.maps.LatLngBounds();
    this.stops.forEach((s) => {
      const c = this.getStopPosition(s);
      if (c) bounds.extend(c);
    });
    this.allDispatchMarkers.forEach((m) => {
      const c = this.getDispatchMarkerPosition(m);
      if (c) bounds.extend(c);
    });
    if (bounds.isEmpty()) return;
    this.map.fitBounds(bounds);
  }

  onMapInitialized(): void {
    this.mapReady = true;
    if (this.pendingZoomToFit) {
      this.pendingZoomToFit = false;
      setTimeout(() => this.zoomToFit(), 0);
    }
  }

  startResizing(event: MouseEvent): void {
    this.isResizing = true;
    document.addEventListener('mousemove', this.resizePanel);
    document.addEventListener('mouseup', this.stopResizing);
  }

  resizePanel = (event: MouseEvent): void => {
    if (!this.isResizing) return;
    const screenWidth = window.innerWidth;
    this.panelWidth = Math.min(Math.max(screenWidth - event.clientX, 480), 1200);
  };

  stopResizing = (): void => {
    this.isResizing = false;
    document.removeEventListener('mousemove', this.resizePanel);
    document.removeEventListener('mouseup', this.stopResizing);
  };

  openOrderModal(): void {
    this.showOrderModal = true;
  }
  openDriverModal(): void {
    this.showDriverModal = true;
  }
  openVehicleModal(): void {
    this.showVehicleModal = true;
  }

  selectOrder(order: TransportOrder): void {
    this.selectedOrder = order;
    this.dispatchForm.patchValue({ transportOrderId: order.id });
    this.showOrderModal = false;

    this.stops = this.normalizeOrderStops(order);
    this.applyStopsToMap(this.stops);

    // Fallback when backend sends invalid coordinates (e.g., 0,0):
    // geocode pickup/drop addresses so markers and route can still render.
    if (this.stops.length < 2) {
      const currentOrderId = order.id;
      this.resolveOrderStopsFromAddress(order).then((resolvedStops) => {
        if (this.selectedOrder?.id !== currentOrderId || resolvedStops.length === 0) {
          return;
        }
        this.stops = resolvedStops;
        this.applyStopsToMap(this.stops);
      });
    }
  }

  selectDriver(driver: Driver): void {
    this.selectedDriver = driver;
    this.dispatchForm.patchValue({ driverId: driver.id });
    this.showDriverModal = false;
  }

  selectVehicle(vehicle: Vehicle): void {
    this.selectedVehicle = vehicle;
    this.dispatchForm.patchValue({ vehicleId: vehicle.id });
    this.showVehicleModal = false;
  }

  async deleteTrip(tripId: number): Promise<void> {
    const ok = await this.confirm.confirm('Are you sure you want to delete this trip?');
    if (!ok) return;
    this.dispatchService.deleteDispatch(tripId).subscribe({
      next: () => {
        this.toastr.success('Trip deleted successfully.');
        if (this.selectedOrder?.id) this.loadOrder(this.selectedOrder.id);
      },
      error: (err) => {
        console.error('Failed to delete trip:', err);
      },
    });
  }

  editTrip(trip: Dispatch): void {
    if (!trip?.id) {
      this.openEditDrawer(trip);
      return;
    }

    this.dispatchService.getDispatchById(trip.id).subscribe({
      next: (res) => this.openEditDrawer((res?.data as Dispatch) || trip),
      error: () => this.openEditDrawer(trip),
    });
  }

  loadOrder(orderId: number): void {
    this.dispatchService.getOrderById(orderId).subscribe({
      next: (order) => this.selectOrder(order),
      error: (err) => console.error('Failed to load order:', err),
    });
  }

  private refreshCurrentOrder(): void {
    const selectedOrderId = this.selectedOrder?.id;
    if (selectedOrderId) {
      this.loadOrder(selectedOrderId);
      return;
    }

    const queryOrderId = Number(this.route.snapshot.queryParamMap.get('orderId'));
    if (!isNaN(queryOrderId) && queryOrderId > 0) {
      this.loadOrder(queryOrderId);
    }
  }

  private openEditDrawer(trip: Dispatch): void {
    this.existingDispatch = trip;
    this.dispatchForm.patchValue({
      manualRouteCode: trip.routeCode || '',
      startTime: this.toDateTimeLocalString(trip.startTime),
      estimatedArrival: this.toDateTimeLocalString(trip.estimatedArrival),
      status: trip.status || 'PLANNED',
      transportOrderId: trip.transportOrderId || this.selectedOrder?.id || null,
      driverId: trip.driverId || null,
      vehicleId: trip.vehicleId || null,
      tripType: this.normalizeTripType(trip.tripType),
      cancelReason: trip.cancelReason || '',
    });

    this.selectedDriver = trip.driverId
      ? ({ id: trip.driverId, name: trip.driverName || `Driver #${trip.driverId}` } as Driver)
      : null;

    this.selectedVehicle = trip.vehicleId
      ? ({
          id: trip.vehicleId,
          licensePlate: trip.licensePlate || `Vehicle #${trip.vehicleId}`,
        } as Vehicle)
      : null;

    this.stopsFormArray.clear();
    this.stops = this.normalizeDispatchStops(trip.stops);
    this.stops.forEach((s) => this.addStop(s));

    this.showTripForm = true;
    this.isFormReady = false;
    setTimeout(() => {
      this.isFormReady = true;
      this.loadRoutePath();
      this.zoomToFit();
    }, 0);
  }

  private normalizeDispatchStops(rawStops?: any[]): any[] {
    if (!Array.isArray(rawStops)) return [];

    return rawStops
      .map((stop: any, index: number) => {
        const lat = Number(stop?.latitude ?? stop?.lat);
        const lng = Number(stop?.longitude ?? stop?.lng);
        const hasValidLatLng = !isNaN(lat) && !isNaN(lng);
        const coordinates =
          typeof stop?.coordinates === 'string' && stop.coordinates.trim()
            ? stop.coordinates.trim()
            : hasValidLatLng
              ? `${lat},${lng}`
              : '';
        const typeUpper = String(stop?.type || 'DROPOFF').toUpperCase();
        const isPickup = typeUpper === 'PICKUP';

        return {
          coordinates,
          latitude: hasValidLatLng ? lat : null,
          longitude: hasValidLatLng ? lng : null,
          stopSequence: stop?.stopSequence || `${isPickup ? 'P' : 'D'}${index + 1}`,
          label:
            stop?.label ||
            stop?.locationName ||
            stop?.location ||
            `${isPickup ? 'Pickup' : 'Dropoff'} ${index + 1}`,
          type: isPickup ? 'pickup' : 'dropoff',
          location: stop?.location || stop?.locationName || stop?.address || '',
          note: stop?.note || '',
        };
      })
      .filter((s) => !!s.coordinates);
  }

  private normalizeTripType(type: unknown): string {
    const normalized = String(type || 'STANDARD').toUpperCase();
    return normalized === 'URGENT' ? 'URGENT' : 'STANDARD';
  }

  private toDateTimeLocalString(value: unknown): string {
    if (!value) return '';
    const date = value instanceof Date ? value : new Date(String(value));
    if (isNaN(date.getTime())) return '';
    const offsetMinutes = date.getTimezoneOffset();
    const localDate = new Date(date.getTime() - offsetMinutes * 60 * 1000);
    return localDate.toISOString().slice(0, 16);
  }

  plotAllDispatches(): void {
    this.allDispatchMarkers = [];

    if (!this.selectedOrder?.dispatches?.length) return;

    this.selectedOrder.dispatches.forEach((dispatch) => {
      dispatch.stops?.forEach((stop: any, stopIndex: number) => {
        const pos =
          this.toValidLatLng(stop?.latitude ?? stop?.lat, stop?.longitude ?? stop?.lng) ||
          this.parseCoordinatesSafe(stop?.coordinates);
        if (!pos) return;
        const typeUpper = String(stop?.type || '').toUpperCase();
        const isPickup = typeUpper === 'PICKUP';
        this.allDispatchMarkers.push({
          coordinates: `${pos.lat},${pos.lng}`,
          type: isPickup ? 'pickup' : 'dropoff',
          label: `${isPickup ? 'P' : 'D'}${stopIndex + 1}`,
          info: `${dispatch.routeCode || 'Dispatch'} - ${stop?.location || stop?.locationName || stop?.address || '-'}`,
        });
      });
    });
  }
  selectDispatchMarker(marker: any): void {
    const coords = this.getDispatchMarkerPosition(marker);
    if (coords) {
      this.infoWindowContent = marker.info;
      this.infoWindowPosition = coords;
      this.showInfoWindow = true;
    }
  }

  private normalizeOrderStops(order: TransportOrder): any[] {
    const normalized: any[] = [];
    if (Array.isArray(order?.stops) && order.stops.length > 0) {
      const sortedStops = [...order.stops].sort((a, b) => (a.sequence || 0) - (b.sequence || 0));
      sortedStops.forEach((stop, index) => {
        const pos = this.toValidLatLng(stop?.address?.latitude, stop?.address?.longitude);
        if (!pos) return;
        const isPickup = String(stop?.type || '').toUpperCase() === 'PICKUP';
        normalized.push({
          coordinates: `${pos.lat},${pos.lng}`,
          latitude: pos.lat,
          longitude: pos.lng,
          stopSequence: `${isPickup ? 'P' : 'D'}${index + 1}`,
          label: isPickup ? 'Pickup' : 'Dropoff',
          type: isPickup ? 'pickup' : 'dropoff',
          location: stop?.address?.name || stop?.address?.address || '',
          note: stop?.remarks || '',
        });
      });
    }

    if (normalized.length === 0) {
      const pickup = this.toValidLatLng(
        order?.pickupAddress?.latitude,
        order?.pickupAddress?.longitude,
      );
      if (pickup) {
        normalized.push({
          coordinates: `${pickup.lat},${pickup.lng}`,
          latitude: pickup.lat,
          longitude: pickup.lng,
          stopSequence: 'P1',
          label: 'Pickup',
          type: 'pickup',
          location: order?.pickupAddress?.name || order?.pickupAddress?.address || 'Pickup',
          note: '',
        });
      }
      const drop = this.toValidLatLng(order?.dropAddress?.latitude, order?.dropAddress?.longitude);
      if (drop) {
        normalized.push({
          coordinates: `${drop.lat},${drop.lng}`,
          latitude: drop.lat,
          longitude: drop.lng,
          stopSequence: 'D1',
          label: 'Dropoff',
          type: 'dropoff',
          location: order?.dropAddress?.name || order?.dropAddress?.address || 'Dropoff',
          note: '',
        });
      }
    }
    return normalized;
  }

  private applyStopsToMap(stops: any[]): void {
    this.stopsFormArray.clear();
    stops.forEach((s) => this.addStop(s));
    this.plotAllDispatches();
    this.loadRoutePath();
    this.zoomToFit();
  }

  private async resolveOrderStopsFromAddress(order: TransportOrder): Promise<any[]> {
    const resolved: any[] = [];
    const pickupQuery = this.buildAddressQuery(order?.pickupAddress);
    const dropQuery = this.buildAddressQuery(order?.dropAddress);

    const [pickupPos, dropPos] = await Promise.all([
      this.geocodeAddress(pickupQuery),
      this.geocodeAddress(dropQuery),
    ]);

    if (pickupPos) {
      resolved.push({
        coordinates: `${pickupPos.lat},${pickupPos.lng}`,
        latitude: pickupPos.lat,
        longitude: pickupPos.lng,
        stopSequence: 'P1',
        label: 'Pickup',
        type: 'pickup',
        location: order?.pickupAddress?.name || order?.pickupAddress?.address || 'Pickup',
        note: 'Geocoded from address',
      });
    }

    if (dropPos) {
      resolved.push({
        coordinates: `${dropPos.lat},${dropPos.lng}`,
        latitude: dropPos.lat,
        longitude: dropPos.lng,
        stopSequence: 'D1',
        label: 'Dropoff',
        type: 'dropoff',
        location: order?.dropAddress?.name || order?.dropAddress?.address || 'Dropoff',
        note: 'Geocoded from address',
      });
    }

    return resolved;
  }

  private buildAddressQuery(address: any): string {
    if (!address) return '';
    return String(address.address || address.name || '').trim();
  }

  private geocodeAddress(query: string): Promise<google.maps.LatLngLiteral | null> {
    if (!query) return Promise.resolve(null);
    const googleMaps = (window as any).google?.maps;
    if (!googleMaps?.Geocoder) return Promise.resolve(null);

    const geocoder = new googleMaps.Geocoder();
    return new Promise((resolve) => {
      geocoder.geocode({ address: query }, (results: any, status: google.maps.GeocoderStatus) => {
        if (status === 'OK' && results?.length) {
          const location = results[0].geometry?.location;
          if (location) {
            const pos = this.toValidLatLng(location.lat(), location.lng());
            resolve(pos);
            return;
          }
        }
        resolve(null);
      });
    });
  }

  private parseCoordinatesSafe(coords: unknown): google.maps.LatLngLiteral | null {
    const [lat, lng] = String(coords || '')
      .split(',')
      .map((v) => Number(v?.trim()));
    return this.toValidLatLng(lat, lng);
  }

  private toValidLatLng(latInput: unknown, lngInput: unknown): google.maps.LatLngLiteral | null {
    const lat = Number(latInput);
    const lng = Number(lngInput);
    if (!Number.isFinite(lat) || !Number.isFinite(lng)) return null;
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return null;
    if (lat === 0 && lng === 0) return null;
    return { lat, lng };
  }

  openRouteInGoogleMaps(): void {
    const validStops = this.stops
      .map((stop) => this.getStopPosition(stop))
      .filter((pos): pos is google.maps.LatLngLiteral => !!pos);

    if (validStops.length < 2) {
      this.toastr.info(
        'Need at least pickup and dropoff coordinates to open route in Google Maps.',
      );
      return;
    }

    const origin = `${validStops[0].lat},${validStops[0].lng}`;
    const destination = `${validStops[validStops.length - 1].lat},${validStops[validStops.length - 1].lng}`;
    const waypoints = validStops
      .slice(1, -1)
      .map((pos) => `${pos.lat},${pos.lng}`)
      .join('|');

    const params = new URLSearchParams({
      api: '1',
      origin,
      destination,
      travelmode: 'driving',
    });
    if (waypoints) params.set('waypoints', waypoints);

    window.open(`https://www.google.com/maps/dir/?${params.toString()}`, '_blank', 'noopener');
  }

  private updateRouteSummary(result: google.maps.DirectionsResult): void {
    const route = result?.routes?.[0];
    if (!route?.legs?.length) {
      this.resetRouteSummary();
      return;
    }

    const totalMeters = route.legs.reduce((sum, leg) => sum + (leg.distance?.value || 0), 0);
    const totalSeconds = route.legs.reduce((sum, leg) => sum + (leg.duration?.value || 0), 0);

    this.routeDistanceText =
      totalMeters >= 1000
        ? `${(totalMeters / 1000).toFixed(1)} km`
        : `${Math.round(totalMeters)} m`;

    const hours = Math.floor(totalSeconds / 3600);
    const minutes = Math.round((totalSeconds % 3600) / 60);
    this.routeDurationText = hours > 0 ? `${hours}h ${minutes}m` : `${minutes} min`;

    this.routeLegSummaries = route.legs.map((leg) => ({
      from: leg.start_address || 'Start',
      to: leg.end_address || 'End',
      distance: leg.distance?.text || '-',
      duration: leg.duration?.text || '-',
    }));
  }

  private resetRouteSummary(): void {
    this.routeDistanceText = '-';
    this.routeDurationText = '-';
    this.routeLegSummaries = [];
  }
}
