import type { PipeTransform } from '@angular/core';
import { Pipe } from '@angular/core';

@Pipe({
  name: 'svSafeDate',
  standalone: true,
})
export class SvSafeDatePipe implements PipeTransform {
  transform(input: unknown): Date | null {
    if (input == null) return null;

    // Already a Date
    if (input instanceof Date) return isNaN(input.getTime()) ? null : input;

    // Epoch number
    if (typeof input === 'number') {
      const d = new Date(input);
      return isNaN(d.getTime()) ? null : d;
    }

    // Array: [yyyy, m, d, hh?, mm?, ss?]
    if (Array.isArray(input)) {
      const [y, m, d, hh = 0, mm = 0, ss = 0] = (input as any[]).map(Number);
      const dt = new Date(y, m - 1, d, hh, mm, ss);
      return isNaN(dt.getTime()) ? null : dt;
    }

    // CSV string: "yyyy,m,d,hh?,mm?,ss?"
    if (typeof input === 'string' && input.includes(',')) {
      const [y, m, d, hh = 0, mm = 0, ss = 0] = input.split(',').map((p) => Number(p.trim()));
      const dt = new Date(y, m - 1, d, hh, mm, ss);
      return isNaN(dt.getTime()) ? null : dt;
    }

    // ISO or parseable string
    if (typeof input === 'string') {
      const dt = new Date(input);
      return isNaN(dt.getTime()) ? null : dt;
    }

    return null;
  }
}
