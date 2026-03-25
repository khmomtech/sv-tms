import { Component, OnInit, inject, signal, computed } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterLink, Router } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { TranslateModule, TranslateService } from '@ngx-translate/core';
import { CaseService } from '../../services/case.service';
import { ConfirmService } from '../../../../services/confirm.service';
import { AuthService } from '../../../../services/auth.service';
import { PERMISSIONS } from '../../../../shared/permissions';
import {
  Case,
  CaseFilter,
  CaseStatus,
  CaseCategory,
  IssueSeverity,
  CaseStatistics,
} from '../../models/incident.model';

/**
 * Case List Component
 *
 * Displays a filterable, paginated list of cases with statistics.
 * Provides navigation to case details and creation.
 */
@Component({
  selector: 'app-case-list',
  standalone: true,
  imports: [CommonModule, RouterLink, FormsModule, TranslateModule],
  templateUrl: './case-list.component.html',
  styleUrls: ['./case-list.component.css'],
})
export class CaseListComponent implements OnInit {
  readonly Math = Math;
  // ============================================================
  // Dependency Injection
  // ============================================================
  private readonly caseService = inject(CaseService);
  private readonly router = inject(Router);
  private readonly confirm = inject(ConfirmService);
  private readonly authService = inject(AuthService);
  private readonly translate = inject(TranslateService);

  // ============================================================
  // State Management (Signals)
  // ============================================================
  cases = signal<Case[]>([]);
  loading = signal(true);
  error = signal<string | null>(null);
  currentPage = signal(0);
  totalElements = signal(0);
  totalPages = signal(0);
  statistics = signal<CaseStatistics | null>(null);
  pageSize = 20;
  openMenu = signal<number | null>(null);
  canCreateCase = signal(false);

  // ============================================================
  // Filter Configuration
  // ============================================================
  statuses = Object.values(CaseStatus);
  categories = Object.values(CaseCategory);
  severities = Object.values(IssueSeverity);
  filters: CaseFilter = {};

  // ============================================================
  // Computed Values
  // ============================================================
  /**
   * Calculate pagination page numbers to display
   */
  pageNumbers = computed(() => {
    const total = this.totalPages();
    const current = this.currentPage();
    const pages: number[] = [];

    let start = Math.max(0, current - 2);
    let end = Math.min(total, start + 5);

    if (end - start < 5) {
      start = Math.max(0, end - 5);
    }

    for (let i = start; i < end; i++) {
      pages.push(i);
    }

    return pages;
  });

  // ============================================================
  // Lifecycle Hooks
  // ============================================================
  /**
   * Initialize component data on load
   */
  ngOnInit() {
    this.canCreateCase.set(this.authService.hasPermission(PERMISSIONS.CASE_CREATE));
    this.loadStatistics();
    this.loadCases();
  }

  // ============================================================
  // Data Loading Methods
  // ============================================================
  /**
   * Load case statistics for dashboard cards
   */
  loadStatistics() {
    this.caseService.getStatistics().subscribe({
      next: (response) => {
        this.statistics.set(response.data);
      },
      error: (err) => {
        console.error('Error loading statistics:', err);
      },
    });
  }

  /**
   * Load cases with current filters and pagination
   */
  loadCases() {
    this.loading.set(true);
    this.error.set(null);

    this.caseService.listCases(this.filters, this.currentPage(), this.pageSize).subscribe({
      next: (response) => {
        this.cases.set(response.data.content);
        this.totalElements.set(response.data.totalElements);
        this.totalPages.set(response.data.totalPages);
        this.loading.set(false);
      },
      error: (err) => {
        this.error.set(this.translate.instant('caseList.failed_to_load'));
        this.loading.set(false);
        console.error('Error loading cases:', err);
      },
    });
  }

  // ============================================================
  // Filter Methods
  // ============================================================
  /**
   * Apply current filters and reload cases
   */
  applyFilters() {
    this.currentPage.set(0);
    this.loadCases();
  }

  /**
   * Clear all filters and reload cases
   */
  clearFilters() {
    this.filters = {};
    this.applyFilters();
  }

  // ============================================================
  // Pagination Methods
  // ============================================================
  /**
   * Navigate to specific page
   * @param page Page number to navigate to
   */
  goToPage(page: number) {
    if (page >= 0 && page < this.totalPages()) {
      this.currentPage.set(page);
      this.loadCases();
    }
  }

  // ============================================================
  // UI Helper Methods
  // ============================================================
  /**
   * Get Bootstrap badge class for case status
   * @param status Case status
   * @returns Bootstrap badge class
   */
  getStatusBadgeClass(status: CaseStatus): string {
    const classes: Record<CaseStatus, string> = {
      [CaseStatus.OPEN]: 'bg-success',
      [CaseStatus.INVESTIGATION]: 'bg-warning',
      [CaseStatus.PENDING_APPROVAL]: 'bg-info',
      [CaseStatus.CLOSED]: 'bg-secondary',
    };
    return classes[status] || 'bg-secondary';
  }

  /**
   * Get Bootstrap badge class for severity level
   * @param severity Severity level
   * @returns Bootstrap badge class
   */
  getSeverityBadgeClass(severity: IssueSeverity): string {
    const classes: Record<IssueSeverity, string> = {
      [IssueSeverity.LOW]: 'bg-success',
      [IssueSeverity.MEDIUM]: 'bg-warning',
      [IssueSeverity.HIGH]: 'bg-danger',
      [IssueSeverity.CRITICAL]: 'bg-dark',
    };
    return classes[severity] || 'bg-secondary';
  }

  goToCase(caze: Case): void {
    if (caze.id) {
      this.router.navigate(['/cases', caze.id]);
    }
  }

  viewCase(caze: Case): void {
    if (!caze.id) return;
    this.router.navigate(['/cases', caze.id]);
  }

  editCase(caze: Case): void {
    if (!caze.id) return;
    this.router.navigate(['/cases', caze.id, 'edit']);
  }

  async deleteCase(caze: Case): Promise<void> {
    if (!caze.id) return;
    const result = await this.confirm.confirm(
      this.translate.instant('caseList.delete_confirm', { title: caze.title }),
    );
    const confirmed: boolean = typeof result === 'boolean' ? result : false;
    if (!confirmed) return;
    this.caseService.deleteCase(caze.id).subscribe({
      next: () => {
        this.loadCases();
        this.loadStatistics();
      },
      error: (err) => console.error('Error deleting case', err),
    });
  }

  formatDate(value?: string | null): string {
    if (!value) return this.translate.instant('common.not_available');
    const parsed = new Date(value);
    if (Number.isNaN(parsed.getTime())) return this.translate.instant('common.not_available');
    return parsed.toLocaleDateString(undefined, {
      month: 'short',
      day: '2-digit',
      year: 'numeric',
    });
  }

  tStatus(status?: string | null): string {
    if (!status) return this.translate.instant('common.unknown');
    return this.translate.instant(`caseStatus.${status.toLowerCase()}`);
  }

  tSeverity(severity?: string | null): string {
    if (!severity) return this.translate.instant('common.not_available');
    return this.translate.instant(`issueSeverity.${severity.toLowerCase()}`);
  }
}
