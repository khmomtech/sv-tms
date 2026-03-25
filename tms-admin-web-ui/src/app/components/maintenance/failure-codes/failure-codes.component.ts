import { CommonModule } from '@angular/common';
import { Component, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';

import { FailureCodeService, type FailureCodeDto } from '../../../services/failure-code.service';
import { AuthService } from '../../../services/auth.service';
import { PERMISSIONS } from '../../../shared/permissions';

@Component({
  selector: 'app-failure-codes',
  standalone: true,
  imports: [CommonModule, FormsModule],
  template: `
    <div class="p-6">
      <div class="flex items-center justify-between mb-6">
        <div class="flex items-center gap-3">
          <div class="flex items-center justify-center w-12 h-12 bg-blue-100 rounded-lg">
            <i class="text-2xl text-blue-600 fas fa-exclamation-triangle"></i>
          </div>
          <div>
            <h1 class="text-2xl font-bold text-gray-900">Failure Codes</h1>
            <p class="text-gray-600">
              Master list for maintenance reporting and root-cause analysis
            </p>
          </div>
        </div>
        <button
          class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
          type="button"
          (click)="openCreate()"
          [disabled]="!canWrite"
        >
          Add Failure Code
        </button>
      </div>

      <div *ngIf="error" class="mb-4 p-3 rounded border border-red-200 bg-red-50 text-red-700">
        {{ error }}
      </div>

      <div class="bg-white border rounded-lg shadow-sm p-4 mb-4 flex flex-wrap items-center gap-3">
        <div class="flex items-center gap-2">
          <label class="text-sm text-gray-700">Status:</label>
          <select
            class="px-3 py-2 border rounded-lg text-sm"
            [(ngModel)]="filters.active"
            (change)="load()"
          >
            <option [ngValue]="''">All</option>
            <option [ngValue]="'true'">Active</option>
            <option [ngValue]="'false'">Inactive</option>
          </select>
        </div>
        <div class="flex items-center gap-2">
          <label class="text-sm text-gray-700">Page size:</label>
          <select class="px-3 py-2 border rounded-lg text-sm" [(ngModel)]="size" (change)="load()">
            <option [ngValue]="10">10</option>
            <option [ngValue]="20">20</option>
            <option [ngValue]="50">50</option>
          </select>
        </div>
        <button
          class="ml-auto px-4 py-2 border rounded-lg text-sm hover:bg-gray-50"
          type="button"
          (click)="load()"
        >
          Refresh
        </button>
      </div>

      <div class="bg-white border rounded-lg shadow-sm overflow-hidden">
        <div class="overflow-x-auto">
          <table class="w-full">
            <thead class="bg-gray-50">
              <tr>
                <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">Code</th>
                <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">Description</th>
                <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">Category</th>
                <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">Status</th>
                <th class="px-4 py-3 text-right text-xs font-semibold text-gray-600">Actions</th>
              </tr>
            </thead>
            <tbody>
              <tr *ngFor="let code of rows" class="border-t">
                <td class="px-4 py-3 text-sm text-gray-900 font-semibold">{{ code.code }}</td>
                <td class="px-4 py-3 text-sm text-gray-700">{{ code.description || '-' }}</td>
                <td class="px-4 py-3 text-sm text-gray-700">{{ code.category || '-' }}</td>
                <td class="px-4 py-3 text-sm">
                  <span
                    class="inline-flex items-center rounded border px-2 py-0.5 text-xs font-semibold"
                    [ngClass]="
                      code.active
                        ? 'border-green-200 bg-green-50 text-green-700'
                        : 'border-gray-200 bg-gray-50 text-gray-700'
                    "
                  >
                    {{ code.active ? 'ACTIVE' : 'INACTIVE' }}
                  </span>
                </td>
                <td class="px-4 py-3 text-sm text-right">
                  <button
                    class="px-3 py-1.5 border rounded-lg mr-2"
                    type="button"
                    (click)="openEdit(code)"
                    [disabled]="!canWrite"
                  >
                    Edit
                  </button>
                  <button
                    class="px-3 py-1.5 border rounded-lg"
                    type="button"
                    (click)="toggleActive(code)"
                    [disabled]="!canWrite"
                  >
                    {{ code.active ? 'Deactivate' : 'Activate' }}
                  </button>
                </td>
              </tr>
              <tr *ngIf="rows.length === 0">
                <td class="px-4 py-6 text-center text-sm text-gray-500" colspan="5">
                  No failure codes found.
                </td>
              </tr>
            </tbody>
          </table>
        </div>
        <div class="px-4 py-3 border-t flex items-center justify-between text-sm text-gray-600">
          <div>Page {{ page + 1 }} of {{ totalPages }}</div>
          <div class="flex items-center gap-2">
            <button
              class="px-3 py-1.5 border rounded-lg"
              [disabled]="page === 0"
              (click)="prevPage()"
            >
              Prev
            </button>
            <button
              class="px-3 py-1.5 border rounded-lg"
              [disabled]="page + 1 >= totalPages"
              (click)="nextPage()"
            >
              Next
            </button>
          </div>
        </div>
      </div>

      <div
        *ngIf="formOpen"
        class="fixed inset-0 bg-gray-600 bg-opacity-40 flex items-center justify-center z-50"
      >
        <div class="bg-white rounded-lg w-full max-w-lg shadow-lg">
          <div class="flex items-center justify-between p-4 border-b">
            <h3 class="text-lg font-semibold">
              {{ editing ? 'Edit Failure Code' : 'Add Failure Code' }}
            </h3>
            <button class="text-gray-500 hover:text-gray-700" (click)="closeForm()" type="button">
              ✕
            </button>
          </div>
          <div class="p-4 space-y-3">
            <div>
              <label class="block text-xs font-medium text-gray-700 mb-1">Code</label>
              <input class="w-full px-3 py-2 border rounded-lg" [(ngModel)]="form.code" />
            </div>
            <div>
              <label class="block text-xs font-medium text-gray-700 mb-1">Description</label>
              <textarea
                class="w-full px-3 py-2 border rounded-lg"
                rows="3"
                [(ngModel)]="form.description"
              ></textarea>
            </div>
            <div>
              <label class="block text-xs font-medium text-gray-700 mb-1">Category</label>
              <input class="w-full px-3 py-2 border rounded-lg" [(ngModel)]="form.category" />
            </div>
            <label class="inline-flex items-center gap-2 text-sm text-gray-700">
              <input type="checkbox" [(ngModel)]="form.active" />
              Active
            </label>
          </div>
          <div class="p-4 border-t flex items-center justify-end gap-2">
            <button class="px-4 py-2 border rounded-lg" type="button" (click)="closeForm()">
              Cancel
            </button>
            <button
              class="px-4 py-2 bg-blue-600 text-white rounded-lg"
              type="button"
              [disabled]="saving"
              (click)="save()"
            >
              {{ saving ? 'Saving...' : 'Save' }}
            </button>
          </div>
        </div>
      </div>
    </div>
  `,
})
export class FailureCodesComponent implements OnInit {
  rows: FailureCodeDto[] = [];
  page = 0;
  size = 20;
  totalPages = 1;
  error = '';
  canWrite = false;

  filters: { active: '' | 'true' | 'false' } = { active: 'true' };

  formOpen = false;
  editing = false;
  saving = false;
  form: FailureCodeDto = { code: '', description: '', category: '', active: true };

  constructor(
    private readonly failureCodeService: FailureCodeService,
    private readonly authService: AuthService,
  ) {}

  ngOnInit(): void {
    this.canWrite = this.authService.hasPermission(PERMISSIONS.MAINTENANCE_FAILURE_CODE_WRITE);
    this.load();
  }

  load(): void {
    this.error = '';
    const active = this.filters.active === '' ? undefined : this.filters.active === 'true';
    this.failureCodeService.list({ active, page: this.page, size: this.size }).subscribe({
      next: (res) => {
        const pageData = res?.data;
        this.rows = pageData?.content ?? [];
        this.totalPages = pageData?.totalPages ?? 1;
      },
      error: () => {
        this.rows = [];
        this.error = 'Failed to load failure codes.';
      },
    });
  }

  prevPage(): void {
    if (this.page > 0) {
      this.page -= 1;
      this.load();
    }
  }

  nextPage(): void {
    if (this.page + 1 < this.totalPages) {
      this.page += 1;
      this.load();
    }
  }

  openCreate(): void {
    this.editing = false;
    this.form = { code: '', description: '', category: '', active: true };
    this.formOpen = true;
  }

  openEdit(code: FailureCodeDto): void {
    this.editing = true;
    this.form = { ...code };
    this.formOpen = true;
  }

  closeForm(): void {
    this.formOpen = false;
    this.saving = false;
  }

  save(): void {
    if (!this.form.code) {
      this.error = 'Code is required.';
      return;
    }
    this.saving = true;
    const request =
      this.editing && this.form.id
        ? this.failureCodeService.update(this.form.id, this.form)
        : this.failureCodeService.create(this.form);
    request.subscribe({
      next: () => {
        this.saving = false;
        this.formOpen = false;
        this.load();
      },
      error: () => {
        this.saving = false;
        this.error = 'Failed to save failure code.';
      },
    });
  }

  toggleActive(code: FailureCodeDto): void {
    if (!code?.id) return;
    if (code.active) {
      this.failureCodeService.deactivate(code.id).subscribe({
        next: () => this.load(),
        error: () => {
          this.error = 'Failed to deactivate failure code.';
        },
      });
      return;
    }
    this.failureCodeService.update(code.id, { active: true }).subscribe({
      next: () => this.load(),
      error: () => {
        this.error = 'Failed to activate failure code.';
      },
    });
  }
}
