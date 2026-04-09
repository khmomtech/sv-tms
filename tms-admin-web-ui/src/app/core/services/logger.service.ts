import { Injectable } from '@angular/core';

import { environment } from '../../environments/environment';

export enum LogLevel {
  DEBUG = 0,
  INFO = 1,
  WARN = 2,
  ERROR = 3,
  FATAL = 4,
}

export interface LogEntry {
  level: LogLevel;
  message: string;
  timestamp: Date;
  context?: Record<string, any>;
  component?: string;
  userId?: string;
  sessionId?: string;
}

/**
 * Structured logging service
 * Replaces console.log with proper log levels and context
 */
@Injectable({
  providedIn: 'root',
})
export class LoggerService {
  private readonly minLevel: LogLevel;
  private readonly sessionId: string;
  private readonly logBuffer: LogEntry[] = [];
  private readonly MAX_BUFFER_SIZE = 100;

  constructor() {
    // Set minimum log level based on environment
    this.minLevel = environment.production ? LogLevel.WARN : LogLevel.DEBUG;
    this.sessionId = this.generateSessionId();
  }

  /**
   * Debug level logging (development only)
   */
  debug(message: string, context?: Record<string, any>, component?: string): void {
    this.log(LogLevel.DEBUG, message, context, component);
  }

  /**
   * Info level logging
   */
  info(message: string, context?: Record<string, any>, component?: string): void {
    this.log(LogLevel.INFO, message, context, component);
  }

  /**
   * Warning level logging
   */
  warn(message: string, context?: Record<string, any>, component?: string): void {
    this.log(LogLevel.WARN, message, context, component);
  }

  /**
   * Error level logging
   */
  error(message: string, context?: Record<string, any>, component?: string): void {
    this.log(LogLevel.ERROR, message, context, component);
  }

  /**
   * Fatal level logging
   */
  fatal(message: string, context?: Record<string, any>, component?: string): void {
    this.log(LogLevel.FATAL, message, context, component);
  }

  /**
   * Core logging method
   */
  private log(
    level: LogLevel,
    message: string,
    context?: Record<string, any>,
    component?: string,
  ): void {
    // Filter by minimum level
    if (level < this.minLevel) {
      return;
    }

    const entry: LogEntry = {
      level,
      message,
      timestamp: new Date(),
      context: this.sanitizeContext(context),
      component,
      userId: this.getCurrentUserId(),
      sessionId: this.sessionId,
    };

    // Store in buffer
    this.addToBuffer(entry);

    // Output to console in development or for errors
    if (!environment.production || level >= LogLevel.ERROR) {
      this.outputToConsole(entry);
    }

    // Send to monitoring service in production
    if (environment.production && level >= LogLevel.ERROR) {
      this.sendToMonitoring(entry);
    }
  }

  /**
   * Output log entry to console
   */
  private outputToConsole(entry: LogEntry): void {
    const prefix = `[${this.getLevelName(entry.level)}] ${entry.timestamp.toISOString()}`;
    const componentTag = entry.component ? `[${entry.component}]` : '';
    const fullMessage = `${prefix} ${componentTag} ${entry.message}`;

    switch (entry.level) {
      case LogLevel.DEBUG:
        console.debug(fullMessage, entry.context || '');
        break;
      case LogLevel.INFO:
        console.info(fullMessage, entry.context || '');
        break;
      case LogLevel.WARN:
        console.warn(fullMessage, entry.context || '');
        break;
      case LogLevel.ERROR:
      case LogLevel.FATAL:
        console.error(fullMessage, entry.context || '');
        break;
    }
  }

  /**
   * Send critical logs to monitoring service (Sentry)
   */
  private sendToMonitoring(entry: LogEntry): void {
    // This would integrate with Sentry or other monitoring
    // For now, we just ensure it's captured
    if (environment.sentryDsn) {
      // Sentry will catch this via global error handler
      // We can also send custom events here if needed
    }
  }

  /**
   * Add entry to circular buffer
   */
  private addToBuffer(entry: LogEntry): void {
    this.logBuffer.push(entry);

    // Keep buffer size limited
    if (this.logBuffer.length > this.MAX_BUFFER_SIZE) {
      this.logBuffer.shift();
    }
  }

  /**
   * Get recent log entries (useful for bug reports)
   */
  getRecentLogs(count: number = 50): LogEntry[] {
    return this.logBuffer.slice(-count);
  }

  /**
   * Export logs as JSON (for support tickets)
   */
  exportLogs(): string {
    return JSON.stringify(this.logBuffer, null, 2);
  }

  /**
   * Clear log buffer
   */
  clearLogs(): void {
    this.logBuffer.length = 0;
  }

  /**
   * Get current user ID from storage
   */
  private getCurrentUserId(): string | undefined {
    try {
      const userStr = localStorage.getItem('user');
      if (userStr) {
        const user = JSON.parse(userStr);
        return user.id || user.username;
      }
    } catch {
      // Ignore errors
    }
    return undefined;
  }

  /**
   * Generate unique session ID
   */
  private generateSessionId(): string {
    return `${Date.now()}-${Math.random().toString(36).substring(2, 9)}`;
  }

  /**
   * Sanitize context to remove sensitive data
   */
  private sanitizeContext(context?: Record<string, any>): Record<string, any> | undefined {
    if (!context) {
      return undefined;
    }

    const sanitized = { ...context };
    const sensitiveKeys = ['password', 'token', 'apiKey', 'secret', 'authorization'];

    // Recursively sanitize
    const sanitizeObject = (obj: any): any => {
      if (typeof obj !== 'object' || obj === null) {
        return obj;
      }

      if (Array.isArray(obj)) {
        return obj.map(sanitizeObject);
      }

      const result: any = {};
      for (const [key, value] of Object.entries(obj)) {
        if (sensitiveKeys.some((sk) => key.toLowerCase().includes(sk))) {
          result[key] = '[REDACTED]';
        } else {
          result[key] = sanitizeObject(value);
        }
      }
      return result;
    };

    return sanitizeObject(sanitized);
  }

  /**
   * Get log level name
   */
  private getLevelName(level: LogLevel): string {
    switch (level) {
      case LogLevel.DEBUG:
        return 'DEBUG';
      case LogLevel.INFO:
        return 'INFO';
      case LogLevel.WARN:
        return 'WARN';
      case LogLevel.ERROR:
        return 'ERROR';
      case LogLevel.FATAL:
        return 'FATAL';
      default:
        return 'UNKNOWN';
    }
  }

  /**
   * Create scoped logger for a component
   */
  createComponentLogger(componentName: string) {
    return {
      debug: (message: string, context?: Record<string, any>) =>
        this.debug(message, context, componentName),
      info: (message: string, context?: Record<string, any>) =>
        this.info(message, context, componentName),
      warn: (message: string, context?: Record<string, any>) =>
        this.warn(message, context, componentName),
      error: (message: string, context?: Record<string, any>) =>
        this.error(message, context, componentName),
      fatal: (message: string, context?: Record<string, any>) =>
        this.fatal(message, context, componentName),
    };
  }
}
