/* eslint-disable @typescript-eslint/consistent-type-imports */
import { CommonModule } from '@angular/common';
import { OnInit } from '@angular/core';
import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { TranslateModule, TranslateService } from '@ngx-translate/core';

import type { DispatchDayReportRow } from '../models/dispatch-day-report-row';
import type { DispatchDayOpts } from '../services/reports.service';
import { ReportsService } from '../services/reports.service';

@Component({
  selector: 'app-dispatch-day-report',
  standalone: true,
  imports: [CommonModule, FormsModule, TranslateModule],
  templateUrl: './dispatch-day-report.component.html',
  styleUrls: ['./dispatch-day-report.component.css'],
})
export class DispatchDayReportComponent implements OnInit {
  // ===== Required date filters =====
  planFrom = ''; // yyyy-MM-dd
  planTo = ''; // yyyy-MM-dd

  // ===== Optional time filters =====
  fromTime = ''; // "HH:mm"
  toTime = ''; // "HH:mm"
  toExtraDays: number | null = 2; // used only when toTime is empty

  // ===== Data + UI state =====
  rows: DispatchDayReportRow[] = [];
  loading = false;
  error: string | null = null;

  constructor(
    private reports: ReportsService,
    private translate: TranslateService,
  ) {}

  ngOnInit(): void {
    const today = this.toDateInputStr(new Date());
    this.planFrom = today;
    this.planTo = today;
  }

  // --------------------------------------------------------------------
  // Build query options for backend (send only valid/meaningful fields)
  // --------------------------------------------------------------------
  private buildOpts(): DispatchDayOpts | undefined {
    const opts: DispatchDayOpts = {};

    const normTime = (t: string) => {
      const s = (t || '').trim();
      return /^\d{2}:\d{2}$/.test(s) ? s : '';
    };

    const from = normTime(this.fromTime);
    const to = normTime(this.toTime);

    if (from) opts.fromTime = from;
    if (to) opts.toTime = to;

    // Only send toExtraDays when toTime is NOT provided
    if (!opts.toTime && this.toExtraDays != null) {
      const days = Number(this.toExtraDays);
      if (Number.isFinite(days) && days >= 0 && days <= 30) {
        opts.toExtraDays = Math.floor(days);
      }
    }

    return Object.keys(opts).length ? opts : undefined;
  }

  // --------------------------------------------------------------------
  // Actions
  // --------------------------------------------------------------------
  search(): void {
    this.error = null;

    if (!this.planFrom || !this.planTo) {
      this.error = this.translate.instant('reports.dispatchDay.select_plan_range');
      return;
    }

    // Validate time inputs (HH:mm)
    const hhmm = /^([01]\d|2[0-3]):[0-5]\d$/;
    if (this.fromTime && !hhmm.test(this.fromTime.trim())) {
      this.error = this.translate.instant('reports.dispatchDay.invalid_from_time');
      return;
    }
    if (this.toTime && !hhmm.test(this.toTime.trim())) {
      this.error = this.translate.instant('reports.dispatchDay.invalid_to_time');
      return;
    }
    if (!this.toTime && this.toExtraDays != null && this.toExtraDays < 0) {
      this.error = this.translate.instant('reports.dispatchDay.invalid_extra_days');
      return;
    }

    this.loading = true;
    this.reports.getDispatchDay(this.planFrom, this.planTo, this.buildOpts()).subscribe({
      next: (data) => {
        this.rows = Array.isArray(data) ? data : [];
        this.loading = false;
      },
      error: (err) => {
        this.error =
          err?.error?.message || this.translate.instant('reports.dispatchDay.load_failed');
        this.loading = false;
      },
    });
  }

  exportCsv(): void {
    this.error = null;
    if (!this.planFrom || !this.planTo) {
      this.error = this.translate.instant('reports.dispatchDay.select_export_range');
      return;
    }
    this.reports.exportDispatchDay(this.planFrom, this.planTo, this.buildOpts()).subscribe({
      next: (blob) => this.download(blob, `dispatch-day-${this.planFrom}-${this.planTo}.csv`),
      error: () => {
        this.error = this.translate.instant('reports.dispatchDay.export_csv_failed');
      },
    });
  }

  exportExcel(): void {
    this.error = null;
    if (!this.planFrom || !this.planTo) {
      this.error = this.translate.instant('reports.dispatchDay.select_export_range');
      return;
    }
    this.reports.exportDispatchDayExcel(this.planFrom, this.planTo, this.buildOpts()).subscribe({
      next: (blob) => this.download(blob, `dispatch-day-${this.planFrom}-${this.planTo}.xlsx`),
      error: () => {
        this.error = this.translate.instant('reports.dispatchDay.export_excel_failed');
      },
    });
  }

  resetFilters(): void {
    this.fromTime = '';
    this.toTime = '';
    this.toExtraDays = 2;
    this.error = null;
  }

  // --------------------------------------------------------------------
  // Download helper
  // --------------------------------------------------------------------
  private download(blob: Blob, filename: string): void {
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = filename;
    a.style.display = 'none';
    document.body.appendChild(a);
    a.click();
    setTimeout(() => {
      URL.revokeObjectURL(url);
      document.body.removeChild(a);
    }, 0);
  }

  // --------------------------------------------------------------------
  // Summary getters (typed, no any)
  // --------------------------------------------------------------------
  get totalPallets(): number {
    return (this.rows ?? []).reduce((sum, r) => sum + Number(r.numberOfPallets ?? 0), 0);
  }

  // Optional: make rows clickable
  openRow(r: DispatchDayReportRow): void {
    // Example: navigate to a detail page if you have IDs
    // this.router.navigate(['/dispatches', r.dispatchId]);
    console.debug('[row-open]', r);
  }

  // For *ngFor trackBy (prefer stable ids; otherwise a composite key)
  public trackRow = (_: number, r: DispatchDayReportRow): string | number => {
    // If your row has a stable id, return it here:
    // if ((r as any).id != null) return (r as any).id;
    const plan = this.fmtDate(r.planDate) || '';
    const truck = r.truckNo || '';
    const depot = r.depot || '';
    return `${truck}|${depot}|${plan}`;
  };

  // --------------------------------------------------------------------
  // Formatting helpers (used in template)
  // --------------------------------------------------------------------

  // Format just a date (Plan Date): dd-MM-yyyy
  fmtDate(v: DispatchDayReportRow['planDate'] | unknown): string {
    if (v == null) return '';

    // already "dd-MM-yyyy"?
    if (typeof v === 'string' && /^\d{2}-\d{2}-\d{4}$/.test(v)) return v;

    // LocalDate array [yyyy, m, d]
    if (Array.isArray(v) && v.length >= 3) {
      const [y, m, d] = v as [number, number, number];
      return `${this.pad2(d)}-${this.pad2(m)}-${y}`;
    }

    // Fallback: parse to Date and render in PP (as date only)
    const dt = this.coerceToDate(v);
    return dt ? this.formatInPP(dt, false) : '';
  }

  // Format date+time: dd-MM-yyyy HH:mm
  fmtDt(v: unknown): string {
    if (v == null) return '';

    // already formatted like "dd-MM-yyyy HH:mm"
    if (typeof v === 'string' && /^\d{2}-\d{2}-\d{4}\s+\d{2}:\d{2}$/.test(v)) return v;

    const dt = this.coerceToDate(v);
    return dt ? this.formatInPP(dt, true) : '';
  }

  // Accepts array forms, epoch (sec/ms), ISO strings, Date
  private coerceToDate(v: unknown): Date | null {
    if (v == null) return null;

    // [y,m,d,h,mi,ss] or [y,m,d]
    if (Array.isArray(v)) {
      const arr = (v as Array<number>).map(Number);
      if (arr.length >= 3) {
        const [y, m, d, hh = 0, mi = 0, ss = 0] = arr;
        if (!Number.isFinite(y) || !Number.isFinite(m) || !Number.isFinite(d)) return null;
        return new Date(y, m - 1, d, hh, mi, ss);
      }
    }

    // Date
    if (v instanceof Date) return isNaN(v.getTime()) ? null : v;

    // Numeric (epoch sec/ms) or numeric string
    const n = Number(v as any);
    if (Number.isFinite(n)) {
      const ms = n < 1e12 ? Math.round(n * 1000) : Math.round(n); // <1e12 → seconds
      const d = new Date(ms);
      return isNaN(d.getTime()) ? null : d;
    }

    // ISO or "yyyy-MM-dd" strings
    if (typeof v === 'string' && v.trim()) {
      if (/^\d{4}-\d{2}-\d{2}$/.test(v)) {
        const [y, m, d] = v.split('-').map(Number);
        return new Date(y, m - 1, d);
      }
      const d = new Date(v);
      return isNaN(d.getTime()) ? null : d;
    }

    return null;
  }

  // Phnom Penh timezone formatting (TS-safe, no index-signature warnings)
  private formatInPP(d: Date, withTime: boolean): string {
    const tz = 'Asia/Phnom_Penh';
    const opts: Intl.DateTimeFormatOptions = {
      timeZone: tz,
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      ...(withTime ? { hour: '2-digit', minute: '2-digit', hour12: false } : {}),
    };

    const parts = new Intl.DateTimeFormat('en-GB', opts).formatToParts(d);

    // Map the parts we care about with explicit properties (no index signature)
    type DParts = {
      day?: string;
      month?: string;
      year?: string;
      hour?: string;
      minute?: string;
    };

    const mapped: DParts = {};
    for (const p of parts) {
      if (p.type === 'day') mapped.day = p.value;
      else if (p.type === 'month') mapped.month = p.value;
      else if (p.type === 'year') mapped.year = p.value;
      else if (p.type === 'hour') mapped.hour = p.value;
      else if (p.type === 'minute') mapped.minute = p.value;
    }

    const dd = this.pad2(Number(mapped.day ?? 0));
    const MM = this.pad2(Number(mapped.month ?? 0));
    const yyyy = mapped.year ?? '';

    if (!withTime) return `${dd}-${MM}-${yyyy}`;

    const HH = this.pad2(Number(mapped.hour ?? 0));
    const mm = this.pad2(Number(mapped.minute ?? 0));
    return `${dd}-${MM}-${yyyy} ${HH}:${mm}`;
  }

  private toDateInputStr(d: Date): string {
    const pad = (n: number) => (n < 10 ? '0' + n : '' + n);
    return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
  }

  private pad2(n: number): string {
    return n < 10 ? `0${n}` : `${n}`;
  }

  // --- Quick preset helpers ---
  private toYmd(d: Date): string {
    const pad = (n: number) => (n < 10 ? '0' + n : '' + n);
    return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
  }

  presetToday(): void {
    const today = this.toYmd(new Date());
    this.planFrom = today;
    this.planTo = today;
    this.fromTime = '00:00';
    this.toTime = '23:59';
    this.toExtraDays = null;
    this.search();
  }

  presetYesterday(): void {
    const d = new Date();
    d.setDate(d.getDate() - 1);
    const y = this.toYmd(d);
    this.planFrom = y;
    this.planTo = y;
    this.fromTime = '00:00';
    this.toTime = '23:59';
    this.toExtraDays = null;
    this.search();
  }

  presetDateOnly(extraDays = 2): void {
    this.fromTime = '';
    this.toTime = '';
    this.toExtraDays = extraDays;
    this.search();
  }

  presetLast7Days(): void {
    const now = new Date();
    const start = new Date();
    start.setDate(now.getDate() - 6);
    this.planFrom = this.toYmd(start);
    this.planTo = this.toYmd(now);
    this.fromTime = '';
    this.toTime = '';
    this.toExtraDays = 0;
    this.search();
  }
}
