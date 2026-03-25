import { CommonModule } from '@angular/common';
import type { OnInit } from '@angular/core';
import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms';

import type { AuditTrail } from '../../models/audit-trail.model';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { AuditTrailService } from '../../services/audit-trail.service';

@Component({
  selector: 'app-audit-trails',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './audit-trails.component.html',
  styleUrls: ['./audit-trails.component.css'],
})
export class AuditTrailsComponent implements OnInit {
  auditTrails: AuditTrail[] = [];
  filteredAuditTrails: AuditTrail[] = [];
  loading = false;
  error: string | null = null;
  filter = {
    username: '',
    action: '',
    resourceType: '',
    startDate: '',
    endDate: '',
  };

  constructor(private auditTrailService: AuditTrailService) {}

  ngOnInit(): void {
    this.loadAuditTrails();
  }

  loadAuditTrails(): void {
    this.loading = true;
    this.error = null;

    this.auditTrailService.getAllAuditTrails().subscribe({
      next: (auditTrails: AuditTrail[]) => {
        this.auditTrails = auditTrails;
        this.filteredAuditTrails = [...auditTrails];
        this.applyFilters();
        this.loading = false;
      },
      error: (error: any) => {
        this.error = 'Failed to load audit trails';
        this.loading = false;
        console.error('Error loading audit trails:', error);
      },
    });
  }

  applyFilters(): void {
    this.filteredAuditTrails = this.auditTrails.filter((trail) => {
      // Username filter
      if (
        this.filter.username &&
        !trail.username.toLowerCase().includes(this.filter.username.toLowerCase())
      ) {
        return false;
      }

      // Action filter
      if (
        this.filter.action &&
        !trail.action.toLowerCase().includes(this.filter.action.toLowerCase())
      ) {
        return false;
      }

      // Resource type filter
      if (
        this.filter.resourceType &&
        !trail.resourceType.toLowerCase().includes(this.filter.resourceType.toLowerCase())
      ) {
        return false;
      }

      // Date range filter
      if (this.filter.startDate || this.filter.endDate) {
        const trailDate = new Date(trail.timestamp);

        if (this.filter.startDate) {
          const startDate = new Date(this.filter.startDate);
          if (trailDate < startDate) {
            return false;
          }
        }

        if (this.filter.endDate) {
          const endDate = new Date(this.filter.endDate);
          if (trailDate > endDate) {
            return false;
          }
        }
      }

      return true;
    });
  }

  clearFilters(): void {
    this.filter = {
      username: '',
      action: '',
      resourceType: '',
      startDate: '',
      endDate: '',
    };
    this.filteredAuditTrails = [...this.auditTrails];
  }

  formatDate(dateString: string): string {
    const date = new Date(dateString);
    return date.toLocaleString();
  }

  formatDetails(details: string): string {
    if (!details) return '';

    // Truncate long details
    if (details.length > 100) {
      return details.substring(0, 100) + '...';
    }

    return details;
  }
}
