import { Injectable } from '@angular/core';

/**
 * Storage Service
 *
 * Type-safe wrapper for LocalStorage and SessionStorage.
 * Automatically handles JSON serialization/deserialization.
 *
 * @example
 * // Inject in component/service
 * constructor(private storage: StorageService) {}
 *
 * // Store user preferences
 * this.storage.setLocal('theme', { mode: 'dark', primaryColor: '#123456' });
 *
 * // Retrieve with type safety
 * const theme = this.storage.getLocal<ThemeConfig>('theme');
 *
 * // Session storage (cleared on tab close)
 * this.storage.setSession('currentFilter', filterState);
 */
@Injectable({
  providedIn: 'root',
})
export class StorageService {
  /**
   * Get item from localStorage with type safety
   */
  getLocal<T>(key: string): T | null {
    return this.getItem<T>(localStorage, key);
  }

  /**
   * Set item in localStorage
   */
  setLocal<T>(key: string, value: T): void {
    this.setItem(localStorage, key, value);
  }

  /**
   * Remove item from localStorage
   */
  removeLocal(key: string): void {
    localStorage.removeItem(key);
  }

  /**
   * Clear all items from localStorage
   */
  clearLocal(): void {
    localStorage.clear();
  }

  /**
   * Check if key exists in localStorage
   */
  hasLocal(key: string): boolean {
    return localStorage.getItem(key) !== null;
  }

  /**
   * Get item from sessionStorage with type safety
   */
  getSession<T>(key: string): T | null {
    return this.getItem<T>(sessionStorage, key);
  }

  /**
   * Set item in sessionStorage
   */
  setSession<T>(key: string, value: T): void {
    this.setItem(sessionStorage, key, value);
  }

  /**
   * Remove item from sessionStorage
   */
  removeSession(key: string): void {
    sessionStorage.removeItem(key);
  }

  /**
   * Clear all items from sessionStorage
   */
  clearSession(): void {
    sessionStorage.clear();
  }

  /**
   * Check if key exists in sessionStorage
   */
  hasSession(key: string): boolean {
    return sessionStorage.getItem(key) !== null;
  }

  /**
   * Get all keys from localStorage
   */
  getLocalKeys(): string[] {
    return Object.keys(localStorage);
  }

  /**
   * Get all keys from sessionStorage
   */
  getSessionKeys(): string[] {
    return Object.keys(sessionStorage);
  }

  /**
   * Get storage size in bytes
   */
  getStorageSize(type: 'local' | 'session' = 'local'): number {
    const storage = type === 'local' ? localStorage : sessionStorage;
    let size = 0;

    for (const key in storage) {
      if (storage.hasOwnProperty(key)) {
        size += key.length + (storage.getItem(key)?.length || 0);
      }
    }

    return size;
  }

  /**
   * Get storage size in MB
   */
  getStorageSizeMB(type: 'local' | 'session' = 'local'): string {
    const bytes = this.getStorageSize(type);
    return (bytes / 1024 / 1024).toFixed(2);
  }

  /**
   * Generic get item with error handling
   */
  private getItem<T>(storage: Storage, key: string): T | null {
    try {
      const item = storage.getItem(key);
      if (!item) return null;

      // Try to parse as JSON, if fails return as string
      try {
        return JSON.parse(item) as T;
      } catch {
        return item as unknown as T;
      }
    } catch (error) {
      console.error(`Error getting item from storage: ${key}`, error);
      return null;
    }
  }

  /**
   * Generic set item with error handling
   */
  private setItem<T>(storage: Storage, key: string, value: T): void {
    try {
      const serialized = typeof value === 'string' ? value : JSON.stringify(value);
      storage.setItem(key, serialized);
    } catch (error) {
      console.error(`Error setting item in storage: ${key}`, error);

      // Check if error is quota exceeded
      if (this.isQuotaExceededError(error)) {
        console.warn('Storage quota exceeded. Consider clearing old data.');
      }
    }
  }

  /**
   * Check if error is quota exceeded error
   */
  private isQuotaExceededError(error: any): boolean {
    return (
      error instanceof DOMException &&
      (error.code === 22 ||
        error.code === 1014 ||
        error.name === 'QuotaExceededError' ||
        error.name === 'NS_ERROR_DOM_QUOTA_REACHED')
    );
  }

  /**
   * Remove items older than specified days
   */
  removeOlderThan(days: number, type: 'local' | 'session' = 'local'): void {
    const storage = type === 'local' ? localStorage : sessionStorage;
    const now = Date.now();
    const expirationTime = days * 24 * 60 * 60 * 1000;

    for (const key in storage) {
      if (storage.hasOwnProperty(key)) {
        try {
          const item = storage.getItem(key);
          if (!item) continue;

          const parsed = JSON.parse(item);
          if (parsed.timestamp) {
            const age = now - parsed.timestamp;
            if (age > expirationTime) {
              storage.removeItem(key);
            }
          }
        } catch {
          // Skip items that aren't JSON or don't have timestamp
        }
      }
    }
  }

  /**
   * Set item with expiration time
   */
  setWithExpiry<T>(
    key: string,
    value: T,
    expiryDays: number,
    type: 'local' | 'session' = 'local',
  ): void {
    const storage = type === 'local' ? localStorage : sessionStorage;
    const now = Date.now();
    const expiryTime = now + expiryDays * 24 * 60 * 60 * 1000;

    const item = {
      value,
      expiry: expiryTime,
      timestamp: now,
    };

    this.setItem(storage, key, item);
  }

  /**
   * Get item with expiration check
   */
  getWithExpiry<T>(key: string, type: 'local' | 'session' = 'local'): T | null {
    const storage = type === 'local' ? localStorage : sessionStorage;
    const item = this.getItem<{ value: T; expiry: number; timestamp: number }>(storage, key);

    if (!item) return null;

    const now = Date.now();
    if (now > item.expiry) {
      storage.removeItem(key);
      return null;
    }

    return item.value;
  }
}
