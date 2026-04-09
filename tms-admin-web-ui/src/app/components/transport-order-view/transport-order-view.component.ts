/* eslint-disable @typescript-eslint/consistent-type-imports */
import { CommonModule } from '@angular/common';
import { OnInit } from '@angular/core';
import { NgZone } from '@angular/core';
import { Component } from '@angular/core';
import { ToastrService } from 'ngx-toastr';
import Swal from 'sweetalert2';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { RouterModule } from '@angular/router';
import { firstValueFrom } from 'rxjs';
import { LoadingOpsService } from '../../services/loading-ops.service';

import { DispatchStatus } from '../../models/dispatch-status.enum';
import type { Driver } from '../../models/driver.model';
import { OrderStatus } from '../../models/enums/order-status.enums';
import type { TransportOrderResponseDto } from '../../models/transport-order-response.model';
import { TransportOrderService } from '../../services/transport-order.service';
import { AuthService } from '../../services/auth.service';

declare const google: any;

@Component({
  selector: 'app-transport-order-view',
  templateUrl: './transport-order-view.component.html',
  styleUrls: ['./transport-order-view.component.css'],
  standalone: true,
  imports: [CommonModule, RouterModule, FormsModule],
})
export class TransportOrderViewComponent implements OnInit {
  order: TransportOrderResponseDto | null = null;
  selectedTab: string = 'items';
  distanceKm: string = 'Calculating...';
  showActionMenu = false;
  showAssignDriverModal = false;
  selectedDriverId: string = '';
  availableDrivers: Driver[] = [];

  showStatusModal = false;
  selectedStatus = '';
  // availableStatuses: string[] = ['PENDING', 'CONFIRMED', 'DISPATCHED', 'LOADING', 'COMPLETED', 'CANCELLED'];

  availableStatuses: string[] = Object.values(OrderStatus);

  public DispatchStatus = DispatchStatus;
  // Report preview state
  reportHtml: string | null = null;
  showReportPreview = false;

  constructor(
    private readonly route: ActivatedRoute,
    private readonly orderService: TransportOrderService,
    private readonly ngZone: NgZone,
    private readonly router: Router,
    private readonly toastr: ToastrService,
    private readonly authService: AuthService,
    private readonly loadingOps: LoadingOpsService,
  ) {}

  ngOnInit(): void {
    const orderIdParam = this.route.snapshot.paramMap.get('id');
    const orderId = Number(orderIdParam);
    if (orderIdParam && !isNaN(orderId)) {
      this.fetchOrderDetails(orderId);
    } else {
      console.error(' Invalid order ID provided.');
    }
  }

  toggleActionMenu(): void {
    this.showActionMenu = !this.showActionMenu;
  }

  fetchOrderDetails(orderId: number): void {
    this.orderService.getOrderById(orderId).subscribe({
      next: (response) => {
        this.order = response.data;
        this.calculateDistance();
      },
      error: (err) => console.error(' Error fetching order details:', err),
    });
  }

  calculateDistance(): void {
    if (this.order?.pickupAddress && this.order?.dropAddress) {
      const service = new google.maps.DistanceMatrixService();
      service.getDistanceMatrix(
        {
          origins: [
            new google.maps.LatLng(
              this.order.pickupAddress.latitude,
              this.order.pickupAddress.longitude,
            ),
          ],
          destinations: [
            new google.maps.LatLng(
              this.order.dropAddress.latitude,
              this.order.dropAddress.longitude,
            ),
          ],
          travelMode: google.maps.TravelMode.DRIVING,
        },
        (response: any, status: string) => {
          this.ngZone.run(() => {
            const element = response?.rows?.[0]?.elements?.[0];
            if (status === 'OK' && element?.status === 'OK' && element?.distance?.text) {
              this.distanceKm = element.distance.text;
            } else {
              this.distanceKm = 'Distance unavailable';
            }
          });
        },
      );
    } else {
      this.distanceKm = 'Address details incomplete';
    }
  }

  getDirectionLink(): string {
    if (this.order?.pickupAddress && this.order?.dropAddress) {
      const origin = `${this.order.pickupAddress.latitude},${this.order.pickupAddress.longitude}`;
      const destination = `${this.order.dropAddress.latitude},${this.order.dropAddress.longitude}`;
      return `https://www.google.com/maps/dir/?api=1&origin=${encodeURIComponent(
        origin,
      )}&destination=${encodeURIComponent(destination)}`;
    }
    return '#';
  }

  getDirectionLink1(latitude: number, longitude: number): string {
    const origin = this.order?.pickupAddress
      ? `${this.order.pickupAddress.latitude},${this.order.pickupAddress.longitude}`
      : '0,0';
    const destination = `${latitude},${longitude}`;
    return `https://www.google.com/maps/dir/?api=1&origin=${encodeURIComponent(
      origin,
    )}&destination=${encodeURIComponent(destination)}`;
  }

  getDistance(
    pickup: { latitude?: number; longitude?: number },
    drop: { latitude?: number; longitude?: number },
  ): string {
    if (pickup?.latitude && pickup?.longitude && drop?.latitude && drop?.longitude) {
      return `From (${pickup.latitude}, ${pickup.longitude}) → (${drop.latitude}, ${drop.longitude})`;
    }
    return 'N/A';
  }

  assignDriver(): void {
    this.loadAvailableDrivers();
    this.showAssignDriverModal = true;
  }

  loadAvailableDrivers(): void {
    this.orderService.getAvailableDrivers().subscribe({
      next: (res) => {
        this.availableDrivers = res.data || [];
      },
      error: (err) => console.error(' Error fetching drivers:', err),
    });
  }

  assignDriverToOrder(): void {
    if (!this.selectedDriverId || !this.order?.id) {
      this.toastr.warning('Please select a driver.');
      return;
    }
    this.orderService.assignDispatch(this.order.id, this.selectedDriverId).subscribe({
      next: (response) => {
        this.ngZone.run(() => {
          this.toastr.success('Driver assigned successfully.');
          if (this.order) {
            this.order.assignedDriver = response.data?.assignedDriver;
          }
          this.showAssignDriverModal = false;
        });
      },
      error: (err) => {
        this.toastr.error(err?.message || 'Failed to assign driver.');
        console.error('🚨 API Error:', err);
      },
    });
  }

  closeAssignDriverModal(): void {
    this.showAssignDriverModal = false;
  }

  createTrip(): void {
    if (this.order?.id) {
      this.router.navigate(['/dispatch/create'], {
        queryParams: { orderId: this.order.id },
      });
    } else {
      this.toastr.error('Order ID not found.');
    }
  }

  updateStatus(): void {
    this.selectedStatus = this.order?.status || '';
    this.showStatusModal = true;
  }

  openDispatchList(): void {
    if (this.order?.id) {
      this.router.navigate(['/dispatch'], { queryParams: { orderId: this.order.id } });
    } else {
      this.router.navigate(['/dispatch']);
    }
  }

  confirmStatusUpdate(): void {
    if (!this.selectedStatus || !this.order?.id) {
      this.toastr.warning('Please select a status.');
      return;
    }
    this.orderService.updateOrderStatus(this.order.id, this.selectedStatus).subscribe({
      next: (response) => {
        this.ngZone.run(() => {
          this.toastr.success('Status updated successfully.');
          this.order!.status = response.data.status;
          this.showStatusModal = false;
        });
      },
      error: (err) => {
        this.toastr.error(err?.message || 'Failed to update status.');
        console.error('🚨 API Error:', err);
      },
    });
  }

  cancelStatusUpdate(): void {
    this.showStatusModal = false;
  }

  changeDriver(): void {
    this.assignDriver();
  }

  printInvoice(): void {
    if (!this.order?.id) {
      this.toastr.error('Order ID missing');
      return;
    }

    if (!this.authService.isAuthenticated()) {
      this.toastr.error('You must be signed in to download invoices.');
      this.router.navigate(['/login']);
      return;
    }

    this.orderService.getInvoice(this.order.id).subscribe({
      next: (blob: Blob) => {
        try {
          const blobUrl = URL.createObjectURL(blob);
          const win = window.open(blobUrl, '_blank');
          if (!win) {
            const a = document.createElement('a');
            a.href = blobUrl;
            a.download = `invoice-${this.order?.orderReference ?? this.order?.id}.pdf`;
            document.body.appendChild(a);
            a.click();
            a.remove();
          } else {
            win.focus();
          }
          setTimeout(() => URL.revokeObjectURL(blobUrl), 20000);
        } catch (e) {
          this.toastr.error('Unable to open invoice');
          console.error(e);
        }
      },
      error: (err) => {
        // Improved diagnostics for user and logs
        const status = (err && err.status) || 'unknown';
        const msg = (err && err.message) || 'Failed to retrieve invoice';
        if (status === 401) {
          this.toastr.error('Session expired or not authenticated. Please login.');
          this.router.navigate(['/login']);
        } else {
          this.toastr.error(`${msg} (status: ${status})`);
        }
        console.error('Invoice error', err);
      },
    });
  }

  generateDeliveryNote(): void {
    if (!this.order?.id) {
      this.toastr.error('Order ID missing');
      return;
    }

    // Ensure user is authenticated before requesting protected blob
    if (!this.authService.isAuthenticated()) {
      this.toastr.error('You must be signed in to download delivery notes.');
      this.router.navigate(['/login']);
      return;
    }

    this.orderService.getDeliveryNote(this.order.id).subscribe({
      next: (blob: Blob) => {
        try {
          const blobUrl = URL.createObjectURL(blob);
          const win = window.open(blobUrl, '_blank');
          if (!win) {
            // popup blocked — force download
            const a = document.createElement('a');
            a.href = blobUrl;
            a.download = `delivery-note-${this.order?.orderReference ?? this.order?.id}.pdf`;
            document.body.appendChild(a);
            a.click();
            a.remove();
          } else {
            win.focus();
          }
          // revoke after a delay
          setTimeout(() => URL.revokeObjectURL(blobUrl), 20000);
        } catch (e) {
          this.toastr.error('Unable to open delivery note');
          console.error(e);
        }
      },
      error: (err) => {
        const status = err?.status ?? 'unknown';
        console.error('Delivery note error', err);
        if (status === 401) {
          // Try alternate public route if admin API returns 401
          this.toastr.info(
            'Primary delivery-note path unauthorized; trying alternate route...',
            'Info',
          );
          this.orderService.getDeliveryNoteAlternate(this.order!.id).subscribe({
            next: (blob2: Blob) => {
              try {
                const blobUrl2 = URL.createObjectURL(blob2);
                const win2 = window.open(blobUrl2, '_blank');
                if (!win2) {
                  const a2 = document.createElement('a');
                  a2.href = blobUrl2;
                  a2.download = `delivery-note-${this.order?.orderReference ?? this.order?.id}.pdf`;
                  document.body.appendChild(a2);
                  a2.click();
                  a2.remove();
                } else {
                  win2.focus();
                }
                setTimeout(() => URL.revokeObjectURL(blobUrl2), 20000);
                this.toastr.success('Delivery note retrieved via alternate route.');
              } catch (e2) {
                this.toastr.error('Unable to open delivery note from alternate route');
                console.error(e2);
              }
            },
            error: (err2) => {
              this.toastr.error('Failed to retrieve delivery note (alternate route).');
              console.error('Alternate delivery note error', err2);
              if (err2?.status === 401) {
                this.toastr.error('Session expired or not authenticated. Please login.');
                this.router.navigate(['/login']);
              }
            },
          });
        } else {
          this.toastr.error(err?.message || `Failed to retrieve delivery note (status: ${status})`);
        }
      },
    });
  }

  /** Open a printable report page for this transport order (items, packing note, delivery note) */
  async openReport(): Promise<void> {
    if (!this.order?.id) {
      this.toastr.error('Order ID missing');
      return;
    }

    this.toastr.info('Preparing report...', 'Report');

    let deliveryBlobUrl: string | null = null;

    // Try primary admin endpoint first
    try {
      const blob = await firstValueFrom(this.orderService.getDeliveryNote(this.order.id));
      if (blob) deliveryBlobUrl = URL.createObjectURL(blob as Blob);
    } catch (err: any) {
      console.debug('Primary delivery-note fetch failed, trying alternate route', err?.status);
      if (err?.status === 401) {
        try {
          const blob2 = await firstValueFrom(
            this.orderService.getDeliveryNoteAlternate(this.order.id),
          );
          if (blob2) deliveryBlobUrl = URL.createObjectURL(blob2 as Blob);
        } catch (err2) {
          console.warn('Alternate delivery-note route failed', err2);
        }
      }
    }

    // Prepare packing note content (try common fields)
    let packingNote =
      (this.order as any)?.packingNote ||
      (this.order as any)?.packing_notes ||
      (this.order as any)?.remarks ||
      '';
    try {
      // determine a dispatchId to lookup session
      const dispatchId =
        (this.order?.dispatches &&
          this.order.dispatches.length > 0 &&
          this.order.dispatches[0].id) ||
        (this.order as any)?.dispatchId;
      if (dispatchId) {
        const session = await firstValueFrom(this.loadingOps.sessionForDispatch(dispatchId));
        if (session?.id) {
          const docs: any[] = await firstValueFrom(this.loadingOps.getSessionDocuments(session.id));
          const packing = docs?.find((d) => d.documentType === 'PACKING_LIST');
          if (packing) {
            try {
              const blob = await firstValueFrom(
                this.loadingOps.downloadSessionDocument(session.id, packing.id),
              );
              if (blob) {
                // try to read blob as text
                const txt = await (blob as Blob).text();
                if (txt && txt.trim().length > 0) packingNote = txt;
              }
            } catch (err) {
              console.warn('Could not download packing-list document', err);
            }
          }
        }
      }
    } catch (err) {
      console.debug('No packing note found in loading session documents', err);
    }

    if (!packingNote) packingNote = 'No packing note available.';

    // Build HTML for report
    const itemsHtml = (this.order?.items || [])
      .map(
        (it: any, idx: number) =>
          `<tr><td style="border:1px solid #ddd;padding:8px">${idx + 1}</td><td style="border:1px solid #ddd;padding:8px">${
            it.itemName || it.name || '-'
          }</td><td style="border:1px solid #ddd;padding:8px">${it.quantity ?? '-'}</td><td style="border:1px solid #ddd;padding:8px">${it.unitOfMeasurement || it.uom || '-'}</td></tr>`,
      )
      .join('');

    const html = `
      <!doctype html>
      <html>
      <head>
        <meta charset="utf-8" />
        <title>Transport Order Report - ${this.order.orderReference || this.order.id}</title>
        <style>
          body { font-family: Arial, Helvetica, sans-serif; margin: 20px; }
          .header { display:flex; justify-content:space-between; align-items:center }
          .card { border:1px solid #e5e7eb; padding:12px; border-radius:6px; margin-bottom:12px }
          table { border-collapse: collapse; width: 100%; }
          th { background:#f3f4f6; padding:8px; border:1px solid #ddd; text-align:left }
        </style>
      </head>
      <body>
        <div class="header">
          <div>
            <h1>Transport Order Report</h1>
            <div>Order: <strong>${this.order.orderReference || this.order.id}</strong></div>
            <div>Customer: <strong>${this.order.customerName || '-'}</strong></div>
            <div>Status: <strong>${this.order.status || '-'}</strong></div>
          </div>
          <div>
            <button onclick="window.print()" style="padding:8px 12px;background:#0ea5a4;color:#fff;border:none;border-radius:4px;cursor:pointer">Print</button>
          </div>
        </div>

        <div class="card">
          <h3>Items</h3>
          <table>
            <thead><tr><th style="width:60px">#</th><th>Item</th><th>Qty</th><th>UOM</th></tr></thead>
            <tbody>
              ${itemsHtml || '<tr><td colspan="4">No items</td></tr>'}
            </tbody>
          </table>
        </div>

        <div class="card">
          <h3>Packing Note</h3>
          <pre style="white-space:pre-wrap;">${this.escapeHtml(packingNote)}</pre>
        </div>

        <div class="card">
          <h3>Delivery Note</h3>
          ${
            deliveryBlobUrl
              ? `<embed src="${deliveryBlobUrl}" type="application/pdf" width="100%" height="600px" />`
              : '<div>No delivery note available or not accessible.</div>'
          }
        </div>
      </body>
      </html>
    `;

    // Show in-app preview (iframe srcdoc) so user can inspect before printing
    this.reportHtml = html;
    this.showReportPreview = true;

    // Revoke will be handled when preview is closed; keep deliveryBlobUrl in closure via property if needed
    // Store blob url on object to revoke later
    (this as any)._reportDeliveryBlobUrl = deliveryBlobUrl;
  }

  private escapeHtml(input: string): string {
    if (!input) return '';
    return String(input)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#039;');
  }

  printFromPreview(): void {
    const iframe = document.getElementById('report-preview-iframe') as HTMLIFrameElement | null;
    if (!iframe || !iframe.contentWindow) {
      this.toastr.error('Preview not available for printing');
      return;
    }
    try {
      iframe.contentWindow.focus();
      iframe.contentWindow.print();
    } catch (e) {
      console.error('Print failed', e);
      this.toastr.error('Unable to print from preview');
    }
  }

  openReportInNewTab(): void {
    if (!this.reportHtml) return;
    const win = window.open('', '_blank');
    if (!win) {
      this.toastr.error('Popup blocked. Please allow popups to open report in new tab.');
      return;
    }
    win.document.open();
    win.document.write(this.reportHtml);
    win.document.close();
  }

  closeReportPreview(): void {
    this.showReportPreview = false;
    this.reportHtml = null;
    const url = (this as any)._reportDeliveryBlobUrl;
    try {
      if (url) URL.revokeObjectURL(url);
    } catch (e) {
      // ignore
    }
    (this as any)._reportDeliveryBlobUrl = null;
  }

  notifyCustomer(): void {
    if (!this.order?.id) {
      this.toastr.error('Order ID missing');
      return;
    }

    Swal.fire({
      title: 'Notify customer',
      input: 'textarea',
      inputLabel: 'Message to send (optional)',
      inputPlaceholder: 'Enter message or leave empty for default',
      showCancelButton: true,
    }).then((result) => {
      if (!result.isConfirmed) return;
      const message = result.value ?? '';
      this.orderService.notifyCustomer(this.order!.id, { message }).subscribe({
        next: () => {
          this.toastr.success('Customer notified successfully.');
        },
        error: (err) => {
          this.toastr.error(err?.message || 'Failed to notify customer.');
          console.error('Notify API error', err);
        },
      });
    });
  }

  cancelOrder(): void {
    if (!this.order?.id) {
      this.toastr.error('Order ID missing');
      return;
    }

    Swal.fire({
      title: 'Cancel Order',
      text: `Are you sure you want to cancel order ${this.order.orderReference ?? ''}?`,
      icon: 'warning',
      input: 'textarea',
      inputLabel: 'Reason (optional)',
      showCancelButton: true,
      confirmButtonText: 'Yes, cancel order',
    }).then((res) => {
      if (!res.isConfirmed) return;
      const reason = res.value ?? '';
      this.orderService.cancelOrder(this.order!.id, reason).subscribe({
        next: () => {
          this.toastr.success('Order cancelled.');
          if (this.order) this.order.status = 'CANCELLED';
        },
        error: (err) => {
          this.toastr.error(err?.message || 'Failed to cancel order.');
          console.error('Cancel API error', err);
        },
      });
    });
  }

  get hasMultiplePickupAddresses(): boolean {
    return !!this.order?.pickupAddresses && this.order.pickupAddresses.length > 0;
  }

  get hasMultipleDropAddresses(): boolean {
    return !!this.order?.dropAddresses && this.order.dropAddresses.length > 0;
  }

  get pickupStops() {
    return this.order?.stops?.filter((s) => s.type === 'PICKUP') ?? [];
  }

  get dropStops() {
    return this.order?.stops?.filter((s) => s.type === 'DROP') ?? [];
  }
}
