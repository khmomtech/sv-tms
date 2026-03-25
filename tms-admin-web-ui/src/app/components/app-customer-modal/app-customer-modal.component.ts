import { CommonModule } from '@angular/common';
import { Component, EventEmitter, Output } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Subject } from 'rxjs';
import { debounceTime, distinctUntilChanged, switchMap } from 'rxjs/operators';

// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { CustomerService } from '../../services/custommer.service';

@Component({
  selector: 'app-customer-modal',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './app-customer-modal.component.html',
  styleUrls: ['./app-customer-modal.component.css'],
})
export class AppCustomerModalComponent {
  @Output() close = new EventEmitter<void>();
  @Output() select = new EventEmitter<any>();

  searchText: string = '';
  filteredCustomers: any[] = [];
  isLoading: boolean = false;

  private readonly searchSubject = new Subject<string>();

  constructor(private readonly customerService: CustomerService) {
    this.searchSubject
      .pipe(
        debounceTime(300),
        distinctUntilChanged(),
        switchMap((query) => {
          this.isLoading = true;
          return this.customerService.searchCustomers(query); // returns Customer[]
        }),
      )
      .subscribe({
        next: (customers) => {
          this.filteredCustomers = Array.isArray(customers) ? customers : [];
          this.isLoading = false;
        },
        error: (err) => {
          console.error('Error fetching customers:', err);
          this.filteredCustomers = [];
          this.isLoading = false;
        },
      });
  }

  /** Called when search input changes */
  onSearchChange(): void {
    const query = this.searchText.trim();
    if (query.length > 1) {
      this.searchSubject.next(query);
    } else {
      this.filteredCustomers = [];
    }
  }

  /** Select a customer and emit event */
  selectCustomer(customer: any): void {
    this.select.emit(customer);
    this.closeModal();
  }

  /** Close modal */
  closeModal(): void {
    this.close.emit();
  }

  /** Manually triggered by close button */
  onClose(): void {
    this.closeModal();
  }
}
