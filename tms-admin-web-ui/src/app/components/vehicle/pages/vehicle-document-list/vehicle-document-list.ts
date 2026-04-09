import { CommonModule, formatDate } from '@angular/common';
import { Component, Inject, LOCALE_ID, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute } from '@angular/router';

import type { VehicleDocument } from '../../../../models/document.model';
import type { Vehicle } from '../../../../models/vehicle.model';
import { DocumentService } from '../../../../services/document.service';
import { VehicleService } from '../../../../services/vehicle.service';

@Component({
  selector: 'app-vehicle-document-list',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './vehicle-document-list.html',
  styleUrl: './vehicle-document-list.css',
})
export class VehicleDocumentListComponent implements OnInit {
  documents: VehicleDocument[] = [];
  vehicles: Vehicle[] = [];
  loading = false;
  error = '';
  page = 0;
  size = 20;
  totalPages = 1;
  totalElements = 0;

  filters: {
    dateField: 'created' | 'issue' | 'expiry';
    from: string;
    to: string;
    vehicleId: number | null;
    documentType: string;
    search: string;
  } = {
    dateField: 'created',
    from: '',
    to: '',
    vehicleId: null,
    documentType: '',
    search: '',
  };

  constructor(
    private readonly documentService: DocumentService,
    private readonly vehicleService: VehicleService,
    private readonly route: ActivatedRoute,
    @Inject(LOCALE_ID) private locale: string,
  ) {}

  ngOnInit(): void {
    const today = new Date();
    const from = new Date();
    from.setDate(today.getDate() - 30);
    this.filters.from = this.formatIsoDate(from);
    this.filters.to = this.formatIsoDate(today);

    this.route.queryParamMap.subscribe((params) => {
      const vehicleId = params.get('vehicleId');
      if (vehicleId) this.filters.vehicleId = Number(vehicleId);
      this.loadDocuments();
    });

    this.loadVehicles();
  }

  loadVehicles(): void {
    this.vehicleService.getVehicles(0, 200, {}).subscribe({
      next: (res: any) => {
        this.vehicles = res?.data?.content ?? [];
      },
      error: () => {
        this.vehicles = [];
      },
    });
  }

  loadDocuments(): void {
    this.loading = true;
    this.error = '';
    this.documentService
      .getDocumentReport({
        dateField: this.filters.dateField,
        from: this.filters.from || undefined,
        to: this.filters.to || undefined,
        vehicleId: this.filters.vehicleId || undefined,
        documentType: this.filters.documentType || undefined,
        search: this.filters.search || undefined,
        page: this.page,
        size: this.size,
      })
      .subscribe({
        next: (res) => {
          const payload = res?.data ?? (res as any);
          this.documents = payload?.content ?? [];
          this.totalPages = payload?.totalPages ?? 1;
          this.totalElements = payload?.totalElements ?? this.documents.length;
          this.loading = false;
        },
        error: () => {
          this.documents = [];
          this.loading = false;
          this.error = 'Failed to load vehicle documents.';
        },
      });
  }

  applyFilters(): void {
    this.page = 0;
    this.loadDocuments();
  }

  resetFilters(): void {
    const today = new Date();
    const from = new Date();
    from.setDate(today.getDate() - 30);
    this.filters = {
      dateField: 'created',
      from: this.formatIsoDate(from),
      to: this.formatIsoDate(today),
      vehicleId: null,
      documentType: '',
      search: '',
    };
    this.page = 0;
    this.loadDocuments();
  }

  prevPage(): void {
    if (this.page > 0) {
      this.page -= 1;
      this.loadDocuments();
    }
  }

  nextPage(): void {
    if (this.page + 1 < this.totalPages) {
      this.page += 1;
      this.loadDocuments();
    }
  }

  statusLabel(doc: VehicleDocument): string {
    if (doc?.expiryDate) {
      const expiry = new Date(doc.expiryDate).getTime();
      return expiry >= Date.now() ? 'Active' : 'Expired';
    }
    return doc?.approved ? 'Active' : 'Pending';
  }

  statusClass(doc: VehicleDocument): string {
    const label = this.statusLabel(doc);
    if (label === 'Active') return 'bg-emerald-50 text-emerald-700 border-emerald-200';
    if (label === 'Expired') return 'bg-red-50 text-red-700 border-red-200';
    return 'bg-amber-50 text-amber-700 border-amber-200';
  }

  formatDate(value?: string): string {
    if (!value) return '—';
    try {
      return formatDate(value, 'MMM d, y', this.locale);
    } catch {
      return value;
    }
  }

  private formatIsoDate(date: Date): string {
    return date.toISOString().slice(0, 10);
  }
}
