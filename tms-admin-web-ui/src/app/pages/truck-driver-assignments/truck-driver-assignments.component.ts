import { CommonModule } from '@angular/common';
import { Component, OnInit, OnDestroy } from '@angular/core';
import { FormBuilder, FormGroup, ReactiveFormsModule } from '@angular/forms';
import { RouterModule, Router } from '@angular/router';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { Subject, debounceTime, distinctUntilChanged, takeUntil } from 'rxjs';

import { VehicleDriverService } from '../../services/vehicle-driver.service';
import { DriverService } from '../../services/driver.service';
import { VehicleService } from '../../services/vehicle.service';
import { ConfirmService } from '../../services/confirm.service';

interface Assignment {
  id: number;
  driverId: number;
  driverName: string;
  vehicleId: number;
  truckPlate: string;
  assignedAt: string;
  assignedBy: string;
  reason?: string;
  active: boolean;
  version: number;
}

interface PaginationInfo {
  currentPage: number;
  totalPages: number;
  totalElements: number;
  pageSize: number;
}

@Component({
  selector: 'app-truck-driver-assignments',
  standalone: true,
  imports: [
    CommonModule,
    ReactiveFormsModule,
    RouterModule,
    MatIconModule,
    MatProgressSpinnerModule,
  ],
  templateUrl: './truck-driver-assignments.component.html',
  styleUrls: ['./truck-driver-assignments.component.css'],
})
export class TruckDriverAssignmentsComponent implements OnInit, OnDestroy {
  private destroy$ = new Subject<void>();

  // Expose Math to template
  Math = Math;

  assignments: Assignment[] = [];
  filteredAssignments: Assignment[] = [];

  loading = false;
  errorMessage = '';
  successMessage = '';

  // Filter form
  filterForm: FormGroup;

  // Pagination
  pagination: PaginationInfo = {
    currentPage: 1,
    totalPages: 1,
    totalElements: 0,
    pageSize: 10,
  };

  // Available page sizes
  pageSizes = [10, 25, 50, 100];

  // Filter options
  drivers: any[] = [];
  vehicles: any[] = [];
  statusOptions = [
    { value: 'all', label: 'All Statuses' },
    { value: 'active', label: 'Active Only' },
    { value: 'inactive', label: 'Inactive Only' },
  ];

  // Sort options
  sortField = 'assignedAt';
  sortDirection: 'asc' | 'desc' = 'desc';

  constructor(
    private assignmentService: VehicleDriverService,
    private driverService: DriverService,
    private vehicleService: VehicleService,
    private fb: FormBuilder,
    private router: Router,
    private confirm: ConfirmService,
  ) {
    this.filterForm = this.fb.group({
      searchQuery: [''],
      driverId: [''],
      vehicleId: [''],
      status: ['all'],
      dateFrom: [''],
      dateTo: [''],
    });
  }

  ngOnInit(): void {
    this.loadDrivers();
    this.loadVehicles();
    this.loadAssignments();
    this.setupFilterListeners();
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  private setupFilterListeners(): void {
    this.filterForm.valueChanges
      .pipe(debounceTime(300), distinctUntilChanged(), takeUntil(this.destroy$))
      .subscribe(() => {
        this.pagination.currentPage = 1; // Reset to first page on filter change
        this.applyFilters();
      });
  }

  private loadDrivers(): void {
    this.driverService
      .getDrivers(0, 1000)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (response) => {
          if (response.success && response.data) {
            // Backend returns PageResponse<DriverDto>
            if ('content' in response.data && Array.isArray(response.data.content)) {
              this.drivers = response.data.content;
            } else if (Array.isArray(response.data)) {
              this.drivers = response.data;
            } else {
              this.drivers = [];
            }
            console.log('📋 Loaded', this.drivers.length, 'drivers for filter');
          } else {
            this.drivers = [];
          }
        },
        error: (error) => {
          console.error('❌ Failed to load drivers:', error);
          this.drivers = [];
        },
      });
  }

  private loadVehicles(): void {
    this.vehicleService
      .getVehicles(0, 1000)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (response) => {
          if (response.success && response.data) {
            // Backend returns Page<VehicleDto>
            if ('content' in response.data && Array.isArray(response.data.content)) {
              this.vehicles = response.data.content;
            } else if (Array.isArray(response.data)) {
              this.vehicles = response.data;
            } else {
              this.vehicles = [];
            }
            console.log('🚛 Loaded', this.vehicles.length, 'vehicles for filter');
          } else {
            this.vehicles = [];
          }
        },
        error: (error) => {
          console.error('❌ Failed to load vehicles:', error);
          this.vehicles = [];
        },
      });
  }

  loadAssignments(): void {
    this.loading = true;
    this.errorMessage = '';
    this.successMessage = '';

    // Try to load from API first, fall back to mock data if endpoint not available
    this.assignmentService
      .getAssignments()
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (response) => {
          if (response.success && Array.isArray(response.data)) {
            this.assignments = response.data.map((assignment) => ({
              id: assignment.id,
              driverId: assignment.driverId,
              driverName: assignment.driverName,
              vehicleId: assignment.vehicleId,
              truckPlate: assignment.truckPlate,
              assignedAt: assignment.assignedAt,
              assignedBy: assignment.assignedBy,
              reason: assignment.reason,
              active: assignment.active,
              version: assignment.version || 1,
            }));
            console.log('Loaded', this.assignments.length, 'assignments from API');
          } else {
            console.warn('⚠️ Unexpected API response, using mock data');
            this.assignments = this.generateMockData();
          }
          this.applyFilters();
          this.loading = false;
        },
        error: (error) => {
          console.warn(
            '⚠️ API endpoint not available (status:',
            error.status,
            '), using mock data',
          );
          // Use mock data as fallback
          this.assignments = this.generateMockData();
          this.applyFilters();
          this.loading = false;

          // Only show error if it's not a 404 (endpoint not implemented)
          if (error.status !== 404) {
            this.errorMessage = 'Failed to load assignments from server. Showing sample data.';
            setTimeout(() => (this.errorMessage = ''), 5000);
          }
        },
      });
  }

  private generateMockData(): Assignment[] {
    const mockAssignments: Assignment[] = [];
    const driverNames = [
      'John Doe',
      'Jane Smith',
      'Mike Johnson',
      'Sarah Williams',
      'Tom Brown',
      'Emily Davis',
      'Chris Wilson',
      'Lisa Anderson',
    ];
    const plates = [
      'ABC-123',
      'XYZ-789',
      'DEF-456',
      'GHI-012',
      'JKL-345',
      'MNO-678',
      'PQR-901',
      'STU-234',
    ];

    for (let i = 1; i <= 50; i++) {
      mockAssignments.push({
        id: i,
        driverId: i,
        driverName: driverNames[i % driverNames.length],
        vehicleId: i,
        truckPlate: plates[i % plates.length],
        assignedAt: new Date(Date.now() - Math.random() * 30 * 24 * 60 * 60 * 1000).toISOString(),
        assignedBy: 'Admin User',
        reason: i % 3 === 0 ? 'Regular assignment rotation' : undefined,
        active: i % 5 !== 0, // Every 5th is inactive
        version: 1,
      });
    }

    return mockAssignments;
  }

  applyFilters(): void {
    const filters = this.filterForm.value;
    let filtered = [...this.assignments];

    // Search query (driver name or truck plate)
    if (filters.searchQuery?.trim()) {
      const query = filters.searchQuery.toLowerCase().trim();
      filtered = filtered.filter(
        (a) =>
          a.driverName.toLowerCase().includes(query) || a.truckPlate.toLowerCase().includes(query),
      );
    }

    // Driver filter
    if (filters.driverId) {
      filtered = filtered.filter((a) => a.driverId === parseInt(filters.driverId));
    }

    // Truck filter
    if (filters.vehicleId) {
      filtered = filtered.filter((a) => a.vehicleId === parseInt(filters.vehicleId));
    }

    // Status filter
    if (filters.status !== 'all') {
      const isActive = filters.status === 'active';
      filtered = filtered.filter((a) => a.active === isActive);
    }

    // Date range filter
    if (filters.dateFrom) {
      const fromDate = new Date(filters.dateFrom);
      filtered = filtered.filter((a) => new Date(a.assignedAt) >= fromDate);
    }

    if (filters.dateTo) {
      const toDate = new Date(filters.dateTo);
      toDate.setHours(23, 59, 59, 999);
      filtered = filtered.filter((a) => new Date(a.assignedAt) <= toDate);
    }

    // Apply sorting
    filtered.sort((a, b) => {
      let aValue: any = a[this.sortField as keyof Assignment];
      let bValue: any = b[this.sortField as keyof Assignment];

      if (this.sortField === 'assignedAt') {
        aValue = new Date(aValue).getTime();
        bValue = new Date(bValue).getTime();
      }

      if (aValue < bValue) return this.sortDirection === 'asc' ? -1 : 1;
      if (aValue > bValue) return this.sortDirection === 'asc' ? 1 : -1;
      return 0;
    });

    // Update pagination
    this.pagination.totalElements = filtered.length;
    this.pagination.totalPages = Math.ceil(filtered.length / this.pagination.pageSize);

    // Apply pagination
    const startIndex = (this.pagination.currentPage - 1) * this.pagination.pageSize;
    const endIndex = startIndex + this.pagination.pageSize;
    this.filteredAssignments = filtered.slice(startIndex, endIndex);
  }

  sort(field: string): void {
    if (this.sortField === field) {
      this.sortDirection = this.sortDirection === 'asc' ? 'desc' : 'asc';
    } else {
      this.sortField = field;
      this.sortDirection = 'asc';
    }
    this.applyFilters();
  }

  getSortIcon(field: string): string {
    if (this.sortField !== field) return 'unfold_more';
    return this.sortDirection === 'asc' ? 'arrow_upward' : 'arrow_downward';
  }

  changePage(page: number): void {
    if (page < 1 || page > this.pagination.totalPages) return;
    this.pagination.currentPage = page;
    this.applyFilters();
    this.scrollToTop();
  }

  changePageSize(size: number): void {
    this.pagination.pageSize = size;
    this.pagination.currentPage = 1;
    this.applyFilters();
  }

  getPageNumbers(): number[] {
    const pages: number[] = [];
    const maxVisible = 5;
    const current = this.pagination.currentPage;
    const total = this.pagination.totalPages;

    if (total <= maxVisible) {
      for (let i = 1; i <= total; i++) {
        pages.push(i);
      }
    } else {
      if (current <= 3) {
        for (let i = 1; i <= 4; i++) pages.push(i);
        pages.push(-1); // Ellipsis
        pages.push(total);
      } else if (current >= total - 2) {
        pages.push(1);
        pages.push(-1); // Ellipsis
        for (let i = total - 3; i <= total; i++) pages.push(i);
      } else {
        pages.push(1);
        pages.push(-1); // Ellipsis
        pages.push(current - 1);
        pages.push(current);
        pages.push(current + 1);
        pages.push(-1); // Ellipsis
        pages.push(total);
      }
    }

    return pages;
  }

  clearFilters(): void {
    this.filterForm.reset({
      searchQuery: '',
      driverId: '',
      vehicleId: '',
      status: 'all',
      dateFrom: '',
      dateTo: '',
    });
    this.pagination.currentPage = 1;
  }

  viewDetails(assignment: Assignment): void {
    // Navigate to assignment details or show modal
    console.log('View assignment:', assignment);
  }

  editAssignment(assignment: Assignment): void {
    this.router.navigate(['/fleet/assign-truck-driver'], {
      queryParams: { assignmentId: assignment.id },
    });
  }

  async revokeAssignment(assignment: Assignment): Promise<void> {
    if (
      !(await this.confirm.confirm(
        `Are you sure you want to revoke the assignment of ${assignment.truckPlate} from ${assignment.driverName}?`,
      ))
    ) {
      return;
    }

    this.loading = true;
    this.assignmentService
      .revokeDriverAssignment(assignment.driverId, 'Assignment revoked from list')
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (response) => {
          if (response.success) {
            this.successMessage = 'Assignment revoked successfully';
            setTimeout(() => (this.successMessage = ''), 3000);
            this.loadAssignments();
          }
        },
        error: (error) => {
          this.errorMessage = error.error?.message || 'Failed to revoke assignment';
          setTimeout(() => (this.errorMessage = ''), 5000);
          this.loading = false;
        },
      });
  }

  exportToCSV(): void {
    const headers = [
      'Driver Name',
      'Truck Plate',
      'Assigned At',
      'Assigned By',
      'Status',
      'Reason',
    ];
    const rows = this.filteredAssignments.map((a) => [
      a.driverName,
      a.truckPlate,
      new Date(a.assignedAt).toLocaleString(),
      a.assignedBy,
      a.active ? 'Active' : 'Inactive',
      a.reason || '-',
    ]);

    let csv = headers.join(',') + '\n';
    rows.forEach((row) => {
      csv += row.map((cell) => `"${cell}"`).join(',') + '\n';
    });

    const blob = new Blob([csv], { type: 'text/csv' });
    const url = window.URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = `truck-driver-assignments-${new Date().toISOString().split('T')[0]}.csv`;
    link.click();
    window.URL.revokeObjectURL(url);
  }

  refreshData(): void {
    this.loadAssignments();
  }

  navigateToAssign(): void {
    this.router.navigate(['/fleet/assign-truck-driver']);
  }

  private scrollToTop(): void {
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }

  formatDate(dateString: string): string {
    const date = new Date(dateString);
    return date.toLocaleDateString() + ' ' + date.toLocaleTimeString();
  }

  getStatusBadgeClass(active: boolean): string {
    return active ? 'badge-success' : 'badge-inactive';
  }
}
