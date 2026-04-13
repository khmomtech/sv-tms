import { CommonModule, NgClass, NgForOf, NgIf } from '@angular/common';
import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { MatIconModule } from '@angular/material/icon';
import { RouterModule, ActivatedRoute, Router, ParamMap } from '@angular/router';
import { Subscription } from 'rxjs';
import { Customer } from '../../models/customer.model';
import { CustomerAddress } from '../../models/customer-address.model';
import { CustomerBillToAddress } from '../../models/customer-bill-to-address.model';
import { CustomerContact } from '../../models/customer-contact.model';
import { TransportOrder } from '../../models/transport-order.model';
import {
  CustomerFinanceMutationPayload,
  CustomerFinanceTransaction,
  CustomerService,
} from '../../services/custommer.service';
import { CustomerContactService } from '../../services/customer-contact.service';
import { CustomerAddressService } from '../../services/customer-address.service';
import { CustomerBillToAddressService } from '../../services/customer-bill-to-address.service';
import { TransportOrderService } from '../../services/transport-order.service';
import { NotificationService } from '../../services/notification.service';
import { ConfirmService } from '../../services/confirm.service';

type CustomerGroup =
  | 'details'
  | 'contacts'
  | 'customer-address'
  | 'bill-to-address'
  | 'orders'
  | 'invoices'
  | 'customer-admin';

@Component({
  standalone: true,
  selector: 'app-customer-view',
  templateUrl: './customer-view.component.html',
  styleUrls: ['./customer-view.component.css'],
  imports: [CommonModule, NgClass, NgForOf, NgIf, FormsModule, RouterModule, MatIconModule],
})
export class CustomerViewComponent {
  readonly Math = Math;
  activeGroup: CustomerGroup = 'details';
  private groupSub: Subscription | null = null;
  private financeActionHandled = false;
  private pendingFinanceAction: string | null = null;
  financeTransactions: CustomerFinanceTransaction[] = [];
  financeHistoryLoading = false;
  financeSubmitting = false;
  isFinanceModalOpen = false;
  financeModalTitle = '';
  financeSubmitLabel = '';
  financeModalMode: 'opening-balance' | 'credit-note' | 'debit-note' | null = null;
  financeForm = {
    amount: null as number | null,
    reference: '',
    note: '',
    effectiveDate: new Date().toISOString().slice(0, 10),
  };

  addressesLoading = false;
  addressesError: string | null = null;
  addressServerTotal = 0;

  billToAddresses: CustomerBillToAddress[] = [];
  billToLoading = false;
  billToError: string | null = null;
  private billToLoaded = false;
  // Server-side paging for bill-to addresses
  billToFilter = { search: '' };
  billToCurrentPage = 1; // 1-based for UI
  billToPageSize = 10;
  billToPageSizes = [5, 10, 25, 50];
  billToTotal = 0;
  private billToFilterDebounceTimer: any = null;

  orders: TransportOrder[] = [];
  ordersLoading = false;
  ordersError: string | null = null;
  private ordersLoaded = false;
  // Orders UI: client-side filtering and pagination
  ordersFiltered: TransportOrder[] = [];
  paginatedOrders: TransportOrder[] = [];
  ordersFilter = { search: '', status: '' };
  ordersCurrentPage = 1;
  ordersPageSize = 25;
  ordersPageSizes = [10, 25, 50, 100];
  // Server-side paging flag and totals
  useServerSideOrders = true;
  ordersTotal = 0;
  private ordersServerPage = 0; // 0-based index when using server
  private orderFilterDebounceTimer: any = null;

  customer: Customer = {
    id: undefined,
    customerCode: '',
    type: 'COMPANY',
    name: '',
    phone: '',
    address: '',
    website: '',
    customerGroup: '',
    city: '',
    state: '',
    zip: '',
    country: '',
    paymentTerm: '',
    codAllowed: false,
    defaultServiceType: '',
    notes: '',
    status: 'ACTIVE',
    balance: 0,
    gender: '',
    passportNumber: '',
    isBanned: false,
    passportImage: '',
    creditLimit: 0,
    paymentTerms: '',
    currentBalance: 0,
    accountManager: '',
    lifecycleStage: undefined,
    totalOrders: 0,
    totalRevenue: 0,
    lastOrderDate: '',
    firstOrderDate: '',
    segment: '',
    tags: [],
    customerSegment: undefined,
    healthScore: 0,
    deletedAt: '',
    deletedBy: '',
    companyDetails: undefined,
    individualDetails: undefined,
    addresses: [],
  };

  // ...existing code...

  // Validation helper for company name
  validateCompanyName(): void {
    this.errorCompanyName = !this.customer.name?.trim();
  }
  errorCompanyName = false;
  errorCustomerCode = false;
  errorEmail = false;
  errorPhone = false;
  errorMessage: string | null = null;
  successMessage: string | null = null;
  isSaving = false;
  isLoading = false;
  isEditMode = false;
  contacts: CustomerContact[] = [];
  filteredContacts: CustomerContact[] = [];
  paginatedContacts: CustomerContact[] = [];
  contactFilter = { search: '', activeOnly: false };
  contactCurrentPage = 1;
  contactPageSize = 10;
  contactPageSizes = [5, 10, 20, 50, 100, 200, 500, 1000];
  editingContact: CustomerContact | null = null;
  isContactModalOpen = false;
  dropdownOpen: number | null = null;
  private contactsLoaded = false;
  private readonly selectedContactIds = new Set<number>();

  // Address modal state
  isAddressModalOpen = false;
  editingAddress: Partial<CustomerAddress> | null = null;
  addressTypeOptions = ['WAREHOUSE', 'DEPO', 'PICKUP', 'DROP', 'SHIP_TO'];
  addressDropdownOpen: number | null = null;
  addressFilter = { search: '', type: '' };
  addressCurrentPage = 1;
  addressPageSize = 5;
  addressPageSizes = [5, 10, 20, 50];
  paginatedAddresses: CustomerAddress[] = [];

  // Bill To modal state
  isBillToModalOpen = false;
  editingBillTo: CustomerBillToAddress | null = null;
  billToDropdownOpen: number | null = null;

  constructor(
    private readonly customerService: CustomerService,
    private readonly customerContactService: CustomerContactService,
    private readonly addressService: CustomerAddressService,
    private readonly customerBillToService: CustomerBillToAddressService,
    private readonly transportOrderService: TransportOrderService,
    private readonly router: Router,
    private readonly route: ActivatedRoute,
    private readonly notify: NotificationService,
    private readonly confirm: ConfirmService,
  ) {}

  ngOnInit(): void {
    this.groupSub = this.route.queryParamMap.subscribe((qpm: ParamMap) => {
      this.setActiveGroup(qpm.get('group'));
      this.pendingFinanceAction = qpm.get('financeAction');
      this.financeActionHandled = false;
      // support optional bill-to query params
      const bp = qpm.get('billPage');
      const bs = qpm.get('billSearch');
      if (bp) this.billToCurrentPage = Number(bp) || 1;
      if (bs !== null && bs !== undefined) this.billToFilter.search = bs || '';
      this.handleFinanceRouteAction();
    });
    this.applyAddressFilter();

    const id = this.route.snapshot.paramMap.get('id');
    if (id) {
      this.isEditMode = true;
      this.isLoading = true;
      this.customerService.getCustomerById(Number(id)).subscribe({
        next: (res: any) => {
          const customer = res?.data?.customer ?? res?.data ?? res;
          this.customer = customer;
          this.legacyBillToAddressesCache = [];
          this.legacyBillToLoaded = false;
          this.applyAddressFilter();
          this.isLoading = false;
          this.handleFinanceRouteAction();
          this.ensureGroupDataLoaded();
        },
        error: () => {
          this.isLoading = false;
          this.errorMessage = 'Failed to load customer.';
        },
      });
    } else {
      this.isEditMode = false;
      this.customerService.generateNextCustomerCode().subscribe({
        next: (code: string) => (this.customer.customerCode = code),
        error: () => (this.customer.customerCode = 'Auto-generated'),
      });
    }
  }

  ngOnDestroy(): void {
    this.groupSub?.unsubscribe();
    this.groupSub = null;
  }

  openOpeningBalanceAction(): void {
    void this.router.navigate(['/customers', this.customer.id], {
      queryParams: { group: 'customer-admin', financeAction: 'opening-balance' },
      queryParamsHandling: 'merge',
    });
  }

  openCreditNoteAction(): void {
    void this.router.navigate(['/customers', this.customer.id], {
      queryParams: { group: 'customer-admin', financeAction: 'credit-note' },
      queryParamsHandling: 'merge',
    });
  }

  openDebitNoteAction(): void {
    void this.router.navigate(['/customers', this.customer.id], {
      queryParams: { group: 'customer-admin', financeAction: 'debit-note' },
      queryParamsHandling: 'merge',
    });
  }

  private setActiveGroup(groupParam: string | null): void {
    const g = (groupParam ?? '').trim();
    const next: CustomerGroup =
      g === 'contacts'
        ? 'contacts'
        : g === 'customer-address'
          ? 'customer-address'
          : g === 'bill-to-address'
            ? 'bill-to-address'
            : g === 'orders'
              ? 'orders'
              : g === 'invoices'
                ? 'invoices'
                : g === 'customer-admin'
                  ? 'customer-admin'
                  : 'details';

    if (this.activeGroup === next) return;
    this.activeGroup = next;
    this.ensureGroupDataLoaded();
  }

  private ensureGroupDataLoaded(): void {
    const customerId = this.customer?.id;
    if (!customerId) return;

    if (this.activeGroup === 'contacts' && !this.contactsLoaded) {
      this.contactsLoaded = true;
      this.loadContacts(customerId);
    }

    if ((this.activeGroup === 'orders' || this.activeGroup === 'invoices') && !this.ordersLoaded) {
      this.ordersLoaded = true;
      this.loadOrders(customerId);
    }

    if (this.activeGroup === 'customer-address') {
      this.fetchAddressPage();
    }

    if (this.activeGroup === 'bill-to-address' && !this.billToLoaded) {
      this.billToLoaded = true;
      // load initial page using server-side search/paging if any filter present
      if (this.billToFilter.search || this.billToCurrentPage > 1) {
        this.loadBillToServer(
          customerId,
          this.billToCurrentPage - 1,
          this.billToPageSize,
          this.billToFilter.search,
        );
      } else {
        this.reloadBillToAddresses(customerId);
      }
    }

    if (this.activeGroup === 'bill-to-address' && !this.legacyBillToLoaded) {
      this.loadLegacyBillToAddresses(customerId);
    }

    if (this.activeGroup === 'customer-admin') {
      this.loadFinanceTransactions();
    }
  }

  private handleFinanceRouteAction(): void {
    if (this.financeActionHandled || !this.customer?.id) {
      return;
    }

    const financeAction = this.pendingFinanceAction;
    if (!financeAction) {
      return;
    }

    this.financeActionHandled = true;
    this.activeGroup = 'customer-admin';

    if (financeAction === 'opening-balance') {
      this.openFinanceModal('opening-balance');
      return;
    }
    if (financeAction === 'credit-note') {
      this.openFinanceModal('credit-note');
      return;
    }
    if (financeAction === 'debit-note') {
      this.openFinanceModal('debit-note');
    }
  }

  openFinanceModal(mode: 'opening-balance' | 'credit-note' | 'debit-note'): void {
    this.financeModalMode = mode;
    this.isFinanceModalOpen = true;
    this.financeForm = {
      amount: null,
      reference: '',
      note: '',
      effectiveDate: new Date().toISOString().slice(0, 10),
    };

    if (mode === 'opening-balance') {
      this.financeModalTitle = 'Add Opening Balance';
      this.financeSubmitLabel = 'Save Opening Balance';
      return;
    }
    if (mode === 'credit-note') {
      this.financeModalTitle = 'Create Credit Note';
      this.financeSubmitLabel = 'Save Credit Note';
      return;
    }
    this.financeModalTitle = 'Create Debit Note';
    this.financeSubmitLabel = 'Save Debit Note';
  }

  closeFinanceModal(): void {
    this.isFinanceModalOpen = false;
    this.financeSubmitting = false;
    this.financeModalMode = null;
    if (this.pendingFinanceAction) {
      void this.router.navigate([], {
        relativeTo: this.route,
        queryParams: { financeAction: null },
        queryParamsHandling: 'merge',
      });
      this.pendingFinanceAction = null;
    }
  }

  submitFinanceAction(): void {
    if (!this.customer?.id || !this.financeModalMode) {
      return;
    }

    const amount = Number(this.financeForm.amount);
    const needsPositive = this.financeModalMode !== 'opening-balance';
    if (!Number.isFinite(amount) || amount < 0 || (needsPositive && amount <= 0)) {
      this.notify.error('Please enter a valid amount.');
      return;
    }

    const payload: CustomerFinanceMutationPayload = {
      amount,
      reference: this.financeForm.reference.trim() || undefined,
      note: this.financeForm.note.trim() || undefined,
      effectiveDate: this.financeForm.effectiveDate || undefined,
    };

    let request$;
    if (this.financeModalMode === 'opening-balance') {
      request$ = this.customerService.createOpeningBalance(this.customer.id, payload);
    } else if (this.financeModalMode === 'credit-note') {
      request$ = this.customerService.createCreditNote(this.customer.id, payload);
    } else {
      request$ = this.customerService.createDebitNote(this.customer.id, payload);
    }

    this.financeSubmitting = true;
    request$.subscribe({
      next: (res) => {
        this.customer = { ...this.customer, ...(res.customer ?? {}) };
        this.financeTransactions = res.history ?? [];
        this.financeSubmitting = false;
        this.notify.success(`${this.financeModalTitle} saved successfully.`);
        this.closeFinanceModal();
      },
      error: (err) => {
        this.financeSubmitting = false;
        this.notify.error(err?.message || 'Failed to save finance transaction');
      },
    });
  }

  loadFinanceTransactions(force = false): void {
    if (!this.customer?.id || (this.financeHistoryLoading && !force)) {
      return;
    }
    this.financeHistoryLoading = true;
    this.customerService.getFinanceTransactions(this.customer.id).subscribe({
      next: (rows) => {
        this.financeTransactions = rows ?? [];
        this.financeHistoryLoading = false;
      },
      error: () => {
        this.financeHistoryLoading = false;
      },
    });
  }

  private normalizeAddressType(type?: string): string {
    return String(type ?? '')
      .trim()
      .toUpperCase();
  }

  legacyBillToAddressesCache: CustomerAddress[] = [];
  private legacyBillToLoaded = false;

  get legacyBillToAddresses(): CustomerAddress[] {
    return this.legacyBillToAddressesCache;
  }

  private loadLegacyBillToAddresses(customerId: number): void {
    this.legacyBillToLoaded = true;
    this.addressService.searchAddressesByCustomer(customerId, '', 'BILL', 0, 1000).subscribe({
      next: (result) => {
        this.legacyBillToAddressesCache = result.addresses ?? [];
      },
      error: () => {
        this.legacyBillToAddressesCache = [];
      },
    });
  }

  get invoicedOrders(): TransportOrder[] {
    return (this.orders ?? []).filter((o) => !!o.invoice);
  }

  loadOrders(customerId: number): void {
    if (this.useServerSideOrders) {
      this.loadOrdersServer(customerId, 0, this.ordersPageSize);
      return;
    }

    this.ordersLoading = true;
    this.ordersError = null;
    this.transportOrderService.getOrdersByCustomer(customerId).subscribe({
      next: (res: any) => {
        this.orders = (res?.data ?? res ?? []) as TransportOrder[];
        this.ordersLoading = false;
        this.applyOrderFilter();
      },
      error: () => {
        this.orders = [];
        this.ordersLoading = false;
        this.ordersError = 'Failed to load orders for this customer.';
      },
    });
  }

  private loadOrdersServer(customerId: number, page = 0, size = 25): void {
    this.ordersLoading = true;
    this.ordersError = null;
    const q = String(this.ordersFilter.search ?? '').trim();
    const status = String(this.ordersFilter.status ?? '').trim();
    this.transportOrderService.getFilteredOrders(q, status, '', '', 'desc', page, size).subscribe({
      next: (res: any) => {
        // Support common pageable shapes: res.data.content and res.data.totalElements
        const body = res?.data ?? res;
        if (body) {
          if (Array.isArray(body)) {
            this.ordersFiltered = body as TransportOrder[];
            this.ordersTotal = (body as any).length || 0;
            this.paginatedOrders = this.ordersFiltered.slice(0, size);
          } else if ('content' in body && Array.isArray(body.content)) {
            this.ordersFiltered = body.content as TransportOrder[];
            this.ordersTotal =
              Number(body.totalElements ?? body.total ?? this.ordersFiltered.length) || 0;
            this.paginatedOrders = this.ordersFiltered;
          } else if ('data' in body && Array.isArray(body.data)) {
            this.ordersFiltered = body.data as TransportOrder[];
            this.ordersTotal =
              Number(body.totalElements ?? body.total ?? this.ordersFiltered.length) || 0;
            this.paginatedOrders = this.ordersFiltered;
          } else {
            this.ordersFiltered = [];
            this.paginatedOrders = [];
            this.ordersTotal = 0;
          }
        }
        this.ordersLoading = false;
        this.ordersServerPage = page;
        this.ordersCurrentPage = this.ordersServerPage + 1;
      },
      error: () => {
        this.ordersFiltered = [];
        this.paginatedOrders = [];
        this.ordersLoading = false;
        this.ordersError = 'Failed to load orders for this customer.';
      },
    });
  }

  applyOrderFilter(): void {
    if (this.useServerSideOrders) {
      // Trigger server filter (page 0)
      const customerId = this.customer?.id;
      if (!customerId) return;
      this.loadOrdersServer(customerId, 0, this.ordersPageSize);
      return;
    }

    let filtered = this.orders ?? [];
    const s = String(this.ordersFilter.search ?? '')
      .trim()
      .toLowerCase();
    if (s) {
      filtered = filtered.filter((o) =>
        ((o.orderReference ?? '') + ' ' + (o.id ?? '') + ' ' + (o.customerName ?? ''))
          .toLowerCase()
          .includes(s),
      );
    }
    if (this.ordersFilter.status) {
      filtered = filtered.filter(
        (o) =>
          String(o.status ?? '').toLowerCase() === String(this.ordersFilter.status).toLowerCase(),
      );
    }
    this.ordersFiltered = filtered;
    this.ordersCurrentPage = 1;
    this.paginateOrders();
  }

  onOrdersFilterChange(): void {
    // Debounce rapid typing to avoid heavy filtering on each keystroke
    if (this.orderFilterDebounceTimer) clearTimeout(this.orderFilterDebounceTimer);
    this.orderFilterDebounceTimer = setTimeout(() => {
      this.applyOrderFilter();
      this.orderFilterDebounceTimer = null;
    }, 250);
  }

  paginateOrders(): void {
    if (this.useServerSideOrders) {
      // paginatedOrders already set from server response
      return;
    }

    const total = this.totalOrderPages();
    if (this.ordersCurrentPage > total) this.ordersCurrentPage = Math.max(1, total);
    const start = (this.ordersCurrentPage - 1) * this.ordersPageSize;
    const end = start + this.ordersPageSize;
    this.paginatedOrders = this.ordersFiltered.slice(start, end);
  }

  totalOrderPages(): number {
    if (this.useServerSideOrders) {
      const total = Math.ceil((this.ordersTotal ?? 0) / this.ordersPageSize);
      return Math.max(1, total);
    }
    const total = Math.ceil((this.ordersFiltered?.length ?? 0) / this.ordersPageSize);
    return Math.max(1, total);
  }

  setOrdersPageSize(size: number): void {
    if (!size || size <= 0) return;
    this.ordersPageSize = size;
    this.ordersCurrentPage = 1;
    this.paginateOrders();
  }

  prevOrdersPage(): void {
    if (this.ordersCurrentPage > 1) {
      this.ordersCurrentPage--;
      if (this.useServerSideOrders) {
        const customerId = this.customer?.id;
        if (!customerId) return;
        const pageIndex = this.ordersCurrentPage - 1;
        this.loadOrdersServer(customerId, pageIndex, this.ordersPageSize);
      } else {
        this.paginateOrders();
      }
    }
  }

  nextOrdersPage(): void {
    if (this.ordersCurrentPage < this.totalOrderPages()) {
      this.ordersCurrentPage++;
      if (this.useServerSideOrders) {
        const customerId = this.customer?.id;
        if (!customerId) return;
        const pageIndex = this.ordersCurrentPage - 1;
        this.loadOrdersServer(customerId, pageIndex, this.ordersPageSize);
      } else {
        this.paginateOrders();
      }
    }
  }

  firstOrdersPage(): void {
    if (this.ordersCurrentPage === 1) return;
    this.ordersCurrentPage = 1;
    if (this.useServerSideOrders) {
      const customerId = this.customer?.id;
      if (!customerId) return;
      this.loadOrdersServer(customerId, 0, this.ordersPageSize);
    } else {
      this.paginateOrders();
    }
  }

  lastOrdersPage(): void {
    const last = this.totalOrderPages();
    if (this.ordersCurrentPage === last) return;
    this.ordersCurrentPage = last;
    if (this.useServerSideOrders) {
      const customerId = this.customer?.id;
      if (!customerId) return;
      const pageIndex = this.ordersCurrentPage - 1;
      this.loadOrdersServer(customerId, pageIndex, this.ordersPageSize);
    } else {
      this.paginateOrders();
    }
  }

  importOrdersForCustomer(customerId: number, e: Event): void {
    const input = e.target as HTMLInputElement | null;
    const file = input?.files?.[0];
    if (!file) return;
    this.transportOrderService.importOrders(customerId, file).subscribe({
      next: () => {
        input.value = '';
        this.loadOrders(customerId);
      },
      error: (err: any) => {
        console.error('Import failed:', err);
        this.notify.error(err?.message || 'Order import failed');
      },
    });
  }

  reloadAddresses(customerId: number): void {
    this.fetchAddressPage();
  }

  downloadCustomerAddressesExport(customerId: number): void {
    this.addressesError = null;
    this.addressService.exportAddresses(customerId).subscribe({
      next: (blob) => {
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `addresses-customer-${customerId}.xlsx`;
        document.body.appendChild(a);
        a.click();
        a.remove();
        window.URL.revokeObjectURL(url);
      },
      error: (err: any) => {
        console.error('Export failed:', err);
        this.addressesError = 'Failed to export addresses.';
      },
    });
  }

  reloadBillToAddresses(customerId: number): void {
    this.billToLoading = true;
    this.billToError = null;
    this.customerBillToService.list(customerId).subscribe({
      next: (res: any) => {
        this.billToAddresses = res?.data ?? [];
        this.billToTotal = Array.isArray(res?.data)
          ? (res?.data?.length ?? 0)
          : (res?.data?.total ?? 0);
        this.billToLoading = false;
      },
      error: () => {
        this.billToAddresses = [];
        this.billToLoading = false;
        this.billToError = 'Failed to load bill-to addresses.';
      },
    });
  }

  loadBillToServer(customerId: number, page = 0, size = 10, search = ''): void {
    this.billToLoading = true;
    this.billToError = null;
    this.customerBillToService.search(customerId, search, page, size).subscribe({
      next: (res: any) => {
        const body = res?.data ?? res;
        if (body && body.addresses) {
          this.billToAddresses = body.addresses as CustomerBillToAddress[];
          this.billToTotal = Number(body.total ?? 0) || 0;
          this.billToCurrentPage = Number(body.page ?? page) + 1;
          this.billToPageSize = Number(body.size ?? size) || size;
        } else if (Array.isArray(body)) {
          this.billToAddresses = body as CustomerBillToAddress[];
          this.billToTotal = body.length;
          this.billToCurrentPage = page + 1;
          this.billToPageSize = size;
        } else {
          this.billToAddresses = [];
          this.billToTotal = 0;
        }
        this.billToLoading = false;
      },
      error: (err: any) => {
        console.error('Failed to load bill-to addresses (server):', err);
        this.billToAddresses = [];
        this.billToLoading = false;
        this.billToError = 'Failed to load bill-to addresses.';
      },
    });
  }

  onBillToFilterChange(): void {
    if (this.billToFilterDebounceTimer) clearTimeout(this.billToFilterDebounceTimer);
    this.billToFilterDebounceTimer = setTimeout(() => {
      const customerId = this.customer?.id;
      if (!customerId) return;
      this.billToCurrentPage = 1;
      this.updateQueryParams({
        billPage: this.billToCurrentPage,
        billSearch: this.billToFilter.search,
      });
      this.loadBillToServer(
        customerId,
        this.billToCurrentPage - 1,
        this.billToPageSize,
        this.billToFilter.search,
      );
      this.billToFilterDebounceTimer = null;
    }, 250);
  }

  totalBillToPages(): number {
    const total = Math.ceil((this.billToTotal ?? 0) / this.billToPageSize);
    return Math.max(1, total);
  }

  setBillToPageSize(size: number): void {
    if (!size || size <= 0) return;
    this.billToPageSize = size;
    this.billToCurrentPage = 1;
    const customerId = this.customer?.id;
    if (!customerId) return;
    this.updateQueryParams({
      billPage: this.billToCurrentPage,
      billSearch: this.billToFilter.search,
    });
    this.loadBillToServer(customerId, 0, this.billToPageSize, this.billToFilter.search);
  }

  prevBillToPage(): void {
    if (this.billToCurrentPage > 1) {
      this.billToCurrentPage--;
      const customerId = this.customer?.id;
      if (!customerId) return;
      this.updateQueryParams({
        billPage: this.billToCurrentPage,
        billSearch: this.billToFilter.search,
      });
      this.loadBillToServer(
        customerId,
        this.billToCurrentPage - 1,
        this.billToPageSize,
        this.billToFilter.search,
      );
    }
  }

  nextBillToPage(): void {
    if (this.billToCurrentPage < this.totalBillToPages()) {
      this.billToCurrentPage++;
      const customerId = this.customer?.id;
      if (!customerId) return;
      this.updateQueryParams({
        billPage: this.billToCurrentPage,
        billSearch: this.billToFilter.search,
      });
      this.loadBillToServer(
        customerId,
        this.billToCurrentPage - 1,
        this.billToPageSize,
        this.billToFilter.search,
      );
    }
  }

  firstBillToPage(): void {
    if (this.billToCurrentPage === 1) return;
    this.billToCurrentPage = 1;
    const customerId = this.customer?.id;
    if (!customerId) return;
    this.updateQueryParams({
      billPage: this.billToCurrentPage,
      billSearch: this.billToFilter.search,
    });
    this.loadBillToServer(customerId, 0, this.billToPageSize, this.billToFilter.search);
  }

  lastBillToPage(): void {
    const last = this.totalBillToPages();
    if (this.billToCurrentPage === last) return;
    this.billToCurrentPage = last;
    const customerId = this.customer?.id;
    if (!customerId) return;
    this.updateQueryParams({
      billPage: this.billToCurrentPage,
      billSearch: this.billToFilter.search,
    });
    this.loadBillToServer(
      customerId,
      this.billToCurrentPage - 1,
      this.billToPageSize,
      this.billToFilter.search,
    );
  }

  billToRangeStart(): number {
    if (!this.billToTotal) return 0;
    return (this.billToCurrentPage - 1) * this.billToPageSize + 1;
  }

  billToRangeEnd(): number {
    if (!this.billToTotal) return 0;
    return Math.min(this.billToCurrentPage * this.billToPageSize, this.billToTotal);
  }

  private updateQueryParams(params: { billPage?: number; billSearch?: string }): void {
    const qp: any = { group: 'bill-to-address' };
    if (params.billPage) qp.billPage = params.billPage;
    if (params.billSearch !== undefined && params.billSearch !== null)
      qp.billSearch = params.billSearch;
    this.router.navigate([], { queryParams: qp, queryParamsHandling: 'merge' });
  }

  downloadBillToExport(customerId: number): void {
    this.billToError = null;
    this.customerBillToService.exportCsv(customerId).subscribe({
      next: (blob) => {
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `bill-to-addresses-customer-${customerId}.csv`;
        document.body.appendChild(a);
        a.click();
        a.remove();
        window.URL.revokeObjectURL(url);
      },
      error: (err: any) => {
        console.error('Bill-to export failed:', err);
        this.billToError = 'Failed to export bill-to addresses.';
      },
    });
  }

  openBillToModal(address?: CustomerBillToAddress): void {
    this.billToDropdownOpen = null;
    if (address) {
      this.editingBillTo = { ...address };
    } else {
      this.editingBillTo = {
        customerId: this.customer.id!,
        name: '',
        address: '',
        city: '',
        state: '',
        zip: '',
        country: '',
        contactName: '',
        contactPhone: '',
        email: '',
        taxId: '',
        notes: '',
        isPrimary: true,
      };
    }
    this.isBillToModalOpen = true;
  }

  closeBillToModal(): void {
    this.isBillToModalOpen = false;
    this.editingBillTo = null;
  }

  toggleBillToDropdown(id: number): void {
    if (!id) {
      this.billToDropdownOpen = null;
      return;
    }
    this.billToDropdownOpen = this.billToDropdownOpen === id ? null : id;
  }

  saveBillTo(): void {
    if (!this.editingBillTo) return;
    const customerId = this.customer.id;
    if (!customerId) return;
    const payload: CustomerBillToAddress = {
      ...this.editingBillTo,
      customerId,
      name: String(this.editingBillTo.name ?? '').trim(),
      address: String(this.editingBillTo.address ?? '').trim(),
      city: String(this.editingBillTo.city ?? '').trim(),
      state: String(this.editingBillTo.state ?? '').trim(),
      zip: String(this.editingBillTo.zip ?? '').trim(),
      country: String(this.editingBillTo.country ?? '').trim(),
      contactName: String(this.editingBillTo.contactName ?? '').trim(),
      contactPhone: String(this.editingBillTo.contactPhone ?? '').trim(),
      email: String(this.editingBillTo.email ?? '').trim(),
      taxId: String(this.editingBillTo.taxId ?? '').trim(),
      notes: String(this.editingBillTo.notes ?? '').trim(),
      isPrimary: !!this.editingBillTo.isPrimary,
    };

    if (!payload.name && !payload.address) {
      this.notify.error('Name or Address is required.');
      return;
    }

    const id = this.editingBillTo.id;
    const req$ = id
      ? this.customerBillToService.update(customerId, id, payload)
      : this.customerBillToService.create(customerId, payload);

    req$.subscribe({
      next: () => {
        this.closeBillToModal();
        this.reloadBillToAddresses(customerId);
      },
      error: (err: any) => {
        console.error('Failed to save bill-to address:', err);
        this.notify.error('Failed to save bill-to address');
      },
    });
  }
  async deleteBillTo(id: number): Promise<void> {
    const confirmed = await this.confirm.confirm('Delete this bill-to address?');
    if (!confirmed) return;
    const customerId = this.customer.id;
    if (!customerId) return;
    this.billToDropdownOpen = null;
    this.customerBillToService.delete(customerId, id).subscribe({
      next: () => this.reloadBillToAddresses(customerId),
      error: (err: any) => {
        console.error('Failed to delete bill-to address:', err);
        this.notify.error('Failed to delete bill-to address');
      },
    });
  }

  async migrateLegacyBillToAddresses(): Promise<void> {
    const customerId = this.customer.id;
    if (!customerId) return;
    const legacyCount = this.legacyBillToAddresses.length;
    if (!legacyCount) return;
    const confirmed = await this.confirm.confirm(
      `Migrate ${legacyCount} legacy bill-to address(es) into Bill To Address?`,
    );
    if (!confirmed) return;

    this.billToLoading = true;
    this.billToError = null;
    this.customerBillToService.migrateLegacy(customerId).subscribe({
      next: (res: any) => {
        const migrated = Number(res?.data ?? 0);
        this.billToLoading = false;
        if (migrated > 0) {
          this.reloadBillToAddresses(customerId);
          this.reloadAddresses(customerId);
          this.legacyBillToLoaded = false;
          this.loadLegacyBillToAddresses(customerId);
        }
      },
      error: (err: any) => {
        console.error('Failed to migrate legacy bill-to addresses:', err);
        this.billToLoading = false;
        this.billToError = 'Failed to migrate legacy bill-to addresses.';
      },
    });
  }

  openAddressModal(typeHint?: string, address?: CustomerAddress): void {
    this.addressDropdownOpen = null;
    if (address) {
      this.editingAddress = { ...address };
      if (!this.editingAddress.type && typeHint) this.editingAddress.type = typeHint;
    } else {
      this.editingAddress = {
        customerId: this.customer.id,
        type: typeHint || 'SHIP_TO',
        name: '',
        address: '',
        city: '',
        country: '',
        postcode: '',
        contactName: '',
        contactPhone: '',
        latitude: 0,
        longitude: 0,
        scheduledTime: '',
      };
    }
    this.isAddressModalOpen = true;
  }

  closeAddressModal(): void {
    this.isAddressModalOpen = false;
    this.editingAddress = null;
  }

  toggleAddressDropdown(addressId: number): void {
    if (!addressId) {
      this.addressDropdownOpen = null;
      return;
    }
    this.addressDropdownOpen = this.addressDropdownOpen === addressId ? null : addressId;
  }

  saveAddress(): void {
    if (!this.editingAddress) return;
    const customerId = this.customer.id;
    if (!customerId) return;

    const payload: any = {
      ...this.editingAddress,
      customerId,
      name: String(this.editingAddress.name ?? '').trim(),
      address: String(this.editingAddress.address ?? '').trim(),
      city: String(this.editingAddress.city ?? '').trim(),
      country: String(this.editingAddress.country ?? '').trim(),
      type: String(this.editingAddress.type ?? '').trim(),
    };

    if (!payload.name || !payload.address) {
      this.notify.error('Name and Address are required.');
      return;
    }

    const id = this.editingAddress.id;
    const req$ = id
      ? this.addressService.updateAddress(id, payload)
      : this.addressService.createAddress(payload);

    req$.subscribe({
      next: () => {
        this.closeAddressModal();
        this.reloadAddresses(customerId);
      },
      error: (err: any) => {
        console.error('Failed to save address:', err);
        this.notify.error('Failed to save address');
      },
    });
  }
  async deleteAddress(id: number): Promise<void> {
    const confirmed = await this.confirm.confirm('Delete this address?');
    if (!confirmed) return;
    const customerId = this.customer.id;
    if (!customerId) return;
    this.addressDropdownOpen = null;
    this.addressService.deleteAddress(id).subscribe({
      next: () => this.reloadAddresses(customerId),
      error: (err: any) => {
        console.error('Failed to delete address:', err);
        this.notify.error('Failed to delete address');
      },
    });
  }

  importAddressesForCustomer(customerId: number, e: Event): void {
    const input = e.target as HTMLInputElement | null;
    const file = input?.files?.[0];
    if (!file) return;
    this.addressService.importAddresses(file, customerId).subscribe({
      next: () => {
        input.value = '';
        this.reloadAddresses(customerId);
      },
      error: (err: any) => {
        console.error('Import failed:', err);
        this.notify.error(err?.message || 'Import failed');
      },
    });
  }

  validateForm(): boolean {
    this.errorCompanyName = !this.customer.name?.trim();
    this.errorCustomerCode = !this.customer.customerCode?.trim();
    this.errorEmail = !!this.customer.email && !/^\S+@\S+\.\S+$/.test(this.customer.email);
    this.errorPhone = !!this.customer.phone && !/^\+?[0-9\- ]{7,}$/.test(this.customer.phone);
    return !(this.errorCompanyName || this.errorCustomerCode || this.errorEmail || this.errorPhone);
  }

  saveCustomer(): void {
    if (!this.validateForm()) return;
    this.isSaving = true;
    this.errorMessage = null;
    this.successMessage = null;
    const save$ =
      this.isEditMode && this.customer.id
        ? this.customerService.updateCustomer(this.customer.id, this.customer)
        : this.customerService.createCustomer(this.customer);
    save$.subscribe({
      next: () => {
        this.isSaving = false;
        this.successMessage = this.isEditMode
          ? 'Customer updated successfully.'
          : 'Customer created successfully.';
        setTimeout(() => {
          this.router.navigate(['/customers']);
        }, 1200);
      },
      error: (err: any) => {
        this.isSaving = false;
        this.errorMessage = err?.error?.message || 'Failed to save customer.';
      },
    });
  }

  getPickupName(order: TransportOrder): string {
    const pickupStop = (order as any).stops?.find((s: any) => s.type === 'PICKUP');
    return pickupStop?.address?.name || (order as any).pickupAddress?.name || 'N/A';
  }

  getDropoffName(order: TransportOrder): string {
    const dropStop = (order as any).stops?.find((s: any) => s.type === 'DROP');
    return dropStop?.address?.name || (order as any).dropAddress?.name || 'N/A';
  }

  // ==================== Contact Persons Methods ====================
  loadContacts(customerId: number): void {
    this.customerContactService
      .getContactsByCustomerId(customerId, this.contactFilter.activeOnly)
      .subscribe({
        next: (res: any) => {
          this.contacts = res.data ?? [];
          this.contactCurrentPage = 1;
          this.applyContactFilter();
        },
        error: (err: any) => {
          console.error('Failed to load contacts:', err);
          this.contacts = [];
          this.filteredContacts = [];
          this.paginatedContacts = [];
        },
      });
  }

  applyContactFilter(): void {
    let filtered = this.contacts;
    if (this.contactFilter.search) {
      const search = this.contactFilter.search.toLowerCase();
      filtered = filtered.filter(
        (c) =>
          c.fullName?.toLowerCase().includes(search) ||
          c.email?.toLowerCase().includes(search) ||
          c.phone?.toLowerCase().includes(search),
      );
    }
    if (this.contactFilter.activeOnly) {
      filtered = filtered.filter((c) => c.isActive);
    }
    this.filteredContacts = filtered;
    this.contactCurrentPage = 1;
    this.paginateContacts();
  }

  paginateContacts(): void {
    const total = this.totalContactPages();
    if (this.contactCurrentPage > total) this.contactCurrentPage = Math.max(1, total);
    const start = (this.contactCurrentPage - 1) * this.contactPageSize;
    const end = start + this.contactPageSize;
    this.paginatedContacts = this.filteredContacts.slice(start, end);
  }

  totalContactPages(): number {
    const total = Math.ceil(this.filteredContacts.length / this.contactPageSize);
    return Math.max(1, total);
  }

  contactRangeStart(): number {
    if (this.filteredContacts.length === 0) return 0;
    return (this.contactCurrentPage - 1) * this.contactPageSize + 1;
  }

  contactRangeEnd(): number {
    if (this.filteredContacts.length === 0) return 0;
    return Math.min(this.contactCurrentPage * this.contactPageSize, this.filteredContacts.length);
  }

  setContactPageSize(size: number): void {
    if (!size || size <= 0) return;
    this.contactPageSize = size;
    this.contactCurrentPage = 1;
    this.paginateContacts();
  }

  prevContactPage(): void {
    if (this.contactCurrentPage > 1) {
      this.contactCurrentPage--;
      this.paginateContacts();
    }
  }

  nextContactPage(): void {
    if (this.contactCurrentPage < this.totalContactPages()) {
      this.contactCurrentPage++;
      this.paginateContacts();
    }
  }

  firstContactPage(): void {
    if (this.contactCurrentPage === 1) return;
    this.contactCurrentPage = 1;
    this.paginateContacts();
  }

  lastContactPage(): void {
    const last = this.totalContactPages();
    if (this.contactCurrentPage === last) return;
    this.contactCurrentPage = last;
    this.paginateContacts();
  }

  isContactSelected(contact: CustomerContact): boolean {
    const id = contact.id ?? null;
    if (!id) return false;
    return this.selectedContactIds.has(id);
  }

  toggleContactSelection(contact: CustomerContact, checked: boolean): void {
    const id = contact.id ?? null;
    if (!id) return;
    if (checked) this.selectedContactIds.add(id);
    else this.selectedContactIds.delete(id);
  }

  isAllContactsOnPageSelected(): boolean {
    const ids = this.paginatedContacts.map((c) => c.id).filter((id): id is number => !!id);
    if (ids.length === 0) return false;
    return ids.every((id) => this.selectedContactIds.has(id));
  }

  toggleSelectAllContactsOnPage(checked: boolean): void {
    const ids = this.paginatedContacts.map((c) => c.id).filter((id): id is number => !!id);
    ids.forEach((id) => {
      if (checked) this.selectedContactIds.add(id);
      else this.selectedContactIds.delete(id);
    });
  }

  applyAddressFilter(): void {
    this.addressCurrentPage = 1;
    this.fetchAddressPage();
  }

  private fetchAddressPage(): void {
    const customerId = this.customer.id;
    if (!customerId) {
      this.paginatedAddresses = [];
      this.addressServerTotal = 0;
      return;
    }

    this.addressesLoading = true;
    this.addressesError = null;
    this.paginatedAddresses = [];
    this.addressServerTotal = 0;
    this.addressService
      .searchAddressesByCustomer(
        customerId,
        this.addressFilter.search,
        this.addressFilter.type,
        this.addressCurrentPage - 1,
        this.addressPageSize,
      )
      .subscribe({
        next: (result) => {
          this.paginatedAddresses = result.addresses ?? [];
          this.addressServerTotal = result.total ?? 0;
          this.addressesLoading = false;
        },
        error: () => {
          this.addressesLoading = false;
          this.addressServerTotal = 0;
          this.paginatedAddresses = [];
          this.addressesError = 'Failed to load addresses for this customer.';
        },
      });
  }

  totalAddressPages(): number {
    const total = Math.ceil(this.addressServerTotal / this.addressPageSize);
    return Math.max(1, total);
  }

  addressRangeStart(): number {
    if (!this.paginatedAddresses.length) return 0;
    return (this.addressCurrentPage - 1) * this.addressPageSize + 1;
  }

  addressRangeEnd(): number {
    if (!this.paginatedAddresses.length) return 0;
    return this.addressRangeStart() + this.paginatedAddresses.length - 1;
  }

  setAddressPageSize(size: number): void {
    if (!size || size <= 0) return;
    this.addressPageSize = size;
    this.addressCurrentPage = 1;
    this.fetchAddressPage();
  }

  prevAddressPage(): void {
    if (this.addressCurrentPage > 1) {
      this.addressCurrentPage--;
      this.fetchAddressPage();
    }
  }

  nextAddressPage(): void {
    if (this.addressCurrentPage < this.totalAddressPages()) {
      this.addressCurrentPage++;
      this.fetchAddressPage();
    }
  }

  firstAddressPage(): void {
    if (this.addressCurrentPage === 1) return;
    this.addressCurrentPage = 1;
    this.fetchAddressPage();
  }

  lastAddressPage(): void {
    const last = this.totalAddressPages();
    if (this.addressCurrentPage === last) return;
    this.addressCurrentPage = last;
    this.fetchAddressPage();
  }

  openContactModal(contact?: CustomerContact): void {
    this.dropdownOpen = null;
    if (contact) {
      this.editingContact = { ...contact };
    } else {
      this.editingContact = {
        id: undefined,
        customerId: this.customer.id!,
        fullName: '',
        email: '',
        phone: '',
        position: '',
        isPrimary: false,
        isActive: true,
        notes: '',
      };
    }
    this.isContactModalOpen = true;
  }

  closeContactModal(): void {
    this.isContactModalOpen = false;
    this.editingContact = null;
  }

  toggleDropdown(contactId: number): void {
    if (!contactId) {
      this.dropdownOpen = null;
      return;
    }
    this.dropdownOpen = this.dropdownOpen === contactId ? null : contactId;
  }

  saveContact(): void {
    if (!this.editingContact || !this.editingContact.fullName) {
      this.notify.error('Full name is required.');
      return;
    }
    const request = {
      customerId: this.editingContact.customerId,
      fullName: this.editingContact.fullName,
      email: this.editingContact.email,
      phone: this.editingContact.phone,
      position: this.editingContact.position,
      isPrimary: this.editingContact.isPrimary,
      isActive: this.editingContact.isActive,
      notes: this.editingContact.notes,
    };
    if (this.editingContact.id) {
      this.customerContactService.updateContact(this.editingContact.id, request).subscribe({
        next: () => {
          this.loadContacts(this.customer.id!);
          this.closeContactModal();
        },
        error: (err: any) => {
          console.error('Failed to update contact:', err);
          this.notify.error('Failed to update contact');
        },
      });
    } else {
      this.customerContactService.createContact(request).subscribe({
        next: () => {
          this.loadContacts(this.customer.id!);
          this.closeContactModal();
        },
        error: (err: any) => {
          console.error('Failed to create contact:', err);
          this.notify.error('Failed to create contact');
        },
      });
    }
  }
  async deleteContact(id: number): Promise<void> {
    const confirmed = await this.confirm.confirm('Are you sure you want to delete this contact?');
    if (!confirmed) return;
    this.dropdownOpen = null;
    this.customerContactService.deleteContact(id).subscribe({
      next: () => {
        this.loadContacts(this.customer.id!);
      },
      error: (err: any) => {
        console.error('Failed to delete contact:', err);
        this.notify.error('Failed to delete contact');
      },
    });
  }

  // Helper methods for displaying new production-ready features
  getLifecycleLabel(stage?: string): string {
    const labels: Record<string, string> = {
      LEAD: 'Lead',
      PROSPECT: 'Prospect',
      QUALIFIED: 'Qualified Lead',
      CUSTOMER: 'Active Customer',
      AT_RISK: 'At Risk',
      DORMANT: 'Dormant',
      CHURNED: 'Churned',
    };
    return labels[stage || ''] || 'Not Set';
  }

  getPaymentTermsLabel(terms?: string): string {
    const labels: Record<string, string> = {
      NET_30: 'Net 30 Days',
      NET_60: 'Net 60 Days',
      NET_90: 'Net 90 Days',
      COD: 'Cash on Delivery',
      PREPAID: 'Prepaid',
      DUE_ON_RECEIPT: 'Due on Receipt',
    };
    return labels[terms || ''] || 'Not Set';
  }

  formatCurrency(amount?: number | null, currency?: string): string {
    const safeAmount = Number(amount ?? 0);
    const resolvedCurrency = currency || this.customer.currency || 'USD';
    try {
      return new Intl.NumberFormat('en-US', {
        style: 'currency',
        currency: resolvedCurrency,
        minimumFractionDigits: 2,
        maximumFractionDigits: 2,
      }).format(Number.isFinite(safeAmount) ? safeAmount : 0);
    } catch {
      const currencySymbol =
        resolvedCurrency === 'KHR' ? '៛' : resolvedCurrency === 'THB' ? '฿' : '$';
      return `${currencySymbol}${(Number.isFinite(safeAmount) ? safeAmount : 0).toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
    }
  }

  formatDateDisplay(date?: string | number | Date): string {
    if (!date) return 'N/A';
    const d = date instanceof Date ? date : new Date(date);
    if (Number.isNaN(d.getTime())) return 'N/A';
    return d.toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
    });
  }
}
