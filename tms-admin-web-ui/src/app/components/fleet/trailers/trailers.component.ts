import { CommonModule } from '@angular/common';
import { Component, inject, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { ToastrService } from 'ngx-toastr';

import { Vehicle } from '../../../models/vehicle.model';
import { VehicleStatus, VehicleType } from '../../../models/enums/vehicle.enums';
import { TrailerService } from '../../../services/trailer.service';
import { VehicleService } from '../../../services/vehicle.service';
import { ConfirmService } from '../../../services/confirm.service';

interface TrailerStatistics {
  total: number;
  available: number;
  inUse: number;
  maintenance: number;
}

interface TrailerFilters {
  search: string;
  status: string;
  zone: string;
  assigned: string;
}

@Component({
  selector: 'app-trailers',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './trailers.component.html',
  styleUrls: ['./trailers.component.scss'],
})
export class TrailersComponent implements OnInit {
  private confirm = inject(ConfirmService);
  trailers: Vehicle[] = [];
  trucks: Vehicle[] = [];
  statistics: TrailerStatistics = {
    total: 0,
    available: 0,
    inUse: 0,
    maintenance: 0,
  };

  filters: TrailerFilters = {
    search: '',
    status: '',
    zone: '',
    assigned: '',
  };

  currentPage = 0;
  totalPages = 1;
  pageSize = 15;

  isLoading = false;
  errorMessage = '';

  // Assignment modal
  isAssignModalOpen = false;
  selectedTrailer: Vehicle | null = null;
  selectedVehicleId: number | null = null;

  VehicleStatus = VehicleStatus;

  constructor(
    private trailerService: TrailerService,
    private vehicleService: VehicleService,
    private router: Router,
    private toastr: ToastrService,
  ) {}

  ngOnInit(): void {
    this.loadTrailers();
    this.loadTrucks();
  }

  loadTrailers(): void {
    this.isLoading = true;
    this.errorMessage = '';

    const filters = {
      search: this.filters.search || undefined,
      status: this.filters.status || undefined,
      zone: this.filters.zone || undefined,
      assigned:
        this.filters.assigned === 'assigned'
          ? true
          : this.filters.assigned === 'unassigned'
            ? false
            : undefined,
    };

    this.trailerService.searchTrailers(filters, this.currentPage, this.pageSize).subscribe({
      next: (response) => {
        if (response.success && response.data) {
          this.trailers = response.data.content || [];
          this.totalPages = response.data.totalPages || 1;
          this.calculateStatistics();
        } else {
          this.toastr.error(response.message || 'Failed to load trailers');
        }
        this.isLoading = false;
      },
      error: (error) => {
        console.error('Error loading trailers:', error);
        this.toastr.error('Failed to load trailers');
        this.isLoading = false;
      },
    });
  }

  loadTrucks(): void {
    // Load all trucks (non-trailer vehicles) for assignment dropdown
    this.vehicleService.getAllVehicles().subscribe({
      next: (response) => {
        if (response.success && response.data) {
          this.trucks = response.data.filter((v: Vehicle) => v.type !== VehicleType.TRAILER);
        }
      },
      error: (error) => {
        console.error('Error loading trucks:', error);
      },
    });
  }

  calculateStatistics(): void {
    this.statistics.total = this.trailers.length;
    this.statistics.available = this.trailers.filter(
      (t) => t.status === VehicleStatus.AVAILABLE,
    ).length;
    this.statistics.inUse = this.trailers.filter((t) => t.status === VehicleStatus.IN_USE).length;
    this.statistics.maintenance = this.trailers.filter(
      (t) => t.status === VehicleStatus.MAINTENANCE,
    ).length;
  }

  applyFilters(): void {
    this.currentPage = 0;
    this.loadTrailers();
  }

  clearFilters(): void {
    this.filters = {
      search: '',
      status: '',
      zone: '',
      assigned: '',
    };
    this.currentPage = 0;
    this.loadTrailers();
  }

  openAssignModal(trailer: Vehicle): void {
    this.selectedTrailer = trailer;
    this.selectedVehicleId = trailer.assignedVehicleId || null;
    this.isAssignModalOpen = true;
  }

  closeAssignModal(): void {
    this.isAssignModalOpen = false;
    this.selectedTrailer = null;
    this.selectedVehicleId = null;
  }

  assignTrailer(): void {
    if (!this.selectedTrailer || !this.selectedVehicleId) {
      this.toastr.warning('Please select a truck');
      return;
    }

    this.trailerService
      .assignTrailerToTruck(this.selectedTrailer.id!, this.selectedVehicleId)
      .subscribe({
        next: (response) => {
          if (response.success) {
            this.toastr.success('Trailer assigned successfully');
            this.closeAssignModal();
            this.loadTrailers();
          } else {
            this.toastr.error(response.message || 'Failed to assign trailer');
          }
        },
        error: (error) => {
          console.error('Error assigning trailer:', error);
          this.toastr.error('Failed to assign trailer');
        },
      });
  }

  async unassignTrailer(trailer: Vehicle): Promise<void> {
    if (!(await this.confirm.confirm(`Unassign trailer ${trailer.licensePlate}?`))) {
      return;
    }

    this.trailerService.unassignTrailer(trailer.id!).subscribe({
      next: (response) => {
        if (response.success) {
          this.toastr.success('Trailer unassigned successfully');
          this.loadTrailers();
        } else {
          this.toastr.error(response.message || 'Failed to unassign trailer');
        }
      },
      error: (error) => {
        console.error('Error unassigning trailer:', error);
        this.toastr.error('Failed to unassign trailer');
      },
    });
  }

  viewTrailer(id: number): void {
    this.router.navigate(['/fleet/vehicles', id]);
  }

  prevPage(): void {
    if (this.currentPage > 0) {
      this.currentPage--;
      this.loadTrailers();
    }
  }

  nextPage(): void {
    if (this.currentPage < this.totalPages - 1) {
      this.currentPage++;
      this.loadTrailers();
    }
  }

  getStatusClass(status: string): string {
    switch (status) {
      case VehicleStatus.AVAILABLE:
        return 'bg-green-100 text-green-800';
      case VehicleStatus.IN_USE:
        return 'bg-orange-100 text-orange-800';
      case VehicleStatus.MAINTENANCE:
        return 'bg-red-100 text-red-800';
      case VehicleStatus.OUT_OF_SERVICE:
        return 'bg-gray-100 text-gray-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  }
}
