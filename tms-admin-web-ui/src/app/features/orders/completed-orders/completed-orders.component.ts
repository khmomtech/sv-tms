import { CommonModule } from '@angular/common';
import { Component, OnInit } from '@angular/core';
import { Router, ActivatedRoute } from '@angular/router';

import { TransportOrderListComponent } from '../../../components/transport-order-list/transport-order-list.component';

@Component({
  selector: 'app-completed-orders',
  standalone: true,
  imports: [CommonModule, TransportOrderListComponent],
  templateUrl: './completed-orders.component.html',
  styleUrls: ['./completed-orders.component.css'],
})
export class CompletedOrdersComponent implements OnInit {
  constructor(
    private router: Router,
    private route: ActivatedRoute,
  ) {}

  // Local UI state (drives query params)
  search = '';
  pageSize = 20;
  currentPage = 0;
  fromDate = '';
  toDate = '';

  get currentPageDisplay(): number {
    return this.currentPage + 1;
  }

  get totalPagesDisplay(): number {
    return 1;
  }

  ngOnInit(): void {
    // Ensure the list receives the status query param so it pre-filters to COMPLETED/DELIVERED
    this.router.navigate([], {
      relativeTo: this.route,
      queryParams: { status: 'COMPLETED', completedOnly: 'true' },
      queryParamsHandling: 'merge',
    });
  }

  private updateQueryParams(params: Record<string, any>): void {
    this.router.navigate([], {
      relativeTo: this.route,
      queryParams: params,
      queryParamsHandling: 'merge',
    });
  }

  onSearch(value: string): void {
    this.search = value;
    this.updateQueryParams({ search: value, page: 0 });
  }

  onPageSizeChange(value: string | number): void {
    const size = typeof value === 'string' ? parseInt(value, 10) || 20 : value;
    this.pageSize = size;
    this.updateQueryParams({ pageSize: size, page: 0 });
  }

  onFromDateChange(value: string): void {
    this.fromDate = value;
    this.updateQueryParams({ fromDate: value, page: 0 });
  }

  onToDateChange(value: string): void {
    this.toDate = value;
    this.updateQueryParams({ toDate: value, page: 0 });
  }

  prevPage(): void {
    if (this.currentPage > 0) {
      this.currentPage -= 1;
      this.updateQueryParams({ page: this.currentPage });
    }
  }

  nextPage(): void {
    this.currentPage += 1;
    this.updateQueryParams({ page: this.currentPage });
  }
}
