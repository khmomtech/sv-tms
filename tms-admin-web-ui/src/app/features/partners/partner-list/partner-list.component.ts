import { CommonModule } from '@angular/common';
import { Component, inject, signal } from '@angular/core';
import type { FormGroup } from '@angular/forms';
import { FormBuilder, FormControl, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router, RouterModule } from '@angular/router';
import { ConfirmService } from '../../../services/confirm.service';
import { catchError, debounceTime, distinctUntilChanged, of } from 'rxjs';

import { environment } from '../../../environments/environment';
import type { PartnerCompany, PartnerStatus } from '../../../models/partner.model';
import { PartnershipType } from '../../../models/partner.model';
import { PARTNERSHIP_TYPE_COLORS, PARTNERSHIP_TYPE_LABELS } from '../../../models/partner.model';
import { VendorService } from '../../../services/vendor.service';

@Component({
  selector: 'app-partner-list',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterModule],
  templateUrl: './partner-list.component.html',
  styleUrls: ['./partner-list.component.css'],
})
export class PartnerListComponent {
  private readonly partnerService = inject(VendorService);
  private readonly fb = inject(FormBuilder);
  private readonly router = inject(Router);
  private readonly confirm = inject(ConfirmService);

  partners = signal<PartnerCompany[]>([]);
  filteredPartners = signal<PartnerCompany[]>([]);
  pagedPartners = signal<PartnerCompany[]>([]);
  loading = signal(false);
  saving = signal(false);
  totalRecords = signal(0);
  totalPages = signal(1);
  pageIndex = signal(1); // 1-based
  pageSize = signal(10);
  pageSizeOptions = [10, 25, 50, 100];
  showingFrom = signal(0);
  showingTo = signal(0);

  searchControl = new FormControl('');
  statusFilter = new FormControl<PartnerStatus | 'ALL'>('ALL');
  typeFilter = new FormControl<PartnershipType | 'ALL'>('ALL');

  displayedColumns = [
    'companyCode',
    'companyName',
    'partnershipType',
    'contactPerson',
    'email',
    'phone',
    'commissionRate',
    'creditLimit',
    'status',
    'actions',
  ];

  partnershipTypes: PartnershipType[] = Object.values(PartnershipType) as PartnershipType[];

  readonly PARTNERSHIP_TYPE_LABELS = PARTNERSHIP_TYPE_LABELS;
  readonly PARTNERSHIP_TYPE_COLORS = PARTNERSHIP_TYPE_COLORS;

  // Inline modal form state (no Material)
  showForm = signal(false);
  formMode: 'create' | 'edit' = 'create';
  currentPartner: PartnerCompany | null = null;
  form: FormGroup = this.fb.group({
    companyCode: [{ value: '', disabled: true }],
    companyName: ['', [Validators.required, Validators.minLength(2)]],
    businessLicense: [''],
    contactPerson: [''],
    email: ['', [Validators.email]],
    phone: [''],
    address: [''],
    partnershipType: [PartnershipType.DRIVER_FLEET, Validators.required],
    status: ['ACTIVE' as PartnerStatus, Validators.required],
    commissionRate: [null],
    creditLimit: [null],
  });
  toastMessage = signal<string | null>(null);

  // Insights (based on filtered set)
  filteredActiveCount = signal(0);
  filteredInactiveCount = signal(0);
  typeCounts: Record<PartnershipType, number> = Object.values(PartnershipType).reduce(
    (acc, t) => ({ ...acc, [t]: 0 }),
    {} as Record<PartnershipType, number>,
  );

  // Feature toggle
  private readonly serverPagingEnabled = environment.useServerPagingPartners;

  ngOnInit(): void {
    this.loadPartners();
    this.setupFilters();
  }

  loadPartners(): void {
    this.loading.set(true);
    if (this.serverPagingEnabled) {
      this.fetchServerPage();
    } else {
      this.partnerService
        .getAllPartners()
        .pipe(
          catchError((error) => {
            console.error('Error loading vendors:', error);
            this.toast('Failed to load vendors');
            return of([]);
          }),
        )
        .subscribe((partners) => {
          this.partners.set(partners);
          this.applyFilters();
          this.loading.set(false);
        });
    }
  }

  setupFilters(): void {
    this.searchControl.valueChanges
      .pipe(debounceTime(300), distinctUntilChanged())
      .subscribe(() => {
        this.pageIndex.set(1);
        this.applyFilters();
      });

    this.statusFilter.valueChanges.subscribe(() => {
      this.pageIndex.set(1);
      this.applyFilters();
    });
    this.typeFilter.valueChanges.subscribe(() => {
      this.pageIndex.set(1);
      this.applyFilters();
    });
  }

  applyFilters(): void {
    if (this.serverPagingEnabled) {
      // With server-side paging, request the current page from backend
      this.fetchServerPage();
      return;
    }

    let filtered = [...this.partners()];

    // Search filter
    const searchTerm = this.searchControl.value?.toLowerCase() || '';
    if (searchTerm) {
      filtered = filtered.filter(
        (p) =>
          p.companyName?.toLowerCase().includes(searchTerm) ||
          p.companyCode?.toLowerCase().includes(searchTerm) ||
          p.contactPerson?.toLowerCase().includes(searchTerm) ||
          p.email?.toLowerCase().includes(searchTerm),
      );
    }

    // Status filter
    const status = this.statusFilter.value;
    if (status && status !== 'ALL') {
      filtered = filtered.filter((p) => p.status === status);
    }

    // Type filter
    const type = this.typeFilter.value;
    if (type && type !== 'ALL') {
      filtered = filtered.filter((p) => p.partnershipType === type);
    }

    this.filteredPartners.set(filtered);
    this.totalRecords.set(filtered.length);

    // Insights
    this.filteredActiveCount.set(filtered.filter((p) => p.status === 'ACTIVE').length);
    this.filteredInactiveCount.set(filtered.filter((p) => p.status !== 'ACTIVE').length);
    const tc: Record<PartnershipType, number> = Object.values(PartnershipType).reduce(
      (acc, t) => ({ ...acc, [t]: 0 }),
      {} as Record<PartnershipType, number>,
    );
    for (const p of filtered) {
      tc[p.partnershipType] = (tc[p.partnershipType] || 0) + 1;
    }
    this.typeCounts = tc;

    // Pagination
    const size = this.pageSize();
    const total = this.totalRecords();
    const pages = Math.max(1, Math.ceil(total / Math.max(1, size)));
    this.totalPages.set(pages);

    let page = this.pageIndex();
    if (page > pages) page = 1;
    if (page < 1) page = 1;
    this.pageIndex.set(page);

    const start = total === 0 ? 0 : (page - 1) * size;
    const end = total === 0 ? 0 : Math.min(start + size, total);
    this.showingFrom.set(total === 0 ? 0 : start + 1);
    this.showingTo.set(end);
    this.pagedPartners.set(filtered.slice(start, end));
  }

  private fetchServerPage(): void {
    const size = this.pageSize();
    const page0 = Math.max(0, this.pageIndex() - 1);
    const query = this.searchControl.value || '';
    const status = this.statusFilter.value || 'ALL';
    const type = this.typeFilter.value || 'ALL';

    this.partnerService
      .getPartnersPaged(page0, size, { query, status, type })
      .pipe(
        catchError((error) => {
          console.error('Error loading vendors (paged):', error);
          this.toast('Failed to load vendors');
          return of({ content: [], totalElements: 0, totalPages: 1 });
        }),
      )
      .subscribe((res) => {
        const content = res.content || [];
        this.partners.set(content);
        this.filteredPartners.set(content);

        // Insights on current page
        this.filteredActiveCount.set(content.filter((p) => p.status === 'ACTIVE').length);
        this.filteredInactiveCount.set(content.filter((p) => p.status !== 'ACTIVE').length);
        const tc: Record<PartnershipType, number> = Object.values(PartnershipType).reduce(
          (acc, t) => ({ ...acc, [t]: 0 }),
          {} as Record<PartnershipType, number>,
        );
        for (const p of content) {
          tc[p.partnershipType] = (tc[p.partnershipType] || 0) + 1;
        }
        this.typeCounts = tc;

        // Page totals from server
        this.totalRecords.set(res.totalElements || content.length);
        this.totalPages.set(Math.max(1, res.totalPages || 1));

        // Showing range for current page
        const total = this.totalRecords();
        const page = this.pageIndex();
        const start = total === 0 ? 0 : (page - 1) * size;
        const end = total === 0 ? 0 : Math.min(start + size, total);
        this.showingFrom.set(total === 0 ? 0 : start + 1);
        this.showingTo.set(end);
        this.pagedPartners.set(content);
        this.loading.set(false);
      });
  }

  openCreateDialog(): void {
    this.formMode = 'create';
    this.currentPartner = null;
    this.form.reset({
      companyCode: '',
      companyName: '',
      businessLicense: '',
      contactPerson: '',
      email: '',
      phone: '',
      address: '',
      partnershipType: PartnershipType.DRIVER_FLEET,
      status: 'ACTIVE',
      commissionRate: null,
      creditLimit: null,
    });
    this.showForm.set(true);

    // Prefill generated company code (if backend supports it)
    this.partnerService.generateCompanyCode().subscribe({
      next: (code) => this.form.patchValue({ companyCode: code }),
      error: () => {
        /* non-blocking */
      },
    });
  }

  openEditDialog(partner: PartnerCompany): void {
    this.formMode = 'edit';
    this.currentPartner = partner;
    this.form.patchValue(partner as any);
    this.showForm.set(true);
  }

  closeForm(): void {
    this.showForm.set(false);
  }

  viewPartner(partner: PartnerCompany): void {
    this.router.navigate(['/vendors', partner.id]);
  }

  async deactivatePartner(partner: PartnerCompany): Promise<void> {
    if (!partner.id) return;

    if (
      !(await this.confirm.confirm(`Are you sure you want to deactivate ${partner.companyName}?`))
    )
      return;
    this.partnerService.deactivatePartner(partner.id).subscribe({
      next: () => {
        this.toast('Vendor deactivated successfully');
        this.loadPartners();
      },
      error: (error) => {
        console.error('Error deactivating vendor:', error);
        this.toast('Failed to deactivate vendor');
      },
    });
  }

  async deletePartner(partner: PartnerCompany): Promise<void> {
    if (!partner.id) return;

    if (
      !(await this.confirm.confirm(
        `Are you sure you want to permanently delete ${partner.companyName}? This action cannot be undone.`,
      ))
    )
      return;
    this.partnerService.deletePartner(partner.id).subscribe({
      next: () => {
        this.toast('Vendor deleted successfully');
        this.loadPartners();
      },
      error: (error) => {
        console.error('Error deleting vendor:', error);
        this.toast('Failed to delete vendor');
      },
    });
  }

  getPartnershipTypeLabel(type: PartnershipType): string {
    return PARTNERSHIP_TYPE_LABELS[type] || type;
  }

  getPartnershipTypeColor(type: PartnershipType): string {
    return PARTNERSHIP_TYPE_COLORS[type] || 'primary';
  }

  formatCurrency(value: number | undefined): string {
    if (!value) return '-';
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
    }).format(value);
  }

  formatPercent(value: number | undefined): string {
    if (!value) return '-';
    return `${value}%`;
  }

  // Pagination handlers
  onPageSizeChange(value: number | string): void {
    const v = Number(value) || 10;
    this.pageSize.set(v);
    this.pageIndex.set(1);
    this.applyFilters();
  }

  previousPage(): void {
    if (this.pageIndex() > 1) {
      this.pageIndex.set(this.pageIndex() - 1);
      this.applyFilters();
    }
  }

  nextPage(): void {
    if (this.pageIndex() < this.totalPages()) {
      this.pageIndex.set(this.pageIndex() + 1);
      this.applyFilters();
    }
  }

  goToPageFrom(raw: string | number): void {
    const n = Number(raw);
    if (!Number.isFinite(n)) return;
    const page = Math.min(Math.max(1, Math.trunc(n)), this.totalPages());
    this.pageIndex.set(page);
    this.applyFilters();
  }

  submitForm(): void {
    if (this.form.invalid) return;
    this.saving.set(true);
    const payload = this.form.getRawValue() as PartnerCompany;

    const req$ =
      this.formMode === 'create' || !this.currentPartner?.id
        ? this.partnerService.createPartner(payload)
        : this.partnerService.updatePartner(this.currentPartner!.id!, payload);

    req$.subscribe({
      next: () => {
        this.toast(this.formMode === 'create' ? 'Vendor created' : 'Vendor updated');
        this.saving.set(false);
        this.showForm.set(false);
        this.loadPartners();
      },
      error: (err) => {
        console.error('Vendor save failed', err);
        this.toast('Failed to save vendor');
        this.saving.set(false);
      },
    });
  }

  private toast(message: string): void {
    this.toastMessage.set(message);
    setTimeout(() => this.toastMessage.set(null), 3000);
  }
}
