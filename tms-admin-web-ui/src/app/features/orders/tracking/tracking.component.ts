import { CommonModule } from '@angular/common';
import { Component, inject, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router, RouterModule } from '@angular/router';
import { forkJoin } from 'rxjs';
import type { TransportOrderResponseDto } from '../../../models/transport-order-response.model';
import { TransportOrderService } from '../../../services/transport-order.service';
import { NotificationService } from '../../../services/notification.service';

@Component({
  selector: 'app-order-tracking',
  standalone: true,
  imports: [CommonModule, RouterModule, FormsModule],
  templateUrl: './tracking.component.html',
  styleUrls: ['./tracking.component.css'],
})
export class TrackingComponent implements OnInit {
  private notification = inject(NotificationService);
  orderId: number | null = null;
  trackingData: any = null;
  orderDetail: TransportOrderResponseDto | null = null;
  eventDetailsOpen: Record<number, boolean> = {};
  isLoading = true;
  error = '';
  // UI helpers
  refInput = '';
  autoEnabled = false;
  private autoTimer: any = null;

  constructor(
    private readonly route: ActivatedRoute,
    private readonly router: Router,
    private readonly orderService: TransportOrderService,
  ) {}

  ngOnInit(): void {
    this.route.paramMap.subscribe((pm) => {
      const id = pm.get('id');
      if (!id) {
        this.error = 'Order id missing';
        this.isLoading = false;
        return;
      }
      this.orderId = parseInt(id, 10);
      this.loadTracking();
    });
  }

  ngOnDestroy(): void {
    this.stopAuto();
  }

  loadTracking(): void {
    if (!this.orderId) return;
    this.isLoading = true;
    // Fetch order details and tracking information in parallel (best-effort)
    forkJoin({
      order: this.orderService.getOrderById(this.orderId),
      tracking: this.orderService.getOrderTracking(this.orderId),
    }).subscribe({
      next: ({ order, tracking }) => {
        this.orderDetail = order?.data ?? null;
        this.trackingData = tracking?.data ?? this.orderDetail?.tracking ?? null;
        this.isLoading = false;
      },
      error: (err) => {
        // If parallel fetch fails, try to at least fetch order details or tracking individually
        this.orderService.getOrderById(this.orderId!).subscribe({
          next: (ord) => {
            this.orderDetail = ord?.data ?? null;
            this.isLoading = false;
          },
          error: () => {
            this.error = err?.message || 'Failed to load tracking';
            this.isLoading = false;
          },
        });
      },
    });
  }

  /** Search orders by reference and load tracking for the first match */
  searchByRef(): void {
    const ref = (this.refInput || '').trim();
    if (!ref) return;
    this.isLoading = true;
    this.orderService.searchOrders(ref, 0, 10).subscribe({
      next: (res) => {
        const items = res?.data?.content || res?.data || [];
        const first = Array.isArray(items) ? items[0] : items;
        const id = first?.id ?? null;
        if (id) {
          this.orderId = id;
          this.loadTracking();
        } else {
          this.error = 'No order found for reference';
          this.isLoading = false;
        }
      },
      error: (err) => {
        this.error = err?.message || 'Search failed';
        this.isLoading = false;
      },
    });
  }

  refreshTracking(): void {
    this.loadTracking();
  }

  toggleAuto(): void {
    this.autoEnabled = !this.autoEnabled;
    if (this.autoEnabled) this.startAuto();
    else this.stopAuto();
  }

  private startAuto(): void {
    this.stopAuto();
    this.autoTimer = setInterval(() => {
      if (!this.orderId) return;
      this.loadTracking();
    }, 8000);
  }

  private stopAuto(): void {
    if (this.autoTimer) clearInterval(this.autoTimer);
    this.autoTimer = null;
  }

  openMap(): void {
    const lat =
      this.trackingData?.currentLocation?.latitude ||
      this.orderDetail?.tracking?.currentLocation?.latitude;
    const lng =
      this.trackingData?.currentLocation?.longitude ||
      this.orderDetail?.tracking?.currentLocation?.longitude;
    if (lat && lng) {
      const url = `https://www.google.com/maps?q=${lat},${lng}`;
      window.open(url, '_blank');
    } else {
      this.notification.simulateNotification('Notice', 'No GPS coordinates available');
    }
  }

  shareLink(): void {
    const ref = this.orderDetail?.orderReference || this.refInput;
    if (!ref) {
      this.notification.simulateNotification('Notice', 'No reference to share');
      return;
    }
    const url = new URL(window.location.href);
    url.searchParams.set('ref', ref);
    navigator.clipboard
      ?.writeText(url.toString())
      .then(() => this.notification.simulateNotification('Success', 'Link copied to clipboard'));
  }

  copyReference(): void {
    const ref = this.orderDetail?.orderReference || '';
    if (!ref) return;
    navigator.clipboard
      .writeText(ref)
      .then(() => {
        // lightweight feedback — could integrate toast service
        this.notification.simulateNotification('Success', 'Order reference copied to clipboard');
      })
      .catch(() => {
        this.notification.simulateNotification('Error', 'Unable to copy reference');
      });
  }

  openLiveTracking(): void {
    const url = this.trackingData?.liveTrackingUrl || this.orderDetail?.tracking?.liveTrackingUrl;
    if (url) window.open(url, '_blank');
  }

  toggleEventDetails(i: number): void {
    this.eventDetailsOpen[i] = !this.eventDetailsOpen[i];
  }

  notifyCustomer(): void {
    if (!this.orderId) return;
    this.orderService.notifyCustomer(this.orderId, { message: 'Shipment update' }).subscribe({
      next: () => this.notification.simulateNotification('Success', 'Customer notified'),
      error: () => this.notification.simulateNotification('Error', 'Failed to notify customer'),
    });
  }

  openDispatchDetail(): void {
    const dispatchId = this.orderDetail?.dispatches?.[0]?.id;
    if (dispatchId) this.router.navigate(['/dispatch', dispatchId]);
  }

  goBack(): void {
    if (this.orderId) {
      this.router.navigate(['/orders', this.orderId]);
    } else {
      this.router.navigate(['/orders']);
    }
  }
}
