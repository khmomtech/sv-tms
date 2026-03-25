/* eslint-disable @typescript-eslint/consistent-type-imports */
import { CommonModule } from '@angular/common';
import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';

import type { Shipment } from '../../models/shipment.model';
import { ShipmentService } from '../../services/shipment.service';
import { NotificationService } from '../../services/notification.service';

@Component({
  selector: 'app-shipment-detail',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './shipment-detail.component.html',
  styleUrls: ['./shipment-detail.component.css'],
})
export class ShipmentDetailComponent implements OnInit {
  shipment: Shipment | null = null;
  loading = true;
  error: string | null = null;

  constructor(
    private readonly route: ActivatedRoute,
    private readonly router: Router,
    private readonly shipmentService: ShipmentService,
    private readonly notify: NotificationService,
  ) {}

  ngOnInit(): void {
    const idParam = this.route.snapshot.paramMap.get('id');
    const id = idParam ? Number(idParam) : NaN;
    if (!id || Number.isNaN(id)) {
      this.error = 'Invalid shipment id.';
      this.loading = false;
      return;
    }
    this.loadShipment(id);
  }

  loadShipment(id: number): void {
    this.loading = true;
    this.shipmentService.getShipmentById(id).subscribe({
      next: (res) => {
        this.shipment = res?.data ?? res ?? null;
        this.loading = false;
      },
      error: () => {
        this.error = 'Failed to load shipment details.';
        this.loading = false;
        this.notify.error('Failed to load shipment details.');
      },
    });
  }

  backToList(): void {
    this.router.navigate(['/shipments']);
  }
}
