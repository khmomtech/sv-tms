/* eslint-disable @typescript-eslint/consistent-type-imports */
import { CommonModule } from '@angular/common';
import { HttpErrorResponse } from '@angular/common/http';
import { Component, ElementRef, HostListener, inject, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';

import type { Order } from '../../models/order.model';
import { OrderService } from '../../services/order.service';
import { ConfirmService } from '../../services/confirm.service';

@Component({
  selector: 'app-order',
  templateUrl: './order.component.html',
  standalone: true,
  imports: [CommonModule, FormsModule],
  styleUrls: ['./order.component.css'],
})
export class OrderComponent implements OnInit {
  private confirm = inject(ConfirmService);
  orders: Order[] = [];
  filteredList: Order[] = [];
  searchQuery = '';
  isModalOpen = false;
  isEditing = false;
  selectedOrder: Order = {} as Order;
  dropdownOpen: number | null = null;
  currentPage = 0;
  totalPages = 1;
  errorMessage: string | null = null;
  isLoading = false;

  constructor(
    private orderService: OrderService,
    private router: Router,
  ) {}

  ngOnInit() {
    this.loadOrders();
  }

  loadOrders() {
    this.isLoading = true;
    this.orderService.getOrders(this.currentPage, 5).subscribe({
      next: (response) => {
        this.isLoading = false;
        if (response.success) {
          this.orders = response.data?.content || [];
          this.filteredList = [...this.orders];
          this.totalPages = response.data?.totalPages || 1;
        } else {
          this.errorMessage = 'Failed to load orders.';
        }
      },
      error: (error) => {
        this.isLoading = false;
        this.errorMessage = error.message;
      },
    });
  }

  filterOrders() {
    this.filteredList = this.orders.filter((order) =>
      order.customerName.toLowerCase().includes(this.searchQuery.toLowerCase()),
    );
  }

  openOrderModal(order: Order | null = null) {
    this.isEditing = !!order;
    this.selectedOrder = order ? { ...order } : ({} as Order);
    this.isModalOpen = true;
  }

  closeModal() {
    this.isModalOpen = false;
  }

  saveOrder() {
    if (this.isEditing) {
      this.orderService.updateOrder(this.selectedOrder.id!, this.selectedOrder).subscribe({
        next: () => this.loadOrders(),
        error: (error) => (this.errorMessage = error.message),
      });
    } else {
      this.orderService.createOrder(this.selectedOrder).subscribe({
        next: () => this.loadOrders(),
        error: (error) => (this.errorMessage = error.message),
      });
    }
    this.closeModal();
  }

  async deleteOrder(orderId: number): Promise<void> {
    if (!(await this.confirm.confirm('Are you sure you want to delete this order?'))) return;
    this.orderService.deleteOrder(orderId).subscribe({
      next: () => this.loadOrders(),
      error: (error) => (this.errorMessage = error.message),
    });
  }

  toggleDropdown(id: number) {
    this.dropdownOpen = this.dropdownOpen === id ? null : id;
  }

  prevPage() {
    if (this.currentPage > 0) {
      this.currentPage--;
      this.loadOrders();
    }
  }

  nextPage() {
    if (this.currentPage < this.totalPages - 1) {
      this.currentPage++;
      this.loadOrders();
    }
  }

  viewOrderDetails(order: Order) {
    this.router.navigate([`/orders/${order.id}`]);
  }
}
