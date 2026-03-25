import { CommonModule } from '@angular/common';
import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, RouterModule } from '@angular/router';
import { ToastrService } from 'ngx-toastr';
import { firstValueFrom } from 'rxjs';

import { TransportOrderService } from '../../services/transport-order.service';
import { LoadingOpsService } from '../../services/loading-ops.service';
import { AuthService } from '../../services/auth.service';

@Component({
  selector: 'app-delivery-note',
  standalone: true,
  imports: [CommonModule, RouterModule],
  templateUrl: './delivery-note.component.html',
  styleUrls: [],
})
export class DeliveryNoteComponent implements OnInit {
  orderId: number | null = null;
  order: any = null;
  deliveryBlobUrl: string | null = null;
  packingNoteText = '';
  loading = false;

  constructor(
    private readonly route: ActivatedRoute,
    private readonly orderService: TransportOrderService,
    private readonly loadingOps: LoadingOpsService,
    private readonly auth: AuthService,
    private readonly toastr: ToastrService,
  ) {}

  async ngOnInit(): Promise<void> {
    const id = Number(this.route.snapshot.paramMap.get('id'));
    if (!id || isNaN(id)) {
      this.toastr.error('Invalid order id');
      return;
    }
    this.orderId = id;
    this.loading = true;

    try {
      const res = await firstValueFrom(this.orderService.getOrderById(id));
      this.order = res.data ?? res;
    } catch (e) {
      console.error('Failed to load order', e);
      this.toastr.error('Failed to load order details');
    }

    // fetch delivery note blob (try admin first, then alternate)
    if (!this.auth.isAuthenticated()) {
      this.toastr.error('Please sign in to access delivery note');
      this.loading = false;
      return;
    }

    try {
      const blob = await firstValueFrom(this.orderService.getDeliveryNote(id));
      if (blob) this.deliveryBlobUrl = URL.createObjectURL(blob as Blob);
    } catch (err: any) {
      console.debug('Primary delivery note failed', err?.status);
      try {
        const blob2 = await firstValueFrom(this.orderService.getDeliveryNoteAlternate(id));
        if (blob2) this.deliveryBlobUrl = URL.createObjectURL(blob2 as Blob);
      } catch (err2) {
        console.error('Alternate delivery note failed', err2);
        this.toastr.error('Delivery note not available');
      }
    }

    // try to find packing note from loading session
    try {
      const dispatchId =
        (this.order?.dispatches && this.order.dispatches.length && this.order.dispatches[0].id) ||
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
                const text = await (blob as Blob).text();
                this.packingNoteText = text;
              }
            } catch (e) {
              console.warn('Failed to download packing note', e);
            }
          }
        }
      }
    } catch (e) {
      console.debug('No packing note available', e);
    }

    this.loading = false;
  }

  printPage(): void {
    window.print();
  }

  downloadDeliveryNote(): void {
    if (!this.deliveryBlobUrl) {
      this.toastr.error('No delivery note available');
      return;
    }
    const a = document.createElement('a');
    a.href = this.deliveryBlobUrl;
    a.download = `delivery-note-${this.order?.orderReference ?? this.orderId}.pdf`;
    document.body.appendChild(a);
    a.click();
    a.remove();
  }
}
