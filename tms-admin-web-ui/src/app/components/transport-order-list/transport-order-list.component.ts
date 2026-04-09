import { CommonModule } from '@angular/common';
import {
  Component,
  ElementRef,
  HostListener,
  Input,
  type OnInit,
  type OnDestroy,
} from '@angular/core';
import { FormsModule } from '@angular/forms';
import { MatIconModule } from '@angular/material/icon';
import { ActivatedRoute, Router, RouterModule } from '@angular/router';
import { Subscription } from 'rxjs';

import type { TransportOrder } from '../../models/transport-order.model';
import type { Stop } from '../../services/order-stop.model';
import { TransportOrderService } from '../../services/transport-order.service';
import { TransportOrderEditModalComponent } from './transport-order-edit-modal/transport-order-edit-modal.component';
import { STATUS_BADGE_MAPPING, OrderStatus } from '../../models/order-status.enum';
import { DateFormatterService } from '../../services/date-formatter.service';
import { ConfirmService } from '../../services/confirm.service';
import type { TransportOrderApiResponse } from '../../models/transport-order-api.model';

@Component({
  selector: 'app-transport-order-list',
  templateUrl: './transport-order-list.component.html',
  styleUrls: ['./transport-order-list.component.css'],
  standalone: true,
  imports: [
    CommonModule,
    RouterModule,
    FormsModule,
    MatIconModule,
    TransportOrderEditModalComponent,
  ],
})
export class TransportOrderListComponent implements OnInit, OnDestroy {
  @Input() pageTitle: string = 'Shipment Order';
  @Input() hideAddButton = false;
  @Input() hideFilterToggle = false;
  constructor(
    private readonly orderService: TransportOrderService,
    private router: Router,
    private route: ActivatedRoute,
    private eRef: ElementRef,
    private dateFormatter: DateFormatterService,
    private confirm: ConfirmService,
  ) {}

  orders: TransportOrder[] = [];
  allOrders: TransportOrder[] = [];
  selectedOrder: TransportOrder | null = null;
  isModalOpen: boolean = false;
  isTimelineModalOpen: boolean = false;
  selectedTimelineOrder: TransportOrder | null = null;
  dropdownOpen!: number | null;

  // Status and filtering
  statusOptions = Object.values(OrderStatus);
  searchQuery: string = '';
  statusFilter: string = '';
  pendingOnlyMode = false;
  fromDate: string = '';
  toDate: string = '';
  sortOrder: 'desc' | 'asc' = 'desc';
  showFilters: boolean = false;

  // Pagination
  currentPage = 0;
  pageSize = 20;
  totalPages = 0;
  pages: number[] = [];

  // Loading and error states
  isLoading = false;
  errorMessage: string | null = null;
  private actionInProgress = new Set<number>();

  // Debounce and subscriptions
  private searchDebounce: ReturnType<typeof setTimeout> | null = null;
  private querySub: Subscription | null = null;

  ngOnInit(): void {
    this.loadFiltersFromStorage();

    // Subscribe to query params so parent pages (like Pending) can control filters & paging
    this.querySub = this.route.queryParamMap.subscribe((qpm) => {
      const qStatus = qpm.get('status') || undefined;
      if (qStatus) {
        this.statusFilter = (qStatus as string).toUpperCase();
      }

      const pendingOnly = qpm.get('pendingOnly');
      this.pendingOnlyMode = pendingOnly === 'true' || pendingOnly === '1';

      const qSearch = qpm.get('search') || qpm.get('q');
      if (qSearch !== null && qSearch !== undefined) this.searchQuery = qSearch as string;

      const qPage = qpm.get('page');
      this.currentPage = qPage ? parseInt(qPage, 10) || 0 : 0;

      const qPageSize = qpm.get('pageSize');
      this.pageSize = qPageSize ? parseInt(qPageSize, 10) || this.pageSize : this.pageSize;

      const qFrom = qpm.get('fromDate');
      if (qFrom !== null && qFrom !== undefined) this.fromDate = qFrom as string;

      const qTo = qpm.get('toDate');
      if (qTo !== null && qTo !== undefined) this.toDate = qTo as string;

      this.applyFilters();
    });
  }

  ngOnDestroy(): void {
    this.querySub?.unsubscribe();
    if (this.searchDebounce) {
      clearTimeout(this.searchDebounce);
    }
  }

  navigateToCreateOrder(): void {
    this.router.navigate(['/orders/create']);
  }

  navigateToEditOrder(orderId: number): void {
    if (orderId == null) return;
    this.router.navigate(['/orders', orderId, 'edit']);
  }

  navigateToOrderDetail(orderId: number): void {
    if (orderId == null) return;
    this.router.navigate(['/orders', orderId]);
  }

  saveFiltersToStorage(): void {
    localStorage.setItem(
      'transportOrderFilters',
      JSON.stringify({
        searchQuery: this.searchQuery,
        statusFilter: this.statusFilter,
        fromDate: this.fromDate,
        toDate: this.toDate,
        sortOrder: this.sortOrder,
      }),
    );
  }

  loadFiltersFromStorage(): void {
    const saved = localStorage.getItem('transportOrderFilters');
    if (saved) {
      const filters = JSON.parse(saved);
      this.searchQuery = filters.searchQuery || '';
      this.statusFilter = filters.statusFilter || '';
      this.fromDate = filters.fromDate || '';
      this.toDate = filters.toDate || '';
      this.sortOrder = filters.sortOrder || 'desc';
    }
  }

  applyFilters(): void {
    this.saveFiltersToStorage();
    this.isLoading = true;
    this.errorMessage = null;

    this.orderService
      .getFilteredOrders(
        this.searchQuery.trim(),
        this.statusFilter,
        this.fromDate,
        this.toDate,
        this.sortOrder,
        this.currentPage,
        this.pageSize,
      )
      .subscribe({
        next: (response) => {
          const content = response?.data?.content ?? [];
          const totalPages = response?.data?.totalPages ?? 0;
          const mappedOrders = this.mapOrders(content);
          this.setOrderList(mappedOrders, totalPages);
        },
        error: (err) => {
          console.error('Error applying filters:', err);
          this.isLoading = false;
          this.errorMessage = 'Failed to load orders. Please try again.';
          this.orders = [];
        },
      });
  }

  onSearchInputChange(): void {
    if (this.searchDebounce) {
      clearTimeout(this.searchDebounce);
    }
    this.searchDebounce = setTimeout(() => {
      this.applyFilters();
    }, 500);
  }

  onDateChange(): void {
    if (this.searchDebounce) {
      clearTimeout(this.searchDebounce);
    }
    this.searchDebounce = setTimeout(() => {
      this.applyFilters();
    }, 500);
  }

  sortOrders(): void {
    this.applyFilters();
  }

  clearFilters(): void {
    this.searchQuery = '';
    this.statusFilter = '';
    this.fromDate = '';
    this.toDate = '';
    this.sortOrder = 'desc';
    this.currentPage = 0;
    localStorage.removeItem('transportOrderFilters');
    this.applyFilters();
  }

  goToPage(page: number): void {
    if (page >= 0 && page < this.totalPages) {
      this.currentPage = page;
      this.applyFilters();
    }
  }

  toggleFilters(): void {
    this.showFilters = !this.showFilters;
  }

  toggleDropdown(orderId: number | undefined): void {
    if (orderId === undefined) return;
    this.dropdownOpen = this.dropdownOpen === orderId ? null : orderId;
  }

  openEditModal(order: TransportOrder): void {
    this.selectedOrder = { ...order };
    this.isModalOpen = true;
  }

  closeModal(): void {
    this.isModalOpen = false;
    this.selectedOrder = null;
  }

  onModalSave(updatedOrder: TransportOrder): void {
    if (!updatedOrder || !updatedOrder.id) return;
    this.saveOrderStatusChange(updatedOrder);
  }

  openTimelineModal(order: TransportOrder): void {
    this.selectedTimelineOrder = order;
    this.isTimelineModalOpen = true;
  }

  closeTimelineModal(): void {
    this.isTimelineModalOpen = false;
  }

  async confirmAction(message: string, callback: () => void): Promise<void> {
    if (await this.confirm.confirm(message)) {
      callback();
    }
  }

  dispatchOrder(orderId: number): void {
    this.router.navigate(['/dispatch/create'], {
      queryParams: { orderId },
    });
  }

  loadOrder(orderId: number): void {
    // TODO: Implement loading state transition to LOADING
    console.warn('loadOrder not yet fully implemented');
    this.updateOrderStatusOptimistic(orderId, OrderStatus.LOADING);
  }

  markAsCompleted(orderId: number): void {
    // TODO: Implement completion workflow with confirmation dialog
    this.confirmAction('Mark order as completed?', () => {
      this.updateOrderStatusOptimistic(orderId, OrderStatus.COMPLETED);
    });
  }

  saveOrderStatusChange(order: TransportOrder): void {
    if (!order) return;
    const orderId = order.id;
    const newStatus = order.status;
    this.actionInProgress.add(orderId!);

    this.orderService.updateOrderStatus(orderId!, newStatus).subscribe({
      next: (response) => {
        const updatedOrder = response.data;
        const index = this.orders.findIndex((o) => o.id === orderId);
        if (index !== -1) {
          this.orders[index].status = updatedOrder.status;
        }
        this.sortOrders();
        this.closeModal();
        this.actionInProgress.delete(orderId!);
      },
      error: (err) => {
        console.error('Failed to update order status:', err);
        this.errorMessage = 'Failed to update order status. Please try again.';
        this.actionInProgress.delete(orderId!);
      },
    });
  }

  approveOrder(orderId: number): void {
    this.updateOrderStatusOptimistic(orderId, 'APPROVED');
  }

  rejectOrder(orderId: number): void {
    this.updateOrderStatusOptimistic(orderId, 'REJECTED');
  }

  onApprove(orderId: number | undefined): void {
    if (orderId == null) return;
    this.confirmAction('Approve this order?', () => this.approveOrder(orderId));
  }

  onReject(orderId: number | undefined): void {
    if (orderId == null) return;
    this.confirmAction('Reject this order?', () => this.rejectOrder(orderId));
  }

  private updateOrderStatusOptimistic(orderId: number, newStatus: string): void {
    const index = this.orders.findIndex((o) => o.id === orderId);
    if (index === -1) return;

    const previousStatus = this.orders[index].status;
    this.actionInProgress.add(orderId);

    // Optimistic UI update
    this.orders[index].status = newStatus;

    this.orderService.updateOrderStatus(orderId, newStatus).subscribe({
      next: (response) => {
        const updated = response.data;
        if (updated && updated.status) {
          this.orders[index].status = updated.status;
        }
        this.sortOrders();
        this.actionInProgress.delete(orderId);
      },
      error: (err) => {
        console.error(`Failed to set status ${newStatus} for order ${orderId}:`, err);
        // Revert on error
        this.orders[index].status = previousStatus;
        this.actionInProgress.delete(orderId);
        this.errorMessage = 'Failed to update order status. Please try again.';
      },
    });
  }

  private mapOrders(raw: TransportOrderApiResponse[]): TransportOrder[] {
    return raw.map(
      (order) =>
        ({
          id: order.id,
          orderReference: order.orderReference,
          tripNo: order.tripNo,
          customerId: order.customerId,
          customerName: order.customerName,
          billTo: order.billTo,
          orderDate: order.orderDate,
          deliveryDate: order.deliveryDate,
          createDate: order.createdAt || new Date().toISOString(),
          createdAt: order.createdAt || new Date().toISOString(),
          shipmentType: order.shipmentType,
          courierAssigned: order.courierAssigned || '',
          status: order.status,
          createdBy: {
            username: order.createdByUsername || 'System',
          },
          pickupAddress: order.pickupAddress || null,
          dropAddress: order.dropAddress || null,
          pickupAddresses: [],
          dropAddresses: [],
          items: [],
          dispatches: [],
          invoice: null,
          stops: (order.stops as any[]) || [],
          // map new fields from backend
          origin: order.origin || 'BOOKING',
          requiresDriver: typeof order.requiresDriver === 'boolean' ? order.requiresDriver : true,
        }) as TransportOrder,
    );
  }

  private setOrderList(data: TransportOrder[], totalPages: number): void {
    let list = data;
    if (this.pendingOnlyMode) {
      list = data.filter((o) => o.status === 'PENDING' || o.status === 'CANCELLED');
      // Show all matching items on a single page for Pending view
      this.totalPages = list.length > 0 ? 1 : 0;
      this.pages = this.totalPages > 0 ? [0] : [];
      this.currentPage = 0;
    } else {
      this.totalPages = totalPages;
      this.pages = Array.from({ length: totalPages }, (_, i) => i);
    }

    this.orders = list;
    this.allOrders = list;
    this.isLoading = false;
  }

  getStatusBadgeClass(status: string): string {
    return STATUS_BADGE_MAPPING[status as OrderStatus] || 'badge-pending';
  }

  isActionInProgress(orderId: number | undefined): boolean {
    return orderId != null && this.actionInProgress.has(orderId);
  }

  formatStatusDisplay(status: string): string {
    return status
      .split('_')
      .map((word) => word.charAt(0).toUpperCase() + word.slice(1).toLowerCase())
      .join(' ');
  }

  trackByStop(index: number, stop: Stop): number {
    return stop?.id ?? index;
  }

  trackByOrderId(index: number, order: TransportOrder): number {
    return order?.id ?? index;
  }

  getPickupStops(order: TransportOrder): Stop[] {
    return this.sortStops(order?.stops).filter((s) => s.type === 'PICKUP');
  }

  getDropStops(order: TransportOrder): Stop[] {
    return this.sortStops(order?.stops).filter((s) => s.type === 'DROP');
  }

  private sortStops(stops: Stop[] | undefined): Stop[] {
    if (!stops || stops.length === 0) return [];

    return [...stops]
      .filter((s): s is Stop => !!s)
      .sort((a, b) => (a.sequence ?? 0) - (b.sequence ?? 0));
  }

  // 👇 Close dropdown when clicking outside
  @HostListener('document:click', ['$event'])
  onDocumentClick(event: MouseEvent): void {
    if (!this.eRef.nativeElement.contains(event.target)) {
      this.dropdownOpen = null;
    }
  }

  // 👇 Close dropdown with ESC key
  @HostListener('document:keydown.escape')
  onEscapePress(): void {
    this.dropdownOpen = null;
  }

  openTracking(order: TransportOrder | undefined): void {
    if (!order || order.id == null) return;
    this.router.navigate(['/orders', order.id, 'tracking']);
  }
}
