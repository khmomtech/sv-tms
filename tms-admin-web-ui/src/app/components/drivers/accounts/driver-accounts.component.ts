import { CommonModule } from '@angular/common';
import type { OnInit } from '@angular/core';
import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms';

import type { Driver } from '../../../models/driver.model';
import { firstValueFrom } from 'rxjs';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { DriverService } from '../../../services/driver.service';
import { ConfirmService } from '../../../services/confirm.service';
import { InputPromptService } from '../../../core/input-prompt.service';

interface DriverAccount {
  driver: Driver;
  account: {
    id: number;
    username: string;
    email: string;
    enabled: boolean;
    roles: string[];
  } | null;
  lastLogin?: string;
  appVersion?: string;
}

@Component({
  selector: 'app-driver-accounts',
  standalone: true,
  imports: [CommonModule, FormsModule],
  template: `
    <div class="p-6">
      <div class="flex items-center gap-3 mb-6">
        <div class="flex items-center justify-center w-12 h-12 bg-blue-100 rounded-lg">
          <i class="text-2xl text-blue-600 fas fa-user-circle"></i>
        </div>
        <div>
          <h1 class="text-2xl font-bold text-gray-900">Driver App Accounts</h1>
          <p class="text-gray-600">Manage driver mobile app accounts and access permissions</p>
        </div>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-4 gap-6 mb-6">
        <!-- Account Statistics -->
        <div class="bg-white rounded-lg shadow-sm border p-6">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-2xl font-bold text-gray-900">{{ totalDrivers }}</p>
              <p class="text-sm text-gray-600">Total Drivers</p>
            </div>
            <div class="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center">
              <i class="text-blue-600 fas fa-users"></i>
            </div>
          </div>
        </div>

        <div class="bg-white rounded-lg shadow-sm border p-6">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-2xl font-bold text-green-600">{{ activeAccounts }}</p>
              <p class="text-sm text-gray-600">Active Accounts</p>
            </div>
            <div class="w-12 h-12 bg-green-100 rounded-lg flex items-center justify-center">
              <i class="text-green-600 fas fa-check-circle"></i>
            </div>
          </div>
        </div>

        <div class="bg-white rounded-lg shadow-sm border p-6">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-2xl font-bold text-yellow-600">{{ noAccounts }}</p>
              <p class="text-sm text-gray-600">No Account</p>
            </div>
            <div class="w-12 h-12 bg-yellow-100 rounded-lg flex items-center justify-center">
              <i class="text-yellow-600 fas fa-user-slash"></i>
            </div>
          </div>
        </div>

        <div class="bg-white rounded-lg shadow-sm border p-6">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-2xl font-bold text-red-600">{{ disabledAccounts }}</p>
              <p class="text-sm text-gray-600">Disabled</p>
            </div>
            <div class="w-12 h-12 bg-red-100 rounded-lg flex items-center justify-center">
              <i class="text-red-600 fas fa-ban"></i>
            </div>
          </div>
        </div>
      </div>

      <!-- Filter and Search -->
      <div class="bg-white rounded-lg shadow-sm border mb-6 p-4">
        <div class="flex items-center gap-4">
          <div class="flex-1">
            <input
              type="text"
              [(ngModel)]="searchTerm"
              (input)="onSearch()"
              placeholder="Search by driver name, username, or email..."
              class="w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
          <select
            [(ngModel)]="filterStatus"
            (change)="onFilterChange()"
            class="px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            <option value="all">All Status</option>
            <option value="active">Active Accounts</option>
            <option value="no-account">No Account</option>
            <option value="disabled">Disabled</option>
          </select>
          <button
            (click)="loadData()"
            class="px-4 py-2 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200"
          >
            <i class="fas fa-sync-alt mr-2"></i>Refresh
          </button>
        </div>
      </div>

      <!-- Driver Accounts Table -->
      <div class="bg-white rounded-lg shadow-sm border">
        <div class="px-6 py-4 border-b flex items-center justify-between">
          <h3 class="font-semibold text-gray-900">
            Driver Accounts <span class="text-gray-500 text-sm">({{ totalRecords }} total)</span>
          </h3>
        </div>

        <div *ngIf="loading" class="p-8 text-center">
          <div
            class="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"
          ></div>
          <p class="mt-2 text-gray-600">Loading driver accounts...</p>
        </div>

        <div *ngIf="!loading && paginatedAccounts.length === 0" class="p-8 text-center">
          <i class="fas fa-user-slash text-4xl text-gray-400 mb-4"></i>
          <p class="text-gray-600">No driver accounts found</p>
        </div>

        <div *ngIf="!loading && paginatedAccounts.length > 0" class="overflow-x-auto">
          <table class="w-full">
            <thead class="bg-gradient-to-r from-blue-50 to-indigo-50 border-b-2 border-blue-200">
              <tr>
                <th
                  class="px-6 py-4 text-left text-xs font-bold text-gray-700 uppercase tracking-wider"
                >
                  <i class="fas fa-user mr-2 text-blue-600"></i>Driver
                </th>
                <th
                  class="px-6 py-4 text-left text-xs font-bold text-gray-700 uppercase tracking-wider"
                >
                  <i class="fas fa-id-badge mr-2 text-blue-600"></i>Username
                </th>
                <th
                  class="px-6 py-4 text-left text-xs font-bold text-gray-700 uppercase tracking-wider"
                >
                  <i class="fas fa-envelope mr-2 text-blue-600"></i>Email
                </th>
                <th
                  class="px-6 py-4 text-left text-xs font-bold text-gray-700 uppercase tracking-wider"
                >
                  <i class="fas fa-shield-alt mr-2 text-blue-600"></i>Roles
                </th>
                <th
                  class="px-6 py-4 text-left text-xs font-bold text-gray-700 uppercase tracking-wider"
                >
                  <i class="fas fa-info-circle mr-2 text-blue-600"></i>Status
                </th>
                <th
                  class="px-6 py-4 text-left text-xs font-bold text-gray-700 uppercase tracking-wider"
                >
                  <i class="fas fa-cog mr-2 text-blue-600"></i>Actions
                </th>
              </tr>
            </thead>
            <tbody class="bg-white divide-y divide-gray-200">
              <tr *ngFor="let item of paginatedAccounts" class="hover:bg-gray-50 transition-colors">
                <td class="px-6 py-4 whitespace-nowrap">
                  <div class="flex items-center">
                    <div class="flex-shrink-0 h-10 w-10">
                      <div
                        class="h-10 w-10 rounded-full flex items-center justify-center text-white font-medium"
                        [ngClass]="getDriverAvatarColor(item.driver.id)"
                      >
                        {{ getInitials(item.driver.firstName, item.driver.lastName) }}
                      </div>
                    </div>
                    <div class="ml-4">
                      <div class="text-sm font-medium text-gray-900">
                        {{ item.driver.firstName }} {{ item.driver.lastName }}
                      </div>
                      <div class="text-sm text-gray-500">ID: {{ item.driver.id }}</div>
                    </div>
                  </div>
                </td>
                <td class="px-6 py-4 whitespace-nowrap">
                  <div *ngIf="item.account" class="text-sm text-gray-900">
                    {{ item.account.username }}
                  </div>
                  <div *ngIf="!item.account" class="text-sm text-gray-400 italic">No account</div>
                </td>
                <td class="px-6 py-4 whitespace-nowrap">
                  <div *ngIf="item.account" class="text-sm text-gray-900">
                    {{ item.account.email }}
                  </div>
                  <div *ngIf="!item.account" class="text-sm text-gray-400 italic">-</div>
                </td>
                <td class="px-6 py-4 whitespace-nowrap">
                  <div *ngIf="item.account" class="flex gap-1">
                    <span
                      *ngFor="let role of item.account.roles"
                      class="px-2 py-1 text-xs font-medium bg-purple-100 text-purple-800 rounded-full"
                    >
                      {{ role }}
                    </span>
                  </div>
                  <div *ngIf="!item.account" class="text-sm text-gray-400 italic">-</div>
                </td>
                <td class="px-6 py-4 whitespace-nowrap">
                  <span
                    *ngIf="item.account && item.account.enabled"
                    class="px-3 py-1 text-xs font-medium bg-green-100 text-green-800 rounded-full inline-flex items-center animate-pulse"
                  >
                    <span class="w-2 h-2 bg-green-600 rounded-full mr-2"></span>
                    Active
                  </span>
                  <span
                    *ngIf="item.account && !item.account.enabled"
                    class="px-3 py-1 text-xs font-medium bg-red-100 text-red-800 rounded-full inline-flex items-center"
                  >
                    <span class="w-2 h-2 bg-red-600 rounded-full mr-2"></span>
                    Disabled
                  </span>
                  <span
                    *ngIf="!item.account"
                    class="px-3 py-1 text-xs font-medium bg-yellow-100 text-yellow-800 rounded-full inline-flex items-center"
                  >
                    <i class="fas fa-exclamation-triangle mr-2"></i>
                    No Account
                  </span>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm">
                  <div class="flex items-center gap-2">
                    <button
                      *ngIf="item.account"
                      (click)="onViewAccount(item)"
                      class="p-2 text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
                      title="View Account"
                    >
                      <i class="fas fa-eye"></i>
                    </button>
                    <button
                      *ngIf="item.account"
                      (click)="onEditAccount(item)"
                      class="p-2 text-green-600 hover:bg-green-50 rounded-lg transition-colors"
                      title="Edit Account"
                    >
                      <i class="fas fa-edit"></i>
                    </button>
                    <button
                      *ngIf="!item.account"
                      (click)="onCreateAccount(item)"
                      class="px-3 py-1 bg-blue-600 text-white rounded-lg hover:bg-blue-700 text-xs"
                      title="Create Account"
                    >
                      <i class="fas fa-plus mr-1"></i>Create
                    </button>
                    <button
                      *ngIf="item.account"
                      (click)="onToggleEnabled(item)"
                      [class]="
                        item.account.enabled
                          ? 'p-2 text-yellow-600 hover:bg-yellow-50 rounded-lg transition-colors'
                          : 'p-2 text-green-600 hover:bg-green-50 rounded-lg transition-colors'
                      "
                      [title]="item.account.enabled ? 'Disable Account' : 'Enable Account'"
                    >
                      <i [class]="item.account.enabled ? 'fas fa-ban' : 'fas fa-check-circle'"></i>
                    </button>
                    <button
                      *ngIf="item.account"
                      (click)="onResetPassword(item)"
                      class="p-2 text-orange-600 hover:bg-orange-50 rounded-lg transition-colors"
                      title="Reset Password"
                    >
                      <i class="fas fa-key"></i>
                    </button>
                    <button
                      *ngIf="item.account"
                      (click)="onDeleteAccount(item)"
                      class="p-2 text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                      title="Delete Account"
                    >
                      <i class="fas fa-trash"></i>
                    </button>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <!-- Pagination Controls -->
        <div *ngIf="!loading && totalRecords > 0" class="px-6 py-4 border-t bg-gray-50">
          <div class="flex items-center justify-between">
            <!-- Records per page -->
            <div class="flex items-center gap-2">
              <label class="text-sm text-gray-700">Show:</label>
              <select
                [value]="showAllRecords ? 'all' : recordsPerPage"
                (change)="onRecordsPerPageChange($any($event.target).value)"
                class="px-3 py-1.5 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 text-sm"
              >
                <option *ngFor="let option of recordsPerPageOptions" [value]="option">
                  {{ option }}
                </option>
                <option value="all">All</option>
              </select>
              <span class="text-sm text-gray-700">records per page</span>
            </div>

            <!-- Page info and navigation -->
            <div class="flex items-center gap-4">
              <div class="text-sm text-gray-700">
                Showing {{ getStartRecord() }} - {{ getEndRecord() }} of {{ totalRecords }}
              </div>

              <div class="flex items-center gap-2">
                <!-- Previous button -->
                <button
                  (click)="previousPage()"
                  [disabled]="currentPage === 0"
                  class="px-3 py-1.5 border border-gray-300 rounded-lg hover:bg-gray-100 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                  title="Previous page"
                >
                  <i class="fas fa-chevron-left"></i>
                </button>

                <!-- Page numbers -->
                <div class="flex items-center gap-1">
                  <span class="text-sm text-gray-700 mr-2"
                    >Page {{ currentPage + 1 }} of {{ totalPages }}</span
                  >
                  <label class="text-sm text-gray-700">Go to page:</label>
                  <input
                    #gotoPageInput
                    type="number"
                    [value]="currentPage + 1"
                    (keyup.enter)="goToPage(gotoPageInput.valueAsNumber)"
                    min="1"
                    [max]="totalPages"
                    class="w-16 px-2 py-1.5 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 text-sm text-center"
                  />
                  <button
                    (click)="goToPage(gotoPageInput.valueAsNumber)"
                    class="px-3 py-1.5 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors text-sm"
                  >
                    Go
                  </button>
                </div>

                <!-- Next button -->
                <button
                  (click)="nextPage()"
                  [disabled]="currentPage >= totalPages - 1"
                  class="px-3 py-1.5 border border-gray-300 rounded-lg hover:bg-gray-100 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                  title="Next page"
                >
                  <i class="fas fa-chevron-right"></i>
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Create/Edit Modal -->
      <div
        *ngIf="showModal"
        class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50"
        (click)="onModalBackdropClick($event)"
      >
        <div
          class="bg-white rounded-lg shadow-xl max-w-md w-full mx-4"
          (click)="$event.stopPropagation()"
        >
          <div class="px-6 py-4 border-b flex items-center justify-between">
            <h3 class="text-lg font-semibold text-gray-900">
              {{ modalMode === 'create' ? 'Create' : 'Edit' }} Driver Account
            </h3>
            <button (click)="closeModal()" class="text-gray-400 hover:text-gray-600">
              <i class="fas fa-times"></i>
            </button>
          </div>

          <div class="px-6 py-4">
            <div class="mb-4">
              <p class="text-sm text-gray-600 mb-2">
                <i class="fas fa-user mr-2"></i>Driver:
                <strong>{{ selectedDriver?.firstName }} {{ selectedDriver?.lastName }}</strong>
                (ID: {{ selectedDriver?.id }})
              </p>
            </div>

            <div *ngIf="serverErrorMessage" class="mb-4">
              <p class="text-sm text-red-600 font-medium">{{ serverErrorMessage }}</p>
            </div>

            <div class="space-y-4">
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-2">
                  <i class="fas fa-user-circle mr-2"></i>Username *
                </label>
                <input
                  type="text"
                  [(ngModel)]="accountForm.username"
                  class="w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  placeholder="Enter username"
                  [disabled]="modalMode === 'edit'"
                />
                <p *ngIf="validationErrors.username" class="text-xs text-red-600 mt-1">
                  {{ validationErrors.username }}
                </p>
              </div>

              <div>
                <label class="block text-sm font-medium text-gray-700 mb-2">
                  <i class="fas fa-envelope mr-2"></i>Email *
                </label>
                <input
                  type="email"
                  [(ngModel)]="accountForm.email"
                  class="w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  placeholder="Enter email"
                />
                <p *ngIf="validationErrors.email" class="text-xs text-red-600 mt-1">
                  {{ validationErrors.email }}
                </p>
              </div>

              <div>
                <label class="block text-sm font-medium text-gray-700 mb-2">
                  <i class="fas fa-lock mr-2"></i>Password
                  {{ modalMode === 'edit' ? '(leave blank to keep)' : '*' }}
                </label>
                <input
                  type="password"
                  [(ngModel)]="accountForm.password"
                  class="w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  [placeholder]="
                    modalMode === 'edit' ? 'Leave blank to keep current password' : 'Enter password'
                  "
                />
              </div>
            </div>
          </div>

          <div class="px-6 py-4 border-t flex items-center justify-end gap-3">
            <button
              (click)="closeModal()"
              class="px-4 py-2 text-gray-700 hover:bg-gray-100 rounded-lg"
            >
              Cancel
            </button>
            <button
              (click)="onSaveAccount()"
              [disabled]="saving"
              class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50"
            >
              <i *ngIf="saving" class="fas fa-spinner fa-spin mr-2"></i>
              <i *ngIf="!saving" class="fas fa-save mr-2"></i>
              {{ saving ? 'Saving...' : 'Save Account' }}
            </button>
          </div>
        </div>
      </div>
    </div>
  `,
  styleUrls: [],
})
export class DriverAccountsComponent implements OnInit {
  drivers: Driver[] = [];
  driverAccounts: DriverAccount[] = [];
  paginatedAccounts: DriverAccount[] = [];

  loading = false;
  searchTerm = '';
  filterStatus = 'all';

  // Pagination
  currentPage = 0; // 0-based for backend API
  recordsPerPage = 10;
  totalPages = 1;
  totalRecords = 0;
  recordsPerPageOptions = [10, 20, 30, 50, 100, 500];
  showAllRecords = false;

  // Statistics
  totalDrivers = 0;
  activeAccounts = 0;
  noAccounts = 0;
  disabledAccounts = 0;

  // Modal
  showModal = false;
  modalMode: 'create' | 'edit' = 'create';
  selectedDriver: Driver | null = null;
  accountForm = {
    username: '',
    email: '',
    password: '',
  };
  validationErrors: Record<string, string> = {};
  serverErrorMessage = '';
  saving = false;

  constructor(
    private readonly driverService: DriverService,
    private readonly confirm: ConfirmService,
    private readonly inputPrompt: InputPromptService,
  ) {}

  ngOnInit(): void {
    this.loadData();
  }

  loadData(): void {
    this.loading = true;
    const page = this.showAllRecords ? 0 : this.currentPage;
    const size = this.showAllRecords ? 10000 : this.recordsPerPage; // Large number for "all"

    this.driverService.getDrivers(page, size).subscribe({
      next: (res) => {
        if (res.data?.content) {
          this.drivers = res.data.content;
          this.totalRecords = res.data.totalElements || 0;
          this.totalPages = res.data.totalPages || 1;
          this.loadDriverAccounts();
        }
      },
      error: (err) => {
        console.error('Error loading drivers:', err);
        this.driverService.showToast('Error loading drivers');
        this.loading = false;
      },
    });
  }

  loadDriverAccounts(): void {
    const accountPromises = this.drivers.map(async (driver) => {
      try {
        const account = await firstValueFrom(this.driverService.getDriverAccountById(driver.id));
        return { driver, account: account || null } as DriverAccount;
      } catch {
        return { driver, account: null } as DriverAccount;
      }
    });

    Promise.all(accountPromises).then((results: DriverAccount[]) => {
      this.driverAccounts = results;
      this.applyFilters();
      this.loadStatistics();
      this.loading = false;
    });
  }

  loadStatistics(): void {
    // Load statistics from all drivers (not just current page)
    this.driverService.getAllDriversModal().subscribe({
      next: (res) => {
        if (res.data) {
          const allDriversPromises = res.data.map(async (driver) => {
            try {
              const account = await firstValueFrom(
                this.driverService.getDriverAccountById(driver.id),
              );
              return { driver, account: account || null } as DriverAccount;
            } catch {
              return { driver, account: null } as DriverAccount;
            }
          });

          Promise.all(allDriversPromises).then((allAccounts: DriverAccount[]) => {
            this.totalDrivers = allAccounts.length;
            this.activeAccounts = allAccounts.filter(
              (item) => item.account && item.account.enabled,
            ).length;
            this.noAccounts = allAccounts.filter((item) => !item.account).length;
            this.disabledAccounts = allAccounts.filter(
              (item) => item.account && !item.account.enabled,
            ).length;
          });
        }
      },
      error: (err) => {
        console.error('Error loading statistics:', err);
      },
    });
  }

  onSearch(): void {
    // Note: Search is applied client-side on current page
    // For true server-side search, modify backend to accept search param
    this.applyFilters();
  }

  onFilterChange(): void {
    // Note: Filter is applied client-side on current page
    // For true server-side filter, modify backend to accept status param
    this.applyFilters();
  }

  applyFilters(): void {
    let filtered = [...this.driverAccounts];

    // Apply client-side search on current page data
    if (this.searchTerm.trim()) {
      const term = this.searchTerm.toLowerCase();
      filtered = filtered.filter((item) => {
        const driverName = `${item.driver.firstName} ${item.driver.lastName}`.toLowerCase();
        const username = item.account?.username?.toLowerCase() || '';
        const email = item.account?.email?.toLowerCase() || '';
        return driverName.includes(term) || username.includes(term) || email.includes(term);
      });
    }

    // Apply client-side status filter on current page data
    if (this.filterStatus !== 'all') {
      if (this.filterStatus === 'active') {
        filtered = filtered.filter((item) => item.account && item.account.enabled);
      } else if (this.filterStatus === 'no-account') {
        filtered = filtered.filter((item) => !item.account);
      } else if (this.filterStatus === 'disabled') {
        filtered = filtered.filter((item) => item.account && !item.account.enabled);
      }
    }

    // For server-side pagination, display filtered results from current page
    this.paginatedAccounts = filtered;
  }

  onRecordsPerPageChange(value: string): void {
    if (value === 'all') {
      this.showAllRecords = true;
      this.recordsPerPage = 10000; // Large number for backend
    } else {
      this.showAllRecords = false;
      this.recordsPerPage = parseInt(value, 10);
    }
    this.currentPage = 0; // Reset to first page (0-based)
    this.loadData(); // Reload from server
  }

  goToPage(page: number): void {
    if (!Number.isFinite(page)) return;
    // Convert to 0-based index for backend
    const pageIndex = Math.trunc(page) - 1;
    if (pageIndex >= 0 && pageIndex < this.totalPages) {
      this.currentPage = pageIndex;
      this.loadData();
    }
  }

  previousPage(): void {
    if (this.currentPage > 0) {
      this.currentPage--;
      this.loadData();
    }
  }

  nextPage(): void {
    if (this.currentPage < this.totalPages - 1) {
      this.currentPage++;
      this.loadData();
    }
  }

  getPageNumbers(): number[] {
    const pages: number[] = [];
    for (let i = 1; i <= this.totalPages; i++) {
      pages.push(i);
    }
    return pages;
  }

  getStartRecord(): number {
    if (this.totalRecords === 0) return 0;
    return this.currentPage * this.recordsPerPage + 1;
  }

  getEndRecord(): number {
    if (this.showAllRecords) return this.totalRecords;
    const end = (this.currentPage + 1) * this.recordsPerPage;
    return end > this.totalRecords ? this.totalRecords : end;
  }

  getInitials(firstName?: string, lastName?: string): string {
    return `${firstName?.charAt(0) || ''}${lastName?.charAt(0) || ''}`.toUpperCase();
  }

  getDriverAvatarColor(id: number): string {
    const colors = [
      'bg-blue-500',
      'bg-green-500',
      'bg-purple-500',
      'bg-pink-500',
      'bg-indigo-500',
      'bg-yellow-500',
      'bg-red-500',
      'bg-teal-500',
    ];
    return colors[id % colors.length];
  }

  onCreateAccount(item: DriverAccount): void {
    this.modalMode = 'create';
    this.selectedDriver = item.driver;
    this.accountForm = {
      username: '',
      email: '',
      password: '',
    };
    this.validationErrors = {};
    this.serverErrorMessage = '';
    this.showModal = true;
  }

  onEditAccount(item: DriverAccount): void {
    if (!item.account) return;
    this.modalMode = 'edit';
    this.selectedDriver = item.driver;
    this.accountForm = {
      username: item.account.username,
      email: item.account.email,
      password: '',
    };
    this.validationErrors = {};
    this.serverErrorMessage = '';
    this.showModal = true;
  }

  onViewAccount(item: DriverAccount): void {
    if (!item.account) return;
    this.driverService.showToast(
      `Account: ${item.account.username} (${item.account.email}) — ${item.account.enabled ? 'Active' : 'Disabled'}`,
    );
  }

  onSaveAccount(): void {
    if (!this.selectedDriver) return;

    if (!this.accountForm.username || !this.accountForm.email) {
      this.driverService.showToast('Username and email are required');
      return;
    }

    if (this.modalMode === 'create' && !this.accountForm.password) {
      this.driverService.showToast('Password is required for new account');
      return;
    }

    this.saving = true;
    const accountData: any = {
      username: this.accountForm.username,
      email: this.accountForm.email,
    };

    if (this.accountForm.password) {
      accountData.password = this.accountForm.password;
    }

    this.driverService.saveDriverAccount(this.selectedDriver.id, accountData).subscribe({
      next: () => {
        this.driverService.showToast(
          `Account ${this.modalMode === 'create' ? 'created' : 'updated'} successfully`,
        );
        this.closeModal();
        this.loadData();
      },
      error: (err) => {
        console.error('Error saving account:', err);
        const validationErrors = err?.error?.validationErrors || {};
        if (Object.keys(validationErrors).length > 0) {
          this.validationErrors = validationErrors;
          this.serverErrorMessage = err?.error?.message || 'Please review the highlighted fields.';
        } else {
          this.driverService.showToast('Error saving account');
        }
        this.saving = false;
      },
    });
  }

  async onResetPassword(item: DriverAccount): Promise<void> {
    const account = item.account;
    if (!account) return;
    const newPassword = await this.inputPrompt.prompt(
      'Enter new password for ' + account.username + ':',
      {
        placeholder: 'New password',
      },
    );
    if (!newPassword) return;

    this.driverService
      .saveDriverAccount(item.driver.id, {
        username: account.username,
        email: account.email,
        password: newPassword,
      })
      .subscribe({
        next: () => {
          this.driverService.showToast('Password reset successfully');
        },
        error: (err) => {
          console.error('Error resetting password:', err);
          this.driverService.showToast('Error resetting password');
        },
      });
  }

  onToggleEnabled(item: DriverAccount): void {
    const account = item.account;
    if (!account) return;

    const action = account.enabled ? 'disable' : 'enable';
    (async () => {
      const confirmed = await this.confirm.confirm(
        `Are you sure you want to ${action} the account for ${item.driver.firstName} ${item.driver.lastName}?\n\nUsername: ${account.username}`,
      );
      if (!confirmed) return;

      // Update account with toggled enabled status
      this.driverService
        .saveDriverAccount(item.driver.id, {
          username: account.username,
          email: account.email,
          enabled: !account.enabled,
        })
        .subscribe({
          next: () => {
            this.driverService.showToast(`Account ${action}d successfully`);
            this.loadData();
          },
          error: (err) => {
            console.error(`Error ${action}ing account:`, err);
            this.driverService.showToast(`Error ${action}ing account`);
          },
        });
    })();
  }

  onDeleteAccount(item: DriverAccount): void {
    const account = item.account;
    if (!account) return;
    (async () => {
      const confirmed = await this.confirm.confirm(
        `Are you sure you want to delete the account for ${item.driver.firstName} ${item.driver.lastName}?\n\nUsername: ${account.username}\n\nThis action cannot be undone.`,
      );
      if (!confirmed) return;

      this.driverService.deleteDriverAccount(item.driver.id).subscribe({
        next: () => {
          this.driverService.showToast('Account deleted successfully');
          this.loadData();
        },
        error: (err) => {
          console.error('Error deleting account:', err);
          this.driverService.showToast('Error deleting account');
        },
      });
    })();
  }

  closeModal(): void {
    this.showModal = false;
    this.selectedDriver = null;
    this.accountForm = {
      username: '',
      email: '',
      password: '',
    };
    this.validationErrors = {};
    this.serverErrorMessage = '';
    this.saving = false;
  }

  onModalBackdropClick(event: MouseEvent): void {
    if (event.target === event.currentTarget) {
      this.closeModal();
    }
  }
}
