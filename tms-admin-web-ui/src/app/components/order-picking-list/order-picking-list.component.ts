import { CommonModule } from '@angular/common';
import {
  Component,
  computed,
  effect,
  signal,
  untracked,
  ViewChild,
  ElementRef,
} from '@angular/core';
import { ActivatedRoute, Router, RouterModule } from '@angular/router';
import { ToastrService } from 'ngx-toastr';
import jsPDF from 'jspdf';
import html2canvas from 'html2canvas';

import type { OrderItemDto } from '../../services/order-item.model';
import type { TransportOrderResponseDto } from '../../models/transport-order-response.model';
import { TransportOrderService } from '../../services/transport-order.service';
import { AuthService } from '../../services/auth.service';

@Component({
  selector: 'app-order-picking-list',
  standalone: true,
  imports: [CommonModule, RouterModule],
  templateUrl: './order-picking-list.component.html',
  styleUrls: ['./order-picking-list.component.css'],
})
export class OrderPickingListComponent {
  orderId = 0;
  loading = signal(false);
  error = signal('');
  exporting = signal(false);
  currentUserName = computed(() => this.authService.getCurrentUser()?.username || 'User');
  assignedTruck = computed(() => {
    const order = this.order();
    if (!order) return '—';

    // Primary: Get licensePlate from first dispatch
    if (order.dispatches && order.dispatches.length > 0) {
      const dispatch = order.dispatches[0] as any;
      // Try licensePlate field directly from dispatch
      if (dispatch.licensePlate) {
        return dispatch.licensePlate;
      }
      // Try vehicle object
      if (dispatch.vehicle?.licensePlate) {
        return dispatch.vehicle.licensePlate;
      }
    }

    // Fallback: Try assignedDriver
    if (order.assignedDriver && 'licensePlate' in order.assignedDriver) {
      return (order.assignedDriver as any).licensePlate || '—';
    }

    // Last fallback: vehicleNumber
    if (order.assignedDriver?.vehicleNumber) {
      return order.assignedDriver.vehicleNumber;
    }

    return '—';
  });

  @ViewChild('formContainer') formContainer!: ElementRef;

  private readonly orderSignal = signal<TransportOrderResponseDto | null>(null);
  readonly order = computed(() => this.orderSignal());
  readonly items = computed(() => this.orderSignal()?.items ?? []);
  readonly totalQty = computed(() =>
    (this.orderSignal()?.items ?? []).reduce((sum, it) => sum + (Number(it.quantity) || 0), 0),
  );
  readonly totalLines = computed(() => (this.orderSignal()?.items ?? []).length);
  readonly totalPallets = computed(() =>
    (this.orderSignal()?.items ?? []).reduce((sum, it) => sum + (it.palletType ? 1 : 0), 0),
  );
  readonly rows = computed(() => {
    const items = this.orderSignal()?.items ?? [];
    const blanks = Math.max(0, 14 - items.length);
    return [...items, ...Array(blanks).fill(null)];
  });

  constructor(
    private readonly route: ActivatedRoute,
    private readonly router: Router,
    private readonly orderService: TransportOrderService,
    private readonly toastr: ToastrService,
    private readonly authService: AuthService,
  ) {
    // Initialize on route param change
    effect(() => {
      const idParam = this.route.snapshot.paramMap.get('id');
      const id = idParam ? Number(idParam) : 0;
      if (id > 0) {
        this.orderId = id;
        untracked(() => this.fetchOrder());
      } else {
        this.error.set('Invalid order id');
        this.toastr.error('Invalid order id');
      }
    });
  }

  goBack(): void {
    this.router.navigate(['/orders', this.orderId]);
  }

  print(): void {
    // Ensure DOM is updated before printing
    setTimeout(() => {
      window.print();
    }, 200);
  }

  async exportPdf(): Promise<void> {
    if (!this.formContainer) {
      this.toastr.error('Form not ready for export');
      return;
    }

    try {
      this.exporting.set(true);

      // Force A4 landscape sizing via CSS during capture
      document.body.classList.add('pdf-export');
      await new Promise((r) => requestAnimationFrame(() => r(null)));

      // Capture the form container as canvas
      const canvas = await html2canvas(this.formContainer.nativeElement, {
        scale: 3,
        useCORS: true,
        logging: false,
        backgroundColor: '#ffffff',
      });

      // Create PDF as true A4 landscape
      const pdf = new jsPDF({
        orientation: 'landscape',
        unit: 'mm',
        format: 'a4',
      });

      const imgData = canvas.toDataURL('image/png');
      const pageWidth = pdf.internal.pageSize.getWidth(); // 297mm in landscape
      const pageHeight = pdf.internal.pageSize.getHeight(); // 210mm in landscape

      // Fit image within A4 landscape with margins, preserving aspect ratio
      const margin = 5; // mm
      const availableWidth = pageWidth - margin * 2;
      const availableHeight = pageHeight - margin * 2;
      const imgRatio = canvas.width / canvas.height;

      let renderWidth = availableWidth;
      let renderHeight = renderWidth / imgRatio;
      if (renderHeight > availableHeight) {
        renderHeight = availableHeight;
        renderWidth = renderHeight * imgRatio;
      }

      const offsetX = margin + (availableWidth - renderWidth) / 2;
      const offsetY = margin + (availableHeight - renderHeight) / 2;

      pdf.addImage(imgData, 'PNG', offsetX, offsetY, renderWidth, renderHeight);

      // Generate filename with order reference
      const orderRef = this.order()?.orderReference || 'PickingList';
      const filename = `Picking_List_${orderRef}_${new Date().getTime()}.pdf`;

      // Download PDF
      pdf.save(filename);
      this.toastr.success('PDF exported successfully');
    } catch (error) {
      console.error('PDF export failed:', error);
      this.toastr.error('Failed to export PDF');
    } finally {
      document.body.classList.remove('pdf-export');
      this.exporting.set(false);
    }
  }

  private fetchOrder(): void {
    this.loading.set(true);
    this.error.set('');
    this.orderService.getOrderById(this.orderId).subscribe({
      next: (res) => {
        const data: any = (res as any).data ?? res;
        this.orderSignal.set(data);
        this.loading.set(false);
      },
      error: (err) => {
        console.error('Failed to load order', err);
        const errorMsg = err?.message || 'Unable to load picking list';
        this.error.set(errorMsg);
        this.toastr.error(errorMsg);
        this.loading.set(false);
      },
    });
  }

  trackItem(_index: number, item: OrderItemDto): number {
    return item.id;
  }
}
