import type { OnInit, OnDestroy } from '@angular/core';
import type { DriverStatsDto } from './driver-overview.models';

import { CommonModule } from '@angular/common';
import { ChangeDetectorRef, Component, ChangeDetectionStrategy, inject } from '@angular/core';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { of, Subject } from 'rxjs';
import { catchError, finalize, takeUntil } from 'rxjs/operators';
import { Router } from '@angular/router';
import { DriverOverviewService } from './driver-overview.service';
import type { UncompliantDriverDto } from './uncompliant-driver.dto';

interface DriverKpiCard {
  label: string;
  subtitle: string;
  metric: () => number;
}

@Component({
  selector: 'app-driver-overview',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './driver-overview.component.html',
  styleUrls: ['./driver-overview.component.scss'],
  imports: [CommonModule, MatButtonModule, MatIconModule],
})
export class DriverOverviewComponent implements OnInit, OnDestroy {
  private readonly overviewService = inject(DriverOverviewService);
  private readonly router = inject(Router);
  private readonly cdr = inject(ChangeDetectorRef);
  private readonly destroy$ = new Subject<void>();

  stats?: DriverStatsDto;
  loadingStats = false;
  errorMessage: string | null = null;
  uncompliantDrivers: UncompliantDriverDto[] = [];
  loadingUncompliant = false;
  uncompliantError: string | null = null;

  readonly fallbackStats: DriverStatsDto = {
    totalDrivers: 4,
    svEmployees: 1,
    partnerDrivers: 1,
    exitDrivers: 0,
    activeDrivers: 2,
    suspendedDrivers: 0,
    onlineDrivers: 1,
    onTripDrivers: 1,
    offlineDrivers: 1,
    expiredDocuments: 0,
    nearExpiryDocuments: 0,
    utilizationRate: 0,
  };

  ngOnInit() {
    this.loadStats();
    this.loadUncompliantDrivers();
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  get kpiCards(): DriverKpiCard[] {
    const stats = this.stats ?? this.fallbackStats;

    return [
      {
        label: 'Total Drivers',
        subtitle: 'All registered drivers',
        metric: () => stats.totalDrivers,
      },
      {
        label: 'Active Drivers',
        subtitle: 'Currently employed',
        metric: () => stats.activeDrivers,
      },
      {
        label: 'Online Drivers',
        subtitle: 'Actively available',
        metric: () => stats.onlineDrivers,
      },
      {
        label: 'On Trip',
        subtitle: 'Currently transporting passengers',
        metric: () => stats.onTripDrivers,
      },
      {
        label: 'Offline Drivers',
        subtitle: 'Not currently online',
        metric: () => stats.offlineDrivers,
      },
      {
        label: 'Expiring Documents',
        subtitle: 'Near expiration or expired',
        metric: () => stats.expiredDocuments + stats.nearExpiryDocuments,
      },
    ];
  }

  refresh() {
    this.loadStats();
    this.loadUncompliantDrivers();
  }

  private loadStats() {
    this.errorMessage = null;
    this.loadingStats = true;
    this.overviewService
      .getStats()
      .pipe(
        takeUntil(this.destroy$),
        catchError((error) => this.handleStatsError('driver statistics', error)),
        finalize(() => (this.loadingStats = false)),
      )
      .subscribe((stats) => {
        this.stats = stats ?? this.fallbackStats;
        this.cdr.markForCheck();
      });
  }

  private handleStatsError(operation: string, error: any) {
    console.error(`DriverOverviewService ${operation} error`, error);
    const message = error?.error?.message || error?.message || 'Unexpected error';
    this.errorMessage = `Failed to load ${operation}: ${message}`;
    return of(this.fallbackStats);
  }

  private loadUncompliantDrivers(limit = 100) {
    this.uncompliantError = null;
    this.loadingUncompliant = true;
    this.overviewService
      .getUncompliantDrivers(limit)
      .pipe(
        takeUntil(this.destroy$),
        catchError((error) => this.handleUncompliantError('uncompliant drivers', error)),
        finalize(() => (this.loadingUncompliant = false)),
      )
      .subscribe((items) => {
        this.uncompliantDrivers = items ?? [];
        this.cdr.markForCheck();
      });
  }

  private handleUncompliantError(operation: string, error: any) {
    console.error(`DriverOverviewService ${operation} error`, error);
    const message = error?.error?.message || error?.message || 'Unexpected error';
    this.uncompliantError = `Failed to load ${operation}: ${message}`;
    return of([]);
  }

  isDriverCompliant(driver: UncompliantDriverDto): boolean {
    const licenseStatus = driver.licenseStatus?.toLowerCase() ?? '';
    const idCardStatus = driver.idCardStatus?.toLowerCase() ?? '';
    const licenseOk = licenseStatus !== 'missing license' && licenseStatus !== 'expired';
    const idOk = !idCardStatus.includes('missing') && !idCardStatus.startsWith('id card expired');
    return licenseOk && idOk && (driver.expiredDocumentCount ?? 0) === 0 && driver.openIssues === 0;
  }

  getComplianceNotes(driver: UncompliantDriverDto): string[] {
    const notes: string[] = [];

    if (driver.openIssues > 0) {
      notes.push(`${driver.openIssues} open issue${driver.openIssues === 1 ? '' : 's'}`);
    }

    if ((driver.expiredDocumentCount ?? 0) > 0) {
      notes.push(
        `${driver.expiredDocumentCount} expired document${driver.expiredDocumentCount === 1 ? '' : 's'}`,
      );
    }

    if (driver.licenseStatus?.toLowerCase().includes('missing')) {
      notes.push('License missing');
    } else if (driver.licenseStatus === 'EXPIRED') {
      notes.push('License expired');
    }

    if (driver.idCardStatus?.toLowerCase().includes('missing')) {
      notes.push('ID card missing');
    } else if (driver.idCardStatus?.startsWith('ID CARD EXPIRED')) {
      notes.push(driver.idCardStatus);
    }

    return notes;
  }

  goToDriverDetails(driverId: number) {
    this.router.navigate(['/drivers', driverId]);
  }
}
