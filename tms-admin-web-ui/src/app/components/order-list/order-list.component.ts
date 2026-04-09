import { Component, OnInit, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router, RouterModule } from '@angular/router';
import { Subject, Subscription, of } from 'rxjs';
import { debounceTime, distinctUntilChanged, switchMap, catchError, tap } from 'rxjs/operators';
import { TransportOrderService } from '../../services/transport-order.service';
import { MatDialog } from '@angular/material/dialog';
import { ConfirmationDialogComponent } from '../../shared/components/confirmation-dialog/confirmation-dialog.component';
import { NotificationService } from '../../services/notification.service';

@Component({
  selector: 'app-order-list',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule],
  templateUrl: './order-list.component.html',
  styleUrls: ['./order-list.component.css'],
})
export class OrderListComponent implements OnInit, OnDestroy {
  search = '';
  fromDate = '';
  toDate = '';
  status: 'All' | string = 'All';
  newestFirst = true;

  orders: any[] = [];
  page = 0;
  size = 10;
  totalPages = 0;
  totalElements = 0;
  loading = false;
  loadingSearch = false;
  error = '';

  // Autocomplete suggestions
  customerSuggestions: string[] = [];
  showSuggestions = false;

  // Streams
  private searchSubject = new Subject<string>();
  private suggestionSubject = new Subject<string>();
  private subs = new Subscription();
  // keyboard navigation for suggestions
  suggestionActiveIndex = -1;

  constructor(
    private readonly transportOrderService: TransportOrderService,
    public router: Router,
    private readonly dialog: MatDialog,
    private readonly notification: NotificationService,
  ) {}

  ngOnInit(): void {
    // Debounced main search (reduces repeated API calls while typing)
    this.subs.add(
      this.searchSubject
        .pipe(
          tap(() => (this.loadingSearch = true)),
          debounceTime(300),
          distinctUntilChanged(),
        )
        .subscribe((q) => {
          this.search = q;
          this.page = 0;
          this.fetchOrders();
          this.loadingSearch = false;
        }),
    );

    // Customer autocomplete suggestions (small result set)
    this.subs.add(
      this.suggestionSubject
        .pipe(
          debounceTime(200),
          distinctUntilChanged(),
          switchMap((q) => {
            if (!q || q.length < 2) return of([]);
            return this.transportOrderService
              .searchCustomers(q, 0, 6)
              .pipe(catchError(() => of([])));
          }),
        )
        .subscribe((resp: any) => {
          const list = (resp && resp.data) || resp || [];
          this.customerSuggestions = Array.isArray(list)
            ? (list as any[]).map((c) => c.name || c.displayName || `${c.id}`)
            : [];
          this.showSuggestions = this.customerSuggestions.length > 0;
        }),
    );

    // Initial load
    this.fetchOrders();
  }

  ngOnDestroy(): void {
    this.subs.unsubscribe();
  }

  // Called from template on change to search text
  onSearchInput(value: string): void {
    this.searchSubject.next(value.trim());
    this.suggestionSubject.next(value.trim());
  }

  onInputKeydown(e: KeyboardEvent): void {
    if (!this.showSuggestions) return;
    const count = this.customerSuggestions.length;
    if (e.key === 'ArrowDown') {
      e.preventDefault();
      this.suggestionActiveIndex = Math.min(this.suggestionActiveIndex + 1, count - 1);
    } else if (e.key === 'ArrowUp') {
      e.preventDefault();
      this.suggestionActiveIndex = Math.max(this.suggestionActiveIndex - 1, 0);
    } else if (e.key === 'Enter') {
      if (this.suggestionActiveIndex >= 0 && this.suggestionActiveIndex < count) {
        e.preventDefault();
        this.onSuggestionChoose(this.customerSuggestions[this.suggestionActiveIndex]);
      }
    } else if (e.key === 'Escape') {
      this.showSuggestions = false;
      this.suggestionActiveIndex = -1;
    }
  }

  onSuggestionChoose(name: string): void {
    this.search = name;
    this.showSuggestions = false;
    this.searchSubject.next(name);
  }

  // Quick date presets
  applyPreset(preset: '7d' | '30d' | 'month' | 'all'): void {
    const now = new Date();
    if (preset === 'all') {
      this.fromDate = '';
      this.toDate = '';
    } else {
      const to = new Date(now);
      let from = new Date(now);
      if (preset === '7d') from.setDate(now.getDate() - 7);
      if (preset === '30d') from.setDate(now.getDate() - 30);
      if (preset === 'month') {
        from = new Date(now.getFullYear(), now.getMonth(), 1);
        to.setMonth(now.getMonth() + 1);
        to.setDate(0);
      }
      this.fromDate = from.toISOString().slice(0, 10);
      this.toDate = to.toISOString().slice(0, 10);
    }
    this.page = 0;
    this.fetchOrders();
  }

  // Show active filter chips
  removeFilter(key: 'search' | 'status' | 'dates'): void {
    if (key === 'search') this.search = '';
    if (key === 'status') this.status = 'All';
    if (key === 'dates') {
      this.fromDate = '';
      this.toDate = '';
    }
    this.page = 0;
    this.fetchOrders();
  }

  fetchOrders(): void {
    this.loading = true;
    this.error = '';
    const sort = this.newestFirst ? 'desc' : 'asc';
    const statusParam = this.status === 'All' ? '' : this.status;
    this.transportOrderService
      .getFilteredOrders(
        this.search.trim(),
        statusParam,
        this.fromDate,
        this.toDate,
        sort,
        this.page,
        this.size,
      )
      .pipe(
        catchError((err) => {
          this.error = err?.message || 'Failed to load orders';
          return of(null);
        }),
      )
      .subscribe((resp: any) => {
        this.loading = false;
        const d = resp?.data ?? resp;
        if (!d) {
          this.orders = [];
          this.totalElements = 0;
          this.totalPages = 0;
          return;
        }
        if (d?.content && Array.isArray(d.content)) {
          this.orders = d.content;
          this.totalElements = d.totalElements ?? d.total ?? 0;
          this.totalPages = d.totalPages ?? Math.ceil((this.totalElements || 0) / this.size);
        } else if (Array.isArray(d)) {
          this.orders = d;
          this.totalElements = d.length;
          this.totalPages = Math.ceil(this.totalElements / this.size);
        } else {
          this.orders = d?.items ?? [];
          this.totalElements = d?.totalElements ?? (this.orders.length || 0);
          this.totalPages = d?.totalPages ?? Math.ceil(this.totalElements / this.size);
        }
        // reset suggestion index when we fetch new data
        this.suggestionActiveIndex = -1;
      });
  }

  onSearchChangeEnter(): void {
    // immediate fetch when user presses Enter
    this.searchSubject.next(this.search.trim());
  }

  clearFilters(): void {
    this.search = '';
    this.fromDate = '';
    this.toDate = '';
    this.status = 'All';
    this.newestFirst = true;
    this.page = 0;
    this.fetchOrders();
  }

  prevPage(): void {
    if (this.page > 0) {
      this.page--;
      this.fetchOrders();
    }
  }

  nextPage(): void {
    if (this.totalPages === 0 || this.page < this.totalPages - 1) {
      this.page++;
      this.fetchOrders();
    }
  }

  viewOrder(id: number): void {
    this.router.navigate(['/shipments', id]);
  }

  deleteOrder(id: number): void {
    const ref = this.dialog.open(ConfirmationDialogComponent, {
      data: {
        title: 'Delete Shipment',
        message: `Are you sure you want to delete shipment order #${id}? This action cannot be undone.`,
        confirmText: 'Delete',
        cancelText: 'Cancel',
        variant: 'danger',
      },
      width: '420px',
    });

    ref.afterClosed().subscribe((confirmed) => {
      if (!confirmed) return;
      this.transportOrderService.deleteOrder(id).subscribe({
        next: () => this.fetchOrders(),
        error: (err) =>
          this.notification.simulateNotification('Error', err?.message ?? 'Failed to delete order'),
      });
    });
  }
}
