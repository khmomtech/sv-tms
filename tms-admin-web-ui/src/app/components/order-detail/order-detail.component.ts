/* eslint-disable @typescript-eslint/consistent-type-imports */
import { CommonModule } from '@angular/common';
import { OnInit } from '@angular/core';
import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';

import type { Order } from '../../models/order.model';
import { OrderService } from '../../services/order.service';

@Component({
  selector: 'app-order-detail',
  templateUrl: './order-detail.component.html',
  standalone: true,
  imports: [CommonModule, FormsModule],
  styleUrls: ['./order-detail.component.css'],
})
export class OrderDetailComponent implements OnInit {
  order: Order | null = null;
  errorMessage: string | null = null;
  isLoading = true;

  constructor(
    private route: ActivatedRoute,
    public router: Router,
    private orderService: OrderService,
  ) {}

  ngOnInit() {
    const orderId = this.route.snapshot.paramMap.get('id');
    if (orderId) {
      this.loadOrderDetails(+orderId);
    }
  }

  loadOrderDetails(orderId: number) {
    this.orderService.getOrderById(orderId).subscribe({
      next: (response) => {
        this.isLoading = false;
        this.order = response.data;
      },
      error: (error) => {
        this.isLoading = false;
        this.errorMessage = error.message;
      },
    });
  }

  goBack() {
    this.router.navigate(['/order']);
  }

  openDispatchDetail(dispatchId?: number) {
    if (dispatchId) {
      this.router.navigate(['/dispatch', dispatchId]);
    }
  }
}
