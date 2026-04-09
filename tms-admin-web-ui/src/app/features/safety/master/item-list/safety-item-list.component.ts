import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterModule } from '@angular/router';
import { SafetyMasterDataService } from '../../services/safety-master-data.service';
import Swal from 'sweetalert2';
import type { SafetyCategory, SafetyMasterItem } from '../../models/safety-master.model';

@Component({
  selector: 'app-safety-item-list',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule],
  template: `
    <div class="page">
      <div class="page-header">
        <div>
          <h1>ធាតុសុវត្ថិភាពប្រចាំថ្ងៃ</h1>
          <p class="subtitle">ទិន្នន័យមេ៖ បញ្ជីធាតុសម្រាប់ត្រួតពិនិត្យសុវត្ថិភាពប្រចាំថ្ងៃ</p>
        </div>
        <a class="link" routerLink="/safety">ត្រឡប់ក្រោយ</a>
      </div>

      <div class="filters">
        <div class="import-box">
          <div class="import-title">នាំចូលពី Excel</div>
          <div class="import-row">
            <input type="file" (change)="onFileSelected($event)" accept=".xlsx,.xls" />
            <button class="btn btn-primary" (click)="importExcel()" [disabled]="!selectedFile">
              នាំចូល
            </button>
            <span class="import-note">Sheet: Category និង Daily Safety Checklist</span>
          </div>
        </div>
        <div class="form-grid">
          <div>
            <label>ប្រភេទ</label>
            <select [(ngModel)]="form.categoryId">
              <option [ngValue]="null">-- ជ្រើសរើស --</option>
              <option *ngFor="let c of categories" [ngValue]="c.id">
                {{ c.nameKm }}
              </option>
            </select>
          </div>
          <div>
            <label>កូដធាតុ (ជម្រើស)</label>
            <input type="text" [(ngModel)]="form.itemKey" placeholder="ឧ: engine_oil" />
          </div>
          <div>
            <label>ឈ្មោះ (ខ្មែរ)</label>
            <input type="text" [(ngModel)]="form.itemLabelKm" placeholder="ឧ: ប្រេងម៉ាស៊ីន" />
          </div>
          <div>
            <label>ពេលវេលា</label>
            <input type="text" [(ngModel)]="form.checkTime" placeholder="ព្រឹក / ពេលបើកបរ" />
          </div>
          <div>
            <label>លំដាប់</label>
            <input type="number" [(ngModel)]="form.sortOrder" />
          </div>
          <div class="checkbox">
            <input type="checkbox" [(ngModel)]="form.isActive" />
            <span>សកម្ម</span>
          </div>
          <div class="actions">
            <button class="btn btn-primary" (click)="save()">
              {{ editingId ? 'កែប្រែ' : 'បង្កើត' }}
            </button>
            <button class="btn" (click)="resetForm()">សម្អាត</button>
          </div>
        </div>

        <div class="filter">
          <label>ប្រភេទ (តម្រង)</label>
          <select [(ngModel)]="selectedCategoryId" (change)="loadItems()">
            <option [ngValue]="null">ទាំងអស់</option>
            <option *ngFor="let c of categories" [ngValue]="c.id">
              {{ c.nameKm }}
            </option>
          </select>
        </div>
        <div class="filter">
          <label>ស្វែងរក</label>
          <input
            type="text"
            [(ngModel)]="searchTerm"
            (keyup.enter)="loadItems()"
            placeholder="ស្វែងរកតាមកូដ ឬ ឈ្មោះ"
          />
        </div>
        <div class="filter checkbox">
          <input type="checkbox" [(ngModel)]="activeOnly" (change)="loadItems()" />
          <span>បង្ហាញតែសកម្ម</span>
        </div>
        <div class="filter actions">
          <button class="btn btn-primary" (click)="loadItems()">ស្វែងរក</button>
          <button class="btn" (click)="resetFilters()">សម្អាតតម្រង</button>
        </div>
      </div>

      <div class="table-card" *ngIf="!loading">
        <table class="table">
          <thead>
            <tr>
              <th>ID</th>
              <th>ប្រភេទ</th>
              <th>កូដ</th>
              <th>ឈ្មោះ (ខ្មែរ)</th>
              <th>ពេលវេលា</th>
              <th>លំដាប់</th>
              <th>ស្ថានភាព</th>
              <th>សកម្មភាព</th>
            </tr>
          </thead>
          <tbody>
            <tr *ngFor="let item of items">
              <td>{{ item.id }}</td>
              <td>{{ item.categoryNameKm || item.categoryCode }}</td>
              <td>{{ item.itemKey }}</td>
              <td>{{ item.itemLabelKm }}</td>
              <td>{{ item.checkTime || '-' }}</td>
              <td>{{ item.sortOrder ?? '-' }}</td>
              <td>
                <span class="badge" [ngClass]="item.isActive ? 'active' : 'inactive'">
                  {{ item.isActive ? 'សកម្ម' : 'មិនសកម្ម' }}
                </span>
              </td>
              <td>
                <button class="btn btn-small" (click)="edit(item)">កែប្រែ</button>
                <button
                  class="btn btn-small btn-danger"
                  [ngClass]="item.isActive ? 'btn-danger' : 'btn-primary'"
                  (click)="toggleActive(item)"
                  [disabled]="!item.id"
                >
                  {{ item.isActive ? 'បិទ' : 'បើក' }}
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <div class="loading" *ngIf="loading">កំពុងផ្ទុក...</div>
      <div class="empty" *ngIf="!loading && items.length === 0">គ្មានទិន្នន័យ</div>
    </div>
  `,
  styles: [
    `
      .page {
        padding: 16px;
      }
      .page-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 16px;
      }
      .subtitle {
        color: #6b7280;
      }
      .filters {
        background: #fff;
        padding: 12px;
        border-radius: 8px;
        margin-bottom: 16px;
        display: grid;
        gap: 12px;
      }
      .import-box {
        background: #f8fafc;
        border: 1px dashed #cbd5f5;
        border-radius: 8px;
        padding: 12px;
      }
      .import-title {
        font-weight: 700;
        margin-bottom: 8px;
      }
      .import-row {
        display: flex;
        flex-wrap: wrap;
        gap: 10px;
        align-items: center;
      }
      .import-note {
        color: #64748b;
        font-size: 12px;
      }
      .form-grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
        gap: 12px;
        align-items: end;
      }
      .form-grid label {
        display: block;
        font-weight: 600;
        margin-bottom: 4px;
      }
      .form-grid input,
      .form-grid select {
        width: 100%;
        padding: 6px 8px;
      }
      .filter label {
        display: block;
        font-weight: 600;
        margin-bottom: 4px;
      }
      .filter select {
        width: 100%;
        padding: 6px 8px;
      }
      .actions {
        display: flex;
        gap: 8px;
      }
      .checkbox {
        display: flex;
        gap: 8px;
        align-items: center;
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
    `,
  ],
})
export class SafetyItemListComponent implements OnInit {
  categories: SafetyCategory[] = [];
  items: SafetyMasterItem[] = [];
  loading = false;
  activeOnly = false;
  selectedCategoryId: number | null = null;
  searchTerm = '';
  editingId: number | null = null;
  selectedFile: File | null = null;
  form: {
    categoryId: number | null;
    itemKey: string;
    itemLabelKm: string;
    checkTime: string;
    sortOrder: number | null;
    isActive: boolean;
  } = {
    categoryId: null,
    itemKey: '',
    itemLabelKm: '',
    checkTime: '',
    sortOrder: null,
    isActive: true,
  };

  constructor(private readonly masterService: SafetyMasterDataService) {}

  ngOnInit(): void {
    this.loadCategories();
    this.loadItems();
  }

  loadCategories(): void {
    this.masterService.getCategories(false).subscribe({
      next: (res) => {
        this.categories = res.data || [];
      },
      error: (err) => {
        this.categories = [];
        this.showError(err);
      },
    });
  }

  loadItems(): void {
    this.loading = true;
    this.masterService
      .getItems({
        categoryId: this.selectedCategoryId ?? undefined,
        activeOnly: this.activeOnly,
        keyword: this.searchTerm?.trim() || undefined,
      })
      .subscribe({
        next: (res) => {
          this.items = res.data || [];
          this.loading = false;
        },
        error: (err) => {
          this.items = [];
          this.loading = false;
          this.showError(err);
        },
      });
  }

  onFileSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    const file = input.files && input.files.length > 0 ? input.files[0] : null;
    this.selectedFile = file;
  }

  importExcel(): void {
    if (!this.selectedFile) return;
    Swal.fire({
      icon: 'question',
      title: 'នាំចូលទិន្នន័យ?',
      text: 'តើអ្នកចង់នាំចូលទិន្នន័យពី Excel មែនទេ?',
      showCancelButton: true,
      confirmButtonText: 'នាំចូល',
      cancelButtonText: 'បោះបង់',
    }).then((result) => {
      if (!result.isConfirmed || !this.selectedFile) return;
      this.masterService.importFromExcel(this.selectedFile).subscribe({
        next: (res) => {
          const msg = res?.data?.message || 'បាននាំចូលទិន្នន័យជោគជ័យ';
          Swal.fire({
            icon: 'success',
            title: 'ជោគជ័យ',
            text: msg,
            confirmButtonText: 'យល់ព្រម',
          });
          this.selectedFile = null;
          this.loadCategories();
          this.loadItems();
        },
        error: (err) => this.showError(err),
      });
    });
  }

  edit(item: SafetyMasterItem): void {
    this.editingId = item.id ?? null;
    this.form = {
      categoryId: item.categoryId ?? null,
      itemKey: item.itemKey || '',
      itemLabelKm: item.itemLabelKm || '',
      checkTime: item.checkTime || '',
      sortOrder: item.sortOrder ?? null,
      isActive: item.isActive ?? true,
    };
  }

  resetForm(): void {
    this.editingId = null;
    this.form = {
      categoryId: null,
      itemKey: '',
      itemLabelKm: '',
      checkTime: '',
      sortOrder: null,
      isActive: true,
    };
  }

  save(): void {
    if (!this.form.categoryId || !this.form.itemLabelKm?.trim()) {
      Swal.fire({
        icon: 'warning',
        title: 'ព័ត៌មានមិនគ្រប់គ្រាន់',
        text: 'សូមជ្រើសប្រភេទ និង បញ្ចូលឈ្មោះ (ខ្មែរ) មុនពេលរក្សាទុក',
        confirmButtonText: 'យល់ព្រម',
      });
      return;
    }
    const payload = {
      categoryId: this.form.categoryId ?? undefined,
      itemKey: this.form.itemKey?.trim() || undefined,
      itemLabelKm: this.form.itemLabelKm?.trim(),
      checkTime: this.form.checkTime?.trim() || undefined,
      sortOrder: this.form.sortOrder ?? undefined,
      isActive: this.form.isActive,
    };
    if (this.editingId) {
      this.masterService.updateItem(this.editingId, payload).subscribe({
        next: () => {
          Swal.fire({
            icon: 'success',
            title: 'ជោគជ័យ',
            text: 'បានកែប្រែធាតុសុវត្ថិភាព',
            confirmButtonText: 'យល់ព្រម',
          });
          this.resetForm();
          this.loadItems();
        },
        error: (err) => this.showError(err),
      });
      return;
    }
    this.masterService.createItem(payload).subscribe({
      next: () => {
        Swal.fire({
          icon: 'success',
          title: 'ជោគជ័យ',
          text: 'បានបង្កើតធាតុសុវត្ថិភាព',
          confirmButtonText: 'យល់ព្រម',
        });
        this.resetForm();
        this.loadItems();
      },
      error: (err) => this.showError(err),
    });
  }

  toggleActive(item: SafetyMasterItem): void {
    if (!item.id) return;
    const nextActive = !(item.isActive ?? false);
    const actionLabel = nextActive ? 'បើក' : 'បិទ';
    const successText = nextActive ? 'បានបើកធាតុសុវត្ថិភាព' : 'បានបិទធាតុសុវត្ថិភាព';
    Swal.fire({
      icon: 'warning',
      title: `${actionLabel}ធាតុសុវត្ថិភាព?`,
      text: `តើអ្នកចង់${actionLabel}ធាតុនេះមែនទេ?`,
      showCancelButton: true,
      confirmButtonText: actionLabel,
      cancelButtonText: 'បោះបង់',
    }).then((result) => {
      if (!result.isConfirmed) return;
      this.masterService.setItemActive(item.id!, nextActive).subscribe({
        next: () => {
          Swal.fire({
            icon: 'success',
            title: 'ជោគជ័យ',
            text: successText,
            confirmButtonText: 'យល់ព្រម',
          });
          this.loadItems();
        },
        error: (err) => this.showError(err),
      });
    });
  }

  resetFilters(): void {
    this.selectedCategoryId = null;
    this.searchTerm = '';
    this.activeOnly = false;
    this.loadItems();
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
