import { CommonModule } from '@angular/common';
import { Component, computed, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';

import type { Incident, IncidentFilter, IncidentStatistics } from '../../models/incident.model';
import { IncidentStatus, IncidentGroup, IssueSeverity } from '../../models/incident.model';
import { IncidentService } from '../../services/incident.service';
import { ConfirmService } from '@services/confirm.service';
import { NotificationService } from '@services/notification.service';

/**
 * Incident List Component
 *
 * Displays a comprehensive list of all incidents with:
 * - Statistics dashboard showing counts by status
 * - Advanced filtering (search, date range, status, group, severity, etc.)
 * - Sortable data table with pagination
 * - Drawer panel for quick incident preview
 * - Real-time status and SLA monitoring
 *
 * Features:
 * - Multiple tab views in drawer (overview, timeline, tasks, attachments, resolution)
 * - Responsive design with mobile support
 * - Export and bulk operations support
 *
 * Following Angular best practices:
 * - External template (incident-list.component.html)
 * - External styles (incident-list.component.css)
 * - Reactive signals for state management
 * - Standalone component architecture
 */
@Component({
  selector: 'app-incident-list',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './incident-list.component.html',
  styleUrls: ['./incident-list.component.css'],
})
export class IncidentListComponent {
  private notification = inject(NotificationService);
  // ============================================================
  // Dependency Injection
  // ============================================================
  private readonly incidentService = inject(IncidentService);
  private readonly router = inject(Router);
  private readonly confirm = inject(ConfirmService);

  // ============================================================
  // State Management (Signals)
  // ============================================================
  incidents = signal<Incident[]>([]);
  loading = signal(true);
  error = signal<string | null>(null);
  currentPage = signal(0);
  totalElements = signal(0);
  totalPages = signal(0);
  pageSize = 20;
  lastUpdated = new Date();

  // Statistics
  statistics = signal<IncidentStatistics | null>(null);

  // Expose enums to template
  IncidentStatus = IncidentStatus;
  IssueSeverity = IssueSeverity;
  IncidentGroup = IncidentGroup;

  // ============================================================
  // Filter Configuration
  // ============================================================
  statuses = Object.values(IncidentStatus);
  groups = Object.values(IncidentGroup);
  severities = Object.values(IssueSeverity);
  filters: IncidentFilter = {};

  // ============================================================
  // Drawer State
  // ============================================================
  selectedIncident = signal<Incident | null>(null);
  activeTab = signal<'overview' | 'timeline' | 'tasks' | 'attachments' | 'resolution'>('overview');

  // ============================================================
  // Lifecycle Hooks
  // ============================================================
  /**
   * Initialize component data on load
   */
  ngOnInit() {
    this.loadIncidents();
    this.loadStatistics();
  }

  // ============================================================
  // Navigation Methods
  // ============================================================
  /**
   * Navigate to incident creation page
   */
  navigateToCreate() {
    this.router.navigate(['/incidents/create']);
  }

  /**
   * Navigate to incident edit page
   * @param incident Incident to edit
   */
  editIncident(incident: Incident) {
    this.router.navigate(['/incidents', incident.id, 'edit']);
  }

  /**
   * Delete incident with confirmation
   * @param incident Incident to delete
   */
  async deleteIncident(incident: Incident): Promise<void> {
    if (
      !(await this.confirm.confirm(
        `Are you sure you want to delete incident "${incident.title}"? This action cannot be undone.`,
      ))
    )
      return;
    this.incidentService.deleteIncident(incident.id!).subscribe({
      next: () => {
        this.loadIncidents();
        this.loadStatistics();
      },
      error: (err) => {
        console.error('Error deleting incident:', err);
        this.notification.simulateNotification(
          'Error',
          'Failed to delete incident. Please try again.',
        );
      },
    });
  }

  // ============================================================
  // Drawer Methods
  // ============================================================
  /**
   * Navigate to incident detail page
   * @param incident Incident to view
   */
  openDrawer(incident: Incident) {
    this.router.navigate(['/incidents', incident.id]);
  }

  /**
   * Close the drawer panel
   */
  closeDrawer() {
    this.selectedIncident.set(null);
  }

  /**
   * Set active tab in drawer
   * @param tab Tab to activate
   */
  setActiveTab(tab: 'overview' | 'timeline' | 'tasks' | 'attachments' | 'resolution') {
    this.activeTab.set(tab);
  }

  // ============================================================
  // Data Loading Methods
  // ============================================================
  /**
   * Load incidents with current filters and pagination
   */
  loadIncidents() {
    this.loading.set(true);
    this.error.set(null);

    this.incidentService.listIncidents(this.filters, this.currentPage(), this.pageSize).subscribe({
      next: (response) => {
        this.incidents.set(response.data.content);
        this.totalElements.set(response.data.totalElements);
        this.totalPages.set(response.data.totalPages);
        this.loading.set(false);
        this.lastUpdated = new Date();
      },
      error: (err) => {
        this.error.set('Failed to load incidents.');
        this.loading.set(false);
        console.error('Error loading incidents:', err);
      },
    });
  }

  /**
   * Load incident statistics for dashboard cards
   */
  loadStatistics() {
    this.incidentService.getStatistics(this.filters).subscribe({
      next: (response) => {
        this.statistics.set(response.data);
      },
      error: (err) => {
        console.error('Error loading statistics:', err);
        // Don't show error to user, just log it
      },
    });
  }

  // ============================================================
  // Filter Methods
  // ============================================================
  /**
   * Apply current filters and reload data
   */
  applyFilters() {
    this.currentPage.set(0);
    this.loadIncidents();
    this.loadStatistics();
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
      this.loadIncidents();
    }
  }

  // ============================================================
  // Statistics Helper Methods
  // ============================================================
  /**
   * Get count of incidents by status
   * @param status Incident status
   * @returns Count of incidents with status
   */
  getStatusCount(status: IncidentStatus): number {
    return this.incidents().filter((i) => i.incidentStatus === status).length;
  }

  /**
   * Get count of incidents by severity
   * @param severity Severity level
   * @returns Count of incidents with severity
   */
  getCount(severity: IssueSeverity): number {
    return this.incidents().filter((i) => i.severity === severity).length;
  }

  /**
   * Get count of incidents by group
   * @param group Incident group
   * @returns Count of incidents in group
   */
  getGroupCount(group: IncidentGroup): number {
    return this.incidents().filter((i) => i.incidentGroup === group).length;
  }

  // ============================================================
  // UI Helper Methods
  // ============================================================
  /**
   * Get Bootstrap badge class for incident status
   * @param status Incident status
   * @returns Bootstrap badge class
   */
  getStatusBadgeClass(status: IncidentStatus): string {
    const map: Record<string, string> = {
      NEW: 'badge-status-new',
      VALIDATED: 'badge-status-validated',
      UNDER_INVESTIGATION: 'badge-status-investigation',
      RESOLVED: 'badge-status-resolved',
      CLOSED: 'badge-status-closed',
      ESCALATED: 'badge-status-escalated',
    };
    return map[status] || 'badge-status-new';
  }

  /**
   * Get Bootstrap badge class for severity level
   * @param severity Severity level
   * @returns Bootstrap badge class
   */
  getSeverityBadgeClass(severity: IssueSeverity): string {
    const map: Record<string, string> = {
      CRITICAL: 'badge-priority-critical',
      HIGH: 'badge-priority-high',
      MEDIUM: 'badge-priority-medium',
      LOW: 'badge-priority-low',
    };
    return map[severity] || 'badge-priority-medium';
  }

  /**
   * Format incident group for display
   * @param group Incident group enum value
   * @returns Formatted display string
   */
  formatGroup(group: IncidentGroup): string {
    return group.replace(/_/g, ' ');
  }

  /**
   * Format incident status for display
   * @param status Incident status enum value
   * @returns Formatted display string
   */
  formatStatus(status: IncidentStatus): string {
    return status.replace(/_/g, ' ');
  }

  /**
   * Format incident type for display
   * @param type Incident type enum value
   * @returns Formatted display string
   */
  formatIncidentType(type: string): string {
    return type.replace(/_/g, ' ');
  }

  /**
   * Format date flexibly - supports custom formats
   *
   * @param date Date to format (string, Date, or array from backend)
   * @param format Format string - flexible and customizable
   *
   * **Supported Formats:**
   * - `'DD-MMM-YYYY'` → "01-DEC-2025" (current default)
   * - `'DD/MM/YYYY'` → "01/12/2025"
   * - `'YYYY-MM-DD'` → "2025-12-01"
   * - `'DD-MMM-YYYY HH:mm'` → "01-DEC-2025 14:30"
   * - `'MM/DD/YY HH:mm:ss'` → "12/01/25 14:30:45"
   *
   * **Format Tokens:**
   * - `YYYY` = Full year (2025)
   * - `YY` = Short year (25)
   * - `MMM` = Short month name (DEC)
   * - `MM` = Month number (12)
   * - `DD` = Day (01)
   * - `HH` = Hours (14)
   * - `mm` = Minutes (30)
   * - `ss` = Seconds (45)
   *
   * @returns Formatted date string
   *
   * @example
   * ```typescript
   * // Change default format:
   * formatDate(incident.createdAt, 'DD-MMM-YYYY')     // "01-DEC-2025"
   * formatDate(incident.createdAt, 'DD/MM/YYYY')      // "01/12/2025"
   * formatDate(incident.createdAt, 'YYYY-MM-DD HH:mm') // "2025-12-01 14:30"
   * ```
   */
  formatDate(date: any, format: string = 'DD-MMM-YYYY'): string {
    if (!date) return '';

    let d: Date;

    // Handle backend array format [2025,12,6,23,10,36,440669000]
    if (Array.isArray(date)) {
      d = new Date(date[0], date[1] - 1, date[2], date[3] || 0, date[4] || 0, date[5] || 0);
    } else {
      d = new Date(date);
    }

    if (isNaN(d.getTime())) return '';

    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    const pad = (n: number) => n.toString().padStart(2, '0');

    return format
      .replace('YYYY', d.getFullYear().toString())
      .replace('YY', d.getFullYear().toString().slice(-2))
      .replace('MMM', months[d.getMonth()])
      .replace('MM', pad(d.getMonth() + 1))
      .replace('DD', pad(d.getDate()))
      .replace('HH', pad(d.getHours()))
      .replace('mm', pad(d.getMinutes()))
      .replace('ss', pad(d.getSeconds()));
  }

  // ============================================================
  // SLA Helper Methods
  // ============================================================
  /**
   * Calculate ETA close based on severity and creation time
   * SLA targets: CRITICAL=2h, HIGH=4h, MEDIUM=8h, LOW=24h
   * @param incident Incident to calculate ETA for
   * @returns Expected close date or null
   */
  getETAClose(incident: Incident): Date | null {
    if (incident.resolvedAt) {
      return new Date(incident.resolvedAt);
    }

    if (!incident.reportedAt) {
      return null;
    }

    const createdDate = new Date(incident.reportedAt);
    const slaHours: Record<string, number> = {
      CRITICAL: 2,
      HIGH: 4,
      MEDIUM: 8,
      LOW: 24,
    };

    const hoursToAdd = slaHours[incident.severity] || 24;
    const etaClose = new Date(createdDate);
    etaClose.setHours(etaClose.getHours() + hoursToAdd);

    return etaClose;
  }

  /**
   * Get SLA status for an incident
   * @param incident Incident to check
   * @returns SLA status text
   */
  getSLAStatus(incident: Incident): string {
    if (incident.resolvedAt) {
      const resolved = new Date(incident.resolvedAt);
      const eta = this.getETAClose(incident);
      if (eta && resolved <= eta) {
        return 'Within SLA';
      }
      return 'Overdue (resolved late)';
    }

    const now = new Date();
    const eta = this.getETAClose(incident);

    if (!eta) {
      return 'Unknown';
    }

    const hoursRemaining = (eta.getTime() - now.getTime()) / (1000 * 60 * 60);

    if (hoursRemaining < 0) {
      return 'Overdue';
    } else if (hoursRemaining <= 4) {
      return `Due in ${Math.ceil(hoursRemaining)}h`;
    } else {
      return 'Within SLA';
    }
  }

  /**
   * Get chip class for SLA status
   * @param incident Incident to check
   * @returns CSS class for SLA chip
   */
  getSLAChipClass(incident: Incident): string {
    const status = this.getSLAStatus(incident);

    if (status.includes('Overdue')) {
      return 'chip-error';
    } else if (status.includes('Due in')) {
      return 'chip-warning';
    } else if (status.includes('Within SLA')) {
      return 'chip-success';
    }

    return 'chip-neutral';
  }
}
