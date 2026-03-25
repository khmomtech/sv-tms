/* eslint-disable @typescript-eslint/consistent-type-imports */
import { CommonModule } from '@angular/common';
import { Component, Input, inject, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';

import type { ApiResponse } from '../../../../models/api-response.model';
import { DriverService } from '../../../../services/driver.service';
import { ConfirmService } from '../../../../services/confirm.service';

interface AttendanceRecord {
  id?: number;
  driverId: number;
  date: string;
  clockInTime?: string;
  clockOutTime?: string;
  totalHours?: number;
  status: 'present' | 'absent' | 'late' | 'half-day';
  notes?: string;
  location?: string;
}

interface AttendanceSummary {
  totalDays: number;
  presentDays: number;
  absentDays: number;
  lateDays: number;
  totalHours: number;
  averageHours: number;
}

@Component({
  selector: 'app-driver-attendance-tab',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './driver-attendance-tab.component.html',
})
export class DriverAttendanceTabComponent implements OnInit {
  private confirm = inject(ConfirmService);
  @Input() driverId!: number;

  attendanceRecords: AttendanceRecord[] = [];
  filteredRecords: AttendanceRecord[] = [];
  summary: AttendanceSummary | null = null;

  isLoading = false;
  showClockModal = false;
  selectedRecord: AttendanceRecord | null = null;

  // Filters
  selectedMonth = new Date().getMonth() + 1;
  selectedYear = new Date().getFullYear();
  statusFilter = '';

  // Clock in/out
  currentTime = new Date();
  clockInTime: string = '';
  clockOutTime: string = '';
  attendanceNotes: string = '';

  // Quick stats
  todayAttendance: AttendanceRecord | null = null;
  isClockedIn = false;

  private clockInterval: any;

  constructor(private driverService: DriverService) {}

  ngOnInit(): void {
    if (this.driverId) {
      this.loadAttendanceRecords();
      this.loadAttendanceSummary();
      this.checkTodayAttendance();
    }

    // Update current time every second
    this.clockInterval = setInterval(() => {
      this.currentTime = new Date();
    }, 1000);
  }

  ngOnDestroy(): void {
    if (this.clockInterval) {
      clearInterval(this.clockInterval);
    }
  }

  loadAttendanceRecords(): void {
    this.isLoading = true;
    this.driverService
      .getDriverAttendance(this.driverId, this.selectedYear, this.selectedMonth)
      .subscribe({
        next: (res: ApiResponse<AttendanceRecord[]>) => {
          this.attendanceRecords = res.data;
          this.applyFilters();
          this.isLoading = false;
        },
        error: () => {
          this.attendanceRecords = [];
          this.filteredRecords = [];
          this.isLoading = false;
          this.driverService.showToast('Failed to load attendance records');
        },
      });
  }

  loadAttendanceSummary(): void {
    this.driverService
      .getDriverAttendanceSummary(this.driverId, this.selectedYear, this.selectedMonth)
      .subscribe({
        next: (res: ApiResponse<AttendanceSummary>) => {
          this.summary = res.data;
        },
        error: () => {
          this.summary = null;
          this.driverService.showToast('Failed to load attendance summary');
        },
      });
  }

  checkTodayAttendance(): void {
    const today = new Date().toISOString().split('T')[0];
    this.driverService.getDriverAttendanceByDate(this.driverId, today).subscribe({
      next: (res: ApiResponse<AttendanceRecord | null>) => {
        this.todayAttendance = res.data;
        this.isClockedIn = !!(
          this.todayAttendance &&
          this.todayAttendance.clockInTime &&
          !this.todayAttendance.clockOutTime
        );
      },
      error: () => {
        this.todayAttendance = null;
        this.isClockedIn = false;
      },
    });
  }

  applyFilters(): void {
    let filtered = [...this.attendanceRecords];

    if (this.statusFilter) {
      filtered = filtered.filter((record) => record.status === this.statusFilter);
    }

    this.filteredRecords = filtered;
  }

  onMonthChange(): void {
    this.loadAttendanceRecords();
    this.loadAttendanceSummary();
  }

  onStatusFilterChange(): void {
    this.applyFilters();
  }

  getStatusColor(status: string): string {
    switch (status) {
      case 'present':
        return 'text-green-600 bg-green-100';
      case 'absent':
        return 'text-red-600 bg-red-100';
      case 'late':
        return 'text-yellow-600 bg-yellow-100';
      case 'half-day':
        return 'text-orange-600 bg-orange-100';
      default:
        return 'text-gray-600 bg-gray-100';
    }
  }

  getStatusIcon(status: string): string {
    switch (status) {
      case 'present':
        return '✅';
      case 'absent':
        return '❌';
      case 'late':
        return '⏰';
      case 'half-day':
        return '🔶';
      default:
        return '❓';
    }
  }

  formatTime(time: string | undefined): string {
    if (!time) return '-';
    return new Date(`1970-01-01T${time}`).toLocaleTimeString([], {
      hour: '2-digit',
      minute: '2-digit',
    });
  }

  calculateHours(record: AttendanceRecord): string {
    if (record.totalHours) {
      return `${record.totalHours.toFixed(1)}h`;
    }

    if (record.clockInTime && record.clockOutTime) {
      const clockIn = new Date(`1970-01-01T${record.clockInTime}`);
      const clockOut = new Date(`1970-01-01T${record.clockOutTime}`);
      const hours = (clockOut.getTime() - clockIn.getTime()) / (1000 * 60 * 60);
      return `${hours.toFixed(1)}h`;
    }

    return '-';
  }

  openClockModal(): void {
    this.clockInTime = '';
    this.clockOutTime = '';
    this.attendanceNotes = '';
    this.showClockModal = true;
  }

  closeClockModal(): void {
    this.showClockModal = false;
  }

  clockIn(): void {
    if (!this.driverId) return;

    const now = new Date();
    const timeString = now.toTimeString().split(' ')[0].substring(0, 5); // HH:MM format

    const record: AttendanceRecord = {
      driverId: this.driverId,
      date: now.toISOString().split('T')[0],
      clockInTime: timeString,
      status: 'present',
      notes: this.attendanceNotes || 'Clocked in automatically',
    };

    this.driverService.addAttendanceRecord(record).subscribe({
      next: (res) => {
        this.driverService.showToast('🕐 Clocked in successfully');
        this.checkTodayAttendance();
        this.loadAttendanceRecords();
        this.closeClockModal();
      },
      error: () => {
        this.driverService.showToast('Failed to clock in');
      },
    });
  }

  clockOut(): void {
    if (!this.todayAttendance) return;

    const now = new Date();
    const timeString = now.toTimeString().split(' ')[0].substring(0, 5);

    const updatedRecord = {
      ...this.todayAttendance,
      clockOutTime: timeString,
      notes: this.attendanceNotes || this.todayAttendance.notes,
    };

    this.driverService.updateAttendanceRecord(this.todayAttendance.id!, updatedRecord).subscribe({
      next: (res) => {
        this.driverService.showToast('🕐 Clocked out successfully');
        this.checkTodayAttendance();
        this.loadAttendanceRecords();
        this.closeClockModal();
      },
      error: () => {
        this.driverService.showToast('Failed to clock out');
      },
    });
  }

  markAttendance(status: 'present' | 'absent' | 'late' | 'half-day'): void {
    if (!this.driverId) return;

    const today = new Date().toISOString().split('T')[0];

    const record: AttendanceRecord = {
      driverId: this.driverId,
      date: today,
      status: status,
      notes: this.attendanceNotes || `Marked as ${status}`,
    };

    this.driverService.addAttendanceRecord(record).subscribe({
      next: (res) => {
        this.driverService.showToast(`📅 Marked as ${status}`);
        this.checkTodayAttendance();
        this.loadAttendanceRecords();
        this.closeClockModal();
      },
      error: () => {
        this.driverService.showToast('Failed to mark attendance');
      },
    });
  }

  editAttendance(record: AttendanceRecord): void {
    this.selectedRecord = { ...record };
    this.clockInTime = record.clockInTime || '';
    this.clockOutTime = record.clockOutTime || '';
    this.attendanceNotes = record.notes || '';
    this.showClockModal = true;
  }

  updateAttendance(): void {
    if (!this.selectedRecord) return;

    const updatedRecord = {
      ...this.selectedRecord,
      clockInTime: this.clockInTime,
      clockOutTime: this.clockOutTime,
      notes: this.attendanceNotes,
    };

    this.driverService.updateAttendanceRecord(this.selectedRecord.id!, updatedRecord).subscribe({
      next: (res) => {
        this.driverService.showToast('📝 Attendance updated');
        this.loadAttendanceRecords();
        this.closeClockModal();
      },
      error: () => {
        this.driverService.showToast('Failed to update attendance');
      },
    });
  }

  async deleteAttendance(record: AttendanceRecord): Promise<void> {
    if (!(await this.confirm.confirm(`Delete attendance record for ${record.date}?`))) return;

    this.driverService.deleteAttendanceRecord(record.id!).subscribe({
      next: () => {
        this.driverService.showToast('🗑️ Attendance record deleted');
        this.loadAttendanceRecords();
        this.checkTodayAttendance();
      },
      error: () => {
        this.driverService.showToast('Failed to delete attendance record');
      },
    });
  }

  getAttendancePercentage(): number {
    if (!this.summary || this.summary.totalDays === 0) return 0;
    return Math.round((this.summary.presentDays / this.summary.totalDays) * 100);
  }
}
