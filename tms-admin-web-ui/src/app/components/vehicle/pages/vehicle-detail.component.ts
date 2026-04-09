/* eslint-disable @typescript-eslint/consistent-type-imports */
import { CommonModule, formatDate } from '@angular/common';
import {
  AfterViewInit,
  Component,
  Inject,
  LOCALE_ID,
  OnDestroy,
  OnInit,
  inject,
} from '@angular/core';
import {
  FormBuilder,
  FormGroup,
  FormsModule,
  ReactiveFormsModule,
  Validators,
} from '@angular/forms';
import { MatSnackBar } from '@angular/material/snack-bar';
import { ActivatedRoute, Router, RouterModule } from '@angular/router';
import { NgSelectModule } from '@ng-select/ng-select';
import { ConfirmService } from '@services/confirm.service';
import { NotificationService } from '@services/notification.service';
import type { Subscription } from 'rxjs';
import { forkJoin, of } from 'rxjs';
import { catchError } from 'rxjs/operators';

import type { Document } from '../../../models/document.model';
import type { Driver } from '../../../models/driver.model';
import type { MaintenanceTask } from '../../../models/maintenance-task.model';
import type { Vehicle } from '../../../models/vehicle.model';
import type { VehicleFuelLog } from '../../../models/vehicle-fuel-log.model';
import { VehicleType, VehicleStatus } from '../../../models/enums/vehicle.enums';

type DocumentStatusFilter = 'all' | 'active' | 'expired';
const MS_IN_DAY = 1000 * 60 * 60 * 24;

interface DriverHistoryEntry {
  driverId?: number;
  driverName?: string;
  driverFullName?: string;
  driverFirstName?: string;
  driverLastName?: string;
  driverLicenseNumber?: string;
  vehicleId?: number;
  truckPlate?: string;
  truckModel?: string;
  assignedAt?: string;
  assignedBy?: string;
  reason?: string;
  active?: boolean;
  revokedAt?: string;
  revokedBy?: string;
  revokeReason?: string;
}
import { DocumentService } from '../../../services/document.service';
import { DriverService } from '../../../services/driver.service';
import { MaintenanceTaskService } from '../../../services/maintenance-task.service';
import {
  PmPlanService,
  type PMExecutionLogDto,
  type PreventiveMaintenancePlanDto,
} from '../../../services/pm-plan.service';
import { VehicleDriverService } from '../../../services/vehicle-driver.service';
import type { AssignmentRequest } from '../../../services/vehicle-driver.service';
import { VehicleService } from '../../../services/vehicle.service';

@Component({
  selector: 'app-vehicle-detail',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, FormsModule, RouterModule, NgSelectModule],
  templateUrl: './vehicle-detail.component.html',
  styleUrls: ['./vehicle-detail.component.css'],
})
export class VehicleDetailComponent implements OnInit, AfterViewInit, OnDestroy {
  navigateToSetupVehicle(): void {
    if (this.vehicleId) {
      this.router.navigate(['/fleet/vehicles', this.vehicleId, 'setup']);
    }
  }
  private confirm = inject(ConfirmService);
  private notification = inject(NotificationService);
  vehicleId!: number;
  vehicle: Vehicle | null = null;
  vehicleForm!: FormGroup;
  editMode = false;
  errorMessage = '';

  // Query-group driven UI like customer-view: profile, driver-history, maintenance, fuel, documents, cost-summary
  activeGroup:
    | 'profile'
    | 'driver-history'
    | 'maintenance'
    | 'fuel'
    | 'documents'
    | 'cost-summary' = 'profile';
  private groupSub: Subscription | null = null;
  compactView = false; // when true, show primary info only

  // Enums for template use
  VehicleStatus = VehicleStatus;
  VehicleType = VehicleType;
  private readonly vehicleStatusValues = Object.values(VehicleStatus) as VehicleStatus[];
  // UI state
  activeAnchor = 'info';
  mobileNavOpen = false;

  // Group data stubs
  driverHistoryLoading = false;
  driverHistory: DriverHistoryEntry[] = [];
  driverHistoryPage = 0;
  driverHistoryPageSize = 10;
  driverHistoryTotalPages = 1;
  driverHistoryTotalElements = 0;
  driverHistorySearchTerm = '';
  driverHistoryFilter: 'all' | 'active' | 'revoked' = 'all';
  private driverHistorySearchTimer: any = null;
  driverHistoryRevokeInProgress: number | null = null;
  // Assignment modal
  assignmentModalOpen = false;
  assignmentForm!: FormGroup;
  assignmentSubmitting = false;
  assignmentError = '';

  maintenanceLoading = false;
  maintenanceRecords: MaintenanceTask[] = [];

  fuelLoading = false;
  fuelLogs: VehicleFuelLog[] = [];
  fuelLogRows: Array<{
    raw: VehicleFuelLog;
    dateLabel: string;
    odometerKm?: number | null;
    liters?: number | null;
    amount?: number | null;
    station?: string | null;
    distanceSinceLast?: number | null;
  }> = [];
  fuelForm!: FormGroup;
  fuelFormOpen = false;
  fuelFormMode: 'create' | 'edit' = 'create';
  fuelFormSubmitting = false;
  fuelFormError = '';
  fuelEditingId: number | null = null;

  costSummaryLoading = false;
  costSummary: any | null = null;

  // UI controls (search + page size) for the left-card
  searchQuery = '';
  pageSize = 10;
  private searchDebounceTimer: any = null;

  private observer?: IntersectionObserver;
  driverPickerOpen = false;
  driverCandidates: Driver[] = [];
  driverSearchTerm = '';
  loadingDrivers = false;
  maintenanceTasks: MaintenanceTask[] = [];
  loadingMaintenance = false;
  maintenanceSummary = {
    nextDueLabel: '',
    overdueCount: 0,
    upcomingCount: 0,
    completedCount: 0,
    totalCount: 0,
  };
  maintenanceFilters = {
    search: '',
    status: 'all',
    sort: 'due-asc',
  };
  pmPlans: PreventiveMaintenancePlanDto[] = [];
  pmHistory: Array<PMExecutionLogDto & { planName?: string }> = [];
  pmNextDueLabel = '';
  loadingPm = false;
  documentFilters: { search: string; status: DocumentStatusFilter; type: string } = {
    search: '',
    status: 'all',
    type: 'all',
  };
  filteredDocuments: Document[] = [];
  lastSyncedAt: string | null = null;
  readonly primaryDocumentTypes = ['REGISTRATION', 'INSURANCE', 'PERMIT', 'CERTIFICATION'];
  documentForm!: FormGroup;
  documentFormVisible = false;
  documentFormMode: 'create' | 'edit' = 'create';
  documentFormSubmitting = false;
  selectedDocument: Document | null = null;
  maintenanceForm!: FormGroup;
  maintenanceFormVisible = false;
  maintenanceFormMode: 'create' | 'edit' = 'create';
  maintenanceFormSubmitting = false;
  maintenanceFormError = '';
  selectedMaintenanceTask: MaintenanceTask | null = null;

  get filteredDriverCandidates(): Driver[] {
    const term = this.driverSearchTerm.trim().toLowerCase();
    if (!term) {
      return this.driverCandidates;
    }
    return this.driverCandidates.filter((driver) => {
      const fullName = (driver.fullName ?? driver.name ?? '').toLowerCase();
      const phoneText = driver.phone ? driver.phone.toLowerCase() : '';
      return fullName.includes(term) || phoneText.includes(term);
    });
  }

  assignmentSearchFn = (term: string, item: Driver): boolean => {
    const needle = (term ?? '').trim().toLowerCase();
    if (!needle) return true;
    const name = (item.fullName ?? item.name ?? '').toLowerCase();
    const phone = item.phone ? item.phone.toLowerCase() : '';
    const license = (item.licenseNumber ?? '').toLowerCase();
    return name.includes(needle) || phone.includes(needle) || license.includes(needle);
  };

  trackDriverById(index: number, driver: Driver): number {
    return driver?.id ?? index;
  }

  constructor(
    private route: ActivatedRoute,
    public router: Router,
    private vehicleService: VehicleService,
    private driverService: DriverService,
    private maintenanceTaskService: MaintenanceTaskService,
    private pmPlanService: PmPlanService,
    private documentService: DocumentService,
    private vehicleDriverService: VehicleDriverService,
    private fb: FormBuilder,
    private snackBar: MatSnackBar,
    @Inject(LOCALE_ID) private locale: string,
  ) {}

  ngOnInit(): void {
    const id = this.route.snapshot.paramMap.get('id');
    this.vehicleId = id ? +id : NaN;

    if (isNaN(this.vehicleId)) {
      this.errorMessage = 'Invalid vehicle ID.';
      return;
    }

    // watch query param `group` to mirror customer-view behaviour
    this.groupSub = this.route.queryParamMap.subscribe((qpm) => {
      const g = (qpm.get('group') ?? '').trim();
      const clean = (qpm.get('clean') ?? '').trim().toLowerCase();
      this.compactView = clean === '1' || clean === 'true' || clean === 'yes';
      const next: VehicleDetailComponent['activeGroup'] =
        g === 'driver-history'
          ? 'driver-history'
          : g === 'maintenance'
            ? 'maintenance'
            : g === 'fuel'
              ? 'fuel'
              : g === 'documents'
                ? 'documents'
                : g === 'cost-summary'
                  ? 'cost-summary'
                  : 'profile';

      if (this.activeGroup !== next) {
        this.activeGroup = next;
        this.ensureGroupDataLoaded();
      }
    });

    this.initializeAssignmentForm();
    this.initFuelForm();
    this.fetchVehicleDetail();

    // If a fragment is present, try to scroll to it after view initializes
    this.route.fragment.subscribe((frag) => {
      if (frag) {
        // Defer to allow DOM to render
        setTimeout(() => this.scrollTo(frag), 300);
      }
    });
  }

  private initFuelForm(): void {
    this.fuelForm = this.fb.group({
      filledAt: [''],
      odometerKm: ['', [Validators.required, Validators.min(0)]],
      liters: ['', [Validators.min(0)]],
      amount: ['', [Validators.min(0)]],
      station: [''],
      notes: [''],
    });
  }

  ngAfterViewInit(): void {
    // Observe major sections and update activeAnchor when they intersect
    try {
      const ids = ['info', 'capacity', 'assignment', 'service', 'routes', 'documents', 'tracking'];
      const options: IntersectionObserverInit = {
        root: null,
        rootMargin: '-20% 0px -60% 0px',
        threshold: [0.1, 0.25, 0.5],
      };

      this.observer = new IntersectionObserver((entries) => {
        // pick the entry with largest intersectionRatio that's intersecting
        const visible = entries
          .filter((e) => e.isIntersecting)
          .sort((a, b) => b.intersectionRatio - a.intersectionRatio);

        if (visible.length > 0) {
          const id = visible[0].target.id;
          if (id) this.activeAnchor = id;
        }
      }, options);

      ids.forEach((id) => {
        const el = document.getElementById(id);
        if (el) this.observer?.observe(el);
      });
    } catch (err) {
      // fail gracefully
      console.warn('IntersectionObserver setup failed', err);
    }
  }

  ngOnDestroy(): void {
    try {
      this.observer?.disconnect();
    } catch (err) {
      /* ignore */
    }
    this.groupSub?.unsubscribe();
    this.groupSub = null;
  }

  private ensureGroupDataLoaded(): void {
    if (!this.vehicle?.id) return;
    switch (this.activeGroup) {
      case 'driver-history':
        if (!this.driverHistoryLoading && this.driverHistory.length === 0) this.loadDriverHistory();
        break;
      case 'maintenance':
        if (!this.maintenanceLoading && this.maintenanceRecords.length === 0)
          this.loadMaintenance();
        break;
      case 'fuel':
        if (!this.fuelLoading && this.fuelLogs.length === 0) this.loadFuelLogs();
        break;
      case 'documents':
        // documents use existing navigation helper; keep lightweight
        break;
      case 'cost-summary':
        if (!this.costSummaryLoading && !this.costSummary) this.loadCostSummary();
        break;
      default:
        break;
    }
  }

  private loadDriverHistory(): void {
    if (!this.vehicleId) {
      this.driverHistory = [];
      return;
    }

    this.driverHistoryLoading = true;
    const activeStatus =
      this.driverHistoryFilter === 'active'
        ? 'active'
        : this.driverHistoryFilter === 'revoked'
          ? 'revoked'
          : 'all';
    this.vehicleService
      .getDriverHistory(
        this.vehicleId,
        this.driverHistoryPage,
        this.driverHistoryPageSize,
        this.driverHistorySearchTerm,
        activeStatus,
      )
      .subscribe({
        next: (res) => {
          const payload = res && (res as any).data ? (res as any).data : (res as any);
          const entries = payload?.content ?? [];
          this.driverHistory = entries.map((entry: any) => this.normalizeDriverHistoryEntry(entry));
          this.updateDriverHistoryPageInfo(payload);
          this.driverHistoryLoading = false;
        },
        error: (err) => {
          console.error('Driver history load failed', err);
          this.driverHistory = [];
          this.driverHistoryLoading = false;
        },
      });
  }

  private loadMaintenance(): void {
    if (!this.vehicleId) {
      this.maintenanceRecords = [];
      this.maintenanceSummary = {
        nextDueLabel: '',
        overdueCount: 0,
        upcomingCount: 0,
        completedCount: 0,
        totalCount: 0,
      };
      return;
    }

    this.maintenanceLoading = true;
    this.maintenanceTaskService
      .getTasks(0, this.pageSize, { vehicleId: this.vehicleId })
      .subscribe({
        next: (res) => {
          const payload = res?.data?.content ?? [];
          this.maintenanceRecords = payload;
          this.updateMaintenanceSummary(payload);
          this.maintenanceLoading = false;
        },
        error: (err) => {
          console.error('Maintenance records load failed', err);
          this.maintenanceRecords = [];
          this.maintenanceSummary = {
            nextDueLabel: '',
            overdueCount: 0,
            upcomingCount: 0,
            completedCount: 0,
            totalCount: 0,
          };
          this.maintenanceLoading = false;
        },
      });
  }

  private loadFuelLogs(): void {
    this.fuelLoading = true;
    this.vehicleService.getFuelLogs(this.vehicleId, 0, this.pageSize, this.searchQuery).subscribe({
      next: (res) => {
        const payload = res && (res as any).data ? (res as any).data : (res as any);
        this.fuelLogs = payload?.content ?? [];
        this.fuelLogRows = this.buildFuelLogRows(this.fuelLogs);
        this.fuelLoading = false;
      },
      error: (err) => {
        console.error('Fuel logs load failed', err);
        this.fuelLogs = [];
        this.fuelLogRows = [];
        this.fuelLoading = false;
      },
    });
  }

  openFuelForm(mode: 'create' | 'edit', log?: VehicleFuelLog): void {
    this.fuelFormError = '';
    this.fuelFormMode = mode;
    this.fuelEditingId = log?.id ?? null;
    this.fuelForm.reset({
      filledAt: log?.filledAt ?? '',
      odometerKm: log?.odometerKm ?? '',
      liters: log?.liters ?? '',
      amount: log?.amount ?? '',
      station: log?.station ?? '',
      notes: log?.notes ?? '',
    });
    this.fuelFormOpen = true;
  }

  closeFuelForm(): void {
    this.fuelFormOpen = false;
    this.fuelFormError = '';
    this.fuelEditingId = null;
  }

  submitFuelForm(): void {
    if (!this.vehicleId) return;
    if (this.fuelForm.invalid) {
      this.fuelFormError = 'Odometer KM is required.';
      return;
    }
    this.fuelFormSubmitting = true;
    this.fuelFormError = '';

    const payload: Partial<VehicleFuelLog> = {
      vehicleId: this.vehicleId,
      filledAt: this.fuelForm.value.filledAt || null,
      odometerKm: this.fuelForm.value.odometerKm,
      liters: this.fuelForm.value.liters || null,
      amount: this.fuelForm.value.amount || null,
      station: this.fuelForm.value.station || null,
      notes: this.fuelForm.value.notes || null,
    };

    const request =
      this.fuelFormMode === 'edit' && this.fuelEditingId
        ? this.vehicleService.updateFuelLog(this.vehicleId, this.fuelEditingId, payload)
        : this.vehicleService.createFuelLog(this.vehicleId, payload);

    request.subscribe({
      next: () => {
        this.fuelFormSubmitting = false;
        this.closeFuelForm();
        this.loadFuelLogs();
      },
      error: (err) => {
        console.error('Fuel log save failed', err);
        this.fuelFormSubmitting = false;
        this.fuelFormError = 'Failed to save fuel log.';
      },
    });
  }

  async deleteFuelLog(log: VehicleFuelLog): Promise<void> {
    if (!this.vehicleId || !log?.id) return;
    if (!(await this.confirm.confirm('Delete fuel log? This action cannot be undone.'))) {
      return;
    }
    this.vehicleService.deleteFuelLog(this.vehicleId, log.id!).subscribe({
      next: () => this.loadFuelLogs(),
      error: () => {
        this.notification.error('Failed to delete fuel log.');
      },
    });
  }

  private buildFuelLogRows(logs: VehicleFuelLog[]): Array<{
    raw: VehicleFuelLog;
    dateLabel: string;
    odometerKm?: number | null;
    liters?: number | null;
    amount?: number | null;
    station?: string | null;
    distanceSinceLast?: number | null;
  }> {
    type NormalizedFuelRow = {
      raw: VehicleFuelLog;
      date: string | null;
      odometerKm?: number | null;
      liters?: number | null;
      amount?: number | null;
      station?: string | null;
      distanceSinceLast?: number | null;
    };

    const normalized: NormalizedFuelRow[] = (logs || []).map((log) => {
      const date = this.getFuelLogDate(log);
      return {
        raw: log,
        date,
        odometerKm: log?.odometerKm ?? null,
        liters: log?.liters ?? null,
        amount: log?.amount ?? null,
        station: log?.station ?? null,
        distanceSinceLast: null,
      };
    });

    normalized.sort((a, b) => {
      const aTime = a.date ? new Date(a.date).getTime() : 0;
      const bTime = b.date ? new Date(b.date).getTime() : 0;
      return bTime - aTime;
    });

    for (let i = 0; i < normalized.length; i += 1) {
      const current = normalized[i];
      const next = normalized[i + 1];
      if (current?.odometerKm != null && next?.odometerKm != null) {
        current.distanceSinceLast = current.odometerKm - next.odometerKm;
      } else {
        current.distanceSinceLast = null;
      }
    }

    return normalized.map((row) => ({
      raw: row.raw,
      dateLabel: row.date ? this.safeFormatDate(row.date) : '—',
      odometerKm: row.odometerKm,
      liters: row.liters,
      amount: row.amount,
      station: row.station,
      distanceSinceLast: row.distanceSinceLast,
    }));
  }

  private getFuelLogDate(log: VehicleFuelLog): string | null {
    return log?.filledAt ?? log?.createdAt ?? null;
  }

  private safeFormatDate(value: string | Date): string {
    try {
      return formatDate(value, 'MMM d, y', this.locale);
    } catch {
      return String(value);
    }
  }

  private loadCostSummary(): void {
    this.costSummaryLoading = true;
    this.vehicleService.getCostSummary(this.vehicleId).subscribe({
      next: (res) => {
        const payload = res && (res as any).data ? (res as any).data : (res as any);
        this.costSummary = payload ?? null;
        this.costSummaryLoading = false;
      },
      error: (err) => {
        console.error('Cost summary load failed', err);
        this.costSummary = null;
        this.costSummaryLoading = false;
      },
    });
  }

  applyDocumentFilters(): void {
    const docs = this.vehicle?.documents ?? [];
    const search = (this.documentFilters.search ?? '').trim().toLowerCase();
    this.filteredDocuments = docs.filter((doc) => {
      if (this.documentFilters.type !== 'all' && doc.documentType !== this.documentFilters.type) {
        return false;
      }
      if (
        this.documentFilters.status !== 'all' &&
        this.getDocumentStatus(doc) !== this.documentFilters.status
      ) {
        return false;
      }
      if (search) {
        const haystack = `${doc.documentType ?? ''} ${doc.fileName ?? ''}`.toLowerCase();
        if (!haystack.includes(search)) {
          return false;
        }
      }
      return true;
    });
    this.lastSyncedAt = this.formatLastSynced(docs);
  }

  get documentTypeOptions(): string[] {
    const docs = this.vehicle?.documents ?? [];
    const types = Array.from(new Set(docs.map((doc) => doc.documentType).filter(Boolean)));
    return Array.from(new Set([...this.primaryDocumentTypes, ...types]));
  }

  isDocumentRecent(doc?: Document): boolean {
    if (!doc?.uploadedDate) return false;
    const days = (Date.now() - new Date(doc.uploadedDate).getTime()) / MS_IN_DAY;
    return days <= 30;
  }

  formatDocumentDate(value?: string | Date): string {
    if (!value) {
      return 'Not uploaded yet';
    }
    try {
      return formatDate(value, 'MMM d, y', this.locale);
    } catch {
      return String(value);
    }
  }

  private parseDocumentTimestamp(value?: string | Date): number {
    if (!value) return 0;
    const parsed = new Date(value).getTime();
    return Number.isNaN(parsed) ? 0 : parsed;
  }

  formatLastSynced(docs: Document[]): string | null {
    const timestamps = docs
      .map((doc) => doc.uploadedDate)
      .filter(Boolean)
      .map((value) => new Date(value ?? '').getTime());
    const latest = timestamps.length ? Math.max(...timestamps) : 0;
    if (!latest) return null;
    return formatDate(latest, 'MMM d, y, h:mm a', this.locale);
  }

  private getDocumentStatus(doc: Document): DocumentStatusFilter {
    if (!doc) return 'expired';
    const now = Date.now();
    if (doc.expiryDate) {
      const expiry = this.parseDocumentTimestamp(doc.expiryDate);
      if (expiry && expiry >= now) return 'active';
      return 'expired';
    }
    if (doc.uploadedDate) {
      const ageDays = (now - this.parseDocumentTimestamp(doc.uploadedDate)) / MS_IN_DAY;
      return ageDays <= 365 ? 'active' : 'expired';
    }
    return 'expired';
  }

  documentStatusLabel(doc?: Document): string {
    if (!doc) return 'Not uploaded';
    return this.getDocumentStatus(doc) === 'active' ? 'Active' : 'Expired';
  }

  documentStatusClass(doc?: Document): string {
    const status = doc ? this.getDocumentStatus(doc) : 'expired';
    return status === 'active'
      ? 'border-green-200 bg-green-50 text-green-700'
      : 'border-red-200 bg-red-50 text-red-700';
  }

  getDocumentUrl(doc?: Document): string | null {
    if (!doc) return null;
    return doc.fileUrl || doc.documentUrl || null;
  }

  get totalDocuments(): number {
    return this.vehicle?.documents?.length ?? 0;
  }

  get activeDocuments(): number {
    const docs = this.vehicle?.documents ?? [];
    return docs.filter((doc) => this.getDocumentStatus(doc) === 'active').length;
  }

  get expiredDocuments(): number {
    const docs = this.vehicle?.documents ?? [];
    return docs.filter((doc) => this.getDocumentStatus(doc) === 'expired').length;
  }

  get missingRequiredDocuments(): string[] {
    const docs = this.vehicle?.documents ?? [];
    const types = new Set(docs.map((doc) => doc.documentType));
    return this.primaryDocumentTypes.filter((type) => !types.has(type));
  }

  get missingRequiredDocumentsLabel(): string {
    const missing = this.missingRequiredDocuments;
    if (!missing.length) return '';
    return missing.map((type) => this.documentTypeLabel(type)).join(', ');
  }

  clearDocumentFilters(): void {
    this.documentFilters = { search: '', status: 'all', type: 'all' };
    this.applyDocumentFilters();
  }

  formatAssignmentDate(value?: string | Date | null): string {
    if (!value) return '—';
    try {
      return formatDate(value, 'MMM d, y, h:mm a', this.locale);
    } catch {
      return String(value);
    }
  }

  getDriverFullName(entry: DriverHistoryEntry): string {
    if (!entry) return 'Unknown driver';
    if (entry.driverFullName) {
      return entry.driverFullName;
    }
    const first = entry.driverFirstName ?? entry.driverName?.split?.(' ')?.[0];
    const last = entry.driverLastName ?? entry.driverName?.split?.(' ')?.slice?.(1).join?.(' ');
    const combined = [first, last]
      .filter((value) => !!value)
      .join(' ')
      .trim();
    if (combined) return combined;
    return entry.driverName ?? 'Unknown driver';
  }

  private normalizeDriverHistoryEntry(entry: any): DriverHistoryEntry {
    return {
      driverId: entry?.driverId ?? entry?.driver_id,
      driverFullName:
        entry?.driverFullName ?? entry?.driver_full_name ?? entry?.driverName ?? entry?.name,
      driverName:
        entry?.driverFullName ?? entry?.driver_full_name ?? entry?.driverName ?? entry?.name,
      driverFirstName:
        entry?.driverFirstName ??
        entry?.driver_first_name ??
        entry?.first_name ??
        entry?.name?.split?.(' ')?.[0],
      driverLastName:
        entry?.driverLastName ??
        entry?.driver_last_name ??
        entry?.last_name ??
        entry?.name?.split?.(' ')?.slice?.(1).join?.(' '),
      driverLicenseNumber: entry?.driverLicenseNumber ?? entry?.driver_license_number,
      vehicleId: entry?.vehicleId ?? entry?.vehicle_id,
      truckPlate: entry?.truckPlate ?? entry?.truck_plate,
      truckModel: entry?.truckModel ?? entry?.truck_model,
      assignedAt: entry?.assignedAt ?? entry?.assigned_at ?? entry?.date,
      assignedBy: entry?.assignedBy ?? entry?.assigned_by,
      reason: entry?.reason,
      active: entry?.active ?? entry?.isActive,
      revokedAt: entry?.revokedAt ?? entry?.revoked_at,
      revokedBy: entry?.revokedBy ?? entry?.revoked_by,
      revokeReason: entry?.revokeReason ?? entry?.revoke_reason,
    };
  }

  private cleanDocumentPayload(payload: Partial<Document>): Partial<Document> {
    const filteredEntries = Object.entries(payload).filter(
      ([, value]) => value !== '' && value !== null && value !== undefined,
    );
    return Object.fromEntries(filteredEntries) as Partial<Document>;
  }

  private normalizeVehicleDocuments(vehicle: Vehicle): Vehicle {
    const documents = (vehicle.documents ?? []).map((doc) => this.normalizeDocumentDates(doc));
    return { ...vehicle, documents };
  }

  private normalizeDocumentDates(doc: Document): Document {
    const normalize = (value?: string | number | Date): string | undefined => {
      if (value === undefined || value === null || value === '') return undefined;
      const date = typeof value === 'number' ? new Date(value) : new Date(value);
      if (Number.isNaN(date.getTime())) return undefined;
      return date.toISOString().split('T')[0];
    };

    return {
      ...doc,
      issueDate: normalize(doc.issueDate) ?? doc.issueDate,
      expiryDate: normalize(doc.expiryDate) ?? doc.expiryDate,
      uploadedDate: normalize(doc.uploadedDate) ?? doc.uploadedDate,
    };
  }

  private normalizeFormDate(value?: string | number | Date | null): string | undefined {
    if (value === undefined || value === null || value === '') {
      return undefined;
    }
    const date = value instanceof Date ? value : new Date(value);
    if (Number.isNaN(date.getTime())) {
      return undefined;
    }
    return date.toISOString().split('T')[0];
  }

  openDocumentForm(mode: 'create' | 'edit', doc?: Document): void {
    this.documentFormMode = mode;
    this.selectedDocument = doc ?? null;
    this.initializeDocumentForm(doc);
    this.documentFormVisible = true;
  }

  closeDocumentForm(): void {
    this.documentFormVisible = false;
    this.documentFormSubmitting = false;
    this.selectedDocument = null;
    this.documentForm?.reset();
  }

  openMaintenanceForm(mode: 'create' | 'edit', record?: MaintenanceTask): void {
    this.maintenanceFormMode = mode;
    this.selectedMaintenanceTask = record ?? null;
    this.initializeMaintenanceForm(record);
    this.maintenanceFormVisible = true;
    this.maintenanceFormError = '';
  }

  closeMaintenanceForm(): void {
    this.maintenanceFormVisible = false;
    this.maintenanceFormSubmitting = false;
    this.selectedMaintenanceTask = null;
    this.maintenanceForm?.reset();
  }

  private initializeMaintenanceForm(record?: MaintenanceTask): void {
    this.maintenanceForm = this.fb.group({
      title: [record?.title ?? '', Validators.required],
      description: [record?.description ?? ''],
      dueDate: [record?.dueDate ?? '', Validators.required],
      status: [record?.status ?? 'SCHEDULED', Validators.required],
      taskTypeId: [record?.taskTypeId ?? 1, Validators.required],
    });
  }

  submitMaintenanceForm(): void {
    if (this.maintenanceForm.invalid || !this.vehicleId) {
      this.maintenanceForm.markAllAsTouched();
      return;
    }
    if (this.maintenanceFormSubmitting) return;

    this.maintenanceFormSubmitting = true;
    const formValue = { ...this.maintenanceForm.value };
    const payload: MaintenanceTask = {
      ...this.selectedMaintenanceTask,
      ...formValue,
      vehicleId: this.vehicleId,
    };

    const request =
      this.maintenanceFormMode === 'edit' && this.selectedMaintenanceTask?.id
        ? this.maintenanceTaskService.updateTask(this.selectedMaintenanceTask.id, payload)
        : this.maintenanceTaskService.createTask(payload);

    request.subscribe({
      next: () => {
        this.snackBar.open(
          `Task ${this.maintenanceFormMode === 'create' ? 'created' : 'updated'}.`,
          'Close',
          { duration: 3000 },
        );
        this.closeMaintenanceForm();
        this.loadMaintenance();
      },
      error: (err) => {
        this.maintenanceFormError = err?.message ?? 'Failed to save maintenance task.';
        this.maintenanceFormSubmitting = false;
      },
    });
  }

  private initializeDocumentForm(doc?: Document): void {
    this.documentForm = this.fb.group({
      documentType: [doc?.documentType ?? '', Validators.required],
      documentName: [doc?.documentName ?? ''],
      docNumber: [doc?.docNumber ?? ''],
      issueDate: [doc?.issueDate ?? ''],
      expiryDate: [doc?.expiryDate ?? ''],
      fileName: [doc?.fileName ?? ''],
      approved: [doc?.approved ?? false],
      notes: [doc?.notes ?? ''],
    });
  }

  submitDocumentForm(): void {
    if (this.documentForm.invalid) {
      this.documentForm.markAllAsTouched();
      return;
    }

    if (!this.vehicleId) {
      this.snackBar.open('Vehicle context missing.', 'Close', { duration: 3000 });
      return;
    }

    const formValue = { ...this.documentForm.value };
    const normalizedIssueDate = this.normalizeFormDate(formValue.issueDate);
    const normalizedExpiryDate = this.normalizeFormDate(formValue.expiryDate);
    const payload: Partial<Document> = this.cleanDocumentPayload({
      ...formValue,
      issueDate: normalizedIssueDate,
      expiryDate: normalizedExpiryDate,
      vehicleId: this.vehicleId,
      documentNumber: formValue.docNumber ?? formValue.documentNumber,
    });
    this.documentFormSubmitting = true;

    const request =
      this.documentFormMode === 'edit' && this.selectedDocument?.id
        ? this.documentService.updateDocument(this.selectedDocument.id, payload)
        : this.documentService.createDocument(payload);

    request.subscribe({
      next: (res) => {
        const doc = res?.data ? this.normalizeDocumentDates(res.data) : null;
        if (doc) {
          this.upsertDocument(doc);
          this.snackBar.open(
            `Document ${this.documentFormMode === 'create' ? 'created' : 'updated'} successfully.`,
            'Close',
            { duration: 3500 },
          );
        } else {
          this.snackBar.open('Document saved but response was empty.', 'Close', { duration: 3500 });
        }
        this.closeDocumentForm();
        this.documentFormSubmitting = false;
      },
      error: (err) => {
        console.error('Document save failed', err);
        this.snackBar.open(
          'Failed to save document: ' + (err?.message ?? 'server error'),
          'Close',
          {
            duration: 5000,
          },
        );
        this.documentFormSubmitting = false;
      },
    });
  }

  async deleteDocument(doc: Document): Promise<void> {
    if (!doc?.id) return;
    if (!(await this.confirm.confirm('Delete this document? This cannot be undone.'))) {
      return;
    }

    this.documentService.deleteDocument(doc.id).subscribe({
      next: () => {
        this.removeDocumentFromVehicle(doc.id);
        this.snackBar.open('Document deleted.', 'Close', { duration: 3000 });
      },
      error: (err) => {
        console.error('Document delete failed', err);
        this.snackBar.open('Failed to delete document: ' + (err?.message ?? ''), 'Close', {
          duration: 4000,
        });
      },
    });
  }

  private upsertDocument(doc: Document): void {
    if (!this.vehicle) {
      return;
    }
    const current = [...(this.vehicle.documents ?? [])];
    const existingIndex = current.findIndex((entry) => entry.id === doc.id);
    if (existingIndex >= 0) {
      current[existingIndex] = doc;
    } else {
      current.unshift(doc);
    }
    this.vehicle = this.normalizeVehicleDocuments({ ...this.vehicle, documents: current });
    this.applyDocumentFilters();
  }

  private removeDocumentFromVehicle(docId: number): void {
    if (!this.vehicle) return;
    const remaining = (this.vehicle.documents ?? []).filter((entry) => entry.id !== docId);
    this.vehicle = this.normalizeVehicleDocuments({ ...this.vehicle, documents: remaining });
    this.applyDocumentFilters();
  }

  documentTypeLabel(value: string): string {
    if (!value) return 'Document';
    return value
      .toLowerCase()
      .split(/[\s_]+/)
      .map((segment) => segment.charAt(0).toUpperCase() + segment.slice(1))
      .join(' ');
  }

  get hasRecentDocument(): boolean {
    return (this.vehicle?.documents ?? []).some((doc) => this.isDocumentRecent(doc));
  }

  onSearchChange(): void {
    if (this.searchDebounceTimer) clearTimeout(this.searchDebounceTimer);
    this.searchDebounceTimer = setTimeout(() => {
      this.applySearch();
      this.searchDebounceTimer = null;
    }, 250);
  }

  onPageSizeChange(newSize: number | string): void {
    const n = typeof newSize === 'string' ? Number(newSize) : newSize;
    if (!Number.isNaN(n) && n > 0) this.pageSize = n;
  }

  applySearch(): void {
    const q = String(this.searchQuery ?? '')
      .trim()
      .toLowerCase();
    if (this.activeGroup === 'driver-history') {
      this.loadDriverHistory();
      return;
    }
    if (this.activeGroup === 'fuel') {
      this.loadFuelLogs();
      return;
    }

    if (q === '') {
      // no-op for stubs; if wired to API, trigger server filter
      return;
    }

    // Simple client-side filter for stubs
    if (this.driverHistory && this.driverHistory.length) {
      this.driverHistory = this.driverHistory.filter((d) =>
        JSON.stringify(d).toLowerCase().includes(q),
      );
    }
  }

  private updateDriverHistoryPageInfo(payload: {
    totalPages?: number;
    totalElements?: number;
  }): void {
    const maxPages = payload?.totalPages ?? 1;
    this.driverHistoryTotalPages = Math.max(1, maxPages);
    if (this.driverHistoryPage >= this.driverHistoryTotalPages) {
      this.driverHistoryPage = Math.max(0, this.driverHistoryTotalPages - 1);
    }
    this.driverHistoryTotalElements = payload?.totalElements ?? this.driverHistory.length;
  }

  onDriverHistorySearchChange(value: string): void {
    if (this.driverHistorySearchTimer) clearTimeout(this.driverHistorySearchTimer);
    this.driverHistorySearchTerm = value;
    this.driverHistorySearchTimer = setTimeout(() => {
      this.driverHistoryPage = 0;
      this.loadDriverHistory();
      this.driverHistorySearchTimer = null;
    }, 350);
  }

  onDriverHistoryFilterChange(filter: 'all' | 'active' | 'revoked'): void {
    this.driverHistoryFilter = filter;
    this.driverHistoryPage = 0;
    this.loadDriverHistory();
  }

  setDriverHistoryPageSize(value: number | string): void {
    const size = typeof value === 'string' ? Number(value) : value;
    if (Number.isNaN(size) || size <= 0) return;
    this.driverHistoryPageSize = size;
    this.driverHistoryPage = 0;
    this.loadDriverHistory();
  }

  goToDriverHistoryPage(page: number): void {
    if (page < 0 || page >= this.driverHistoryTotalPages || page === this.driverHistoryPage) return;
    this.driverHistoryPage = page;
    this.loadDriverHistory();
  }

  get driverHistoryStartIndex(): number {
    if (this.driverHistoryTotalElements === 0) return 0;
    return this.driverHistoryPage * this.driverHistoryPageSize;
  }

  get driverHistoryEndIndex(): number {
    return Math.min(
      this.driverHistoryTotalElements,
      this.driverHistoryStartIndex + this.driverHistoryPageSize,
    );
  }

  get driverHistoryPages(): number[] {
    const total = this.driverHistoryTotalPages;
    if (!total) return [];
    const maxButtons = 5;
    const radius = Math.floor(maxButtons / 2);
    const current = this.driverHistoryPage;
    let start = Math.max(0, current - radius);
    let end = Math.min(total, start + maxButtons);
    if (end - start < maxButtons) {
      start = Math.max(0, end - maxButtons);
    }
    return Array.from({ length: end - start }, (_, idx) => start + idx);
  }

  async revokeDriverHistoryAssignment(entry: DriverHistoryEntry | null): Promise<void> {
    if (!entry?.driverId || !entry.active) return;
    if (
      !(await this.confirm.confirm(`Revoke assignment for ${entry.driverName ?? 'this driver'}?`))
    )
      return;
    this.driverHistoryRevokeInProgress = entry.driverId;
    this.vehicleService.revokeDriverAssignment(entry.driverId).subscribe({
      next: () => {
        this.snackBar.open('Assignment revoked.', 'Close', { duration: 3000 });
        this.driverHistoryRevokeInProgress = null;
        this.loadDriverHistory();
      },
      error: (err) => {
        console.error('Revoke failed', err);
        this.snackBar.open('Failed to revoke assignment.', 'Close', { duration: 4000 });
        this.driverHistoryRevokeInProgress = null;
      },
    });
  }

  fetchVehicleDetail(): void {
    this.vehicleService.getVehicleById(this.vehicleId).subscribe({
      next: (res) => {
        const body = res?.data ?? res;
        if (body) {
          // support both ApiResponse shape and direct payload
          const v = res && (res as any).data ? (res as any).data : body;
          this.vehicle = this.normalizeVehicleDocuments(v as Vehicle);
          if (this.vehicle) {
            this.initializeForm(this.vehicle);
            this.disableEditMode();
            this.loadDriverCandidates();
            this.loadMaintenanceTasks();
            this.loadPmPlans();
            this.applyDocumentFilters();
            this.ensureGroupDataLoaded();
          } else {
            this.errorMessage = 'Vehicle not found.';
          }
        } else {
          this.errorMessage = 'No vehicle data received.';
        }
      },
      error: (err) => {
        console.error('Fetch error:', err);
        this.errorMessage =
          err && err.message ? err.message : 'Server error while fetching vehicle.';
      },
    });
  }

  initializeForm(vehicle: Vehicle): void {
    this.vehicleForm = this.fb.group({
      licensePlate: [vehicle.licensePlate],
      manufacturer: [vehicle.manufacturer],
      model: [vehicle.model],
      type: [vehicle.type],
      status: [vehicle.status],
      truckSize: [vehicle.truckSize],
      yearMade: [vehicle.yearMade ?? vehicle.year],
      mileage: [vehicle.mileage],
      engineHours: [vehicle.engineHours],
      fuelConsumption: [vehicle.fuelConsumption],
      qtyPalletsCapacity: [vehicle.qtyPalletsCapacity ?? vehicle.palletCapacity],
      maxWeight: [vehicle.maxWeight],
      maxVolume: [vehicle.maxVolume],
      assignedZoneId: [vehicle.assignedZoneId ?? null],
      assignedDriver: [vehicle.assignedDriver?.fullName || ''],
      lastInspectionDate: [vehicle.lastInspectionDate],
      lastServiceDate: [vehicle.lastServiceDate],
      nextServiceDue: [vehicle.nextServiceDue],
      remarks: [vehicle.remarks],
      unavailableRoutes: [vehicle.unavailableRoutes],
      availableRoutes: [vehicle.availableRoutes],
      gpsDeviceId: [vehicle.gpsDeviceId],
    });
  }

  onSubmit(): void {
    if (this.vehicleForm.invalid || !this.vehicle) {
      return;
    }

    const formValue = { ...this.vehicleForm.getRawValue() };
    delete formValue.assignedDriver;

    const updated: Vehicle = {
      ...this.vehicle,
      ...formValue,
      assignedDriver: this.vehicle.assignedDriver ?? null,
      id: this.vehicleId,
    };

    this.vehicleService.updateVehicle(updated).subscribe({
      next: () => {
        this.snackBar.open('Vehicle updated successfully.', 'Close', { duration: 3000 });
        this.vehicle = { ...updated };
        this.disableEditMode();
      },
      error: (err) =>
        this.snackBar.open('Failed to update vehicle: ' + (err?.message ?? ''), 'Close', {
          duration: 5000,
        }),
    });
  }

  enableEditMode(): void {
    if (!this.vehicleForm) return;
    this.editMode = true;
    this.vehicleForm.enable();
  }

  cancelEditMode(): void {
    if (!this.vehicle || !this.vehicleForm) return;
    this.initializeForm(this.vehicle);
    this.disableEditMode();
  }

  private disableEditMode(): void {
    if (!this.vehicleForm) return;
    this.editMode = false;
    this.vehicleForm.disable();
  }

  getServiceStatusLabel(dateValue?: string | Date | null): string {
    if (!dateValue) return 'Not scheduled';
    const due = new Date(dateValue);
    if (Number.isNaN(due.getTime())) return 'Unknown';
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const dueDate = new Date(due);
    dueDate.setHours(0, 0, 0, 0);
    const diffDays = Math.floor((dueDate.getTime() - today.getTime()) / (1000 * 60 * 60 * 24));
    if (diffDays < 0) return 'Overdue';
    if (diffDays <= 14) return 'Due soon';
    return 'On track';
  }

  getServiceStatusClasses(dateValue?: string | Date | null): string {
    const label = this.getServiceStatusLabel(dateValue);
    switch (label) {
      case 'Overdue':
        return 'bg-red-100 text-red-700 border-red-200';
      case 'Due soon':
        return 'bg-amber-100 text-amber-700 border-amber-200';
      case 'On track':
        return 'bg-emerald-100 text-emerald-700 border-emerald-200';
      default:
        return 'bg-gray-100 text-gray-700 border-gray-200';
    }
  }

  isOverdue(dateValue?: string | Date | null): boolean {
    if (!dateValue) return false;
    const due = new Date(dateValue);
    if (Number.isNaN(due.getTime())) return false;
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    due.setHours(0, 0, 0, 0);
    return due.getTime() < today.getTime();
  }

  toggleDriverPicker(): void {
    this.driverPickerOpen = !this.driverPickerOpen;
  }

  selectDriver(candidate: Driver): void {
    if (!this.vehicle) return;
    this.vehicle = {
      ...this.vehicle,
      assignedDriver: {
        id: candidate.id,
        fullName: candidate.fullName ?? candidate.name,
        phone: candidate.phone,
      },
    };
    this.vehicleForm.patchValue({ assignedDriver: candidate.fullName ?? candidate.name });
    this.driverPickerOpen = false;
  }

  private initializeAssignmentForm(): void {
    this.assignmentForm = this.fb.group({
      driverId: [null, Validators.required],
      reason: [''],
      forceReassignment: [false],
    });
  }

  openAssignmentModal(): void {
    this.assignmentForm.reset({
      driverId: null,
      reason: '',
      forceReassignment: false,
    });
    this.assignmentError = '';
    this.assignmentModalOpen = true;
  }

  closeAssignmentModal(): void {
    this.assignmentModalOpen = false;
  }

  submitAssignmentForm(): void {
    if (this.assignmentForm.invalid) {
      this.assignmentError = 'Select a driver to assign.';
      this.assignmentForm.markAllAsTouched();
      return;
    }

    if (!this.vehicleId) {
      this.assignmentError = 'Vehicle context missing.';
      return;
    }

    if (this.assignmentSubmitting) {
      return;
    }

    this.assignmentSubmitting = true;
    const formValue = this.assignmentForm.value;
    const request: AssignmentRequest = {
      driverId: formValue.driverId,
      vehicleId: this.vehicleId,
      reason: formValue.reason?.trim() || undefined,
      forceReassignment: formValue.forceReassignment,
    };

    this.vehicleDriverService.assignTruckToDriver(request).subscribe({
      next: () => {
        this.snackBar.open('Driver assigned successfully.', 'Close', { duration: 3000 });
        this.assignmentModalOpen = false;
        this.assignmentSubmitting = false;
        this.assignmentError = '';
        this.loadDriverHistory();
        this.fetchVehicleDetail();
      },
      error: (err) => {
        console.error('Driver assignment failed', err);
        const baseMessage = err?.message ?? 'Failed to assign driver.';
        const requestId = err?.requestId ? ` (Request ID: ${err.requestId})` : '';
        this.assignmentError = `${baseMessage}${requestId}`;
        this.assignmentSubmitting = false;
      },
    });
  }

  private loadDriverCandidates(): void {
    this.loadingDrivers = true;
    this.driverService.getAllDriversModal({ isActive: true }).subscribe({
      next: (res) => {
        this.driverCandidates = (res?.data ?? []).map((driver) => ({
          ...driver,
          displayName: driver.fullName ?? driver.name ?? `Driver #${driver.id}`,
        }));
        this.loadingDrivers = false;
      },
      error: () => {
        this.driverCandidates = [];
        this.loadingDrivers = false;
      },
    });
  }

  private loadMaintenanceTasks(): void {
    if (!this.vehicleId) return;
    this.loadingMaintenance = true;
    this.maintenanceTaskService.getTasks(0, 5, { vehicleId: this.vehicleId }).subscribe({
      next: (res) => {
        const tasks = res?.data?.content ?? [];
        this.maintenanceTasks = tasks;
        this.updateMaintenanceSummary(tasks);
        this.loadingMaintenance = false;
      },
      error: () => {
        this.maintenanceTasks = [];
        this.maintenanceSummary = {
          nextDueLabel: '',
          overdueCount: 0,
          upcomingCount: 0,
          completedCount: 0,
          totalCount: 0,
        };
        this.loadingMaintenance = false;
      },
    });
  }

  private loadPmPlans(): void {
    if (!this.vehicleId) return;
    this.loadingPm = true;
    this.pmPlanService.listByVehicle(this.vehicleId).subscribe({
      next: (res) => {
        this.pmPlans = res?.data ?? [];
        this.updatePmSummary();
        this.loadPmHistory();
        this.loadingPm = false;
      },
      error: () => {
        this.pmPlans = [];
        this.pmHistory = [];
        this.pmNextDueLabel = '';
        this.loadingPm = false;
      },
    });
  }

  private loadPmHistory(): void {
    if (!this.pmPlans.length) {
      this.pmHistory = [];
      return;
    }
    const calls = this.pmPlans.map((plan) =>
      this.pmPlanService.history(plan.id as number).pipe(catchError(() => of({ data: [] }))),
    );
    forkJoin(calls).subscribe({
      next: (results) => {
        const merged: Array<PMExecutionLogDto & { planName?: string }> = [];
        results.forEach((res: any, idx: number) => {
          const plan = this.pmPlans[idx];
          const logs = res?.data ?? [];
          logs.forEach((log: PMExecutionLogDto) =>
            merged.push({ ...log, planName: plan?.planName }),
          );
        });
        this.pmHistory = merged
          .sort((a, b) => (b.executedAt || '').localeCompare(a.executedAt || ''))
          .slice(0, 10);
      },
    });
  }

  private updatePmSummary(): void {
    if (!this.pmPlans.length) {
      this.pmNextDueLabel = '';
      return;
    }
    const dated = this.pmPlans
      .filter((p) => p.nextDueDate)
      .sort((a, b) => String(a.nextDueDate).localeCompare(String(b.nextDueDate)));
    if (dated.length) {
      this.pmNextDueLabel = dated[0].nextDueDate as string;
      return;
    }
    const valued = this.pmPlans
      .filter((p) => p.nextDueValue != null)
      .sort((a, b) => (a.nextDueValue ?? 0) - (b.nextDueValue ?? 0));
    if (valued.length) {
      let unit = 'km';
      if (valued[0].intervalType === 'HOURS') unit = 'hrs';
      if (valued[0].intervalType === 'TIME' || valued[0].intervalType === 'COMPLIANCE')
        unit = 'days';
      this.pmNextDueLabel = `${valued[0].nextDueValue} ${unit}`;
      return;
    }
    this.pmNextDueLabel = '';
  }

  private updateMaintenanceSummary(tasks: MaintenanceTask[]): void {
    const now = new Date();
    const overdueCount = tasks.filter(
      (task) => new Date(task.dueDate) < now && task.status !== 'COMPLETED',
    ).length;
    const completedCount = tasks.filter((task) => task.status === 'COMPLETED').length;
    const upcomingCount = tasks.filter(
      (task) => new Date(task.dueDate) >= now && task.status !== 'COMPLETED',
    ).length;
    const futureTask = tasks
      .filter((task) => new Date(task.dueDate) >= now)
      .sort((a, b) => new Date(a.dueDate).getTime() - new Date(b.dueDate).getTime())[0];

    this.maintenanceSummary = {
      nextDueLabel: futureTask ? this.formatDueDate(futureTask.dueDate) : '',
      overdueCount,
      upcomingCount,
      completedCount,
      totalCount: tasks.length,
    };
  }

  formatDueDate(value?: string): string {
    if (!value) return 'Not scheduled';
    try {
      return formatDate(value, 'MMM d, y', this.locale);
    } catch {
      return value;
    }
  }

  getMaintenanceStatusLabel(status?: string): string {
    if (!status) return 'Unknown';
    const normalized = status.toUpperCase();
    const labels: Record<string, string> = {
      PENDING: 'Pending',
      SCHEDULED: 'Scheduled',
      IN_PROGRESS: 'In Progress',
      COMPLETED: 'Completed',
      CANCELLED: 'Cancelled',
      OVERDUE: 'Overdue',
    };
    return labels[normalized] || status;
  }

  getMaintenanceStatusClasses(status?: string, dueDate?: string): string {
    const normalized = (status || '').toUpperCase();
    if (normalized === 'COMPLETED') {
      return 'border-emerald-200 bg-emerald-50 text-emerald-700';
    }
    if (normalized === 'CANCELLED') {
      return 'border-gray-200 bg-gray-50 text-gray-600';
    }
    if (dueDate && this.isOverdue(dueDate)) {
      return 'border-red-200 bg-red-50 text-red-700';
    }
    if (normalized === 'IN_PROGRESS') {
      return 'border-blue-200 bg-blue-50 text-blue-700';
    }
    return 'border-amber-200 bg-amber-50 text-amber-700';
  }

  get filteredMaintenanceRecords(): MaintenanceTask[] {
    const records = [...this.maintenanceRecords];
    const search = this.maintenanceFilters.search.trim().toLowerCase();
    const statusFilter = this.maintenanceFilters.status;

    const filtered = records.filter((record) => {
      if (statusFilter !== 'all') {
        if (statusFilter === 'overdue') {
          if (!record.dueDate || !this.isOverdue(record.dueDate)) return false;
          if ((record.status || '').toUpperCase() === 'COMPLETED') return false;
        } else if ((record.status || '').toUpperCase() !== statusFilter.toUpperCase()) {
          return false;
        }
      }
      if (search) {
        const haystack = `${record.title ?? ''} ${record.description ?? ''}`.toLowerCase();
        if (!haystack.includes(search)) return false;
      }
      return true;
    });

    const sorter = this.maintenanceFilters.sort;
    const byDueAsc = (a: MaintenanceTask, b: MaintenanceTask) =>
      new Date(a.dueDate || 0).getTime() - new Date(b.dueDate || 0).getTime();
    const byDueDesc = (a: MaintenanceTask, b: MaintenanceTask) =>
      new Date(b.dueDate || 0).getTime() - new Date(a.dueDate || 0).getTime();
    const byCreatedDesc = (a: MaintenanceTask, b: MaintenanceTask) =>
      new Date(b.createdDate || 0).getTime() - new Date(a.createdDate || 0).getTime();

    if (sorter === 'due-desc') filtered.sort(byDueDesc);
    if (sorter === 'created-desc') filtered.sort(byCreatedDesc);
    if (sorter === 'due-asc') filtered.sort(byDueAsc);

    return filtered;
  }

  get completedMaintenanceRecords(): MaintenanceTask[] {
    return this.maintenanceRecords
      .filter((record) => (record.status || '').toUpperCase() === 'COMPLETED')
      .sort(
        (a, b) => new Date(b.completedAt || 0).getTime() - new Date(a.completedAt || 0).getTime(),
      );
  }

  resetMaintenanceFilters(): void {
    this.maintenanceFilters = { search: '', status: 'all', sort: 'due-asc' };
  }

  viewMaintenanceTask(record: MaintenanceTask): void {
    if (!record?.id) {
      this.snackBar.open('Task details not available.', 'Close', { duration: 3000 });
      return;
    }
    this.router.navigate(['/tasks/maintenance', record.id]);
  }

  editMaintenanceTask(record: MaintenanceTask): void {
    if (!record?.id) {
      this.snackBar.open('Task cannot be edited.', 'Close', { duration: 3000 });
      return;
    }
    this.openMaintenanceForm('edit', record);
  }

  createMaintenanceTask(): void {
    this.openMaintenanceForm('create');
  }

  async markMaintenanceCompleted(record: MaintenanceTask): Promise<void> {
    if (!record?.id) return;
    if (record.status && record.status.toUpperCase() === 'COMPLETED') return;
    if (!(await this.confirm.confirm('Mark this maintenance task as completed?'))) return;
    const updated: MaintenanceTask = {
      ...record,
      status: 'COMPLETED',
      completedAt: new Date().toISOString(),
    };
    this.maintenanceTaskService.updateTask(record.id, updated).subscribe({
      next: () => {
        this.snackBar.open('Task marked as completed.', 'Close', { duration: 3000 });
        this.loadMaintenance();
      },
      error: (err) => {
        this.snackBar.open('Failed to update task: ' + (err?.message ?? 'server error'), 'Close', {
          duration: 4000,
        });
      },
    });
  }

  getVehicleStatusLabel(status?: VehicleStatus | string): string {
    const labels: Record<VehicleStatus, string> = {
      [VehicleStatus.ACTIVE]: 'Active',
      [VehicleStatus.UNDER_REPAIR]: 'Under Repair',
      [VehicleStatus.SAFETY_HOLD]: 'Safety Hold',
      [VehicleStatus.RETIRED]: 'Retired',
      [VehicleStatus.AVAILABLE]: 'Available',
      [VehicleStatus.IN_USE]: 'In Use',
      [VehicleStatus.MAINTENANCE]: 'Maintenance',
      [VehicleStatus.IN_ISSUE]: 'In Issue',
      [VehicleStatus.OUT_OF_SERVICE]: 'Out of Service',
    };
    const normalized = this.normalizeVehicleStatus(status);
    if (normalized) return labels[normalized] || normalized;
    return typeof status === 'string' ? status : '';
  }

  getVehicleStatusBadgeClasses(status?: VehicleStatus | string): string {
    const classes: Record<VehicleStatus, string> = {
      [VehicleStatus.ACTIVE]: 'border-green-200 bg-green-50 text-green-700',
      [VehicleStatus.UNDER_REPAIR]: 'border-orange-200 bg-orange-50 text-orange-700',
      [VehicleStatus.SAFETY_HOLD]: 'border-red-200 bg-red-50 text-red-700',
      [VehicleStatus.RETIRED]: 'border-gray-200 bg-gray-50 text-gray-700',
      [VehicleStatus.AVAILABLE]: 'border-emerald-200 bg-emerald-50 text-emerald-700',
      [VehicleStatus.IN_USE]: 'border-blue-200 bg-blue-50 text-blue-700',
      [VehicleStatus.MAINTENANCE]: 'border-yellow-200 bg-yellow-50 text-yellow-700',
      [VehicleStatus.IN_ISSUE]: 'border-red-200 bg-red-50 text-red-700',
      [VehicleStatus.OUT_OF_SERVICE]: 'border-gray-200 bg-gray-50 text-gray-700',
    };
    const normalized = this.normalizeVehicleStatus(status);
    return normalized
      ? classes[normalized] || 'border-gray-200 bg-gray-50 text-gray-700'
      : 'border-gray-200 bg-gray-50 text-gray-700';
  }

  private normalizeVehicleStatus(status?: VehicleStatus | string): VehicleStatus | undefined {
    if (!status) return undefined;
    const candidate = status as VehicleStatus;
    return this.vehicleStatusValues.includes(candidate) ? candidate : undefined;
  }

  goBack(): void {
    this.router.navigate(['/fleet/vehicles']);
  }

  /**
   * Navigate to assigned driver details page
   */
  viewDriverDetails(): void {
    if (this.vehicle?.assignedDriver?.id) {
      this.router.navigate(['/driver-app-accounts', this.vehicle.assignedDriver.id]);
    }
  }

  /**
   * Navigate to vehicle maintenance history page
   */
  viewMaintenanceHistory(): void {
    this.router.navigate(['/fleet/maintenance/records'], {
      queryParams: { vehicleId: this.vehicleId },
    });
  }

  /**
   * Navigate to vehicle documents page
   */
  viewVehicleDocuments(): void {
    this.router.navigate(['/fleet/vehicles/documents'], {
      queryParams: { vehicleId: this.vehicleId, vehiclePlate: this.vehicle?.licensePlate },
    });
  }

  /**
   * Scroll to a section anchor within the detail page
   */
  scrollTo(anchorId: string): void {
    try {
      const el = document.getElementById(anchorId);
      if (el) {
        el.scrollIntoView({ behavior: 'smooth', block: 'start' });
        // update fragment without reloading
        this.router.navigate([], { fragment: anchorId, replaceUrl: true });
      }
    } catch (err) {
      // ignore scrolling errors
      console.warn('ScrollTo failed:', err);
    }
  }

  toggleMobileNav(): void {
    this.mobileNavOpen = !this.mobileNavOpen;
  }
}
