import { Injectable } from '@angular/core';
import type { MonoTypeOperatorFunction } from 'rxjs';
import { debounceTime, distinctUntilChanged, throttleTime } from 'rxjs/operators';

/**
 * Rate limiting service for search and filter operations
 * Provides reusable RxJS operators for debouncing and throttling
 */
@Injectable({
  providedIn: 'root',
})
export class RateLimitService {
  /**
   * Default debounce time for search inputs (300ms)
   */
  readonly DEFAULT_SEARCH_DEBOUNCE = 300;

  /**
   * Default throttle time for API calls (1000ms)
   */
  readonly DEFAULT_API_THROTTLE = 1000;

  /**
   * Debounce operator for search inputs
   * Waits for user to stop typing before emitting
   *
   * @param time - Debounce time in milliseconds (default: 300ms)
   * @returns RxJS operator
   */
  debounceSearch<T>(time: number = this.DEFAULT_SEARCH_DEBOUNCE): MonoTypeOperatorFunction<T> {
    return (source) => source.pipe(debounceTime(time), distinctUntilChanged());
  }

  /**
   * Throttle operator for API calls
   * Limits the rate of API calls
   *
   * @param time - Throttle time in milliseconds (default: 1000ms)
   * @returns RxJS operator
   */
  throttleApi<T>(time: number = this.DEFAULT_API_THROTTLE): MonoTypeOperatorFunction<T> {
    return (source) =>
      source.pipe(throttleTime(time, undefined, { leading: true, trailing: true }));
  }

  /**
   * Combined debounce and throttle for complex scenarios
   *
   * @param debounce - Debounce time in milliseconds
   * @param throttle - Throttle time in milliseconds
   * @returns RxJS operator
   */
  debounceAndThrottle<T>(
    debounce: number = this.DEFAULT_SEARCH_DEBOUNCE,
    throttle: number = this.DEFAULT_API_THROTTLE,
  ): MonoTypeOperatorFunction<T> {
    return (source) =>
      source.pipe(
        debounceTime(debounce),
        distinctUntilChanged(),
        throttleTime(throttle, undefined, { leading: true, trailing: true }),
      );
  }
}
