/* eslint-disable @typescript-eslint/consistent-type-imports */
import { CommonModule } from '@angular/common';
import { OnDestroy, OnInit, ElementRef } from '@angular/core';
import { Component, ViewChild, HostListener } from '@angular/core';
import { FormsModule, ReactiveFormsModule, FormControl, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import { ConfirmService } from '@services/confirm.service';
import type { Driver } from '@models/driver.model';
import { DriverService } from '@services/driver.service';
import { Subject, forkJoin, debounceTime, distinctUntilChanged, switchMap, of } from 'rxjs';
import { takeUntil, catchError } from 'rxjs/operators';

interface AttendanceRecord {
  id?: number;
  driverId: number;
  driverName?: string;
  truckPlateNo?: string;
  date: string; // YYYY-MM-DD
  status: 'PRESENT' | 'ABSENT' | 'LATE' | 'ON_LEAVE' | 'OFF_DUTY';
  checkInTime?: string; // HH:mm
  checkOutTime?: string; // HH:mm
  hoursWorked?: number;
  notes?: string;
}

@Component({
  selector: 'app-driver-attendance',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, FormsModule],
  templateUrl: './driver-attendance.component.html',
  styleUrls: ['./driver-attendance.component.css'],
})
export class DriverAttendanceComponent implements OnInit, OnDestroy {
  driverIdCtrl = new FormControl<number | null>(null);
  yearCtrl = new FormControl<number>(new Date().getFullYear());
  monthCtrl = new FormControl<number>(new Date().getMonth() + 1);
  fromDateCtrl = new FormControl<string>('');
  toDateCtrl = new FormControl<string>('');

  isLoading = false;
  errorMessage = '';
  summary: any = null;
  records: AttendanceRecord[] = [];
  monthPage = 0;
  monthSize = 20;
  monthTotalPages = 0;
  monthTotalElements = 0;

  get monthShowingStart(): number {
    return this.monthTotalElements > 0 ? this.monthPage * this.monthSize + 1 : 0;
  }
  get monthShowingEnd(): number {
    const total = this.monthTotalElements || 0;
    const end = (this.monthPage + 1) * this.monthSize;
    return total > 0 ? (end < total ? end : total) : 0;
  }

  driverQueryCtrlTop = new FormControl<string>('');
  driverResultsTop: Driver[] = [];
  showDropdownTop = false;
  isSearchingTop = false;
  selectedDriverTop: Driver | null = null;
  activeIndexTop = -1;

  driverQueryCtrlModal = new FormControl<string>('');
  driverResultsModal: Driver[] = [];
  showDropdownModal = false;
  isSearchingModal = false;
  selectedDriverModal: Driver | null = null;
  activeIndexModal = -1;

  readonly maxResults = 20;

  @ViewChild('topWrapper', { static: false }) topWrapper?: ElementRef<HTMLElement>;
  @ViewChild('modalWrapper', { static: false }) modalWrapper?: ElementRef<HTMLElement>;

  isModalOpen = false;
  isEditing = false;
  saveInProgress = false;
  formError = '';
  form = {
    id: null as number | null,
    driverId: new FormControl<number | null>(null),
    date: new FormControl<string>('', { validators: [Validators.required] }),
    endDate: new FormControl<string>(''),
    status: new FormControl<'ON_LEAVE' | 'OFF_DUTY'>('ON_LEAVE', { nonNullable: true }),
    checkInTime: new FormControl<string | undefined>(''),
    checkOutTime: new FormControl<string | undefined>(''),
    notes: new FormControl<string>(''),
  };

  private destroy$ = new Subject<void>();

  constructor(
    private readonly driverService: DriverService,
    private readonly router: Router,
    private readonly confirm: ConfirmService,
  ) {}

  ngOnInit(): void {
    this.driverQueryCtrlTop.valueChanges
      .pipe(
        debounceTime(250),
        distinctUntilChanged(),
        switchMap((q) => {
          const query = (q || '').trim();
          if (query.length < 2) {
            this.driverResultsTop = [];
            this.showDropdownTop = false;
            this.activeIndexTop = -1;
            return of(null);
          }
          this.isSearchingTop = true;
          return this.driverService.searchDrivers(query).pipe(catchError(() => of(null)));
        }),
      )
      .pipe(takeUntil(this.destroy$))
      .subscribe((res) => {
        this.isSearchingTop = false;
        if (!res) return;
        const list = Array.isArray(res?.data) ? res.data : [];
        this.driverResultsTop = list.slice(0, this.maxResults);
        this.showDropdownTop = this.driverResultsTop.length > 0;
        this.activeIndexTop = this.driverResultsTop.length ? 0 : -1;
      });

    this.driverQueryCtrlModal.valueChanges
      .pipe(
        debounceTime(250),
        distinctUntilChanged(),
        switchMap((q) => {
          const query = (q || '').trim();
          if (query.length < 2) {
            this.driverResultsModal = [];
            this.showDropdownModal = false;
            this.activeIndexModal = -1;
            return of(null);
          }
          this.isSearchingModal = true;
          return this.driverService.searchDrivers(query).pipe(catchError(() => of(null)));
        }),
      )
      .pipe(takeUntil(this.destroy$))
      .subscribe((res) => {
        this.isSearchingModal = false;
        if (!res) return;
        const list = Array.isArray(res?.data) ? res.data : [];
        this.driverResultsModal = list.slice(0, this.maxResults);
        this.showDropdownModal = this.driverResultsModal.length > 0;
        this.activeIndexModal = this.driverResultsModal.length ? 0 : -1;
      });
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  loadAttendance(): void {
    this.errorMessage = '';
    this.records = [];
    this.summary = null;

    const driverId = this.driverIdCtrl.value ?? 0;
    const year = this.yearCtrl.value ?? new Date().getFullYear();
    const month = this.monthCtrl.value ?? new Date().getMonth() + 1;
    const fromDate = (this.fromDateCtrl.value || '').trim();
    const toDate = (this.toDateCtrl.value || '').trim();

    this.isLoading = true;

    if (!driverId) {
      this.driverService
        .getAttendanceByMonth(year, month, {
          permissionOnly: true,
          page: this.monthPage,
          size: this.monthSize,
          fromDate: fromDate || undefined,
          toDate: toDate || undefined,
        })
        .pipe(takeUntil(this.destroy$))
        .subscribe({
          next: (res: any) => {
            const page = res?.data;
            this.records = (page?.content ?? []) as AttendanceRecord[];
            this.monthTotalPages = page?.totalPages ?? 0;
            this.monthTotalElements = page?.totalElements ?? 0;
            this.summary = null;
          },
          error: (err: any) => {
            console.error('[Attendance] month-wide load failed', err);
            this.errorMessage = 'Failed to load records. Please try again.';
          },
          complete: () => {
            this.isLoading = false;
          },
        });
      return;
    }

    forkJoin({
      list: this.driverService.getDriverAttendance(driverId, year, month),
      summary: this.driverService.getDriverAttendanceSummary(driverId, year, month),
    })
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: ({ list, summary }: any) => {
          this.records = (list?.data ?? []) as AttendanceRecord[];
          this.summary = summary?.data ?? null;
        },
        error: (err: any) => {
          console.error('[Attendance] load failed', err);
          this.errorMessage = 'Failed to load attendance. Please try again.';
        },
        complete: () => {
          this.isLoading = false;
        },
      });
  }

  goPrevMonthPage(): void {
    if (this.monthPage > 0) {
      this.monthPage -= 1;
      this.loadAttendance();
    }
  }
  goNextMonthPage(): void {
    if (this.monthPage + 1 < this.monthTotalPages) {
      this.monthPage += 1;
      this.loadAttendance();
    }
  }

  onChangeMonthSize(val: number | string): void {
    const n = Number(val);
    if (!Number.isFinite(n)) return;
    const clamped = Math.min(Math.max(Math.trunc(n), 5), 200);
    if (clamped === this.monthSize) return;
    this.monthSize = clamped;
    this.monthPage = 0;
    this.loadAttendance();
  }

  onTopFocus(): void {
    this.showDropdownTop = this.driverResultsTop.length > 0;
  }
  onTopBlur(): void {
    setTimeout(() => (this.showDropdownTop = false), 120);
  }

  pickDriverTop(driver: Driver, event?: Event): void {
    if (event) event.preventDefault();
    this.selectedDriverTop = driver;
    this.driverIdCtrl.setValue(driver.id);
    const label = driver.name || `${driver.firstName || ''} ${driver.lastName || ''}`.trim();
    this.driverQueryCtrlTop.setValue(label, { emitEvent: false });
    this.showDropdownTop = false;
    this.activeIndexTop = -1;
  }
  clearDriverTop(): void {
    this.selectedDriverTop = null;
    this.driverIdCtrl.setValue(null);
    this.driverQueryCtrlTop.setValue('');
    this.showDropdownTop = false;
    this.activeIndexTop = -1;
  }

  onModalFocus(): void {
    this.showDropdownModal = this.driverResultsModal.length > 0;
  }
  onModalBlur(): void {
    setTimeout(() => (this.showDropdownModal = false), 120);
  }

  pickDriverModal(driver: Driver, event?: Event): void {
    if (event) event.preventDefault();
    this.selectedDriverModal = driver;
    this.form.driverId.setValue(driver.id);
    const label = driver.name || `${driver.firstName || ''} ${driver.lastName || ''}`.trim();
    this.driverQueryCtrlModal.setValue(label, { emitEvent: false });
    this.showDropdownModal = false;
    this.activeIndexModal = -1;
  }
  clearDriverModal(): void {
    this.selectedDriverModal = null;
    this.form.driverId.setValue(this.driverIdCtrl.value ?? null);
    this.driverQueryCtrlModal.setValue('');
    this.showDropdownModal = false;
    this.activeIndexModal = -1;
  }

  onTopKeyDown(event: KeyboardEvent): void {
    if (!this.showDropdownTop && (event.key === 'ArrowDown' || event.key === 'ArrowUp')) {
      this.showDropdownTop = this.driverResultsTop.length > 0;
    }
    switch (event.key) {
      case 'ArrowDown':
        event.preventDefault();
        if (this.driverResultsTop.length) {
          this.activeIndexTop = (this.activeIndexTop + 1) % this.driverResultsTop.length;
        }
        break;
      case 'ArrowUp':
        event.preventDefault();
        if (this.driverResultsTop.length) {
          this.activeIndexTop =
            (this.activeIndexTop - 1 + this.driverResultsTop.length) % this.driverResultsTop.length;
        }
        break;
      case 'Enter':
        if (this.showDropdownTop && this.activeIndexTop >= 0) {
          event.preventDefault();
          this.pickDriverTop(this.driverResultsTop[this.activeIndexTop]);
        }
        break;
      case 'Escape':
        this.showDropdownTop = false;
        break;
    }
  }

  onModalKeyDown(event: KeyboardEvent): void {
    if (!this.showDropdownModal && (event.key === 'ArrowDown' || event.key === 'ArrowUp')) {
      this.showDropdownModal = this.driverResultsModal.length > 0;
    }
    switch (event.key) {
      case 'ArrowDown':
        event.preventDefault();
        if (this.driverResultsModal.length) {
          this.activeIndexModal = (this.activeIndexModal + 1) % this.driverResultsModal.length;
        }
        break;
      case 'ArrowUp':
        event.preventDefault();
        if (this.driverResultsModal.length) {
          this.activeIndexModal =
            (this.activeIndexModal - 1 + this.driverResultsModal.length) %
            this.driverResultsModal.length;
        }
        break;
      case 'Enter':
        if (this.showDropdownModal && this.activeIndexModal >= 0) {
          event.preventDefault();
          this.pickDriverModal(this.driverResultsModal[this.activeIndexModal]);
        }
        break;
      case 'Escape':
        this.showDropdownModal = false;
        break;
    }
  }

  searchDriversTop(): void {
    const query = (this.driverQueryCtrlTop.value || '').trim();
    if (query.length < 2) return;
    this.isSearchingTop = true;
    this.driverService
      .searchDrivers(query)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (res: any) => {
          const list = Array.isArray(res?.data) ? res.data : [];
          this.driverResultsTop = list.slice(0, this.maxResults);
          this.showDropdownTop = this.driverResultsTop.length > 0;
          this.activeIndexTop = this.driverResultsTop.length ? 0 : -1;
        },
        error: () => {
          this.driverResultsTop = [];
          this.showDropdownTop = false;
        },
        complete: () => (this.isSearchingTop = false),
      });
  }

  searchDriversModal(): void {
    const query = (this.driverQueryCtrlModal.value || '').trim();
    if (query.length < 2) return;
    this.isSearchingModal = true;
    this.driverService
      .searchDrivers(query)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (res: any) => {
          const list = Array.isArray(res?.data) ? res.data : [];
          this.driverResultsModal = list.slice(0, this.maxResults);
          this.showDropdownModal = this.driverResultsModal.length > 0;
          this.activeIndexModal = this.driverResultsModal.length ? 0 : -1;
        },
        error: () => {
          this.driverResultsModal = [];
          this.showDropdownModal = false;
        },
        complete: () => (this.isSearchingModal = false),
      });
  }

  @HostListener('document:click', ['$event'])
  onDocumentClick(event: MouseEvent): void {
    const target = event.target as HTMLElement;
    if (this.topWrapper && !this.topWrapper.nativeElement.contains(target)) {
      this.showDropdownTop = false;
    }
    if (this.modalWrapper && !this.modalWrapper.nativeElement.contains(target)) {
      this.showDropdownModal = false;
    }
  }

  highlightText(text: string | undefined, query: string | null | undefined): string {
    const t = (text || '').toString();
    const q = (query || '').trim();
    if (!q) return this.escapeHtml(t);
    const safeT = this.escapeHtml(t);
    const re = new RegExp(this.escapeRegExp(q), 'ig');
    return safeT.replace(re, (m) => `<mark>${this.escapeHtml(m)}</mark>`);
  }
  private escapeHtml(str: string): string {
    return str
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#039;');
  }
  private escapeRegExp(str: string): string {
    return str.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  }

  openCreate(): void {
    this.isEditing = false;
    this.form.id = null;
    this.formError = '';
    this.form.driverId.setValue(this.driverIdCtrl.value ?? null);
    this.form.date.setValue('');
    this.form.endDate.setValue('');
    this.form.status.setValue('ON_LEAVE');
    this.form.checkInTime.setValue('');
    this.form.checkOutTime.setValue('');
    this.form.notes.setValue('');
    this.isModalOpen = true;
  }
  openEdit(rec: AttendanceRecord): void {
    this.isEditing = true;
    this.form.id = rec.id ?? null;
    this.formError = '';
    this.form.driverId.setValue(rec.driverId);
    this.form.date.setValue(rec.date);
    this.form.endDate.setValue('');
    this.form.status.setValue((rec.status as any) || 'ON_LEAVE');
    this.form.checkInTime.setValue(rec.checkInTime || '');
    this.form.checkOutTime.setValue(rec.checkOutTime || '');
    this.form.notes.setValue(rec.notes || '');
    this.isModalOpen = true;
  }
  closeModal(): void {
    this.isModalOpen = false;
  }

  save(): void {
    this.formError = '';
    const driverId = this.form.driverId.value || this.driverIdCtrl.value;
    const date = (this.form.date.value || '').trim();
    const endDate = (this.form.endDate.value || '').trim();
    const status = this.form.status.value;

    if (!driverId) {
      this.formError = 'Driver is required';
      return;
    }
    if (!date) {
      this.formError = 'Date is required';
      return;
    }

    if (!this.isEditing && endDate) {
      if (endDate < date) {
        this.formError = 'End date must be after or equal to start date';
        return;
      }
      const bulkPayload = {
        driverId: driverId!,
        fromDate: date,
        toDate: endDate,
        status: status || 'ON_LEAVE',
        notes: this.form.notes.value || undefined,
      };
      this.saveInProgress = true;
      this.driverService
        .addPermissionRange(bulkPayload)
        .pipe(takeUntil(this.destroy$))
        .subscribe({
          next: () => {
            this.closeModal();
            this.loadAttendance();
          },
          error: (err: any) => {
            console.error('Bulk save failed', err);
            this.formError = err?.error?.message || 'Failed to save range. Please try again.';
          },
          complete: () => (this.saveInProgress = false),
        });
      return;
    }

    const payload: any = {
      driverId,
      date,
      status,
      checkInTime: this.form.checkInTime.value || undefined,
      checkOutTime: this.form.checkOutTime.value || undefined,
      notes: this.form.notes.value || undefined,
    };

    this.saveInProgress = true;
    const op$ =
      this.isEditing && this.form.id
        ? this.driverService.updateAttendanceRecord(this.form.id, payload)
        : this.driverService.addAttendanceRecord(payload);

    op$.pipe(takeUntil(this.destroy$)).subscribe({
      next: () => {
        this.closeModal();
        this.loadAttendance();
      },
      error: (err: any) => {
        console.error('Save failed', err);
        this.formError =
          err?.error?.message ||
          (err?.status
            ? `Failed to save record (HTTP ${err.status}). Please try again.`
            : 'Failed to save record. Please try again.');
      },
      complete: () => (this.saveInProgress = false),
    });
  }

  async delete(rec: AttendanceRecord): Promise<void> {
    if (!rec.id) return;
    if (!(await this.confirm.confirm('Delete this permission record?'))) return;
    this.driverService
      .deleteAttendanceRecord(rec.id)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: () => this.loadAttendance(),
        error: (err: any) => console.error('Delete failed', err),
      });
  }

  goToDriver(driverId: number): void {
    this.router.navigate(['/fleet/drivers', driverId]);
  }

  statusBadgeClass(status: string): string {
    switch ((status || '').toUpperCase()) {
      case 'PRESENT':
        return 'bg-green-100 text-green-800';
      case 'LATE':
        return 'bg-yellow-100 text-yellow-800';
      case 'ABSENT':
        return 'bg-red-100 text-red-800';
      case 'ON_LEAVE':
        return 'bg-blue-100 text-blue-800';
      case 'OFF_DUTY':
        return 'bg-gray-100 text-gray-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  }
}
