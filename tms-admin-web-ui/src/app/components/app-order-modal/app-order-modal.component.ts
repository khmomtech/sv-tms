import { CommonModule } from '@angular/common';
import type { OnInit } from '@angular/core';
import { Component, EventEmitter, Input, Output } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Subject } from 'rxjs';
import { debounceTime, distinctUntilChanged } from 'rxjs/operators';

import type { TransportOrder } from '../../models/transport-order.model';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { TransportOrderService } from '../../services/transport-order.service';

@Component({
  selector: 'app-order-modal',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './app-order-modal.component.html',
  styleUrls: ['./app-order-modal.component.css'],
})
export class AppOrderModalComponent implements OnInit {
  @Input() visible = false; //  Needed for binding with [visible]

  @Output() orderSelected = new EventEmitter<TransportOrder>();
  @Output() close = new EventEmitter<void>();

  orders: TransportOrder[] = [];
  searchText: string = '';
  readonly searchSubject = new Subject<string>();

  constructor(private readonly transportOrderService: TransportOrderService) {}

  ngOnInit(): void {
    this.loadAllOrders();

    this.searchSubject.pipe(debounceTime(300), distinctUntilChanged()).subscribe((query) => {
      if (query.length > 1) {
        this.searchOrders(query);
      } else {
        this.loadAllOrders();
      }
    });
  }

  onSearchInputChange(): void {
    this.searchSubject.next(this.searchText);
  }

  loadAllOrders(): void {
    this.transportOrderService.getAllOrders().subscribe({
      next: (response) => {
        this.orders = response?.data || [];
      },
      error: (err: any) => {
        console.error('Failed to load orders', err);
        this.orders = [];
      },
    });
  }

  searchOrders(query: string): void {
    this.transportOrderService.searchOrders(query).subscribe({
      next: (response) => {
        this.orders = response?.data || [];
      },
      error: (err: any) => {
        console.error('Order search failed', err);
        this.orders = [];
      },
    });
  }

  select(order: TransportOrder): void {
    this.orderSelected.emit(order);
    this.close.emit();
  }

  cancel(): void {
    this.close.emit();
  }
}
