import { CommonModule } from '@angular/common';
import { HttpClientModule } from '@angular/common/http';
import { Component, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { RouterModule } from '@angular/router';
import { catchError, of } from 'rxjs';

import type { PartnerCompany, PartnerAdmin } from '../../../../models/partner.model';
import { VendorService } from '../../../../services/vendor.service';

@Component({
  selector: 'app-subcontractor-admins',
  standalone: true,
  imports: [CommonModule, RouterModule, FormsModule, HttpClientModule],
  template: `
    <section class="page">
      <h1>Subcontractor Admins</h1>
      <p class="muted">Select a subcontractor to view assigned admins.</p>

      <div class="controls">
        <label>
          Company:
          <select [(ngModel)]="selectedCompanyId" (change)="onCompanyChange()">
            <option [ngValue]="null">— Select —</option>
            <option *ngFor="let c of companies()" [ngValue]="c.id">{{ c.companyName }}</option>
          </select>
        </label>
        <button (click)="refresh()">Refresh</button>
      </div>

      <div *ngIf="loading()" class="muted">Loading…</div>
      <div *ngIf="error()" class="error">{{ error() }}</div>

      <table *ngIf="!loading() && admins().length" class="table">
        <thead>
          <tr>
            <th>User</th>
            <th>Email</th>
            <th>Primary</th>
            <th>Manage Drivers</th>
            <th>Manage Customers</th>
            <th>View Reports</th>
            <th>Manage Settings</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          <tr *ngFor="let a of admins(); trackBy: trackByAdmin">
            <td>{{ a.user?.username || a.userId }}</td>
            <td>{{ a.user?.email || '—' }}</td>
            <td>{{ a.isPrimary ? 'Yes' : 'No' }}</td>
            <td>{{ a.canManageDrivers ? 'Yes' : 'No' }}</td>
            <td>{{ a.canManageCustomers ? 'Yes' : 'No' }}</td>
            <td>{{ a.canViewReports ? 'Yes' : 'No' }}</td>
            <td>{{ a.canManageSettings ? 'Yes' : 'No' }}</td>
            <td>
              <button (click)="togglePrimary(a)">Toggle Primary</button>
              <button (click)="removeAdmin(a)">Remove</button>
            </td>
          </tr>
        </tbody>
      </table>

      <p *ngIf="!loading() && !admins().length" class="muted">No admins found.</p>

      <hr />
      <h2>Assign Admin</h2>
      <form (ngSubmit)="assignAdmin()" #assignForm="ngForm" class="controls">
        <label>
          User ID:
          <input type="number" [(ngModel)]="newAdmin.userId" name="userId" required />
        </label>
        <label>
          Primary:
          <input type="checkbox" [(ngModel)]="newAdmin.isPrimary" name="isPrimary" />
        </label>
        <fieldset class="perm-set">
          <legend>Permissions</legend>
          <label
            ><input
              type="checkbox"
              [(ngModel)]="newAdmin.canManageDrivers"
              name="canManageDrivers"
            />
            Manage Drivers</label
          >
          <label
            ><input
              type="checkbox"
              [(ngModel)]="newAdmin.canManageCustomers"
              name="canManageCustomers"
            />
            Manage Customers</label
          >
          <label
            ><input type="checkbox" [(ngModel)]="newAdmin.canViewReports" name="canViewReports" />
            View Reports</label
          >
          <label
            ><input
              type="checkbox"
              [(ngModel)]="newAdmin.canManageSettings"
              name="canManageSettings"
            />
            Manage Settings</label
          >
        </fieldset>
        <button type="submit" [disabled]="!selectedCompanyId || assignForm.invalid">Assign</button>
      </form>
    </section>
  `,
  styles: [
    `
      .page {
        padding: 16px;
      }
      .muted {
        color: #666;
      }
      .error {
        color: #b00020;
      }
      .controls {
        margin: 12px 0;
        display: flex;
        gap: 12px;
        align-items: center;
      }
      .table {
        width: 100%;
        border-collapse: collapse;
      }
      .table th,
      .table td {
        border: 1px solid #ddd;
        padding: 8px;
      }
      .table th {
        background: #f6f6f6;
        text-align: left;
      }
      .perm-set {
        display: flex;
        gap: 12px;
        align-items: center;
      }
    `,
  ],
})
export class SubcontractorAdminsComponent {
  private readonly vendorService = inject(VendorService);

  companies = signal<PartnerCompany[]>([]);
  admins = signal<PartnerAdmin[]>([]);
  selectedCompanyId: number | null = null;
  loading = signal(false);
  error = signal<string | null>(null);
  newAdmin: Partial<PartnerAdmin> = {
    userId: undefined as any,
    isPrimary: false,
    canManageDrivers: false,
    canManageCustomers: false,
    canViewReports: false,
    canManageSettings: false,
  };

  ngOnInit(): void {
    this.loadCompanies();
  }

  loadCompanies(): void {
    this.loading.set(true);
    this.error.set(null);
    this.vendorService
      .getAllPartners()
      .pipe(
        catchError((err) => {
          console.error('Failed to load companies', err);
          this.error.set('Failed to load companies');
          this.loading.set(false);
          return of([]);
        }),
      )
      .subscribe((list) => {
        this.companies.set(list || []);
        this.loading.set(false);
      });
  }

  onCompanyChange(): void {
    this.refresh();
  }

  refresh(): void {
    if (!this.selectedCompanyId) {
      this.admins.set([]);
      return;
    }
    this.loading.set(true);
    this.error.set(null);
    this.vendorService
      .getCompanyAdmins(this.selectedCompanyId)
      .pipe(
        catchError((err) => {
          console.error('Failed to load admins', err);
          this.error.set('Failed to load admins');
          this.loading.set(false);
          return of([]);
        }),
      )
      .subscribe((admins: PartnerAdmin[]) => {
        this.admins.set(admins || []);
        this.loading.set(false);
      });
  }

  trackByAdmin = (_: number, admin: PartnerAdmin) => admin.id ?? admin.userId;

  assignAdmin(): void {
    if (!this.selectedCompanyId || !this.newAdmin.userId) return;
    const payload: Partial<PartnerAdmin> = {
      userId: Number(this.newAdmin.userId),
      partnerCompanyId: Number(this.selectedCompanyId),
      isPrimary: !!this.newAdmin.isPrimary,
      canManageDrivers: !!this.newAdmin.canManageDrivers,
      canManageCustomers: !!this.newAdmin.canManageCustomers,
      canViewReports: !!this.newAdmin.canViewReports,
      canManageSettings: !!this.newAdmin.canManageSettings,
    };
    this.loading.set(true);
    this.error.set(null);
    this.vendorService
      .assignAdminToCompany(payload)
      .pipe(
        catchError((err) => {
          console.error('Failed to assign admin', err);
          this.error.set('Failed to assign admin');
          this.loading.set(false);
          return of(null);
        }),
      )
      .subscribe((res) => {
        // reset form and refresh list
        this.newAdmin = {
          userId: undefined as any,
          isPrimary: false,
          canManageDrivers: false,
          canManageCustomers: false,
          canViewReports: false,
          canManageSettings: false,
        };
        this.refresh();
      });
  }

  togglePrimary(a: PartnerAdmin): void {
    const next = !a.isPrimary;
    this.loading.set(true);
    this.error.set(null);
    this.vendorService
      .updateAdminPermissions(a.id!, {
        canManageDrivers: !!a.canManageDrivers,
        canManageCustomers: !!a.canManageCustomers,
        canViewReports: !!a.canViewReports,
        canManageSettings: !!a.canManageSettings,
      })
      .pipe(
        catchError((err) => {
          console.error('Failed to update permissions', err);
          this.error.set('Failed to update permissions');
          this.loading.set(false);
          return of(a);
        }),
      )
      .subscribe(() => {
        // In a real API, primary might be a separate flag endpoint; here we just refresh.
        a.isPrimary = next;
        this.refresh();
      });
  }

  removeAdmin(a: PartnerAdmin): void {
    if (!a.id) return;
    this.loading.set(true);
    this.error.set(null);
    this.vendorService
      .removeAdmin(a.id)
      .pipe(
        catchError((err) => {
          console.error('Failed to remove admin', err);
          this.error.set('Failed to remove admin');
          this.loading.set(false);
          return of(void 0);
        }),
      )
      .subscribe(() => {
        this.refresh();
      });
  }
}
