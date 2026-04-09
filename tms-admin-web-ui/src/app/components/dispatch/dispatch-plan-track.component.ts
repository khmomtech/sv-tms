import { CommonModule } from '@angular/common';
import type { OnInit, AfterViewInit } from '@angular/core';
import { Component, ViewChild, HostListener } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { GoogleMap, GoogleMapsModule } from '@angular/google-maps';

import { PagedResponse } from '../../models/api-response-page.model';
import { ApiResponse } from '../../models/api-response.model';
import type { Dispatch } from '../../models/dispatch.model';
import type { Driver } from '../../models/driver.model';
import type { TransportOrder } from '../../models/transport-order.model';
import type { Vehicle } from '../../models/vehicle.model';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { DispatchService } from '../../services/dispatch.service';
import { ConfirmService } from '../../services/confirm.service';
import { ToastrService } from 'ngx-toastr';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { DriverService } from '../../services/driver.service';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { TransportOrderService } from '../../services/transport-order.service';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { VehicleService } from '../../services/vehicle.service';

import { TripPlanningModalComponent } from './modals/trip-planning-modal.component';

@Component({
  selector: 'app-dispatch-plan-track',
  standalone: true,
  imports: [CommonModule, FormsModule, GoogleMapsModule, TripPlanningModalComponent],
  templateUrl: './dispatch-plan-track.component.html',
  styleUrls: ['./dispatch-plan-track.component.css'],
})
export class DispatchPlanTrackComponent implements OnInit, AfterViewInit {
  openOrderMenuId: number | null = null;

  dispatches: Dispatch[] = [];
  drivers: Driver[] = [];
  vehicles: Vehicle[] = [];
  transportOrders: TransportOrder[] = [];
  unscheduledOrders: TransportOrder[] = [];

  showTripModal = false;

  selectedDispatch: Dispatch | null = null;
  selectedOrder: TransportOrder | null = null;

  selectedStatus = '';
  selectedDriver = '';
  searchQuery = '';
  searchUnscheduled = '';

  selectedOrderIds: Set<number> = new Set<number>();

  mapCenter: google.maps.LatLngLiteral = { lat: 11.5564, lng: 104.9282 };
  zoom = 8;

  @ViewChild(GoogleMap) map!: GoogleMap;

  routeMarkers: {
    position: google.maps.LatLngLiteral;
    label: string;
    title: string;
  }[] = [];

  directionsService!: google.maps.DirectionsService;
  directionsRenderer!: google.maps.DirectionsRenderer;

  constructor(
    private dispatchService: DispatchService,
    private driverService: DriverService,
    private vehicleService: VehicleService,
    private transportOrderService: TransportOrderService,
    private readonly toastr: ToastrService,
    private readonly confirmService: ConfirmService,
  ) {}

  ngOnInit(): void {
    this.directionsService = new google.maps.DirectionsService();
    this.directionsRenderer = new google.maps.DirectionsRenderer({
      suppressMarkers: true,
      polylineOptions: { strokeColor: '#007bff', strokeWeight: 4 },
    });
    this.loadAllData();
  }

  ngAfterViewInit(): void {
    if (this.map?.googleMap) {
      this.directionsRenderer.setMap(this.map.googleMap);
    }
  }

  loadAllData(): void {
    this.loadDispatches();
    this.loadDrivers();
    this.loadVehicles();
    this.loadOrders();
    this.loadUnscheduledOrders();
  }

  loadDispatches(): void {
    this.dispatchService.getAllDispatches(0, 100).subscribe({
      next: (res) => (this.dispatches = res.data?.content || []),
      error: (err) => console.error(' Failed to fetch dispatches:', err),
    });
  }

  loadDrivers(): void {
    this.driverService.getAllDrivers().subscribe({
      next: (res) => (this.drivers = res.data?.content || []),
      error: (err) => console.error(' Failed to fetch drivers:', err),
    });
  }

  loadVehicles(): void {
    this.vehicleService.getAllVehicles().subscribe({
      next: (res) => (this.vehicles = res.data || []),
      error: (err) => console.error(' Failed to fetch vehicles:', err),
    });
  }

  loadOrders(): void {
    this.transportOrderService.getOrders().subscribe({
      next: (res) => (this.transportOrders = res.data?.content || []),
      error: (err) => console.error(' Failed to fetch transport orders:', err),
    });
  }

  loadUnscheduledOrders(): void {
    this.transportOrderService.getUnscheduledOrders().subscribe({
      next: (res) => (this.unscheduledOrders = res.data || []),
      error: (err) => console.error(' Failed to fetch unscheduled orders:', err),
    });
  }

  onSelectDispatch(dispatch: Dispatch): void {
    this.selectedDispatch = dispatch;
    this.selectedOrder = null;
    this.drawRoute(
      dispatch.pickupLat,
      dispatch.pickupLng,
      dispatch.dropoffLat,
      dispatch.dropoffLng,
    );
  }

  onSelectOrder(order: TransportOrder): void {
    this.selectedOrder = order;
    this.selectedDispatch = null;
    this.drawRoute(
      order.pickupAddress?.latitude,
      order.pickupAddress?.longitude,
      order.dropAddress?.latitude,
      order.dropAddress?.longitude,
    );
  }

  drawRoute(
    pickupLat?: number,
    pickupLng?: number,
    dropoffLat?: number,
    dropoffLng?: number,
  ): void {
    if (!pickupLat || !pickupLng || !dropoffLat || !dropoffLng) return;

    const origin = new google.maps.LatLng(pickupLat, pickupLng);
    const destination = new google.maps.LatLng(dropoffLat, dropoffLng);

    this.mapCenter = origin.toJSON();
    this.routeMarkers = [
      { position: origin.toJSON(), label: 'P', title: 'Pickup Location' },
      { position: destination.toJSON(), label: 'D', title: 'Drop-off Location' },
    ];

    this.directionsService.route(
      { origin, destination, travelMode: google.maps.TravelMode.DRIVING },
      (result, status) => {
        if (status === 'OK' && result) {
          this.directionsRenderer.setDirections(result);
        } else {
          console.error(' Directions request failed:', status);
        }
      },
    );
  }

  drawSelectedOrderRoutes(): void {
    if (!this.map?.googleMap) return;

    this.directionsRenderer.setMap(null);
    this.routeMarkers = [];

    const bounds = new google.maps.LatLngBounds();
    let count = 1;

    const selectedOrders = this.unscheduledOrders.filter(
      (o) => o.id != null && this.selectedOrderIds.has(o.id),
    );

    for (const order of selectedOrders) {
      const pickup = order.pickupAddress;
      const dropoff = order.dropAddress;

      if (pickup?.latitude && pickup?.longitude && dropoff?.latitude && dropoff?.longitude) {
        const pickupLatLng = { lat: pickup.latitude, lng: pickup.longitude };
        const dropoffLatLng = { lat: dropoff.latitude, lng: dropoff.longitude };

        this.routeMarkers.push(
          {
            position: pickupLatLng,
            label: `P${count}`,
            title: `Pickup ${count} - ${order.customerName}\n${pickupLatLng.lat} / ${pickupLatLng.lng}`,
          },
          {
            position: dropoffLatLng,
            label: `D${count}`,
            title: `Dropoff ${count} - ${order.customerName}\n${dropoffLatLng.lat} / ${dropoffLatLng.lng}`,
          },
        );

        bounds.extend(pickupLatLng);
        bounds.extend(dropoffLatLng);

        if (count === 1) {
          this.directionsRenderer.setMap(this.map.googleMap);
          this.directionsService.route(
            {
              origin: pickupLatLng,
              destination: dropoffLatLng,
              travelMode: google.maps.TravelMode.DRIVING,
            },
            (result, status) => {
              if (status === 'OK' && result) {
                this.directionsRenderer.setDirections(result);
              }
            },
          );
        }

        count++;
      }
    }

    if (!bounds.isEmpty()) {
      this.map.googleMap!.fitBounds(bounds);
    }
  }

  formatAddress(lat?: number, lng?: number): string {
    return lat && lng ? `${lat.toFixed(6)} / ${lng.toFixed(6)}` : '0 / 0';
  }

  filterDispatches(): Dispatch[] {
    return this.dispatches.filter((d) => {
      const matchDriver = this.selectedDriver
        ? d.driverName?.toLowerCase().includes(this.selectedDriver.toLowerCase())
        : true;
      const matchStatus = this.selectedStatus ? d.status === this.selectedStatus : true;
      const matchQuery = this.searchQuery
        ? d.routeCode?.toLowerCase().includes(this.searchQuery.toLowerCase())
        : true;
      return matchDriver && matchStatus && matchQuery;
    });
  }

  get filteredUnscheduledOrders(): TransportOrder[] {
    if (!this.searchUnscheduled) return this.unscheduledOrders;
    const search = this.searchUnscheduled.toLowerCase();
    return this.unscheduledOrders.filter(
      (order) =>
        order.orderReference?.toLowerCase().includes(search) ||
        order.customerName?.toLowerCase().includes(search),
    );
  }

  resetFilters(): void {
    this.selectedStatus = '';
    this.selectedDriver = '';
    this.searchQuery = '';
  }

  isOrderSelected(orderId: number): boolean {
    return this.selectedOrderIds.has(orderId);
  }

  toggleOrderSelection(orderId: number, checked: boolean): void {
    checked ? this.selectedOrderIds.add(orderId) : this.selectedOrderIds.delete(orderId);
    this.drawSelectedOrderRoutes();
  }

  toggleSelectAllOrders(checked: boolean): void {
    if (checked) {
      this.filteredUnscheduledOrders.forEach((o) => {
        if (o.id != null) this.selectedOrderIds.add(o.id);
      });
    } else {
      this.selectedOrderIds.clear();
    }
    this.drawSelectedOrderRoutes();
  }

  areAllOrdersSelected(): boolean {
    return this.filteredUnscheduledOrders.every(
      (o) => o.id != null && this.selectedOrderIds.has(o.id),
    );
  }

  toggleSelectAllOrdersFromEvent(event: Event): void {
    const checked = (event.target as HTMLInputElement)?.checked ?? false;
    this.toggleSelectAllOrders(checked);
  }

  onOrderCheckboxChange(orderId: number, event: Event): void {
    const checked = (event.target as HTMLInputElement)?.checked ?? false;
    this.toggleOrderSelection(orderId, checked);
  }

  bulkAssignToRoute(): void {
    console.log(' Bulk Assign Orders:', Array.from(this.selectedOrderIds));
    // 🔧 Implement modal or backend call here.
  }

  openMenuId: number | null = null;

  /**
   * Toggles the action menu for a given dispatch ID.
   * - If the clicked dispatch is already open, it closes the menu.
   * - If it's a different one, it opens that dispatch's menu.
   */
  toggleMenu(dispatchId: number, event: MouseEvent): void {
    event.stopPropagation(); // Prevent the menu from closing due to document click listener
    this.openMenuId = this.openMenuId === dispatchId ? null : dispatchId;
  }

  onViewDispatch(dispatch: Dispatch): void {
    this.openMenuId = null;
    if (dispatch.id) {
      window.open(`/dispatch/${dispatch.id}`, '_blank');
    }
  }

  onEditDispatch(dispatch: Dispatch): void {
    this.openMenuId = null;
    this.selectedDispatch = dispatch;
    this.showTripModal = true;
  }

  async onDeleteDispatch(dispatch: Dispatch): Promise<void> {
    if (!dispatch.id) return;

    const ok = await this.confirmService.confirm(
      `Are you sure you want to delete dispatch ${dispatch.routeCode}?\n\nThis action cannot be undone.`,
    );

    if (!ok) return;

    this.openMenuId = null;
    this.dispatchService.deleteDispatch(dispatch.id).subscribe({
      next: () => {
        this.toastr.success('Dispatch deleted successfully');
        this.loadDispatches();
      },
      error: (err) => {
        console.error('Failed to delete dispatch:', err);
        this.toastr.error('Failed to delete dispatch. Please try again.');
      },
    });
  }

  @HostListener('document:click')
  onDocumentClick(): void {
    this.openMenuId = null;
    this.openOrderMenuId = null;
  }

  onAssignDriver(dispatch: Dispatch): void {
    this.openMenuId = null;
    this.selectedDispatch = dispatch;
    // Open trip modal to reassign driver
    this.showTripModal = true;
  }

  onManageOrders(dispatch: Dispatch): void {
    this.openMenuId = null;
    if (dispatch.transportOrderId) {
      window.open(`/orders/${dispatch.transportOrderId}`, '_blank');
    } else {
      this.toastr.info('No transport order associated with this dispatch');
    }
  }

  onTrackRoute(dispatch: Dispatch): void {
    console.log('🧭 Tracking route for dispatch:', dispatch);
    this.openMenuId = null;
    this.onSelectDispatch(dispatch); // optional: center map
  }

  onGenerateReport(dispatch: Dispatch): void {
    this.openMenuId = null;
    if (!dispatch.id) return;

    // Navigate to dispatch detail which has PDF export functionality
    window.open(`/dispatch/${dispatch.id}?action=export`, '_blank');
  }

  async onMarkAsComplete(dispatch: Dispatch): Promise<void> {
    this.openMenuId = null;
    if (!dispatch.id) return;

    const confirmed = await this.confirmService.confirm(
      `Mark dispatch ${dispatch.routeCode} as COMPLETED?\n\nThis will update the status to COMPLETED.`,
    );

    if (!confirmed) return;
    this.dispatchService.updateDispatchStatus(dispatch.id, 'COMPLETED').subscribe({
      next: () => {
        this.toastr.success('Dispatch marked as completed');
        this.loadDispatches();
      },
      error: (err) => {
        console.error('Failed to update status:', err);
        this.toastr.error('Failed to update status. Please try again.');
      },
    });
  }

  toggleOrderMenu(orderId: number, event: MouseEvent): void {
    event.stopPropagation();
    this.openOrderMenuId = this.openOrderMenuId === orderId ? null : orderId;
  }
  onViewOrder(order: TransportOrder): void {
    this.openOrderMenuId = null;
    if (order.id) {
      window.open(`/orders/${order.id}`, '_blank');
    }
  }

  onPlanTrip(order: TransportOrder): void {
    console.log(' Planning trip for:', order);
    this.selectedOrder = order;
    this.showTripModal = true;
  }

  onEditOrder(order: TransportOrder): void {
    this.openOrderMenuId = null;
    if (order.id) {
      window.open(`/orders/${order.id}`, '_blank');
    }
  }

  async onDeleteOrder(order: TransportOrder): Promise<void> {
    if (!order.id) return;

    const ok = await this.confirmService.confirm(
      `Delete order ${order.orderReference}?\n\nThis action cannot be undone.`,
    );
    if (!ok) return;

    this.openOrderMenuId = null;
    this.transportOrderService.deleteOrder(order.id).subscribe({
      next: () => {
        this.toastr.success('Order deleted successfully');
        this.loadUnscheduledOrders();
      },
      error: (err) => {
        console.error('Failed to delete order:', err);
        this.toastr.error('Failed to delete order. Please try again.');
      },
    });
  }

  onDuplicateOrder(order: any) {
    console.log('📄 Duplicate order:', order);
    // implement logic here
  }

  onAssignToDriver(order: any) {
    console.log(' Assign to driver:', order);
    // implement modal/dialog or direct action
  }

  onPrintOrder(order: any) {
    console.log('🖨️ Print order:', order);
    // open print view or generate PDF
  }

  //TripPlan
  openTripModal(order: TransportOrder) {
    this.selectedOrder = order;
    this.showTripModal = true;
  }

  handleTripSubmit(plan: any) {
    console.log('Trip Plan:', plan);
    this.showTripModal = false;

    // Save to backend
    this.dispatchService.planTrip(plan).subscribe({
      next: () => this.toastr.success('Trip planned'),
      error: () => this.toastr.error('Failed to plan trip'),
    });
  }

  closeModal() {
    this.showTripModal = false;
  }
}
