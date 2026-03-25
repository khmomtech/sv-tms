/* eslint-disable @typescript-eslint/consistent-type-imports */
import { CommonModule } from '@angular/common';
import { Component, ElementRef, OnInit, OnDestroy, ViewChild } from '@angular/core';
import { FormGroup } from '@angular/forms';
import { Validators, ReactiveFormsModule, FormsModule } from '@angular/forms';
import { FormBuilder } from '@angular/forms';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatIconModule } from '@angular/material/icon';
import { ActivatedRoute, Router, RouterModule } from '@angular/router';
import { forkJoin, Subject, Subscription, of } from 'rxjs';
import {
  takeUntil,
  finalize,
  debounceTime,
  distinctUntilChanged,
  switchMap,
  catchError,
} from 'rxjs/operators';
import { DomSanitizer, SafeResourceUrl } from '@angular/platform-browser';

import type { DriverAssignment } from '../../../models/driver-assignment.model';
import type { Driver } from '../../../models/driver.model';
import type { DriverDocument } from '../../../models/driver-document.model';
import type { DriverPerformance } from '../../../models/driver-performance.model';
import type { PartnerCompany } from '../../../models/partner.model';
import type { Vehicle } from '../../../models/vehicle.model';
import {
  DriverAssignmentExtendedService,
  DriverCurrentAssignment,
} from '../../../services/driver-assignment-extended.service';
import { DriverDocumentService } from '../../../services/driver-document.service';
import { DriverService } from '../../../services/driver.service';
import { DriverPerformanceService } from '../../../services/driver-performance.service';
import type {
  DriverAccount,
  DriverGroup,
  DriverIdCardRecord,
} from '../../../services/driver.service';
import { ConfirmService } from '../../../services/confirm.service';
import { VehicleService } from '../../../services/vehicle.service';
import { VehicleDriverService } from '../../../services/vehicle-driver.service';
import { VendorService } from '../../../services/vendor.service';

import QRCode from 'qrcode';
import html2canvas from 'html2canvas';
import jsPDF from 'jspdf';

@Component({
  standalone: true,
  selector: 'app-driver-detail',
  templateUrl: './driver-detail.component.html',
  styleUrls: ['./driver-detail.component.css'],
  imports: [
    CommonModule,
    ReactiveFormsModule,
    RouterModule,
    MatProgressSpinnerModule,
    MatIconModule,
    FormsModule,
  ],
})
export class DriverDetailComponent implements OnInit, OnDestroy {
  driverForm!: FormGroup;
  accountForm!: FormGroup;

  isEditMode = false;
  driverId!: number;
  hasLoginAccount = false;
  accountLoading = false;
  accountLoadMessage = '';

  statusOptions = ['ONLINE', 'OFFLINE', 'BUSY', 'IDLE'];
  currentLicenseNumber = '';
  firstRowTabs = [
    { key: 'overview', label: 'Overview' },
    { key: 'profile', label: 'Profile' },
    { key: 'compliance', label: 'Compliance' },
    { key: 'operations', label: 'Operations' },
  ];
  secondRowTabs = [
    { key: 'performance', label: 'Performance' },
    { key: 'access', label: 'Access' },
    { key: 'lifecycle', label: 'Lifecycle' },
    { key: 'issue-id-card', label: 'Issue ID Card' },
  ];
  activeTab: string = 'overview';
  overviewPhone = '—';
  overviewZone = '—';
  overviewGroup = '—';
  overviewVendor = '—';
  overviewRating = 0;
  overviewLastSeen = 'Not available';
  overviewMetrics = [
    { label: 'Trips MTD', value: '124' },
    { label: 'On-Time %', value: '94%' },
    { label: 'Cancel %', value: '3%' },
    { label: 'Incidents', value: '1 (Low)' },
  ];
  get overviewEmploymentStatus(): string {
    const control = this.driverForm?.get('isActive');
    if (control && control.value !== undefined && control.value !== null) {
      return control.value ? 'Active' : 'Inactive';
    }
    return 'Unknown';
  }
  currentVehicleLabel = '—';
  currentVehicleSince = '';
  lifecycleStages = ['REGISTERED', 'ONBOARDING', 'ACTIVE'];
  lifecycleMasterStatus = 'ACTIVE';
  lifecycleActionMessage = '';
  lifecycleActionInProgress = false;
  complianceSummary = {
    license: 'Not set',
    documents: '0/0 Approved',
    backgroundCheck: 'Pending',
    dispatchEligible: '—',
  };
  operationalStatus = {
    presence: 'OFFLINE',
    shift: 'Morning',
    attendance: { present: 22, absent: 1, late: 2 },
  };
  alerts: string[] = [];
  documentSummary = { total: 0, approved: 0 };
  documentsList: DriverDocument[] = [];
  selectedDocumentForPreview: DriverDocument | null = null;
  documentPreviewUrl: SafeResourceUrl | null = null;
  previewError = '';
  showDocumentPreview = false;
  licenseSummary = {
    number: '—',
    clazz: '—',
    expires: '—',
    status: 'Not set',
    tone: 'neutral' as 'neutral' | 'success' | 'warning' | 'danger',
  };
  private pendingPartnerCompanyName: string | null = null;

  vehicleList: Vehicle[] = [];
  driverAssignments: DriverAssignment[] = [];
  partners: PartnerCompany[] = [];
  driverGroups: DriverGroup[] = [];
  currentAssignment?: DriverCurrentAssignment | null;
  profilePreviewUrl: string | null = null;
  profileUploadInProgress = false;
  profileUploadError = '';
  idCardQrDataUrl: string | null = null;
  idCardIssuedDateLabel = '—';
  idCardPreviewImageUrl: string | null = null;
  showIdCardPreview = false;
  idCardPreviewLoading = false;
  idCardSavingLayout = false;
  idCardRecordExists = false;
  idCardInfo: { code: string; phone: string; vehicle: string; licenseValid: string } = {
    code: '',
    phone: '',
    vehicle: '',
    licenseValid: '',
  };
  tempAssignHours = 8;
  isSubmitting = false;
  isAssignmentLoading = false;
  assignmentReason = '';
  assignmentActionInProgress = false;
  attendanceSummary = { present: 22, absent: 1, late: 2 };
  vehicleSearchQuery = '';
  assignmentType: 'permanent' | 'temporary' = 'permanent';
  selectedVehicleForAssignment: number | null = null;
  filteredVehicleSuggestions: Vehicle[] = [];
  showVehicleSuggestions = false;
  showAssignmentModal = false;
  selectedAssignment: DriverAssignment | null = null;
  assignmentModalType: 'permanent' | 'temporary' = 'permanent';
  assignmentModalStatus: DriverAssignment['status'] = 'ASSIGNED';
  assignmentModalReason = '';
  assignmentModalHours = 8;

  private destroy$ = new Subject<void>();

  phoneExists = false;
  private phoneCheckSub?: Subscription;

  @ViewChild('documentUploadInput') documentUploadInput?: ElementRef<HTMLInputElement>;
  @ViewChild('idCardLayout') idCardLayoutRef?: ElementRef<HTMLElement>;
  documentUploadTarget: DriverDocument | null = null;
  isDocumentUploadInProgress = false;

  documentEditForm!: FormGroup;
  editingDocument: DriverDocument | null = null;
  showDocumentEditModal = false;
  documentEditInProgress = false;
  documentEditError = '';
  documentCategories = [
    { key: 'license', label: 'Driver License' },
    { key: 'insurance', label: 'Insurance' },
    { key: 'registration', label: 'Vehicle Registration' },
    { key: 'medical', label: 'Medical Certificate' },
    { key: 'training', label: 'Training Certificate' },
    { key: 'passport', label: 'Passport' },
    { key: 'permit', label: 'Permit' },
    { key: 'other', label: 'Other' },
  ];

  performanceLoading = false;
  performanceSummary: DriverPerformance | null = null;
  performanceHistory: DriverPerformance[] = [];
  performanceTrend: Array<{ label: string; value: number }> = [];
  performanceTrendMax = 1;

  get selectedVehicleForAssignmentData(): Vehicle | undefined {
    return this.vehicleList.find((v) => v.id === this.selectedVehicleForAssignment);
  }

  get currentAssignedVehicleId(): number | null {
    return this.currentAssignment?.permanentVehicle?.id ?? null;
  }

  // Current vehicle that is effectively active (temporary takes precedence)
  get currentEffectiveVehicleId(): number | null {
    const tempId = this.currentAssignment?.temporaryVehicle?.id ?? null;
    const permId = this.currentAssignment?.permanentVehicle?.id ?? null;
    if (this.currentAssignment?.effectiveType === 'TEMPORARY' && tempId) {
      return tempId;
    }
    return permId ?? tempId;
  }

  constructor(
    private fb: FormBuilder,
    private route: ActivatedRoute,
    private router: Router,
    private driverService: DriverService,
    private driverAssignmentExtended: DriverAssignmentExtendedService,
    private partnerService: VendorService,
    private vehicleService: VehicleService,
    private vehicleDriverService: VehicleDriverService,
    private driverDocumentService: DriverDocumentService,
    private readonly driverPerformanceService: DriverPerformanceService,
    private readonly sanitizer: DomSanitizer,
    private readonly confirm: ConfirmService,
  ) {}

  ngOnInit(): void {
    this.initForm();
    this.initAccountForm();
    this.configurePasswordValidator();

    // Load active partners for selection
    this.partnerService
      .getActivePartners()
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (list) => {
          this.partners = list || [];
          this.syncPartnerSelection();
        },
        error: () => {
          this.partners = [];
        },
      });
    // Load driver groups
    this.driverService
      .getDriverGroups()
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (res) => (this.driverGroups = res.data || []),
        error: () => (this.driverGroups = []),
      });

    const id = this.route.snapshot.paramMap.get('id');
    if (id) {
      this.isEditMode = true;
      this.driverId = +id;
      this.loadDriverById(this.driverId);
      this.loadDriverAccount(this.driverId);
      this.loadCurrentAssignment();
      this.configurePasswordValidator();
    }

    this.route.queryParams.pipe(takeUntil(this.destroy$)).subscribe((params) => {
      const tab = params['tab'] || 'overview';
      this.activeTab = tab;
      if (tab === 'operations' && this.driverId) {
        this.loadAvailableVehicles();
        this.loadCurrentAssignment();
      }
      if (tab === 'profile' && this.driverId) {
        this.loadCurrentAssignment();
      }
      if (tab === 'issue-id-card' && this.driverId) {
        this.loadCurrentAssignment();
        this.refreshIdCardData();
        this.loadDriverIdCard(this.driverId);
      }
    });

    this.driverForm
      .get('driverType')
      ?.valueChanges.pipe(takeUntil(this.destroy$))
      .subscribe((type: string) => {
        const isPartner = type === 'Vendor';
        this.driverForm.get('isPartner')?.setValue(isPartner, { emitEvent: false });
        if (!isPartner) {
          this.driverForm.get('partnerCompany')?.setValue('');
          this.driverForm.get('partnerCompanyId')?.setValue(null);
        }
      });
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
    this.phoneCheckSub?.unsubscribe();
  }

  initForm(): void {
    this.driverForm = this.fb.group({
      firstName: ['', Validators.required],
      lastName: ['', Validators.required],
      name: [''],
      licenseClass: [null], // Initialize as null so backend value can be set properly
      phone: ['', Validators.required],
      rating: [0],
      isActive: [true],
      partnerCompany: [''],
      partnerCompanyId: [null],
      isPartner: [false],
      status: ['OFFLINE'],
      vehicleType: ['TRUCK'],
      zone: [''],
      profilePicture: [''],
      licenseExpiryDate: [''],
      idCardExpiry: [''],
      idCardIssuedDate: [''],
      idCardNumber: [''],
      driverGroupId: [null],
      driverType: ['Employee'],
    });
    this.initDocumentEditForm();
    this.watchPhoneFieldForDuplicates();
  }

  initAccountForm(): void {
    this.accountForm = this.fb.group({
      username: ['', Validators.required],
      email: ['', [Validators.required, Validators.email]],
      password: ['', Validators.required],
    });
  }

  private initDocumentEditForm(): void {
    this.documentEditForm = this.fb.group({
      name: ['', Validators.required],
      category: ['other', Validators.required],
      description: [''],
      expiryDate: [''],
      isRequired: [false],
    });
  }

  loadDriverById(id: number): void {
    this.driverService
      .getDriverById(id)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (res) => {
          const data = res.data;
          const normalized = this.normalizeDriverForForm(data);
          this.driverForm.patchValue({
            ...normalized,
            idCardExpiry:
              normalized['idCardExpiry'] ??
              (data as any)['idCardExpiry'] ??
              (data as any)['idCardExpiryDate'] ??
              (data as any)['licenseExpiryDate'] ??
              '',
            idCardIssuedDate:
              normalized['idCardIssuedDate'] ??
              (data as any)['idCardIssuedDate'] ??
              this.toDateInputString((data as any)['createdAt']) ??
              '',
            idCardNumber: normalized['idCardNumber'] ?? (data as any)['idCardNumber'] ?? '',
          });
          this.currentLicenseNumber =
            normalized['licenseNumber'] ??
            (data as any)['licenseNumber'] ??
            (data as any)?.['driverLicenseNumber'] ??
            '';
          this.profilePreviewUrl = res.data?.profilePicture || null;
          this.refreshIdCardData();
          this.pendingPartnerCompanyName = data?.partnerCompany ?? null;
          this.syncPartnerSelection();
          this.updateOverviewData(data);
          this.updateLicenseSummary(data);
          this.updateIdCardMetadata(data);
          // this.loadDriverIdCard(id);
          this.loadDocumentSummary(id);
          this.loadDriverAssignments(id);
          // this.loadPerformanceData(id);
          this.updateLifecycleFromDriver(data);
        },
        error: () => this.driverService.showToast(' Failed to load driver'),
      });
  }

  loadAvailableVehicles(): void {
    this.driverService
      .getAllVehicles()
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (res) => (this.vehicleList = res.data),
        error: () => this.driverService.showToast(' Failed to load vehicles'),
      });
  }

  loadDriverAssignments(driverId: number): void {
    this.isAssignmentLoading = true;

    // Load permanent assignments from vehicle_drivers table
    this.vehicleDriverService
      .getAssignments({ driverId })
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (res) => {
          const rawList = res.data || [];

          // Normalize backend assignment payload to UI model
          const mapped = rawList.map((assignment: any) => ({
            id: assignment.id,
            driverId: assignment.driverId,
            driverName: assignment.driverName,
            vehicleId: assignment.vehicleId,
            vehicleLicensePlate: assignment.truckPlate,
            assignedAt: assignment.assignedAt,
            unassignedAt: assignment.revokedAt,
            status: assignment.active ? ('ASSIGNED' as const) : ('UNASSIGNED' as const),
            assignmentType: 'PERMANENT' as const,
            reason: assignment.reason,
            vehicle: {
              id: assignment.vehicleId,
              licensePlate: assignment.truckPlate,
              model: assignment.truckModel,
              manufacturer: '',
              type: '',
              status: '',
              mileage: 0,
              fuelConsumption: 0,
            },
          }));

          this.driverAssignments = mapped.sort((a, b) => {
            const aDate = a.assignedAt ? new Date(a.assignedAt).getTime() : 0;
            const bDate = b.assignedAt ? new Date(b.assignedAt).getTime() : 0;
            return bDate - aDate;
          });
          this.refreshIdCardData();
          this.updateVehicleOverview();
          this.isAssignmentLoading = false;
        },
        error: () => {
          this.driverAssignments = [];
          this.isAssignmentLoading = false;
          this.driverService.showToast(' Failed to load assignment history');
          this.refreshIdCardData();
          this.updateVehicleOverview();
        },
      });
  }

  loadDriverAccount(id: number): void {
    this.accountLoading = true;
    this.accountLoadMessage = '';
    this.accountForm.enable({ emitEvent: false });
    this.driverService
      .getDriverAccountById(id)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (account: DriverAccount | null) => {
          if (account) {
            this.hasLoginAccount = true;
            this.accountForm.enable({ emitEvent: false });
            this.accountForm.patchValue({
              username: account.username,
              email: account.email,
              password: '',
            });
            this.accountLoadMessage = '';
          } else {
            this.hasLoginAccount = false;
            this.accountForm.enable({ emitEvent: false });
            this.accountForm.reset({
              username: '',
              email: '',
              password: '',
            });
            this.accountLoadMessage = 'No login account found. Complete the form to create one.';
          }
          this.configurePasswordValidator();
          this.accountLoading = false;
        },
        error: (error) => {
          this.hasLoginAccount = false;
          this.accountForm.reset();
          if (error?.status === 403) {
            this.accountLoadMessage =
              'You do not have permission to view or edit this login account.';
            this.accountForm.disable({ emitEvent: false });
          } else {
            this.accountLoadMessage =
              'Unable to load login account details. Please try again later.';
            this.accountForm.enable({ emitEvent: false });
          }
          this.configurePasswordValidator();
          this.accountLoading = false;
        },
      });
  }

  // Simple browser confirm will be used for unassign actions

  onSubmit(): void {
    if (this.driverForm.invalid) {
      this.driverService.showToast('⚠️ Please fill in all required fields.');
      this.markFormGroupTouched(this.driverForm);
      return;
    }

    if (this.isSubmitting) {
      return; // Prevent double-submit
    }

    if (!this.isEditMode && this.phoneExists) {
      this.driverService.showToast(
        '⚠️ A driver already exists with this phone number. Please review or use a different number.',
      );
      return;
    }

    this.isSubmitting = true;
    const formValue = { ...this.driverForm.value } as any;
    formValue.name = `${formValue.firstName || ''} ${formValue.lastName || ''}`.trim();

    // Map partnerCompanyId to partnerCompany string for backend
    if (formValue.partnerCompanyId) {
      const selectedPartner = this.partners.find((p) => p.id === formValue.partnerCompanyId);
      formValue.partnerCompany = selectedPartner?.companyName || '';
    } else {
      formValue.partnerCompany = '';
    }
    // Remove partnerCompanyId as backend doesn't expect it
    delete formValue.partnerCompanyId;

    const updatePayload = {
      ...formValue,
      phoneNumber: formValue.phone,
    } as any;
    delete updatePayload.phone;

    const action = this.isEditMode
      ? this.driverService.updateDriver(this.driverId, updatePayload)
      : this.driverService.addDriver({
          ...formValue,
          idCardExpiry: formValue.idCardExpiry,
        });

    action.subscribe({
      next: () => {
        this.isSubmitting = false;
        this.router.navigate(['/fleet/drivers']);
      },
      error: () => {
        this.isSubmitting = false;
        this.driverService.showToast(` Failed to ${this.isEditMode ? 'update' : 'add'} driver`);
      },
    });
  }

  private markFormGroupTouched(formGroup: FormGroup): void {
    Object.keys(formGroup.controls).forEach((key) => {
      const control = formGroup.get(key);
      control?.markAsTouched();
    });
  }

  onAccountSubmit(): void {
    if (this.accountForm.disabled) {
      this.driverService.showToast('⚠️ You do not have permission to modify this account.');
      return;
    }

    if (this.accountForm.invalid) {
      this.driverService.showToast('⚠️ Please fill in all login fields.');
      return;
    }

    const account = this.accountForm.value;
    if (this.driverId) {
      this.driverService.saveDriverAccount(this.driverId, account).subscribe({
        next: () => {
          this.driverService.showToast(' Login account saved');
          this.hasLoginAccount = true;
          this.loadDriverAccount(this.driverId);
        },
        error: () => this.driverService.showToast(' Failed to save login account'),
      });
    }
  }

  private watchPhoneFieldForDuplicates(): void {
    if (this.isEditMode) {
      return;
    }
    const control = this.driverForm.get('phone');
    if (!control) return;
    this.phoneCheckSub = control.valueChanges
      .pipe(
        debounceTime(400),
        distinctUntilChanged(),
        switchMap((value: string) =>
          this.driverService.checkDriverExists(value).pipe(catchError(() => of(false))),
        ),
        takeUntil(this.destroy$),
      )
      .subscribe((exists) => (this.phoneExists = exists));
  }

  async onDeleteAccount(): Promise<void> {
    if (!this.driverId) return;
    const confirmed = await this.confirm.confirm(
      'Are you sure you want to delete this login account?',
    );
    if (!confirmed) return;

    this.driverService.deleteDriverAccount(this.driverId).subscribe({
      next: () => {
        this.driverService.showToast('🗑️ Login account deleted');
        this.accountForm.reset();
        this.hasLoginAccount = false;
        this.accountLoadMessage = 'Login account deleted. Complete the form to create a new one.';
        this.accountForm.enable({ emitEvent: false });
        this.configurePasswordValidator();
      },
      error: () => this.driverService.showToast(' Failed to delete login account'),
    });
  }

  cancelAccountEdit(): void {
    this.accountForm.reset();
    if (this.driverId) this.loadDriverAccount(this.driverId);
  }

  private configurePasswordValidator(): void {
    const passwordCtrl = this.accountForm.get('password');
    if (!passwordCtrl) return;
    if (this.hasLoginAccount || this.accountForm.disabled) {
      passwordCtrl.clearValidators();
    } else {
      passwordCtrl.setValidators([Validators.required]);
    }
    passwordCtrl.updateValueAndValidity({ emitEvent: false });
  }

  onTabChange(tabKey: string): void {
    this.router.navigate([], {
      relativeTo: this.route,
      queryParams: { tab: tabKey },
      queryParamsHandling: 'merge',
    });
    if ((tabKey === 'operations' || tabKey === 'profile') && this.driverId) {
      this.loadCurrentAssignment();
    }
    if (tabKey === 'operations' && this.driverId) {
      this.loadAvailableVehicles();
    }
    if (tabKey === 'issue-id-card' && this.driverId) {
      this.loadDriverIdCard(this.driverId);
      this.refreshIdCardData();
    }
  }

  goBack(): void {
    this.router.navigate(['/fleet/drivers']);
  }

  buildDriverDisplayName(): string {
    const first = (this.driverForm.get('firstName')?.value || '').toString().trim();
    const last = (this.driverForm.get('lastName')?.value || '').toString().trim();
    const name = (this.driverForm.get('name')?.value || '').toString().trim();
    return (name || `${first} ${last}`).trim();
  }

  private normalizeDriverForForm(data: any): Record<string, any> {
    if (!data) return {};
    return {
      ...data,
      phone: data.phone ?? data.phoneNumber ?? '',
      rating: data.rating ?? 0,
      isActive: data.isActive ?? data.active ?? true,
      isPartner: data.isPartner ?? data.partner ?? false,
      driverGroupId: (() => {
        const groupId = data.driverGroup?.id ?? data.driverGroupId ?? null;
        return groupId !== null && groupId !== undefined ? Number(groupId) : null;
      })(),
      driverType: data.isPartner ? 'Vendor' : 'Employee',
    };
  }

  get driverInitials(): string {
    const name = this.buildDriverDisplayName();
    if (!name) return 'DR';
    const parts = name.split(/\s+/).filter(Boolean);
    const initials = parts
      .slice(0, 2)
      .map((p) => p[0].toUpperCase())
      .join('');
    return initials || 'DR';
  }

  private syncPartnerSelection(): void {
    const pending = this.pendingPartnerCompanyName?.trim().toLowerCase();
    if (!pending || this.partners.length === 0) {
      return;
    }
    const match = this.partners.find((partner) => {
      const name = partner.companyName?.trim().toLowerCase() ?? '';
      const code = partner.companyCode?.trim().toLowerCase() ?? '';
      return (
        name === pending ||
        code === pending ||
        (name && name.includes(pending)) ||
        (code && pending.includes(code))
      );
    });
    if (!match) return;
    const control = this.driverForm.get('partnerCompanyId');
    if (control?.value !== match.id) {
      control?.setValue(match.id, { emitEvent: false });
    }
    this.pendingPartnerCompanyName = null;
  }

  get driverGroupName(): string {
    const controlVal = this.driverForm.get('driverGroupId')?.value;
    const id = controlVal !== null && controlVal !== undefined ? Number(controlVal) : null;
    const group = this.driverGroups.find((g) => g.id === id);
    return group?.name || '—';
  }

  private computeLicenseValidity(raw: any): string {
    if (!raw) return 'Not set';
    const date = raw instanceof Date ? raw : new Date(raw);
    if (Number.isNaN(date.getTime())) return 'Not set';
    const formatted = this.formatDateDDMMMYYYY(date);
    return date.getTime() < Date.now() ? `Expired on ${formatted}` : `Valid until ${formatted}`;
  }

  private formatDateDDMMMYYYY(date: Date): string {
    const day = String(date.getDate()).padStart(2, '0');
    const month = date.toLocaleString('en-US', { month: 'short' });
    const year = date.getFullYear();
    return `${day}-${month}-${year}`;
  }

  private getLastPermanentVehicleLabel(driver: any): string {
    // Prefer current assignment vehicle plate/id if permanent
    const currentPermPlate = this.currentAssignment?.permanentVehicle?.licensePlate;
    const currentPermId = this.currentAssignment?.permanentVehicle?.id;
    // Fall back to latest permanent assignment from history (sorted newest first)
    const latestPermanent = this.driverAssignments.find(
      (a) => a.assignmentType === 'PERMANENT' && a.vehicleId,
    );
    const latestPlate = latestPermanent?.vehicleLicensePlate;

    return (
      currentPermPlate ||
      latestPlate ||
      currentPermId?.toString() ||
      latestPermanent?.vehicleId?.toString() ||
      driver.assignedVehicle?.licensePlate ||
      driver.assignedVehicleId ||
      '—'
    ).toString();
  }

  private refreshIdCardData(): void {
    const driver = this.driverForm.value as any;
    const name = this.buildDriverDisplayName();
    const code = driver.idCardNumber || this.currentLicenseNumber || `DR-${this.driverId || ''}`;
    const phone = driver.phone || '';
    const vehicle = this.getLastPermanentVehicleLabel(driver);

    const licenseValid = this.computeLicenseValidity(
      driver.idCardExpiry || driver.licenseExpiryDate,
    );

    this.idCardInfo = {
      code: code.toString(),
      phone: phone.toString(),
      vehicle: vehicle?.toString(),
      licenseValid,
    };

    const payload = {
      driverId: this.driverId,
      code: this.idCardInfo.code,
      name,
      phone: this.idCardInfo.phone,
      vehicle: this.idCardInfo.vehicle,
      licenseValid,
    };

    const text = JSON.stringify(payload);
    QRCode.toDataURL(text, { errorCorrectionLevel: 'M', margin: 1, width: 300 })
      .then((url) => (this.idCardQrDataUrl = url))
      .catch(() => (this.idCardQrDataUrl = null));
  }

  private updateIdCardMetadata(driverData: any): void {
    const issuedRaw =
      driverData?.idCardIssuedDate ??
      driverData?.idCardIssueDate ??
      driverData?.issueDate ??
      driverData?.createdAt ??
      driverData?.createdDate;

    if (!issuedRaw) {
      this.idCardIssuedDateLabel = '—';
      return;
    }

    const issued = new Date(issuedRaw);
    this.idCardIssuedDateLabel = Number.isNaN(issued.getTime())
      ? '—'
      : this.formatDateDDMMMYYYY(issued);
  }

  private loadDriverIdCard(driverId: number): void {
    this.driverService
      .getDriverIdCard(driverId)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (res) => {
          const record = res?.data;
          if (!record) {
            this.idCardRecordExists = false;
            return;
          }
          this.applyIdCardRecord(record);
        },
        error: () => {
          this.idCardRecordExists = false;
        },
      });
  }

  private applyIdCardRecord(record: DriverIdCardRecord): void {
    this.idCardRecordExists = Boolean(
      (record.idCardNumber && record.idCardNumber.trim().length > 0) ||
      record.issuedDate ||
      record.expiryDate,
    );
    this.driverForm.patchValue({
      idCardNumber: record.idCardNumber || '',
      idCardIssuedDate: this.toDateInputString(record.issuedDate) || '',
      idCardExpiry:
        this.toDateInputString(record.expiryDate) ||
        this.driverForm.get('idCardExpiry')?.value ||
        '',
    });
    this.updateIdCardMetadata({ idCardIssuedDate: record.issuedDate });
    this.refreshIdCardData();
  }

  private toDateInputString(value: any): string | null {
    if (!value) return null;
    const date = new Date(value);
    if (Number.isNaN(date.getTime())) {
      const raw = String(value);
      return /^\d{4}-\d{2}-\d{2}$/.test(raw) ? raw : null;
    }
    return date.toISOString().slice(0, 10);
  }

  private loadDocumentSummary(driverId: number): void {
    if (!driverId) return;
    this.driverDocumentService
      .getDriverDocuments(driverId)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (res) => {
          const docs = res.data ?? [];
          this.documentsList = docs;
          const approved = docs.filter((doc) => doc.status !== 'expired').length;
          this.documentSummary = { total: docs.length, approved };
          this.refreshDocumentComplianceSummary();
        },
        error: () => {
          this.documentSummary = { total: 0, approved: 0 };
          this.documentsList = [];
          this.refreshDocumentComplianceSummary();
        },
      });
  }

  private refreshDocumentComplianceSummary(): void {
    const target = Math.max(5, this.documentSummary.total);
    const approved = Math.min(this.documentSummary.approved, target);
    this.complianceSummary.documents = `${approved}/${target} Approved`;
  }

  private loadPerformanceData(driverId: number): void {
    this.performanceLoading = true;
    forkJoin({
      current: this.driverPerformanceService.getCurrentPerformance(driverId),
      history: this.driverPerformanceService.getPerformanceHistory(driverId, 6),
    })
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: ({ current, history }) => {
          this.performanceSummary = current?.data ?? null;
          this.performanceHistory = history?.data ?? [];
          this.buildPerformanceTrend();
          this.performanceLoading = false;
        },
        error: () => {
          this.performanceSummary = null;
          this.performanceHistory = [];
          this.performanceTrend = [];
          this.performanceTrendMax = 1;
          this.performanceLoading = false;
        },
      });
  }

  private buildPerformanceTrend(): void {
    const entries = [...(this.performanceHistory ?? [])].reverse();
    const maxValue = Math.max(1, ...entries.map((entry) => entry.totalDeliveries ?? 0));
    this.performanceTrendMax = maxValue;
    this.performanceTrend = entries.map((entry) => ({
      label: (() => {
        const source = (entry.monthName || entry.period || '—').toString();
        return source.length > 3 ? source.substring(0, 3) : source;
      })(),
      value: entry.totalDeliveries ?? 0,
    }));
  }

  get performanceOnTimePercent(): number {
    return this.performanceSummary?.onTimePercent ?? this.performanceSummary?.onTimeRate ?? 0;
  }

  get performanceCancelRate(): number {
    const total = this.performanceSummary?.totalDeliveries ?? 0;
    if (total === 0) return 0;
    const cancelled = this.performanceSummary?.cancelledDeliveries ?? 0;
    return Number(((cancelled / total) * 100).toFixed(1));
  }

  get performanceIncidentCount(): number {
    return this.performanceSummary?.incidentsCount ?? 0;
  }

  get averageRatingDisplay(): string {
    const rating = this.performanceSummary?.averageRating;
    return rating !== undefined && rating !== null ? rating.toFixed(1) : '—';
  }

  get fuelEfficiencyDisplay(): string {
    const efficiency = this.performanceSummary?.fuelEfficiency;
    return efficiency !== undefined && efficiency !== null ? efficiency.toFixed(1) : '—';
  }

  getTrendBarWidth(value: number): number {
    if (!this.performanceTrendMax || this.performanceTrendMax <= 0) return 0;
    const ratio = (value / this.performanceTrendMax) * 100;
    return Math.min(100, Math.max(0, Math.round(ratio)));
  }

  private updateOverviewData(data: any): void {
    if (!data) return;
    this.overviewPhone = data.phone ?? data.phoneNumber ?? '—';
    this.overviewZone = data.zone ?? '—';
    this.overviewGroup = data.driverGroupName ?? data.driverGroup?.name ?? '—';
    this.overviewVendor = data.partnerCompany ?? '—';
    const rating = Number(data.rating ?? 0);
    this.overviewRating = Number.isFinite(rating) ? rating : 0;
    this.overviewLastSeen = this.formatRelativeTime(data.lastLocationAt);
    const licenseField = data.licenseExpiryDate ?? data.idCardExpiry ?? data.licenseExpiry;
    const licenseInfo = this.computeLicenseExpiryLabel(licenseField);
    this.complianceSummary.license = licenseInfo.status;
    this.operationalStatus.presence = (data.status ?? 'OFFLINE').toString().toUpperCase();
    this.updateAlerts(this.overviewRating, licenseInfo.daysRemaining);
  }

  private updateAlerts(rating: number, licenseDays?: number): void {
    const alerts: string[] = [];
    if (licenseDays !== undefined && licenseDays >= 0 && licenseDays <= 10) {
      alerts.push(`⚠ Insurance expires in ${licenseDays} day${licenseDays === 1 ? '' : 's'}`);
    }
    if (rating < 4.5) {
      alerts.push('⚠ Rating dropped below 4.5');
    }
    this.alerts = alerts;
  }

  private updateVehicleOverview(): void {
    const activeAssignment =
      this.driverAssignments.find((a) => a.status === 'ASSIGNED') ?? this.driverAssignments[0];
    const effectiveVehicle =
      this.currentAssignment?.effectiveVehicle ??
      this.currentAssignment?.permanentVehicle ??
      activeAssignment?.vehicle;
    if (effectiveVehicle) {
      const plate = activeAssignment?.vehicleLicensePlate || effectiveVehicle.licensePlate || '';
      const details = [plate, effectiveVehicle.model, effectiveVehicle.manufacturer]
        .filter((part) => part)
        .join(' ');
      this.currentVehicleLabel = details || '—';
    } else {
      this.currentVehicleLabel = '—';
    }
    if (activeAssignment?.assignedAt) {
      this.currentVehicleSince = this.formatDateShort(new Date(activeAssignment.assignedAt));
    } else {
      this.currentVehicleSince = '';
    }
  }

  private computeLicenseExpiryLabel(raw?: string | Date | null): {
    status: string;
    daysRemaining?: number;
  } {
    if (!raw) {
      return { status: 'Not set' };
    }
    const date = raw instanceof Date ? raw : new Date(raw);
    if (Number.isNaN(date.getTime())) {
      return { status: 'Not set' };
    }
    const diffMs = date.getTime() - Date.now();
    const days = Math.ceil(diffMs / (1000 * 60 * 60 * 24));
    if (diffMs >= 0) {
      return {
        status: `VALID (expires in ${Math.max(days, 0)} day${days === 1 ? '' : 's'})`,
        daysRemaining: Math.max(days, 0),
      };
    }
    return {
      status: `EXPIRED (on ${this.formatDateShort(date)})`,
      daysRemaining: days,
    };
  }

  private formatRelativeTime(value?: string | Date | null): string {
    if (!value) return 'Not available';
    const timestamp = value instanceof Date ? value.getTime() : new Date(value).getTime();
    if (Number.isNaN(timestamp)) return 'Not available';
    const diffMs = Date.now() - timestamp;
    const minutes = Math.floor(diffMs / 60000);
    if (minutes < 1) return 'Just now';
    if (minutes < 60) return `${minutes} min ago`;
    const hours = Math.floor(minutes / 60);
    if (hours < 24) return `${hours} hour${hours === 1 ? '' : 's'} ago`;
    const days = Math.floor(hours / 24);
    return `${days} day${days === 1 ? '' : 's'} ago`;
  }

  private formatDateShort(date: Date): string {
    const day = String(date.getDate()).padStart(2, '0');
    const month = date.toLocaleString('en-US', { month: 'short' });
    const year = date.getFullYear();
    return `${day}-${month}-${year}`;
  }

  private updateLicenseSummary(data?: any): void {
    const driverData = data ?? {};
    const licenseNumber =
      driverData?.licenseNumber ??
      this.currentLicenseNumber ??
      driverData?.driverLicenseNumber ??
      '—';
    const licenseClass = driverData?.licenseClass ?? '—';
    const expiryField = driverData?.licenseExpiryDate ?? driverData?.idCardExpiry ?? null;
    const expiryLabel = expiryField ? this.formatDateDDMMMYYYY(new Date(expiryField)) : '—';
    const computed = this.computeLicenseExpiryLabel(expiryField);
    let tone: 'neutral' | 'success' | 'warning' | 'danger' = 'neutral';
    if (computed.daysRemaining !== undefined) {
      if (computed.daysRemaining < 0) tone = 'danger';
      else if (computed.daysRemaining <= 30) tone = 'warning';
      else tone = 'success';
    }
    this.licenseSummary = {
      number: licenseNumber,
      clazz: licenseClass,
      expires: expiryLabel,
      status: computed.status,
      tone,
    };
  }

  private getDocumentStatusTone(doc: DriverDocument): 'success' | 'warning' | 'danger' | 'neutral' {
    if (doc.status === 'expired' || this.isDocumentExpired(doc)) return 'danger';
    if (this.isDocumentExpiringSoon(doc)) return 'warning';
    return 'success';
  }

  private isDocumentExpired(doc: DriverDocument): boolean {
    if (!doc.expiryDate) return false;
    const expiry = new Date(doc.expiryDate);
    return expiry.getTime() < Date.now();
  }

  private isDocumentExpiringSoon(doc: DriverDocument): boolean {
    if (!doc.expiryDate) return false;
    const expiry = new Date(doc.expiryDate);
    const diffDays = (expiry.getTime() - Date.now()) / (1000 * 60 * 60 * 24);
    return diffDays >= 0 && diffDays <= 30;
  }

  documentStatusLabel(doc: DriverDocument): string {
    if (this.isDocumentExpired(doc)) {
      return '⚠ Expired';
    }
    if (this.isDocumentExpiringSoon(doc)) {
      return '⚠ Expiring';
    }
    return '✔ Approved';
  }

  documentActionLabel(doc: DriverDocument): string {
    const needsReplacement = this.isDocumentExpired(doc) || this.isDocumentExpiringSoon(doc);
    return needsReplacement ? 'Replace' : 'View';
  }

  handleDocumentAction(doc: DriverDocument, event?: MouseEvent): void {
    event?.stopPropagation();
    const needsReplacement = this.isDocumentExpired(doc) || this.isDocumentExpiringSoon(doc);
    if (needsReplacement) {
      this.promptDocumentReplacement(doc);
      return;
    }
    this.openDocumentFile(doc);
  }

  private promptDocumentReplacement(doc: DriverDocument): void {
    this.documentUploadTarget = doc;
    if (this.documentUploadInput?.nativeElement) {
      this.documentUploadInput.nativeElement.value = '';
      this.documentUploadInput.nativeElement.click();
    }
  }

  onDocumentFileSelected(event: Event): void {
    const files = (event.target as HTMLInputElement)?.files;
    const file = files?.length ? files[0] : null;
    const doc = this.documentUploadTarget;
    if (!file || !doc || !this.driverId || doc.id == null) {
      this.documentUploadTarget = null;
      return;
    }
    this.isDocumentUploadInProgress = true;
    this.driverDocumentService
      .updateDriverDocumentFile(this.driverId, doc.id, file, {
        name: doc.name,
        category: doc.category,
        expiryDate: doc.expiryDate,
        description: doc.description,
        isRequired: doc.isRequired ?? false,
      })
      .pipe(
        finalize(() => {
          this.isDocumentUploadInProgress = false;
          this.documentUploadTarget = null;
          if (this.documentUploadInput?.nativeElement) {
            this.documentUploadInput.nativeElement.value = '';
          }
        }),
      )
      .subscribe({
        next: () => {
          this.loadDocumentSummary(this.driverId!);
        },
        error: () => {},
      });
  }

  openDocumentFile(doc: DriverDocument | null): void {
    if (!doc?.fileUrl) {
      this.driverService.showToast('Document file is not available.');
      return;
    }
    const url = this.driverDocumentService.buildDocumentFileUrl(doc.fileUrl);
    if (!url) {
      this.driverService.showToast('Unable to resolve document URL.');
      return;
    }
    window.open(url, '_blank');
  }

  openDocumentEdit(doc: DriverDocument, event?: Event): void {
    event?.stopPropagation();
    this.editingDocument = doc;
    this.showDocumentEditModal = true;
    this.documentEditError = '';
    this.documentEditForm.patchValue({
      name: doc.name,
      category: doc.category || 'other',
      description: doc.description || '',
      expiryDate: doc.expiryDate || '',
      isRequired: doc.isRequired ?? false,
    });
  }

  closeDocumentEdit(): void {
    this.showDocumentEditModal = false;
    this.editingDocument = null;
    this.documentEditForm.reset({
      name: '',
      category: 'other',
      description: '',
      expiryDate: '',
      isRequired: false,
    });
    this.documentEditError = '';
  }

  saveDocumentEdit(): void {
    if (!this.driverId || !this.editingDocument || !this.editingDocument.id) {
      return;
    }
    if (this.documentEditForm.invalid) {
      this.documentEditForm.markAllAsTouched();
      return;
    }
    this.documentEditInProgress = true;
    this.documentEditError = '';
    const payload = {
      name: this.documentEditForm.value.name,
      category: this.documentEditForm.value.category,
      description: this.documentEditForm.value.description || undefined,
      expiryDate: this.documentEditForm.value.expiryDate || undefined,
      isRequired: this.documentEditForm.value.isRequired ?? false,
    };
    this.driverDocumentService
      .updateDriverDocument(this.driverId, this.editingDocument.id, payload)
      .pipe(finalize(() => (this.documentEditInProgress = false)))
      .subscribe({
        next: () => {
          this.loadDocumentSummary(this.driverId!);
          this.closeDocumentEdit();
        },
        error: (err) => {
          this.documentEditError =
            err?.error?.message || 'Unable to save document metadata at the moment.';
        },
      });
  }

  openDocumentPreview(doc: DriverDocument, event?: Event): void {
    event?.stopPropagation();
    this.previewError = '';
    this.selectedDocumentForPreview = doc;

    if (!doc?.fileUrl) {
      this.documentPreviewUrl = null;
      this.previewError = 'File preview is not available for this document.';
      this.showDocumentPreview = true;
      return;
    }

    const url = this.driverDocumentService.buildDocumentFileUrl(doc.fileUrl);
    if (!url) {
      this.documentPreviewUrl = null;
      this.previewError = 'Unable to resolve document URL for preview.';
      this.showDocumentPreview = true;
      return;
    }

    this.documentPreviewUrl = this.sanitizer.bypassSecurityTrustResourceUrl(url);
    this.showDocumentPreview = true;
  }

  closeDocumentPreview(): void {
    this.showDocumentPreview = false;
    this.previewError = '';
    this.selectedDocumentForPreview = null;
    this.documentPreviewUrl = null;
  }

  openLicenseUploader(): void {
    this.onTabChange('profile');
  }

  formatDocumentExpiry(doc: DriverDocument): string {
    if (!doc.expiryDate) return '—';
    return this.formatDateDDMMMYYYY(new Date(doc.expiryDate));
  }

  documentStatusClass(doc: DriverDocument): string {
    const tone = this.getDocumentStatusTone(doc);
    switch (tone) {
      case 'success':
        return 'text-green-700 bg-green-100';
      case 'warning':
        return 'text-yellow-700 bg-yellow-100';
      case 'danger':
        return 'text-red-700 bg-red-100';
      default:
        return 'text-gray-600 bg-gray-100';
    }
  }

  saveIdCardExpiry(): void {
    if (!this.driverId) return;
    const expiryValue = this.driverForm.get('idCardExpiry')?.value || null;
    const issuedValue = this.driverForm.get('idCardIssuedDate')?.value || null;
    const numberValue = this.driverForm.get('idCardNumber')?.value || null;
    const payload = {
      idCardNumber: numberValue,
      idCardIssuedDate: issuedValue,
      idCardExpiry: expiryValue,
    };
    this.isSubmitting = true;
    const request$ = this.idCardRecordExists
      ? this.driverService.updateDriverIdCard(this.driverId, payload)
      : this.driverService.createDriverIdCard(this.driverId, payload);
    request$.subscribe({
      next: (res) => {
        this.driverService.showToast(
          this.idCardRecordExists ? 'ID card details updated' : 'ID card created',
        );
        if (res?.data) {
          this.applyIdCardRecord(res.data);
        } else {
          this.updateIdCardMetadata({ idCardIssuedDate: issuedValue });
          this.refreshIdCardData();
        }
        this.idCardRecordExists = true;
        this.isSubmitting = false;
      },
      error: () => {
        this.driverService.showToast('Failed to save ID card details');
        this.isSubmitting = false;
      },
    });
  }

  deleteIdCard(): void {
    if (!this.driverId) return;
    if (!window.confirm('Delete ID card details for this driver?')) return;
    this.isSubmitting = true;
    this.driverService.deleteDriverIdCard(this.driverId).subscribe({
      next: () => {
        this.driverService.showToast('ID card deleted');
        this.idCardRecordExists = false;
        this.driverForm.patchValue({
          idCardNumber: '',
          idCardIssuedDate: '',
          idCardExpiry: '',
        });
        this.idCardIssuedDateLabel = '—';
        this.refreshIdCardData();
        this.isSubmitting = false;
      },
      error: () => {
        this.driverService.showToast('Failed to delete ID card');
        this.isSubmitting = false;
      },
    });
  }

  printIdCard(): void {
    window.print();
  }

  get idCardExpiryLabel(): string {
    const raw =
      this.driverForm.get('idCardExpiry')?.value || this.driverForm.get('licenseExpiryDate')?.value;
    if (!raw) return '—';
    const parsed = new Date(raw);
    return Number.isNaN(parsed.getTime()) ? '—' : this.formatDateDDMMMYYYY(parsed);
  }

  get idCardIssuedDisplayLabel(): string {
    const raw = this.driverForm.get('idCardIssuedDate')?.value;
    if (!raw) return this.idCardIssuedDateLabel;
    const parsed = new Date(raw);
    return Number.isNaN(parsed.getTime())
      ? this.idCardIssuedDateLabel
      : this.formatDateDDMMMYYYY(parsed);
  }

  get idCardStatusLabel(): string {
    const raw =
      this.driverForm.get('idCardExpiry')?.value || this.driverForm.get('licenseExpiryDate')?.value;
    if (!raw) return 'NO_EXPIRY';
    const parsed = new Date(raw);
    if (Number.isNaN(parsed.getTime())) return 'UNKNOWN';
    return parsed.getTime() < Date.now() ? 'EXPIRED' : 'ACTIVE';
  }

  get idCardStatusClass(): string {
    switch (this.idCardStatusLabel) {
      case 'ACTIVE':
        return 'bg-green-100 text-green-700';
      case 'EXPIRED':
        return 'bg-red-100 text-red-700';
      default:
        return 'bg-gray-100 text-gray-600';
    }
  }

  async openIdCardPreview(): Promise<void> {
    if (this.idCardPreviewLoading) return;
    this.idCardPreviewLoading = true;
    try {
      this.idCardPreviewImageUrl = await this.generateIdCardImageDataUrl(2);
      this.showIdCardPreview = true;
    } catch {
      this.driverService.showToast('Failed to render ID card preview');
    } finally {
      this.idCardPreviewLoading = false;
    }
  }

  closeIdCardPreview(): void {
    this.showIdCardPreview = false;
  }

  async saveIdCardLayout(): Promise<void> {
    if (this.idCardSavingLayout) return;
    this.idCardSavingLayout = true;
    try {
      const imageData = await this.generateIdCardImageDataUrl(3);
      const pdf = new jsPDF({
        orientation: 'landscape',
        unit: 'mm',
        format: [85.6, 54],
      });
      const pageW = pdf.internal.pageSize.getWidth();
      const pageH = pdf.internal.pageSize.getHeight();
      pdf.addImage(imageData, 'PNG', 0, 0, pageW, pageH);
      pdf.save(`driver-id-card-${this.driverId || 'new'}.pdf`);
      this.driverService.showToast('ID card layout saved');
    } catch {
      this.driverService.showToast('Failed to save ID card layout');
    } finally {
      this.idCardSavingLayout = false;
    }
  }

  private async generateIdCardImageDataUrl(scale: number): Promise<string> {
    const el = this.idCardLayoutRef?.nativeElement;
    if (!el) {
      throw new Error('ID card layout not found');
    }
    const canvas = await html2canvas(el, {
      scale,
      useCORS: true,
      backgroundColor: '#ffffff',
      logging: false,
    });
    return canvas.toDataURL('image/png');
  }

  onProfileFileSelected(event: Event): void {
    if (!this.isEditMode || !this.driverId) {
      this.driverService.showToast('Save the driver first, then upload a photo.');
      return;
    }
    const input = event.target as HTMLInputElement;
    const file = input?.files && input.files.length > 0 ? input.files[0] : null;
    if (!file) return;

    // Basic client-side guard (backend enforces types/size as well)
    const maxSize = 5 * 1024 * 1024; // 5MB
    if (file.size > maxSize) {
      this.profileUploadError = 'File is too large. Max 5MB.';
      input.value = '';
      return;
    }

    this.profileUploadError = '';
    this.profileUploadInProgress = true;

    this.driverService
      .uploadDriverProfilePicture(this.driverId, file)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (res) => {
          const url = res.data || '';
          this.profilePreviewUrl = url || this.profilePreviewUrl;
          this.driverForm.patchValue({ profilePicture: url });
          this.profileUploadInProgress = false;
        },
        error: (err) => {
          this.profileUploadError = err?.error?.message || 'Failed to upload photo';
          this.profileUploadInProgress = false;
        },
      });
  }

  // Vehicle actions
  viewVehicle(vehicle: Vehicle): void {
    if (!vehicle?.id) return;
    // Navigate to vehicle detail page (conventional route)
    this.router.navigate(['/fleet/vehicles', vehicle.id]);
  }

  editVehicle(vehicle: Vehicle): void {
    // TODO: Implement vehicle edit modal (not assignment modal)
    // For now, navigate to vehicle detail
    this.router.navigate(['/fleet/vehicles', vehicle.id]);
  }

  async deleteVehicle(vehicle: Vehicle): Promise<void> {
    if (!vehicle?.id) return;
    const confirmed = await this.confirm.confirm(
      `Are you sure you want to delete vehicle #${vehicle.id} (${vehicle.licensePlate || 'N/A'})? This cannot be undone.`,
    );
    if (!confirmed) return;
    this.vehicleService.deleteVehicle(vehicle.id).subscribe({
      next: () => {
        this.driverService.showToast('🗑️ Vehicle deleted');
        // Refresh lists
        if (this.driverId) this.reloadDriverAndVehicles();
      },
      error: () => this.driverService.showToast('Failed to delete vehicle'),
    });
  }

  cancel(): void {
    this.goBack();
  }

  onAssignVehicle(vehicleId: number): void {
    if (this.isSubmitting) return;
    if (vehicleId === this.currentEffectiveVehicleId) {
      this.driverService.showToast('🚫 Driver is already assigned to this vehicle');
      return;
    }
    this.isSubmitting = true;
    this.driverService.assignDriverToVehicle(this.driverId, vehicleId).subscribe({
      next: () => {
        this.driverService.showToast('Vehicle assigned successfully');
        this.reloadDriverAndVehicles();
        this.clearAssignmentSelection();
        this.isSubmitting = false;
      },
      error: () => {
        this.driverService.showToast('❌ Failed to assign vehicle');
        this.isSubmitting = false;
      },
    });
  }

  async onUnassignVehicle(): Promise<void> {
    if (!this.driverId) return;
    const confirmed = await this.confirm.confirm(
      'Are you sure you want to unassign the current vehicle from this driver?',
    );
    if (!confirmed) return;
    if (this.isSubmitting) return;
    this.isSubmitting = true;
    this.driverService
      .unassignDriver(this.driverId, 'Manual unassign from driver detail')
      .subscribe({
        next: () => {
          this.driverService.showToast('Vehicle unassigned successfully');
          this.reloadDriverAndVehicles();
          this.isSubmitting = false;
        },
        error: () => {
          this.driverService.showToast('❌ Failed to unassign vehicle');
          this.isSubmitting = false;
        },
      });
  }

  // Vehicle Assignment Methods
  onVehicleSearchInput(): void {
    const query = this.vehicleSearchQuery.trim().toLowerCase();
    if (query.length < 1) {
      this.filteredVehicleSuggestions = [];
      this.showVehicleSuggestions = false;
      return;
    }

    this.filteredVehicleSuggestions = this.vehicleList
      .filter(
        (v) =>
          (v.licensePlate || '').toLowerCase().includes(query) ||
          (v.model || '').toLowerCase().includes(query) ||
          (v.type || '').toLowerCase().includes(query),
      )
      .slice(0, 10); // Limit to 10 suggestions

    this.showVehicleSuggestions = this.filteredVehicleSuggestions.length > 0;
  }

  selectVehicleForAssignment(vehicle: Vehicle): void {
    this.selectedVehicleForAssignment = vehicle.id || null;
    this.vehicleSearchQuery = vehicle.licensePlate || `#${vehicle.id}`;
    this.showVehicleSuggestions = false;
  }

  clearAssignmentSelection(): void {
    this.selectedVehicleForAssignment = null;
    this.vehicleSearchQuery = '';
    this.assignmentType = 'permanent';
    this.tempAssignHours = 8;
    this.assignmentReason = '';
  }

  getVehicleInfo(vehicleId?: number | null): Vehicle | undefined {
    if (!vehicleId) return undefined;
    return this.vehicleList.find((v) => v.id === vehicleId);
  }

  confirmAssignVehicle(): void {
    if (!this.selectedVehicleForAssignment || !this.driverId) {
      this.driverService.showToast('⚠️ Please select a vehicle');
      return;
    }

    this.assignVehicleWithOptions({
      vehicleId: this.selectedVehicleForAssignment,
      mode: this.assignmentType,
      hours: this.tempAssignHours,
      reason: this.assignmentReason,
      onSuccess: () => this.clearAssignmentSelection(),
    });
  }

  openAssignmentModal(assignment: DriverAssignment): void {
    this.selectedAssignment = assignment;
    this.assignmentModalType =
      assignment.assignmentType === 'TEMPORARY' ? 'temporary' : 'permanent';
    this.assignmentModalStatus = assignment.status;
    this.assignmentModalHours = this.tempAssignHours;
    this.assignmentModalReason = assignment.reason ?? '';
    this.showAssignmentModal = true;
  }

  closeAssignmentModal(): void {
    this.showAssignmentModal = false;
    this.selectedAssignment = null;
    this.assignmentModalType = 'permanent';
    this.assignmentModalStatus = 'ASSIGNED';
    this.assignmentModalReason = '';
    this.assignmentModalHours = 8;
  }

  saveAssignmentModal(): void {
    if (!this.selectedAssignment?.vehicleId) return;
    this.assignVehicleWithOptions({
      vehicleId: this.selectedAssignment.vehicleId,
      mode: this.assignmentModalType,
      hours: this.assignmentModalHours,
      reason: this.assignmentModalReason,
      onSuccess: () => {
        this.closeAssignmentModal();
        this.clearAssignmentSelection();
      },
    });
  }

  private ensureVehicleCanBeAssigned(vehicleId: number, mode: 'permanent' | 'temporary'): boolean {
    if (!this.driverId) {
      this.driverService.showToast('Driver context missing');
      return false;
    }
    if (
      mode === 'permanent' &&
      this.currentAssignment?.effectiveType === 'PERMANENT' &&
      this.currentEffectiveVehicleId === vehicleId
    ) {
      this.driverService.showToast('🚫 Driver is already permanently assigned to this vehicle');
      return false;
    }
    if (
      mode === 'temporary' &&
      this.currentAssignment?.effectiveType === 'TEMPORARY' &&
      this.currentEffectiveVehicleId === vehicleId
    ) {
      this.driverService.showToast('🚫 Temporary assignment already active for this vehicle');
      return false;
    }
    return true;
  }

  private assignVehicleWithOptions(options: {
    vehicleId: number;
    mode: 'permanent' | 'temporary';
    hours?: number;
    reason?: string;
    onSuccess?: () => void;
  }): void {
    if (!this.driverId) return;
    if (!this.ensureVehicleCanBeAssigned(options.vehicleId, options.mode)) {
      return;
    }
    if (this.isSubmitting) return;
    this.isSubmitting = true;

    if (options.mode === 'permanent') {
      this.driverService.assignDriverToVehicle(this.driverId, options.vehicleId).subscribe({
        next: () => {
          this.reloadDriverAndVehicles();
          options.onSuccess?.();
          this.isSubmitting = false;
        },
        error: () => {
          this.driverService.showToast('❌ Failed to assign vehicle');
          this.isSubmitting = false;
        },
      });
    } else {
      const hours = Math.max(1, options.hours ?? this.tempAssignHours);
      const expiry = new Date(Date.now() + hours * 3600_000).toISOString();
      this.driverAssignmentExtended
        .setTemporary(this.driverId, {
          vehicleId: options.vehicleId,
          expiry,
          reason: options.reason?.trim() || 'Manual temporary assignment',
        })
        .subscribe({
          next: () => {
            this.driverService.showToast(`Temporary vehicle assigned (${hours}h)`);
            this.reloadDriverAndVehicles();
            options.onSuccess?.();
            this.isSubmitting = false;
          },
          error: () => {
            this.driverService.showToast('❌ Failed to assign temporary vehicle');
            this.isSubmitting = false;
          },
        });
    }
  }

  reactivateAssignment(assignment: DriverAssignment): void {
    if (!assignment?.vehicleId) return;
    const mode: 'permanent' | 'temporary' =
      assignment.assignmentType === 'TEMPORARY' ? 'temporary' : 'permanent';
    this.assignVehicleWithOptions({
      vehicleId: assignment.vehicleId,
      mode,
      hours: mode === 'temporary' ? this.tempAssignHours : undefined,
      reason: assignment.reason ?? '',
      onSuccess: () => {
        this.closeAssignmentModal();
        this.clearAssignmentSelection();
      },
    });
  }

  getStatusChipClasses(status: DriverAssignment['status']): string {
    switch (status) {
      case 'ASSIGNED':
        return 'bg-green-100 text-green-800';
      case 'COMPLETED':
        return 'bg-blue-100 text-blue-800';
      case 'CANCELED':
        return 'bg-red-100 text-red-700';
      case 'EXPIRED':
        return 'bg-yellow-100 text-yellow-800';
      case 'UNASSIGNED':
        return 'bg-gray-200 text-gray-700';
      default:
        return 'bg-gray-100 text-gray-600';
    }
  }

  formatAssignmentType(type?: DriverAssignment['assignmentType'] | null): string {
    if (!type) return 'N/A';
    return type === 'TEMPORARY' ? 'Temporary' : 'Permanent';
  }

  formatDate(value?: string | null): string {
    if (!value) return '—';
    const date = new Date(value);
    if (Number.isNaN(date.getTime())) return '—';
    return date.toLocaleString();
  }

  formatMonthYear(value?: string | null): string {
    if (!value) return '—';
    const date = new Date(value);
    if (Number.isNaN(date.getTime())) return '—';
    return date.toLocaleString('en-US', { month: 'short', year: 'numeric' });
  }

  get activeAssignment(): DriverAssignment | undefined {
    return this.driverAssignments.find((assignment) => assignment.status === 'ASSIGNED');
  }

  get assignmentTimeline(): DriverAssignment[] {
    return this.driverAssignments.filter((assignment) => !!assignment.assignedAt).slice(0, 3);
  }

  completeAssignmentRecord(assignment: DriverAssignment): void {
    if (!assignment?.id || this.assignmentActionInProgress) return;
    if (!this.driverId || assignment.status !== 'ASSIGNED') {
      this.driverService.showToast('Only active assignments can be completed.');
      return;
    }
    this.assignmentActionInProgress = true;
    this.driverService
      .unassignDriver(this.driverId, 'Assignment completed from driver detail')
      .subscribe({
        next: () => {
          this.driverService.showToast('Assignment marked as completed');
          this.reloadDriverAndVehicles();
          this.assignmentActionInProgress = false;
        },
        error: () => {
          this.driverService.showToast('❌ Failed to complete assignment');
          this.assignmentActionInProgress = false;
        },
      });
  }

  cancelAssignmentRecord(assignment: DriverAssignment): void {
    if (!assignment?.id || this.assignmentActionInProgress) return;
    if (!this.driverId || assignment.status !== 'ASSIGNED') {
      this.driverService.showToast('Only active assignments can be canceled.');
      return;
    }
    this.assignmentActionInProgress = true;
    this.driverService
      .unassignDriver(this.driverId, 'Assignment canceled from driver detail')
      .subscribe({
        next: () => {
          this.driverService.showToast('Assignment canceled');
          this.reloadDriverAndVehicles();
          this.assignmentActionInProgress = false;
        },
        error: () => {
          this.driverService.showToast('❌ Failed to cancel assignment');
          this.assignmentActionInProgress = false;
        },
      });
  }

  async deleteAssignmentRecord(assignment: DriverAssignment): Promise<void> {
    if (!assignment?.id || this.assignmentActionInProgress) return;
    if (!this.driverId || assignment.status !== 'ASSIGNED') {
      this.driverService.showToast(
        'Deleting historical assignment records is deprecated for permanent assignments.',
      );
      return;
    }
    const confirmed = await this.confirm.confirm('Unassign active assignment now?');
    if (!confirmed) return;
    this.assignmentActionInProgress = true;
    this.driverService
      .unassignDriver(this.driverId, 'Assignment removed from driver detail')
      .subscribe({
        next: () => {
          this.driverService.showToast('Assignment removed');
          this.reloadDriverAndVehicles();
          this.assignmentActionInProgress = false;
        },
        error: () => {
          this.driverService.showToast('❌ Failed to remove assignment');
          this.assignmentActionInProgress = false;
        },
      });
  }

  viewAssignmentVehicle(assignment: DriverAssignment): void {
    const vehicle = this.getVehicleInfo(assignment.vehicleId);
    if (vehicle) {
      this.viewVehicle(vehicle);
    } else {
      this.driverService.showToast('Vehicle details unavailable for this record');
    }
  }

  private reloadDriverAndVehicles(): void {
    this.loadDriverById(this.driverId);
    this.loadAvailableVehicles();
    this.loadDriverAssignments(this.driverId);
    this.loadCurrentAssignment();
  }

  loadCurrentAssignment(): void {
    if (!this.driverId) return;
    this.isAssignmentLoading = true;
    this.driverAssignmentExtended
      .getCurrent(this.driverId)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (res) => {
          const data = res.data;
          // Derive remaining minutes until temporaryExpiry if present
          if (data?.temporaryExpiry) {
            const ms = new Date(data.temporaryExpiry).getTime() - Date.now();
            const minutes = Math.max(0, Math.floor(ms / 60000));
            data.remainingMinutes = Number.isFinite(minutes) ? minutes : null;
          } else {
            data.remainingMinutes = null;
          }
          this.currentAssignment = data;
          this.refreshIdCardData();
          this.updateVehicleOverview();
          this.isAssignmentLoading = false;
        },
        error: () => {
          this.currentAssignment = null;
          this.isAssignmentLoading = false;
        },
      });
  }

  onSetTemporaryVehicle(vehicleId?: number): void {
    if (!this.driverId || !vehicleId) return;
    const expiry = new Date(Date.now() + this.tempAssignHours * 3600_000).toISOString();
    this.driverAssignmentExtended
      .setTemporary(this.driverId, { vehicleId, expiry, reason: 'Manual override' })
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: () => {
          this.driverService.showToast(' Temporary vehicle assigned');
          this.loadCurrentAssignment();
        },
        error: () => this.driverService.showToast(' Failed to set temporary vehicle'),
      });
  }

  onRemoveTemporary(): void {
    if (!this.driverId) return;
    this.driverAssignmentExtended
      .removeTemporary(this.driverId)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: () => {
          this.driverService.showToast(' Temporary assignment removed');
          this.loadCurrentAssignment();
        },
        error: () => this.driverService.showToast(' Failed to remove temporary assignment'),
      });
  }

  isActiveLifecycleStage(stage: string): boolean {
    const currentIndex = this.lifecycleStages.indexOf(this.lifecycleMasterStatus);
    const stageIndex = this.lifecycleStages.indexOf(stage);
    if (stageIndex < 0) return false;
    if (currentIndex < 0) return true;
    return stageIndex <= currentIndex;
  }

  async onLifecycleAction(action: 'Suspend' | 'Exit'): Promise<void> {
    if (this.lifecycleActionInProgress) return;
    const reason = window?.prompt
      ? window.prompt(`Optional: add a note when ${action.toLowerCase()}ing this driver:`, '')
      : '';
    const reasonLabel = reason?.trim() ? `\nReason: ${reason.trim()}` : '';
    const confirmed = await this.confirm.confirm(
      `Are you sure you want to ${action.toLowerCase()} this driver?${reasonLabel}`,
    );
    if (!confirmed || !this.driverId) return;
    this.lifecycleActionInProgress = true;
    this.driverService
      .updateDriverLifecycleStatus(this.driverId, {
        action,
        reason: reason?.trim() || '',
      })
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: () => {
          const note = reason?.trim() ? ` (${reason.trim()})` : '';
          this.lifecycleActionMessage = `Driver ${action.toLowerCase()}ed${note}`;
          this.driverService.showToast(this.lifecycleActionMessage);
          this.reloadDriverAndVehicles();
          this.loadDriverById(this.driverId);
          this.lifecycleActionInProgress = false;
        },
        error: () => {
          this.driverService.showToast(`Failed to ${action.toLowerCase()} driver`);
          this.lifecycleActionInProgress = false;
        },
      });
  }

  private updateLifecycleFromDriver(driver: Driver): void {
    if (!driver) return;
    const candidate =
      (driver as any).lifecycleStage ?? driver.status ?? (driver.isActive ? 'ACTIVE' : 'INACTIVE');
    const normalized = String(candidate || '').toUpperCase();
    if (this.lifecycleStages.includes(normalized)) {
      this.lifecycleMasterStatus = normalized;
    } else {
      this.lifecycleMasterStatus = driver.isActive ? 'ACTIVE' : 'INACTIVE';
    }
  }
}
