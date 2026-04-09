// ...existing code...

/* eslint-disable @typescript-eslint/consistent-type-imports */
import { CommonModule } from '@angular/common';
import { Component, HostListener, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { MatIconModule } from '@angular/material/icon';
import { Router, RouterModule, ActivatedRoute } from '@angular/router';
import * as ExcelJS from 'exceljs';
import * as FileSaver from 'file-saver';
import { firstValueFrom } from 'rxjs';

import { environment } from '../../environments/environment';
import type { Customer } from '../../models/customer.model';
import { AuthService } from '../../services/auth.service';
import { CustomerService } from '../../services/custommer.service';
import { VendorService } from '../../services/vendor.service';
import { ConfirmService } from '../../services/confirm.service';
import { NotificationService } from '../../services/notification.service';
import { InputPromptService } from '../../core/input-prompt.service';

type SelectionScope = 'page' | 'query' | null;

interface FilterState {
  customerCode: string;
  name: string;
  phone: string;
  email: string;
  types: string[];
  status: string;
  tags: string[];

  segments: string[];
}

interface SavedFilter {
  id: string;
  name: string;
  filters: FilterState;
}

@Component({
  selector: 'app-customers',
  templateUrl: './customer.component.html',
  styleUrls: ['./customer.component.css'],
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule, MatIconModule],
})
export class CustomerComponent implements OnInit {
  // Pagination page size options
  pageSizes = [10, 20, 50, 100];

  // Loading state for table and pagination
  loading = false;

  /**
   * Handle page size change from pagination dropdown
   */
  onPageSizeChange(size: number): void {
    this.pageSize = size;
    this.currentPage = 0;
    this.onSearchChange();
  }
  private readonly FILTER_STORAGE_KEY = 'svtms.customer.filters.v2';
  private readonly PRESET_STORAGE_KEY = 'svtms.customer.filter-presets.v1';

  customers: Customer[] = [];
  selectedCustomer: Customer = this.createDefaultCustomer();
  isModalOpen = false;
  dropdownOpen: number | null = null;
  showColumnSettings = false;
  errorMessage: string | null = null;

  // Validation error handling
  validationErrors: string[] = [];
  isSaving = false;
  importBusy = false;
  importFailureMessages: string[] = [];

  // Portal account dialog state
  isAccountModalOpen = false;
  accountSaving = false;
  accountError = '';
  accountCustomerId: number | null = null;
  account = {
    username: '',
    email: '',
    password: '',
  };

  readonly typeOptions = [
    { value: 'COMPANY', label: 'Company' },
    { value: 'INDIVIDUAL', label: 'Individual' },
  ];

  readonly statusOptions = [
    { value: 'ACTIVE', label: 'Active' },
    { value: 'INACTIVE', label: 'Inactive' },
  ];

  readonly lifecycleStageOptions = [
    { value: 'LEAD', label: 'Lead' },
    { value: 'PROSPECT', label: 'Prospect' },
    { value: 'QUALIFIED', label: 'Qualified Lead' },
    { value: 'CUSTOMER', label: 'Active Customer' },
    { value: 'AT_RISK', label: 'At Risk' },
    { value: 'DORMANT', label: 'Dormant' },
    { value: 'CHURNED', label: 'Churned' },
  ];

  readonly paymentTermsOptions = [
    { value: 'NET_30', label: 'Net 30 Days' },
    { value: 'NET_60', label: 'Net 60 Days' },
    { value: 'NET_90', label: 'Net 90 Days' },
    { value: 'COD', label: 'Cash on Delivery' },
    { value: 'PREPAID', label: 'Prepaid' },
    { value: 'DUE_ON_RECEIPT', label: 'Due on Receipt' },
  ];

  readonly currencyOptions = [
    { value: 'USD', label: 'USD - US Dollar' },
    { value: 'KHR', label: 'KHR - Cambodian Riel' },
    { value: 'THB', label: 'THB - Thai Baht' },
    { value: 'VND', label: 'VND - Vietnamese Dong' },
    { value: 'EUR', label: 'EUR - Euro' },
  ];

  readonly segmentOptions = [
    { value: 'VIP', label: 'VIP Customer', color: 'purple' },
    { value: 'REGULAR', label: 'Regular', color: 'blue' },
    { value: 'HIGH_VALUE', label: 'High Value', color: 'green' },
    { value: 'AT_RISK', label: 'At Risk', color: 'red' },
    { value: 'NEW', label: 'New Customer', color: 'yellow' },
    { value: 'DORMANT', label: 'Dormant', color: 'gray' },
  ];

  // Tag management
  availableTags: string[] = [
    'Important',
    'Follow-up',
    'Priority',
    'Urgent',
    'Contract',
    'Seasonal',
  ];
  isTagModalOpen = false;
  selectedCustomerForTags: Customer | null = null;
  newTag = '';

  filters: FilterState = {
    customerCode: '',
    name: '',
    phone: '',
    email: '',
    types: [],
    status: '',
    tags: [],
    segments: [],
  };

  savedFilters: SavedFilter[] = [];
  selectedPresetId = '';

  currentPage = 0;
  totalPages = 1;
  totalElements = 0;
  pageSize = 10;

  typeMenuOpen = false;
  statusMenuOpen = false;
  tagMenuOpen = false;
  segmentMenuOpen = false;

  selectedIds: number[] = [];
  selectionScope: SelectionScope = null;

  // Quick view & recent customers
  quickViewCustomer: Customer | null = null;
  showRecentSidebar = false;
  recentCustomers: (Customer & { viewedAt?: Date })[] = [];
  private readonly RECENT_CUSTOMERS_KEY = 'svtms.recent.customers.v1';
  private readonly MAX_RECENT_CUSTOMERS = 10;

  // Expose Math for template
  Math = Math;

  constructor(
    private readonly customerService: CustomerService,
    private readonly partnerService: VendorService,
    private readonly route: ActivatedRoute,
    private readonly authService: AuthService,
    private readonly router: Router,
    private readonly confirm: ConfirmService,
    private readonly notify: NotificationService,
    private readonly inputPrompt: InputPromptService,
  ) {}

  ngOnInit(): void {
    // Check authentication before loading data
    if (!this.authService.isAuthenticated()) {
      this.errorMessage = 'Please log in to view customers.';
      setTimeout(() => {
        this.router.navigate(['/login'], {
          queryParams: { returnUrl: '/customers' },
        });
      }, 1000);
      return;
    }

    this.restoreSavedFilters();
    this.restoreLastFilters();
    this.loadRecentCustomers();
    this.fetchCustomers();

    // Check if route data indicates we should open create modal
    const action = this.route.snapshot.data['action'];
    if (action === 'create') {
      setTimeout(() => this.openCustomerModal(), 100);
    }
  }

  /**
   * Get count of active customers
   */
  getActiveCount(): number {
    return this.customers.filter((c) => c.status === 'ACTIVE').length;
  }

  /**
   * Get count of company customers
   */
  getCompanyCount(): number {
    return this.customers.filter((c) => c.type === 'COMPANY').length;
  }

  /**
   * Get count of individual customers
   */
  getIndividualCount(): number {
    return this.customers.filter((c) => c.type === 'INDIVIDUAL').length;
  }

  private createDefaultCustomer(): Customer {
    return {
      customerCode: '',
      type: 'INDIVIDUAL',
      name: '',
      phone: '',
      status: 'ACTIVE',
      addresses: [],
      // Default values for new fields
      currency: 'USD',
      lifecycleStage: 'LEAD',
      currentBalance: 0,
    };
  }

  private restoreLastFilters(): void {
    try {
      const saved = localStorage.getItem(this.FILTER_STORAGE_KEY);
      if (!saved) return;
      const parsed = JSON.parse(saved) as Partial<FilterState>;
      this.filters = {
        ...this.filters,
        ...parsed,
        types: Array.isArray(parsed?.types) ? parsed!.types : [],
        status: typeof parsed?.status === 'string' ? parsed.status! : '',
      };
    } catch (err) {
      console.warn('[CustomerComponent] Failed to restore filters:', err);
    }
  }

  private restoreSavedFilters(): void {
    try {
      const saved = localStorage.getItem(this.PRESET_STORAGE_KEY);
      if (!saved) return;
      const parsed = JSON.parse(saved) as SavedFilter[];
      this.savedFilters = Array.isArray(parsed) ? parsed : [];
    } catch (err) {
      console.warn('[CustomerComponent] Failed to restore saved presets:', err);
    }
  }

  private persistFilters(): void {
    localStorage.setItem(this.FILTER_STORAGE_KEY, JSON.stringify(this.filters));
  }

  private persistSavedFilters(): void {
    localStorage.setItem(this.PRESET_STORAGE_KEY, JSON.stringify(this.savedFilters));
  }

  private hasActiveFilters(): boolean {
    const { customerCode, name, phone, email, types, status } = this.filters;
    return (
      customerCode.trim() !== '' ||
      name.trim() !== '' ||
      phone.trim() !== '' ||
      email.trim() !== '' ||
      types.length > 0 ||
      (!!status && status !== '')
    );
  }

  private fetchCustomers(): void {
    const useFilters = this.hasActiveFilters();
    const source$ = useFilters
      ? this.customerService.searchCustomersByFilters(this.filters, this.currentPage, this.pageSize)
      : this.customerService.getAllCustomers(this.currentPage, this.pageSize);

    this.loading = true;
    this.errorMessage = null;
    source$.subscribe({
      next: (res) => {
        this.customers = res?.content ?? [];
        this.totalPages = res?.totalPages ?? 1;
        this.totalElements = res?.totalElements ?? this.customers.length;
        this.reconcileSelection();
        this.errorMessage = null;
        this.loading = false;
      },
      error: (err) => {
        console.error('Load customers error:', err);
        this.loading = false;
        // Check for authentication errors
        if (
          err?.status === 401 ||
          err?.message?.includes('authentication') ||
          err?.message?.includes('Full authentication is required')
        ) {
          this.errorMessage = 'Your session has expired. Redirecting to login...';
          // Redirect to login after a brief delay
          setTimeout(() => {
            this.authService.logout();
            this.router.navigate(['/login'], {
              queryParams: { returnUrl: '/customers' },
            });
          }, 1500);
        } else if (err?.status === 403) {
          this.errorMessage =
            'Access denied. You need proper permissions to view customers. Contact an administrator.';
        } else if (err?.status === 500) {
          this.errorMessage =
            'Server error. Please try again later or contact support if the problem persists.';
        } else if (err?.error?.message) {
          this.errorMessage = err.error.message;
        } else if (err?.message) {
          this.errorMessage = err.message;
        } else {
          this.errorMessage =
            'Failed to load customers. Please check your connection and try again.';
        }
      },
    });
  }

  private reconcileSelection(): void {
    if (this.selectionScope === 'query') {
      // keep selectedIds as-is; ensure they remain unique
      this.selectedIds = Array.from(new Set(this.selectedIds));
      return;
    }

    if (this.selectionScope === 'page') {
      const currentIds = new Set(this.customers.map((c) => c.id!).filter(Boolean));
      this.selectedIds = this.selectedIds.filter((id) => currentIds.has(id));
      if (this.selectedIds.length === 0) {
        this.selectionScope = null;
      }
    } else {
      this.resetSelection();
    }
  }

  private resetSelection(): void {
    this.selectedIds = [];
    this.selectionScope = null;
  }

  applyFilters(): void {
    this.persistFilters();
    this.selectedPresetId = '';
    this.currentPage = 0;
    this.resetSelection();
    this.fetchCustomers();
  }

  onSearchChange(): void {
    this.applyFilters();
  }

  clearFilters(): void {
    this.filters = {
      customerCode: '',
      name: '',
      phone: '',
      email: '',
      types: [],
      status: '',
      tags: [],
      segments: [],
    };
    this.persistFilters();
    this.selectedPresetId = '';
    this.currentPage = 0;
    this.resetSelection();
    this.fetchCustomers();
  }

  resetAllFilters(): void {
    this.clearFilters();
  }

  toggleTypeMenu(): void {
    this.typeMenuOpen = !this.typeMenuOpen;
    if (this.typeMenuOpen) {
      this.statusMenuOpen = false;
      this.tagMenuOpen = false;
      this.segmentMenuOpen = false;
    }
  }

  toggleStatusMenu(): void {
    this.statusMenuOpen = !this.statusMenuOpen;
    if (this.statusMenuOpen) {
      this.typeMenuOpen = false;
      this.tagMenuOpen = false;
      this.segmentMenuOpen = false;
    }
  }

  toggleTagMenu(): void {
    this.tagMenuOpen = !this.tagMenuOpen;
    if (this.tagMenuOpen) {
      this.typeMenuOpen = false;
      this.statusMenuOpen = false;
      this.segmentMenuOpen = false;
    }
  }

  toggleSegmentMenu(): void {
    this.segmentMenuOpen = !this.segmentMenuOpen;
    if (this.segmentMenuOpen) {
      this.typeMenuOpen = false;
      this.statusMenuOpen = false;
      this.tagMenuOpen = false;
    }
  }

  // onMultiSelectChange removed for status (single-select now)

  // multiSelectSummary removed for status (single-select now)

  async saveCurrentFilters(): Promise<void> {
    if (!this.hasActiveFilters()) {
      this.notify.simulateNotification('Filters', 'Add at least one filter before saving.');
      return;
    }

    const name = await this.inputPrompt.prompt('Name this filter preset:', {
      placeholder: 'Preset name',
    });
    if (!name || !name.trim()) {
      return;
    }

    const preset: SavedFilter = {
      id: `${Date.now()}`,
      name: name.trim(),
      filters: JSON.parse(JSON.stringify(this.filters)),
    };
    this.savedFilters = [...this.savedFilters, preset];
    this.selectedPresetId = preset.id;
    this.persistSavedFilters();
  }

  onPresetSelect(): void {
    if (!this.selectedPresetId) return;
    const preset = this.savedFilters.find((p) => p.id === this.selectedPresetId);
    if (!preset) return;
    this.filters = JSON.parse(JSON.stringify(preset.filters));
    this.persistFilters();
    this.currentPage = 0;
    this.resetSelection();
    this.fetchCustomers();
  }

  async deleteCurrentPreset(): Promise<void> {
    if (!this.selectedPresetId) return;
    const preset = this.savedFilters.find((p) => p.id === this.selectedPresetId);
    if (!preset) return;
    if (!(await this.confirm.confirm(`Delete saved filter "${preset.name}"?`))) return;
    this.savedFilters = this.savedFilters.filter((p) => p.id !== preset.id);
    this.selectedPresetId = '';
    this.persistSavedFilters();
  }

  toggleCustomerSelection(id: number): void {
    if (this.selectionScope === 'query') {
      const exists = this.selectedIds.includes(id);
      this.selectedIds = exists
        ? this.selectedIds.filter((x) => x !== id)
        : [...this.selectedIds, id];
      return;
    }

    const exists = this.selectedIds.includes(id);
    this.selectedIds = exists
      ? this.selectedIds.filter((x) => x !== id)
      : [...this.selectedIds, id];
    this.selectionScope = this.selectedIds.length > 0 ? 'page' : null;
  }

  isCustomerSelected(id: number | undefined): boolean {
    if (id == null) return false;
    return this.selectedIds.includes(id);
  }

  toggleSelectAllOnPage(checked: boolean): void {
    if (checked) {
      this.selectedIds = this.customers
        .map((c) => c.id)
        .filter((id): id is number => typeof id === 'number');
      this.selectionScope = 'page';
    } else {
      this.resetSelection();
    }
  }

  selectAllAcrossQuery(): void {
    const size = Math.max(this.totalElements, this.pageSize);
    const useFilters = this.hasActiveFilters();
    const source$ = useFilters
      ? this.customerService.searchCustomersByFilters(this.filters, 0, size)
      : this.customerService.getAllCustomers(0, size);

    source$.subscribe({
      next: (res) => {
        const all = res?.content ?? [];
        this.selectedIds = all
          .map((c) => c.id)
          .filter((id): id is number => typeof id === 'number');
        this.selectionScope = 'query';
      },
      error: (err) => console.error('Failed to select all results:', err),
    });
  }

  isCurrentPageFullySelected(): boolean {
    if (!this.customers.length) return false;
    const idsOnPage = this.customers
      .map((c) => c.id)
      .filter((id): id is number => typeof id === 'number');
    return idsOnPage.every((id) => this.selectedIds.includes(id));
  }

  clearSelection(): void {
    this.resetSelection();
  }

  // ===== Bulk Operations =====
  async bulkUpdateStatus(status: 'ACTIVE' | 'INACTIVE'): Promise<void> {
    if (!this.selectedIds.length) return;

    const action = status === 'ACTIVE' ? 'activate' : 'deactivate';
    if (
      !(await this.confirm.confirm(
        `Are you sure you want to ${action} ${this.selectedIds.length} customer(s)?`,
      ))
    ) {
      return;
    }

    const updates = this.selectedIds.map((id) => {
      const customer = this.customers.find((c) => c.id === id);
      if (!customer) return Promise.resolve();

      return firstValueFrom(this.customerService.updateCustomer(id, { ...customer, status }));
    });

    try {
      await Promise.all(updates);
      this.resetSelection();
      this.fetchCustomers();
      this.notify.simulateNotification(
        'Success',
        `Successfully ${action}d ${this.selectedIds.length} customer(s)`,
      );
    } catch (err) {
      console.error(`Bulk ${action} failed:`, err);
      this.errorMessage = `Failed to ${action} some customers. Please try again.`;
    }
  }

  async bulkDelete(): Promise<void> {
    await this.deleteSelectedCustomers();
  }

  // ===== Customer Portal Account =====
  openAccountModal(customer: Customer): void {
    this.accountCustomerId = customer.id ?? null;
    this.account = {
      username: (customer?.email || customer?.customerCode || '').toString().split('@')[0],
      email: customer?.email || '',
      password: '',
    };
    this.accountError = '';
    this.isAccountModalOpen = true;
  }

  closeAccountModal(): void {
    this.isAccountModalOpen = false;
    this.accountSaving = false;
    this.accountError = '';
    this.accountCustomerId = null;
  }

  saveCustomerAccount(): void {
    if (!this.accountCustomerId) return;
    const { username, email, password } = this.account;
    if (!username?.trim() || !email?.trim() || !password?.trim()) {
      this.accountError = 'Please fill username, email, and password.';
      return;
    }
    this.accountSaving = true;
    this.partnerService
      .createCustomerAccount(this.accountCustomerId, { username, email, password })
      .subscribe({
        next: () => {
          this.accountSaving = false;
          this.closeAccountModal();
          // Refresh list to reflect any account-linked state if available later
          this.fetchCustomers();
        },
        error: (err) => {
          this.accountSaving = false;
          this.accountError = err?.error?.message || 'Failed to create account. Please retry.';
        },
      });
  }

  async deleteSelectedCustomers(): Promise<void> {
    if (!this.selectedIds.length) return;
    if (!(await this.confirm.confirm('Delete all selected customers?'))) return;

    const deletions = this.selectedIds.map((id) =>
      firstValueFrom(this.customerService.deleteCustomer(id)),
    );

    try {
      await Promise.all(deletions);
      this.resetSelection();
      this.fetchCustomers();
    } catch (err) {
      console.error('Bulk delete failed:', err);
    }
  }

  async exportSelectedToExcel(): Promise<void> {
    if (!this.selectedIds.length) return;

    let dataset: Customer[] = [];

    if (this.selectionScope === 'query') {
      const size = Math.max(this.totalElements, this.pageSize);
      const source$ = this.hasActiveFilters()
        ? this.customerService.searchCustomersByFilters(this.filters, 0, size)
        : this.customerService.getAllCustomers(0, size);
      const result = await firstValueFrom(source$);
      dataset = (result?.content ?? []).filter((c) => this.selectedIds.includes(c.id!));
    } else {
      dataset = this.customers.filter((c) => this.selectedIds.includes(c.id!));
    }

    if (!dataset.length) {
      this.notify.simulateNotification('Export', 'No customers available to export.');
      return;
    }

    const workbook = new ExcelJS.Workbook();
    const worksheet = workbook.addWorksheet('Customers');

    worksheet.columns = [
      { header: 'ID', key: 'id', width: 10 },
      { header: 'Customer Code', key: 'customerCode', width: 20 },
      { header: 'Name', key: 'name', width: 20 },
      { header: 'Type', key: 'type', width: 15 },
      { header: 'Phone', key: 'phone', width: 15 },
      { header: 'Email', key: 'email', width: 25 },
      { header: 'Address', key: 'address', width: 30 },
      { header: 'Status', key: 'status', width: 15 },
    ];

    dataset.forEach((c) => {
      worksheet.addRow({
        id: c.id,
        customerCode: c.customerCode,
        name: c.name,
        type: c.type,
        phone: c.phone,
        email: c.email,
        address: c.address,
        status: c.status,
      });
    });

    worksheet.getRow(1).font = { bold: true };

    const buffer = await workbook.xlsx.writeBuffer();
    const blob = new Blob([buffer], {
      type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    });
    FileSaver.saveAs(blob, `Customers_${new Date().toISOString().slice(0, 10)}.xlsx`);
  }

  async importFromExcel(event: any): Promise<void> {
    const file: File | undefined = event.target.files?.[0];
    if (!file) return;
    this.importBusy = true;
    this.errorMessage = null;
    this.importFailureMessages = [];
    try {
      const response = await firstValueFrom(this.customerService.importCustomers(file));
      await this.fetchCustomers();
      const message = response?.message ?? 'Customer import completed.';
      const failures = response?.data?.failureMessages ?? [];
      const failureCount = response?.data?.failureCount ?? 0;
      if (failureCount > 0) {
        this.errorMessage = `${message} (${failureCount} failed.)`;
        this.importFailureMessages = failures;
      } else {
        this.notify.simulateNotification('Import', message);
        this.errorMessage = null;
        this.importFailureMessages = [];
      }
    } catch (err) {
      console.error('Import failed', err);
      const message =
        err instanceof Error && err.message
          ? err.message
          : 'Import failed. Please check the template and try again.';
      this.errorMessage = message;
      this.importFailureMessages = [];
    } finally {
      this.importBusy = false;
      if (event?.target) event.target.value = '';
    }
  }

  openCustomerModal(customer?: Customer): void {
    this.selectedCustomer = customer ? { ...customer } : this.createDefaultCustomer();
    this.validationErrors = [];
    this.isSaving = false;
    this.isModalOpen = true;
  }

  async downloadTemplate(): Promise<void> {
    try {
      const url = `${environment.baseUrl}/api/admin/customers/import/template`;
      const token = this.authService.getToken();
      const response = await fetch(url, {
        headers: token ? { Authorization: `Bearer ${token}` } : {},
      });
      if (!response.ok) throw new Error(`Template download failed (${response.status})`);
      const blob = await response.blob();
      FileSaver.saveAs(blob, 'customer-import-template.csv');
    } catch (err) {
      console.error('Failed to download template', err);
      this.errorMessage = 'Failed to download template. Please try again.';
    }
  }

  closeModal(): void {
    this.isModalOpen = false;
    this.validationErrors = [];
    this.isSaving = false;
  }

  saveCustomer(): void {
    this.validationErrors = [];
    this.isSaving = true;

    // First: Client-side validation
    const clientErrors = this.customerService.validateCustomer(this.selectedCustomer);
    if (clientErrors.length > 0) {
      this.validationErrors = clientErrors;
      this.isSaving = false;
      return;
    }

    // Second: Prepare the request
    const op = this.selectedCustomer.id
      ? this.customerService.updateCustomer(this.selectedCustomer.id, this.selectedCustomer)
      : this.customerService.createCustomer(this.selectedCustomer);

    op.subscribe({
      next: () => {
        this.isSaving = false;
        this.fetchCustomers();
        this.closeModal();
      },
      error: (err) => {
        this.isSaving = false;
        console.error('Save error:', err);

        // Initialize validation errors
        this.validationErrors = [];

        // Primary: Check for structured validation errors in response
        if (err?.error?.validationErrors && typeof err.error.validationErrors === 'object') {
          const fieldErrors = err.error.validationErrors;

          // Extract field-specific errors (prioritize non-global errors)
          const fieldMessages = Object.entries(fieldErrors)
            .filter(([field]) => field !== '_global')
            .map(([field, message]) => {
              // Format error message with field context
              if (field === 'email') {
                return `Email: ${message}`;
              } else if (field === 'phone') {
                return `Phone: ${message}`;
              } else if (field === 'customerCode') {
                return `Customer Code: ${message}`;
              }
              return `${field}: ${message}`;
            });

          if (fieldMessages.length > 0) {
            this.validationErrors = fieldMessages;
          }

          // Add global error if no field errors
          if (this.validationErrors.length === 0 && fieldErrors._global) {
            this.validationErrors.push(fieldErrors._global as string);
          }
        }

        // Secondary: Handle error message from response body
        if (this.validationErrors.length === 0 && err?.error?.message) {
          const errorMsg = err.error.message;

          // Parse specific duplicate field errors
          if (errorMsg.includes('email')) {
            this.validationErrors.push(
              'Email: This email address is already in use. Please use a different email.',
            );
          } else if (errorMsg.includes('phone')) {
            this.validationErrors.push(
              'Phone: This phone number is already in use. Please use a different number.',
            );
          } else if (errorMsg.includes('customerCode') || errorMsg.includes('customer code')) {
            // Extract the duplicate code from the error message
            const codeMatch = errorMsg.match(/'([^']+)'/);
            const duplicateCode = codeMatch ? codeMatch[1] : 'provided';
            this.validationErrors.push(
              `Customer Code: The code '${duplicateCode}' is already in use. Please choose a different code.`,
            );
          } else {
            this.validationErrors.push(errorMsg);
          }
        }

        // Tertiary: Handle legacy array-based errors
        if (
          this.validationErrors.length === 0 &&
          err?.error?.errors &&
          Array.isArray(err.error.errors)
        ) {
          this.validationErrors = err.error.errors.map((e: any) =>
            e.field ? `${e.field}: ${e.message}` : e.message,
          );
        }

        // Fallback: Generic error message
        if (this.validationErrors.length === 0) {
          this.validationErrors.push(
            'Failed to save customer. Please check all fields and try again.',
          );
        }
      },
    });
  }

  hasCustomerCodeError(): boolean {
    return this.validationErrors.some(
      (error) =>
        error.toLowerCase().includes('customer code') && error.toLowerCase().includes('already'),
    );
  }

  /**
   * Check if there's an error for a specific field
   */
  hasFieldError(fieldName: string): boolean {
    return this.validationErrors.some((error) =>
      error.toLowerCase().startsWith(fieldName.toLowerCase() + ':'),
    );
  }

  /**
   * Get error message for a specific field
   */
  getFieldErrorMessage(fieldName: string): string {
    const error = this.validationErrors.find((error) =>
      error.toLowerCase().startsWith(fieldName.toLowerCase() + ':'),
    );
    return error ? error.substring(fieldName.length + 2).trim() : '';
  }

  /**
   * Check if email field has error
   */
  hasEmailError(): boolean {
    return this.hasFieldError('email');
  }

  /**
   * Check if phone field has error
   */
  hasPhoneError(): boolean {
    return this.hasFieldError('phone');
  }

  /**
   * Check if customer name field has error
   */
  hasNameError(): boolean {
    return this.hasFieldError('name');
  }

  /**
   * Get formatted validation errors grouped by field
   */
  getGroupedErrors(): { field: string; message: string }[] {
    return this.validationErrors.map((error) => {
      const colonIndex = error.indexOf(':');
      if (colonIndex > -1) {
        return {
          field: error.substring(0, colonIndex).trim(),
          message: error.substring(colonIndex + 1).trim(),
        };
      }
      return { field: 'General', message: error };
    });
  }

  /**
   * Clear specific field error
   */
  clearFieldError(fieldName: string): void {
    this.validationErrors = this.validationErrors.filter(
      (error) => !error.toLowerCase().startsWith(fieldName.toLowerCase() + ':'),
    );
  }

  /**
   * Validate email format on blur (inline validation)
   */
  validateEmailFormat(): void {
    if (!this.selectedCustomer.email) {
      this.clearFieldError('email');
      return;
    }

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(this.selectedCustomer.email)) {
      this.clearFieldError('email');
      this.validationErrors.push(
        'Email: Please enter a valid email address (e.g., user@example.com)',
      );
    } else {
      this.clearFieldError('email');
    }
  }

  /**
   * Validate phone format on blur (inline validation)
   * Note: No format validation - accepts any input
   */
  validatePhoneFormat(): void {
    // Clear any existing phone errors
    this.clearFieldError('phone');

    // Only check if required field is filled
    if (!this.selectedCustomer.phone || this.selectedCustomer.phone.trim() === '') {
      this.validationErrors.push('Phone: This field is required');
    }
    // No format validation - accept any phone format
  }

  /**
   * Check for duplicate email (async validation)
   */
  checkEmailDuplicate(): void {
    if (!this.selectedCustomer.email || this.hasEmailError()) return;

    // Validate format first
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(this.selectedCustomer.email)) return;

    this.customerService
      .isEmailAvailable(this.selectedCustomer.email, this.selectedCustomer.id)
      .subscribe({
        next: (isAvailable) => {
          this.clearFieldError('email');
          if (!isAvailable) {
            this.validationErrors.push(
              'Email: This email address is already registered. Please use a different email.',
            );
          }
        },
        error: (err) => console.error('Email availability check failed:', err),
      });
  }

  /**
   * Check for duplicate phone (async validation)
   * Note: No format validation - just checks for duplicates
   */
  checkPhoneDuplicate(): void {
    if (!this.selectedCustomer.phone || this.hasPhoneError()) return;

    // Skip format validation - just check for duplicates
    this.customerService
      .isPhoneAvailable(this.selectedCustomer.phone, this.selectedCustomer.id)
      .subscribe({
        next: (isAvailable) => {
          this.clearFieldError('phone');
          if (!isAvailable) {
            this.validationErrors.push(
              'Phone: This phone number is already registered. Please use a different number.',
            );
          }
        },
        error: (err) => console.error('Phone availability check failed:', err),
      });
  }

  /**
   * Check for duplicate customer code (async validation)
   */
  checkCustomerCodeDuplicate(): void {
    if (!this.selectedCustomer.customerCode || this.hasCustomerCodeError()) return;

    this.customerService
      .isCustomerCodeAvailable(this.selectedCustomer.customerCode, this.selectedCustomer.id)
      .subscribe({
        next: (isAvailable) => {
          this.clearFieldError('customer code');
          this.clearFieldError('customerCode');
          if (!isAvailable) {
            this.validationErrors.push(
              `Customer Code: The code '${this.selectedCustomer.customerCode}' is already in use. Please choose a different code.`,
            );
          }
        },
        error: (err) => console.error('Customer code availability check failed:', err),
      });
  }

  /**
   * Get CSS class for form field based on validation state
   */
  getFieldClass(fieldName: string): string {
    if (this.hasFieldError(fieldName)) {
      return 'border-red-500 focus:border-red-500 focus:ring-red-500';
    }
    return 'border-gray-300 focus:border-blue-500 focus:ring-blue-500';
  }

  /**
   * Show tooltip with validation hint
   */
  getFieldTooltip(fieldName: string): string {
    switch (fieldName.toLowerCase()) {
      case 'email':
        return 'Enter a valid email address (e.g., user@example.com)';
      case 'phone':
        return 'Enter phone number in any format (with or without country code)';
      case 'customercode':
        return 'Unique identifier for this customer (auto-generated if left empty)';
      case 'name':
        return 'Full name or company name of the customer';
      default:
        return '';
    }
  }

  /**
   * Count total validation errors
   */
  getErrorCount(): number {
    return this.validationErrors.length;
  }

  /**
   * Check if form has any errors
   */
  hasErrors(): boolean {
    return this.validationErrors.length > 0;
  }

  /**
   * Get all non-field-specific errors (global errors)
   */
  getGlobalErrors(): string[] {
    return this.validationErrors.filter((error) => !error.includes(':'));
  }

  /**
   * Check if email is available (real-time validation)
   */
  checkEmailAvailability(): void {
    if (!this.selectedCustomer.email || this.selectedCustomer.email.trim() === '') {
      // Clear email errors only
      this.validationErrors = this.validationErrors.filter(
        (error) => !error.toLowerCase().includes('email'),
      );
      return;
    }

    this.customerService
      .isEmailAvailable(this.selectedCustomer.email, this.selectedCustomer.id)
      .subscribe({
        next: (available) => {
          if (!available) {
            // Remove old email error if exists
            this.validationErrors = this.validationErrors.filter(
              (error) => !error.toLowerCase().includes('email'),
            );
            this.validationErrors.push('Email: This email address is already in use.');
          } else {
            // Remove email duplicate error if it was there
            this.validationErrors = this.validationErrors.filter(
              (error) =>
                !(error.toLowerCase().includes('email') && error.toLowerCase().includes('already')),
            );
          }
        },
        error: (err) => {
          console.error('Error checking email availability:', err);
        },
      });
  }

  /**
   * Check if phone is available (real-time validation)
   */
  checkPhoneAvailability(): void {
    if (!this.selectedCustomer.phone || this.selectedCustomer.phone.trim() === '') {
      // Clear phone errors
      this.validationErrors = this.validationErrors.filter(
        (error) => !error.toLowerCase().includes('phone'),
      );
      return;
    }

    this.customerService
      .isPhoneAvailable(this.selectedCustomer.phone, this.selectedCustomer.id)
      .subscribe({
        next: (available) => {
          if (!available) {
            // Remove old phone error if exists
            this.validationErrors = this.validationErrors.filter(
              (error) => !error.toLowerCase().includes('phone'),
            );
            this.validationErrors.push('Phone: This phone number is already in use.');
          } else {
            // Remove phone duplicate error if it was there
            this.validationErrors = this.validationErrors.filter(
              (error) =>
                !(error.toLowerCase().includes('phone') && error.toLowerCase().includes('already')),
            );
          }
        },
        error: (err) => {
          console.error('Error checking phone availability:', err);
        },
      });
  }

  /**
   * Generate next sequential customer code
   * Calls backend API to get next sequential code (format: CUSTXXXX)
   * Falls back to local generation if API fails
   */
  generateCustomerCode(): void {
    this.customerService.generateNextCustomerCode().subscribe({
      next: (code: string) => {
        this.selectedCustomer.customerCode = code;
        // Clear customer code related errors
        this.validationErrors = this.validationErrors.filter(
          (error) =>
            !(
              error.toLowerCase().includes('customer code') &&
              error.toLowerCase().includes('already')
            ),
        );
        console.log('Generated customer code:', code);
      },
      error: (err) => {
        console.error('Error generating customer code:', err);
        // Fallback: use timestamp-based code
        const timestamp = Date.now().toString().slice(-4);
        this.selectedCustomer.customerCode = `CUST${timestamp}`;
        console.log('Using fallback customer code:', this.selectedCustomer.customerCode);
      },
    });
  }

  async deleteCustomer(id?: number): Promise<void> {
    if (!id || !(await this.confirm.confirm('Delete this customer?'))) return;

    this.customerService.deleteCustomer(id).subscribe({
      next: () => this.fetchCustomers(),
      error: (err) => console.error('Delete error:', err),
    });
  }

  toggleDropdown(id: number): void {
    this.dropdownOpen = this.dropdownOpen === id ? null : id;
  }

  getPages(): number[] {
    return Array.from({ length: this.totalPages }, (_, i) => i);
  }

  goToPage(page: number): void {
    this.currentPage = page;
    this.fetchCustomers();
  }

  nextPage(): void {
    if (this.currentPage < this.totalPages - 1) {
      this.currentPage++;
      this.fetchCustomers();
    }
  }

  prevPage(): void {
    if (this.currentPage > 0) {
      this.currentPage--;
      this.fetchCustomers();
    }
  }

  selectionSummary(): string {
    if (this.selectionScope === 'query') {
      return `All ${this.totalElements} results selected`;
    }
    if (this.selectedIds.length === 0) {
      return 'No customers selected';
    }
    return `${this.selectedIds.length} selected`;
  }

  @HostListener('document:click', ['$event'])
  onClickOutside(event: MouseEvent): void {
    const target = event.target as HTMLElement;
    if (!target.closest('.dropdown-menu') && !target.closest('.toggle-dropdown')) {
      this.dropdownOpen = null;
    }

    if (!target.closest('.types-filter')) {
      this.typeMenuOpen = false;
    }
    if (!target.closest('.statuses-filter')) {
      this.statusMenuOpen = false;
    }
    if (!target.closest('.tags-filter')) {
      this.tagMenuOpen = false;
    }
    if (!target.closest('.segments-filter')) {
      this.segmentMenuOpen = false;
    }
  }

  // ============ Quick View Modal ============
  openQuickView(customer: Customer): void {
    this.quickViewCustomer = customer;
    this.dropdownOpen = null;
  }

  closeQuickView(): void {
    this.quickViewCustomer = null;
  }

  viewCustomerDetails(customer: Customer): void {
    this.closeQuickView();
    this.addToRecentCustomers(customer);
    this.router.navigate(['/customers', customer.id]);
  }

  // ============ Recent Customers Sidebar ============
  toggleRecentSidebar(): void {
    this.showRecentSidebar = !this.showRecentSidebar;
  }

  loadRecentCustomers(): void {
    try {
      const stored = localStorage.getItem(this.RECENT_CUSTOMERS_KEY);
      if (stored) {
        const parsed = JSON.parse(stored);
        this.recentCustomers = parsed
          .map((c: Customer & { viewedAt?: string }) => ({
            ...c,
            viewedAt: c.viewedAt ? new Date(c.viewedAt) : undefined,
          }))
          .filter((c: Customer) => c.id && c.name); // Filter out invalid entries
      }
    } catch (error) {
      console.error('Failed to load recent customers:', error);
      this.recentCustomers = [];
    }
  }

  addToRecentCustomers(customer: Customer): void {
    // Skip if customer doesn't have required data
    if (!customer || !customer.id || !customer.name) {
      console.warn('Cannot add customer to recent: missing required data', customer);
      return;
    }

    const existing = this.recentCustomers.findIndex((c) => c.id === customer.id);

    if (existing !== -1) {
      this.recentCustomers.splice(existing, 1);
    }

    this.recentCustomers.unshift({ ...customer, viewedAt: new Date() });

    if (this.recentCustomers.length > this.MAX_RECENT_CUSTOMERS) {
      this.recentCustomers = this.recentCustomers.slice(0, this.MAX_RECENT_CUSTOMERS);
    }

    this.saveRecentCustomers();
  }

  private saveRecentCustomers(): void {
    try {
      localStorage.setItem(this.RECENT_CUSTOMERS_KEY, JSON.stringify(this.recentCustomers));
    } catch (error) {
      console.error('Failed to save recent customers:', error);
    }
  }

  async clearRecentCustomers(): Promise<void> {
    if (!(await this.confirm.confirm('Clear all recent customers history?'))) return;
    this.recentCustomers = [];
    localStorage.removeItem(this.RECENT_CUSTOMERS_KEY);
  }

  navigateToCustomer(customer: Customer): void {
    this.addToRecentCustomers(customer);
    this.router.navigate(['/customers', customer.id]);
  }

  timeAgo(date: Date): string {
    const seconds = Math.floor((new Date().getTime() - new Date(date).getTime()) / 1000);

    if (seconds < 60) return 'Just now';
    if (seconds < 3600) return `${Math.floor(seconds / 60)}m ago`;
    if (seconds < 86400) return `${Math.floor(seconds / 3600)}h ago`;
    return `${Math.floor(seconds / 86400)}d ago`;
  }

  // ============ Keyboard Shortcuts ============
  @HostListener('document:keydown', ['$event'])
  handleKeyboardShortcuts(event: KeyboardEvent): void {
    // Don't trigger shortcuts when typing in inputs
    const target = event.target as HTMLElement;
    if (
      target.tagName === 'INPUT' ||
      target.tagName === 'TEXTAREA' ||
      target.tagName === 'SELECT'
    ) {
      return;
    }

    // Don't trigger when modals are open (except Esc)
    if (event.key !== 'Escape' && (this.isModalOpen || this.quickViewCustomer)) {
      return;
    }

    switch (event.key.toLowerCase()) {
      case 'n':
        event.preventDefault();
        this.openCustomerModal();
        break;
      case 'e':
        if (this.selectedIds.length === 1) {
          event.preventDefault();
          const customer = this.customers.find((c) => c.id === this.selectedIds[0]);
          if (customer) this.openCustomerModal(customer);
        }
        break;
      case 'q':
        if (this.selectedIds.length === 1) {
          event.preventDefault();
          const customer = this.customers.find((c) => c.id === this.selectedIds[0]);
          if (customer) this.openQuickView(customer);
        }
        break;
      case 'escape':
        event.preventDefault();
        if (this.quickViewCustomer) {
          this.closeQuickView();
        } else if (this.isModalOpen) {
          this.closeModal();
        } else if (this.showRecentSidebar) {
          this.toggleRecentSidebar();
        }
        break;
      case 'r':
        if (event.ctrlKey || event.metaKey) {
          event.preventDefault();
          this.toggleRecentSidebar();
        }
        break;
    }
  }

  // ============ Tag Management ============
  openTagModal(customer: Customer): void {
    this.selectedCustomerForTags = { ...customer };
    if (!this.selectedCustomerForTags.tags) {
      this.selectedCustomerForTags.tags = [];
    }
    this.isTagModalOpen = true;
  }

  closeTagModal(): void {
    this.isTagModalOpen = false;
    this.selectedCustomerForTags = null;
    this.newTag = '';
  }

  addTagToCustomer(tag: string): void {
    if (!this.selectedCustomerForTags || !tag.trim()) return;

    if (!this.selectedCustomerForTags.tags) {
      this.selectedCustomerForTags.tags = [];
    }

    if (!this.selectedCustomerForTags.tags.includes(tag)) {
      this.selectedCustomerForTags.tags.push(tag);
    }
  }

  removeTagFromCustomer(tag: string): void {
    if (!this.selectedCustomerForTags) return;

    if (this.selectedCustomerForTags.tags) {
      this.selectedCustomerForTags.tags = this.selectedCustomerForTags.tags.filter(
        (t) => t !== tag,
      );
    }
  }

  addNewTag(): void {
    if (!this.newTag.trim()) return;

    const tag = this.newTag.trim();
    if (!this.availableTags.includes(tag)) {
      this.availableTags.push(tag);
    }

    this.addTagToCustomer(tag);
    this.newTag = '';
  }

  saveCustomerTags(): void {
    if (!this.selectedCustomerForTags?.id) return;

    this.customerService
      .updateCustomer(this.selectedCustomerForTags.id, this.selectedCustomerForTags)
      .subscribe({
        next: () => {
          const index = this.customers.findIndex((c) => c.id === this.selectedCustomerForTags!.id);
          if (index >= 0) {
            this.customers[index] = { ...this.selectedCustomerForTags! };
          }
          this.closeTagModal();
        },
        error: (err) => {
          console.error('Failed to update tags:', err);
          this.notify.simulateNotification(
            'Tag Update Failed',
            'Failed to update tags. Please try again.',
          );
        },
      });
  }

  async bulkAddTag(tag: string): Promise<void> {
    if (!this.selectedIds.length) return;

    const updates = this.selectedIds.map((id) => {
      const customer = this.customers.find((c) => c.id === id);
      if (!customer) return Promise.resolve();

      const tags = customer.tags || [];
      if (!tags.includes(tag)) {
        tags.push(tag);
      }

      return firstValueFrom(this.customerService.updateCustomer(id, { ...customer, tags }));
    });

    try {
      await Promise.all(updates);
      this.fetchCustomers();
    } catch (err) {
      console.error('Bulk tag update failed:', err);
      this.notify.simulateNotification(
        'Bulk Tag Update',
        'Failed to update tags for some customers.',
      );
    }
  }

  getSegmentBadgeClass(segment?: string): string {
    if (!segment) return 'bg-gray-200 text-gray-700';

    const segmentOption = this.segmentOptions.find((s) => s.value === segment);
    const color = segmentOption?.color || 'gray';

    const colorMap: Record<string, string> = {
      purple: 'bg-purple-100 text-purple-800',
      blue: 'bg-blue-100 text-blue-800',
      green: 'bg-green-100 text-green-800',
      red: 'bg-red-100 text-red-800',
      yellow: 'bg-yellow-100 text-yellow-800',
      gray: 'bg-gray-100 text-gray-800',
    };

    return colorMap[color] || 'bg-gray-200 text-gray-700';
  }

  getHealthScoreClass(score?: number): string {
    if (!score) return 'text-gray-500';
    if (score >= 80) return 'text-green-600';
    if (score >= 60) return 'text-blue-600';
    if (score >= 40) return 'text-yellow-600';
    return 'text-red-600';
  }

  getHealthScoreIcon(score?: number): string {
    if (!score) return '○';
    if (score >= 80) return '●';
    if (score >= 60) return '◐';
    if (score >= 40) return '◑';
    return '◯';
  }
}
