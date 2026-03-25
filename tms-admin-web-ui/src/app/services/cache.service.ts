import { Injectable } from '@angular/core';
import { Observable, of, throwError } from 'rxjs';
import { catchError, shareReplay, tap } from 'rxjs/operators';

/**
 * Cache service for resilient data access with offline fallback
 *
 * Features:
 * - In-memory cache with TTL (time-to-live)
 * - Automatic cache invalidation
 * - Fallback to cached data on network errors
 * - Request deduplication
 * - Cache statistics for monitoring
 */
@Injectable({
  providedIn: 'root',
})
export class CacheService {
  private cache = new Map<string, CacheEntry>();
  private pendingRequests = new Map<string, Observable<any>>();

  // Cache statistics
  private stats = {
    hits: 0,
    misses: 0,
    errors: 0,
    fallbacks: 0,
  };

  /**
   * Get cached data or execute the request with caching
   *
   * @param key Cache key (usually the request URL)
   * @param request Observable that fetches fresh data
   * @param ttlMs Time-to-live in milliseconds (default: 5 minutes)
   * @param fallbackOnError If true, return stale cache on error
   */
  getOrFetch<T>(
    key: string,
    request: Observable<T>,
    ttlMs: number = 5 * 60 * 1000,
    fallbackOnError: boolean = true,
  ): Observable<T> {
    // Check cache first
    const cached = this.get<T>(key);
    if (cached !== null) {
      console.debug(`[Cache] HIT: ${key}`);
      return of(cached);
    }

    // Check if request is already in flight (request deduplication)
    const pending = this.pendingRequests.get(key);
    if (pending) {
      console.debug(`[Cache] Deduplicating request: ${key}`);
      return pending as Observable<T>;
    }

    // Execute request with caching
    const shared = request.pipe(
      tap((data) => {
        this.set(key, data, ttlMs);
        this.pendingRequests.delete(key);
      }),
      catchError((error) => {
        this.stats.errors++;
        this.pendingRequests.delete(key);

        // Try to use stale cache as fallback
        if (fallbackOnError) {
          const stale = this.getStale<T>(key);
          if (stale !== null) {
            this.stats.fallbacks++;
            console.warn(`[Cache] Using stale fallback for: ${key}`, error);
            return of(stale);
          }
        }

        return throwError(() => error);
      }),
      shareReplay(1), // Share response with multiple subscribers
    );

    this.pendingRequests.set(key, shared);
    return shared;
  }

  /**
   * Get fresh cached data (not expired)
   */
  get<T>(key: string): T | null {
    const entry = this.cache.get(key);
    if (!entry) {
      this.stats.misses++;
      return null;
    }

    if (this.isExpired(entry)) {
      this.stats.misses++;
      return null;
    }

    this.stats.hits++;
    return entry.data as T;
  }

  /**
   * Get cached data even if expired (for fallback scenarios)
   */
  getStale<T>(key: string): T | null {
    const entry = this.cache.get(key);
    return entry ? (entry.data as T) : null;
  }

  /**
   * Set data in cache with TTL
   */
  set<T>(key: string, data: T, ttlMs: number): void {
    const entry: CacheEntry = {
      data,
      timestamp: Date.now(),
      ttl: ttlMs,
    };
    this.cache.set(key, entry);
    console.debug(`[Cache] SET: ${key} (TTL: ${ttlMs}ms)`);
  }

  /**
   * Invalidate specific cache entry
   */
  invalidate(key: string): void {
    const deleted = this.cache.delete(key);
    if (deleted) {
      console.debug(`[Cache] INVALIDATE: ${key}`);
    }
  }

  /**
   * Invalidate cache entries matching pattern
   */
  invalidatePattern(pattern: RegExp): void {
    let count = 0;
    for (const key of this.cache.keys()) {
      if (pattern.test(key)) {
        this.cache.delete(key);
        count++;
      }
    }
    console.debug(`[Cache] INVALIDATE PATTERN: ${pattern} (${count} entries)`);
  }

  /**
   * Clear entire cache
   */
  clear(): void {
    const size = this.cache.size;
    this.cache.clear();
    this.pendingRequests.clear();
    console.debug(`[Cache] CLEAR ALL (${size} entries)`);
  }

  /**
   * Get cache statistics
   */
  getStats() {
    const hitRate =
      this.stats.hits + this.stats.misses > 0
        ? ((this.stats.hits / (this.stats.hits + this.stats.misses)) * 100).toFixed(2)
        : '0.00';

    return {
      ...this.stats,
      hitRate: `${hitRate}%`,
      cacheSize: this.cache.size,
      pendingRequests: this.pendingRequests.size,
    };
  }

  /**
   * Reset statistics
   */
  resetStats(): void {
    this.stats = {
      hits: 0,
      misses: 0,
      errors: 0,
      fallbacks: 0,
    };
  }

  /**
   * Check if cache entry is expired
   */
  private isExpired(entry: CacheEntry): boolean {
    const age = Date.now() - entry.timestamp;
    return age > entry.ttl;
  }

  /**
   * Cleanup expired entries (call periodically)
   */
  cleanup(): void {
    let removed = 0;
    for (const [key, entry] of this.cache.entries()) {
      if (this.isExpired(entry)) {
        this.cache.delete(key);
        removed++;
      }
    }
    if (removed > 0) {
      console.debug(`[Cache] CLEANUP: Removed ${removed} expired entries`);
    }
  }
}

interface CacheEntry {
  data: any;
  timestamp: number;
  ttl: number;
}
