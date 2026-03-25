import { Injectable } from '@angular/core';

import { environment } from '../../../environments/environment';

/**
 * Centralized logging service that respects production mode.
 * In production, only errors are logged to avoid console clutter.
 */
@Injectable({
  providedIn: 'root',
})
export class LoggerService {
  private readonly isProduction = environment.production;
  private readonly enableDebug = !this.isProduction || environment.enableDebugLogs;

  log(message: string, ...args: unknown[]): void {
    if (this.enableDebug) {
      console.log(`[LOG] ${message}`, ...args);
    }
  }

  info(message: string, ...args: unknown[]): void {
    if (this.enableDebug) {
      console.info(`[INFO] ${message}`, ...args);
    }
  }

  warn(message: string, ...args: unknown[]): void {
    console.warn(`[WARN] ${message}`, ...args);
  }

  error(message: string, error?: unknown): void {
    console.error(`[ERROR] ${message}`, error);
  }

  debug(message: string, ...args: unknown[]): void {
    if (this.enableDebug) {
      console.debug(`[DEBUG] ${message}`, ...args);
    }
  }

  /**
   * Group logs together (useful for debugging complex flows)
   */
  group(label: string): void {
    if (this.enableDebug) {
      console.group(label);
    }
  }

  groupEnd(): void {
    if (this.enableDebug) {
      console.groupEnd();
    }
  }

  /**
   * Performance timing utility
   */
  time(label: string): void {
    if (this.enableDebug) {
      console.time(label);
    }
  }

  timeEnd(label: string): void {
    if (this.enableDebug) {
      console.timeEnd(label);
    }
  }
}
