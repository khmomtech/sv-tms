import { CommonModule } from '@angular/common';
import { Component, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { RouterModule } from '@angular/router';
import { ToastrService } from 'ngx-toastr';

import type { LoadingQueue, WarehouseCode } from '../../models/loading-queue.model';
import { LoadingOpsService } from '../../services/loading-ops.service';

@Component({
  selector: 'app-queue-board',
  standalone: true,
  imports: [CommonModule, RouterModule, FormsModule],
  templateUrl: './queue-board.component.html',
})
export class QueueBoardComponent implements OnInit {
  warehouses: WarehouseCode[] = ['KHB', 'W2', 'W3'];
  selectedWarehouse: WarehouseCode = 'KHB';

  queue: LoadingQueue[] = [];
  loading = false;

  constructor(
    private readonly loadingOpsService: LoadingOpsService,
    private readonly toastr: ToastrService,
  ) {}

  ngOnInit(): void {
    this.loadQueue();
  }

  loadQueue(): void {
    this.loading = true;
    this.loadingOpsService.queueByWarehouse(this.selectedWarehouse).subscribe({
      next: (data) => {
        this.queue = data || [];
        this.loading = false;
      },
      error: (err) => {
        console.error('Failed to load queue', err);
        this.toastr.error(err?.error?.message || 'Unable to load queue');
        this.loading = false;
      },
    });
  }

  callToBay(entry: LoadingQueue, bay?: string): void {
    this.loadingOpsService.callToBay(entry.id, bay || entry.bay || '').subscribe({
      next: (updated) => {
        this.toastr.success('Queue entry called.');
        this.replaceQueueEntry(updated);
      },
      error: (err) => {
        console.error(err);
        this.toastr.error(err?.error?.message || 'Unable to call entry');
      },
    });
  }

  startLoading(entry: LoadingQueue): void {
    this.loadingOpsService
      .startLoading({
        dispatchId: entry.dispatchId,
        queueId: entry.id,
        warehouseCode: entry.warehouseCode,
        bay: entry.bay || null,
      })
      .subscribe({
        next: () => {
          this.toastr.success('Loading started.');
          this.loadQueue();
        },
        error: (err) => {
          console.error(err);
          this.toastr.error(err?.error?.message || 'Unable to start loading');
        },
      });
  }

  private replaceQueueEntry(updated: LoadingQueue): void {
    const idx = this.queue.findIndex((q) => q.id === updated.id);
    if (idx >= 0) {
      this.queue[idx] = updated;
      this.queue = [...this.queue];
    } else {
      this.loadQueue();
    }
  }
}
