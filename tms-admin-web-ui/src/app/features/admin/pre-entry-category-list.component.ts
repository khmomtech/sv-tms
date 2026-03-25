import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterModule } from '@angular/router';
import { PreEntryMasterDataService } from './pre-entry-master-data.service';
import Swal from 'sweetalert2';
import type { SafetyCategory } from '../safety/models/safety-master.model';

@Component({
  selector: 'app-pre-entry-category-list',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule],
  template: `
    <div class="page">
      <div class="page-header">
        <div>
          <h1>ប្រភេទ Pre-entry</h1>
          <p class="subtitle">ទិន្នន័យមេ៖ ប្រភេទសម្រាប់ Pre-entry checklist (KHB)</p>
        </div>
        <div class="header-actions">
          <button class="btn btn-primary" (click)="openCreateDrawer()">បង្កើតថ្មី</button>
          <a class="link" routerLink="/dispatch/pre-entry-safety">ត្រឡប់ក្រោយ</a>
        </div>
      </div>

      <div class="filters">
        <label class="checkbox">
          <input type="checkbox" [(ngModel)]="activeOnly" (change)="load()" />
          <span>បង្ហាញតែសកម្ម</span>
        </label>
      </div>

      <div class="table-card" *ngIf="!loading">
        <table class="table">
          <thead>
            <tr>
              <th>ID</th>
              <th>កូដ</th>
              <th>ឈ្មោះ (ខ្មែរ)</th>
              <th>លំដាប់</th>
              <th>ស្ថានភាព</th>
              <th>សកម្មភាព</th>
            </tr>
          </thead>
          <tbody>
            <tr *ngFor="let cat of categories" class="click-row" (click)="openEditDrawer(cat)">
              <td>{{ cat.id }}</td>
              <td>{{ cat.code }}</td>
              <td>{{ cat.nameKm }}</td>
              <td>{{ cat.sortOrder ?? '-' }}</td>
              <td>
                <span class="badge" [ngClass]="cat.isActive ? 'active' : 'inactive'">
                  {{ cat.isActive ? 'សកម្ម' : 'មិនសកម្ម' }}
                </span>
              </td>
              <td>
                <button
                  class="btn btn-small btn-danger"
                  [ngClass]="cat.isActive ? 'btn-danger' : 'btn-primary'"
                  (click)="toggleActive(cat); $event.stopPropagation()"
                  [disabled]="!cat.id"
                >
                  {{ cat.isActive ? 'បិទ' : 'បើក' }}
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <div class="loading" *ngIf="loading">កំពុងផ្ទុក...</div>
      <div class="empty" *ngIf="!loading && categories.length === 0">គ្មានទិន្នន័យ</div>

      <div class="drawer-backdrop" *ngIf="drawerOpen" (click)="closeDrawer()"></div>
      <aside class="drawer" [class.open]="drawerOpen">
        <div class="drawer-header">
          <h3>{{ editingId ? 'កែប្រែប្រភេទ' : 'បង្កើតប្រភេទថ្មី' }}</h3>
          <button class="btn btn-small" (click)="closeDrawer()">បិទ</button>
        </div>
        <div class="drawer-body">
          <label>កូដ</label>
          <input type="text" [(ngModel)]="form.code" placeholder="ឧ: LOAD" />

          <label>ឈ្មោះ (ខ្មែរ)</label>
          <input type="text" [(ngModel)]="form.nameKm" placeholder="ឧ: សម្ភារះលើឡានមុនចូលរោងចក្រ" />

          <label>លំដាប់</label>
          <input type="number" [(ngModel)]="form.sortOrder" />

          <label class="checkbox">
            <input type="checkbox" [(ngModel)]="form.isActive" />
            <span>សកម្ម</span>
          </label>
        </div>
        <div class="drawer-footer">
          <button class="btn" (click)="resetForm()">សម្អាត</button>
          <button class="btn btn-primary" (click)="save()">
            {{ editingId ? 'រក្សាទុក' : 'បង្កើត' }}
          </button>
        </div>
      </aside>
    </div>
  `,
  styles: [
    `
      .page {
        padding: 16px;
        position: relative;
      }
      .page-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 16px;
      }
      .header-actions {
        display: flex;
        gap: 8px;
        align-items: center;
      }
      .subtitle {
        color: #6b7280;
      }
      .filters {
        background: #fff;
        padding: 12px;
        border-radius: 8px;
        margin-bottom: 16px;
      }
      .checkbox {
        display: flex;
        gap: 8px;
        align-items: center;
      }
      .checkbox input[type='checkbox'] {
        width: 16px;
        height: 16px;
        padding: 0;
        accent-color: #2563eb;
      }
      .table-card {
        background: #fff;
        border-radius: 8px;
        padding: 8px;
      }
      .table {
        width: 100%;
        border-collapse: collapse;
      }
      .table th,
      .table td {
        padding: 10px;
        border-bottom: 1px solid #e5e7eb;
      }
      .click-row {
        cursor: pointer;
      }
      .click-row:hover {
        background: #f8fafc;
      }
      .badge {
        padding: 4px 8px;
        border-radius: 12px;
        font-size: 12px;
      }
      .badge.active {
        background: #dcfce7;
        color: #166534;
      }
      .badge.inactive {
        background: #fee2e2;
        color: #991b1b;
      }
      .btn {
        padding: 6px 12px;
      }
      .btn-primary {
        background: #2563eb;
        color: #fff;
      }
      .btn-small {
        padding: 4px 8px;
        font-size: 12px;
      }
      .btn-danger {
        background: #dc2626;
        color: #fff;
      }
      .loading,
      .empty {
        text-align: center;
        padding: 20px;
      }
      .link {
        color: #2563eb;
      }
      .drawer-backdrop {
        position: fixed;
        inset: 0;
        background: rgba(15, 23, 42, 0.25);
        z-index: 70;
      }
      .drawer {
        position: fixed;
        top: 0;
        right: -420px;
        width: 420px;
        max-width: 96vw;
        height: 100vh;
        background: #fff;
        box-shadow: -10px 0 30px rgba(15, 23, 42, 0.15);
        z-index: 80;
        transition: right 0.2s ease;
        display: flex;
        flex-direction: column;
      }
      .drawer.open {
        right: 0;
      }
      .drawer-header,
      .drawer-footer {
        padding: 12px;
        border-bottom: 1px solid #e5e7eb;
        display: flex;
        justify-content: space-between;
        align-items: center;
      }
      .drawer-footer {
        border-bottom: none;
        border-top: 1px solid #e5e7eb;
        margin-top: auto;
      }
      .drawer-body {
        padding: 12px;
        display: grid;
        gap: 8px;
      }
      .drawer-body input[type='text'],
      .drawer-body input[type='number'] {
        width: 100%;
        padding: 8px;
      }
    `,
  ],
})
export class PreEntryCategoryListComponent implements OnInit {
  categories: SafetyCategory[] = [];
  loading = false;
  activeOnly = false;
  editingId: number | null = null;
  drawerOpen = false;
  form: {
    code: string;
    nameKm: string;
    sortOrder: number | null;
    isActive: boolean;
  } = {
    code: '',
    nameKm: '',
    sortOrder: null,
    isActive: true,
  };

  constructor(private readonly masterService: PreEntryMasterDataService) {}

  ngOnInit(): void {
    this.load();
  }

  load(): void {
    this.loading = true;
    this.masterService.getCategories(this.activeOnly).subscribe({
      next: (res) => {
        this.categories = res.data || [];
        this.loading = false;
      },
      error: (err) => {
        this.categories = [];
        this.loading = false;
        this.showError(err);
      },
    });
  }

  openCreateDrawer(): void {
    this.resetForm();
    this.drawerOpen = true;
  }

  openEditDrawer(cat: SafetyCategory): void {
    this.editingId = cat.id ?? null;
    this.form = {
      code: cat.code || '',
      nameKm: cat.nameKm || '',
      sortOrder: cat.sortOrder ?? null,
      isActive: cat.isActive ?? true,
    };
    this.drawerOpen = true;
  }

  closeDrawer(): void {
    this.drawerOpen = false;
  }

  resetForm(): void {
    this.editingId = null;
    this.form = {
      code: '',
      nameKm: '',
      sortOrder: null,
      isActive: true,
    };
  }

  save(): void {
    if (!this.form.code?.trim() || !this.form.nameKm?.trim()) {
      Swal.fire({
        icon: 'warning',
        title: 'ព័ត៌មានមិនគ្រប់គ្រាន់',
        text: 'សូមបញ្ចូលកូដ និង ឈ្មោះ (ខ្មែរ) មុនពេលរក្សាទុក',
        confirmButtonText: 'យល់ព្រម',
      });
      return;
    }
    const payload = {
      code: this.form.code?.trim(),
      nameKm: this.form.nameKm?.trim(),
      sortOrder: this.form.sortOrder ?? undefined,
      isActive: this.form.isActive,
    };
    if (this.editingId) {
      this.masterService.updateCategory(this.editingId, payload).subscribe({
        next: () => {
          Swal.fire({
            icon: 'success',
            title: 'ជោគជ័យ',
            text: 'បានកែប្រែប្រភេទសុវត្ថិភាព',
            confirmButtonText: 'យល់ព្រម',
          });
          this.closeDrawer();
          this.resetForm();
          this.load();
        },
        error: (err) => {
          this.showError(err);
        },
      });
      return;
    }
    this.masterService.createCategory(payload).subscribe({
      next: () => {
        Swal.fire({
          icon: 'success',
          title: 'ជោគជ័យ',
          text: 'បានបង្កើតប្រភេទសុវត្ថិភាព',
          confirmButtonText: 'យល់ព្រម',
        });
        this.closeDrawer();
        this.resetForm();
        this.load();
      },
      error: (err) => {
        this.showError(err);
      },
    });
  }

  toggleActive(cat: SafetyCategory): void {
    if (!cat.id) return;
    const nextActive = !(cat.isActive ?? false);
    const actionLabel = nextActive ? 'បើក' : 'បិទ';
    const successText = nextActive ? 'បានបើកប្រភេទសុវត្ថិភាព' : 'បានបិទប្រភេទសុវត្ថិភាព';
    Swal.fire({
      icon: 'warning',
      title: `${actionLabel}ប្រភេទសុវត្ថិភាព?`,
      text: `តើអ្នកចង់${actionLabel}ប្រភេទនេះមែនទេ?`,
      showCancelButton: true,
      confirmButtonText: actionLabel,
      cancelButtonText: 'បោះបង់',
    }).then((result) => {
      if (!result.isConfirmed) return;
      this.masterService.setCategoryActive(cat.id!, nextActive).subscribe({
        next: () => {
          Swal.fire({
            icon: 'success',
            title: 'ជោគជ័យ',
            text: successText,
            confirmButtonText: 'យល់ព្រម',
          });
          this.load();
        },
        error: (err) => this.showError(err),
      });
    });
  }

  private showError(err: any): void {
    const status = err?.status;
    let message = err?.error?.message || err?.message || 'មានបញ្ហាក្នុងការប្រតិបត្តិការណ៍';
    if (status === 404) {
      message = 'API សុវត្ថិភាពមេមិនត្រូវបានរកឃើញ។ សូមបើក Backend (tms-backend) ដែលបានអាប់ដេតថ្មី។';
    }
    Swal.fire({
      icon: 'error',
      title: 'កំហុស',
      text: message,
      confirmButtonText: 'យល់ព្រម',
    });
  }
}
