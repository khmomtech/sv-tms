import { CommonModule } from '@angular/common';
import { Component, inject, signal } from '@angular/core';
import { ActivatedRoute, Router, RouterModule } from '@angular/router';
import { catchError, of, switchMap } from 'rxjs';

import type { PartnerCompany } from '../../../models/partner.model';
import { PARTNERSHIP_TYPE_LABELS, PARTNERSHIP_TYPE_COLORS } from '../../../models/partner.model';
import { VendorService } from '../../../services/vendor.service';

@Component({
  selector: 'app-partner-detail',
  standalone: true,
  imports: [CommonModule, RouterModule],
  templateUrl: './partner-detail.component.html',
  styleUrls: ['./partner-detail.component.css'],
})
export class PartnerDetailComponent {
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);
  private readonly partnerService = inject(VendorService);

  loading = signal(true);
  error = signal<string | null>(null);
  partner = signal<PartnerCompany | null>(null);

  readonly PARTNERSHIP_TYPE_LABELS = PARTNERSHIP_TYPE_LABELS;
  readonly PARTNERSHIP_TYPE_COLORS = PARTNERSHIP_TYPE_COLORS;

  ngOnInit(): void {
    this.route.paramMap
      .pipe(
        switchMap((params) => {
          const id = Number(params.get('id'));
          if (!Number.isFinite(id)) {
            this.error.set('Invalid vendor ID');
            this.loading.set(false);
            return of(null);
          }
          this.loading.set(true);
          this.error.set(null);
          return this.partnerService.getPartnerById(id).pipe(
            catchError((err) => {
              console.error('Failed to load vendor', err);
              this.error.set('Failed to load vendor');
              return of(null);
            }),
          );
        }),
      )
      .subscribe((p) => {
        this.partner.set(p);
        this.loading.set(false);
      });
  }

  getPartnershipTypeLabel(type: any): string {
    return PARTNERSHIP_TYPE_LABELS[type as keyof typeof PARTNERSHIP_TYPE_LABELS] || String(type);
  }

  getPartnershipTypeColor(type: any): string {
    return PARTNERSHIP_TYPE_COLORS[type as keyof typeof PARTNERSHIP_TYPE_COLORS] || 'default';
  }

  formatCurrency(value?: number): string {
    if (value == null) return '-';
    return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(value);
  }

  backToList(): void {
    this.router.navigate(['/vendors']);
  }
}
