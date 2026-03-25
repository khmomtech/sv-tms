import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterModule } from '@angular/router';
import { SafetyMasterDataService } from '../../services/safety-master-data.service';
import Swal from 'sweetalert2';
import type { SafetyCategory } from '../../models/safety-master.model';

@Component({
  selector: 'app-safety-category-list',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule],
  template: `
    <div class="page">
      <div class="page-header">
        <div>
          <h1>ប្រភេទសុវត្ថិភាពប្រចាំថ្ងៃ</h1>
          <p class="subtitle">ទិន្នន័យមេ៖ ប្រភេទសម្រាប់ត្រួតពិនិត្យសុវត្ថិភាពប្រចាំថ្ងៃ</p>
        </div>
        <a class="link" routerLink="/safety">ត្រឡប់ក្រោយ</a>
      </div>

      <div class="filters">
        <div class="form-grid">
          <div>
            <label>កូដ</label>
            <input type="text" [(ngModel)]="form.code" placeholder="ឧ: ENGINE" />
          </div>
          <div>
            <label>ឈ្មោះ (ខ្មែរ)</label>
            <input type="text" [(ngModel)]="form.nameKm" placeholder="ឧ: ផ្នែកម៉ាស៊ីន" />
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
            <tr *ngFor="let cat of categories">
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
                <button class="btn btn-small" (click)="edit(cat)">កែប្រែ</button>
                <button
                  class="btn btn-small btn-danger"
                  [ngClass]="cat.isActive ? 'btn-danger' : 'btn-primary'"
                  (click)="toggleActive(cat)"
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
      }
      .form-grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
        gap: 12px;
        margin-bottom: 12px;
        align-items: end;
      }
      .form-grid label {
        display: block;
        font-weight: 600;
        margin-bottom: 4px;
      }
      .form-grid input {
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
export class SafetyCategoryListComponent implements OnInit {
  categories: SafetyCategory[] = [];
  loading = false;
  activeOnly = false;
  editingId: number | null = null;
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

  constructor(private readonly masterService: SafetyMasterDataService) {}

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

  edit(cat: SafetyCategory): void {
    this.editingId = cat.id ?? null;
    this.form = {
      code: cat.code || '',
      nameKm: cat.nameKm || '',
      sortOrder: cat.sortOrder ?? null,
      isActive: cat.isActive ?? true,
    };
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
