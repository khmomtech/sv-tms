import { CommonModule } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { Component, EventEmitter, Output } from '@angular/core';
import { FormsModule } from '@angular/forms';

// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { TransportOrderService } from '../../services/transport-order.service';

@Component({
  selector: 'app-customer-modal',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './customer-modal.component.html',
  styleUrls: ['./customer-modal.component.css'],
})
export class CustomerModalComponent {
  @Output() close = new EventEmitter<void>();
  @Output() select = new EventEmitter<any>();

  searchText: string = '';
  customers: any[] = [];

  constructor(private transportOrderService: TransportOrderService) {}

  /**  Fetch Customers from API */
  fetchCustomers(): void {
    if (this.searchText.length > 1) {
      this.transportOrderService.searchCustomers(this.searchText).subscribe({
        next: (response) => {
          this.customers = response.data;
        },
        error: (error) => {
          console.error('Customer search failed:', error);
        },
      });
    }
  }

  /**  Select a Customer */
  selectCustomer(customer: any) {
    this.select.emit(customer);
    this.close.emit();
  }
}
