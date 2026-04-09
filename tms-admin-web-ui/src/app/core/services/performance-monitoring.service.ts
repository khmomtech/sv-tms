import { Injectable } from '@angular/core';
import { onCLS, onFCP, onINP, onLCP, onTTFB, type Metric } from 'web-vitals';

import { environment } from '../../environments/environment';
import { LoggerService } from './logger.service';

export interface PerformanceMetrics {
  CLS?: number; // Cumulative Layout Shift
  FCP?: number; // First Contentful Paint
  INP?: number; // Interaction to Next Paint (replaces FID)
  LCP?: number; // Largest Contentful Paint
  TTFB?: number; // Time to First Byte
}

export interface PerformanceReport {
  timestamp: Date;
  metrics: PerformanceMetrics;
  userAgent: string;
  url: string;
  sessionId: string;
}

/**
 * Web Vitals Performance Monitoring Service
 * Tracks Core Web Vitals and reports to analytics
 */
@Injectable({
  providedIn: 'root',
})
export class PerformanceMonitoringService {
  private metrics: PerformanceMetrics = {};
  private readonly sessionId: string;

  constructor(private logger: LoggerService) {
    this.sessionId = this.generateSessionId();
  }

  /**
   * Initialize Web Vitals monitoring
   */
  initWebVitals(): void {
    if (!environment.production) {
      this.logger.info('Performance monitoring initialized (development mode)');
    }

    // Monitor all Core Web Vitals
    onCLS(this.handleMetric.bind(this), { reportAllChanges: true });
    onFCP(this.handleMetric.bind(this));
    onINP(this.handleMetric.bind(this), { reportAllChanges: true });
    onLCP(this.handleMetric.bind(this), { reportAllChanges: true });
    onTTFB(this.handleMetric.bind(this));
  }

  /**
   * Handle individual metric
   */
  private handleMetric(metric: Metric): void {
    const value = metric.value;
    const name = metric.name;

    // Store metric
    this.metrics[name as keyof PerformanceMetrics] = value;

    // Log metric
    this.logger.info(`Web Vital: ${name}`, {
      value: Math.round(value),
      rating: metric.rating,
      delta: metric.delta,
    });

    // Send to analytics in production
    if (environment.production) {
      this.sendToAnalytics(metric);
    }

    // Check thresholds and warn
    this.checkThresholds(metric);
  }

  /**
   * Send metric to analytics service
   */
  private sendToAnalytics(metric: Metric): void {
    // Send to Google Analytics 4 if configured
    if (typeof gtag !== 'undefined') {
      gtag('event', metric.name, {
        value: Math.round(metric.value),
        metric_id: metric.id,
        metric_value: metric.value,
        metric_delta: metric.delta,
        metric_rating: metric.rating,
      });
    }

    // Could also send to custom analytics endpoint
    // this.http.post('/api/analytics/web-vitals', { metric });
  }

  /**
   * Check if metrics exceed thresholds
   */
  private checkThresholds(metric: Metric): void {
    const thresholds = {
      CLS: { good: 0.1, needsImprovement: 0.25 },
      FCP: { good: 1800, needsImprovement: 3000 },
      INP: { good: 200, needsImprovement: 500 },
      LCP: { good: 2500, needsImprovement: 4000 },
      TTFB: { good: 800, needsImprovement: 1800 },
    };

    const threshold = thresholds[metric.name as keyof typeof thresholds];
    if (!threshold) return;

    if (metric.value > threshold.needsImprovement) {
      this.logger.warn(`Poor ${metric.name}: ${Math.round(metric.value)}`, {
        threshold: threshold.needsImprovement,
        rating: metric.rating,
      });
    }
  }

  /**
   * Get current metrics snapshot
   */
  getMetrics(): PerformanceMetrics {
    return { ...this.metrics };
  }

  /**
   * Generate performance report
   */
  generateReport(): PerformanceReport {
    return {
      timestamp: new Date(),
      metrics: this.getMetrics(),
      userAgent: navigator.userAgent,
      url: window.location.href,
      sessionId: this.sessionId,
    };
  }

  /**
   * Track custom performance mark
   */
  markPerformance(name: string): void {
    if (performance.mark) {
      performance.mark(name);
      this.logger.debug(`Performance mark: ${name}`);
    }
  }

  /**
   * Measure time between two marks
   */
  measurePerformance(name: string, startMark: string, endMark: string): number | null {
    try {
      if (performance.measure) {
        const measure = performance.measure(name, startMark, endMark);
        const duration = measure.duration;

        this.logger.info(`Performance measure: ${name}`, {
          duration: Math.round(duration),
          startMark,
          endMark,
        });

        return duration;
      }
    } catch (error) {
      this.logger.error('Performance measurement failed', { name, error });
    }
    return null;
  }

  /**
   * Track component render time
   */
  trackComponentRender(componentName: string, renderTime: number): void {
    this.logger.debug(`Component render: ${componentName}`, {
      renderTime: Math.round(renderTime),
    });

    if (renderTime > 16) {
      // More than 1 frame (60fps)
      this.logger.warn(`Slow component render: ${componentName}`, {
        renderTime: Math.round(renderTime),
      });
    }
  }

  /**
   * Track API call performance
   */
  trackApiCall(endpoint: string, duration: number, status: number): void {
    this.logger.debug(`API call: ${endpoint}`, {
      duration: Math.round(duration),
      status,
    });

    if (duration > 3000) {
      this.logger.warn(`Slow API call: ${endpoint}`, {
        duration: Math.round(duration),
        status,
      });
    }
  }

  /**
   * Get navigation timing info
   */
  getNavigationTiming(): PerformanceTiming | null {
    return performance.timing || null;
  }

  /**
   * Clear all performance marks and measures
   */
  clearPerformance(): void {
    if (performance.clearMarks) {
      performance.clearMarks();
    }
    if (performance.clearMeasures) {
      performance.clearMeasures();
    }
  }

  /**
   * Generate unique session ID
   */
  private generateSessionId(): string {
    return `${Date.now()}-${Math.random().toString(36).substring(2, 9)}`;
  }
}

// Declare gtag for Google Analytics
declare let gtag: any;
