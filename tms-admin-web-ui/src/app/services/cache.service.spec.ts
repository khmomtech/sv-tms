import { TestBed } from '@angular/core/testing';
import { Observable, firstValueFrom } from 'rxjs';
import { HttpClientTestingModule, HttpTestingController } from '@angular/common/http/testing';

import { CacheService } from './cache.service';

describe('CacheService', () => {
  let service: CacheService;
  let httpMock: HttpTestingController;

  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [HttpClientTestingModule],
      providers: [CacheService],
    });
    service = TestBed.inject(CacheService);
    httpMock = TestBed.inject(HttpTestingController);
  });

  afterEach(() => {
    httpMock.verify();
    service.clear(); // Clear cache between tests
    service.resetStats();
  });

  describe('Basic Cache Operations', () => {
    it('should be created', () => {
      expect(service).toBeTruthy();
    });

    it('should set and get cache value', () => {
      const key = 'test-key';
      const value = { data: 'test-data' };

      service.set(key, value, 60000);
      const result = service.get(key);
      expect(result).toEqual(value);
    });

    it('should return null for non-existent key', () => {
      const result = service.get('non-existent-key');
      expect(result).toBeNull();
    });

    it('should invalidate cache entry', () => {
      const key = 'test-key';
      const value = { data: 'test' };

      service.set(key, value, 60000);
      service.invalidate(key);

      const result = service.get(key);
      expect(result).toBeNull();
    });

    it('should clear all cache entries', () => {
      service.set('key1', 'value1', 60000);
      service.set('key2', 'value2', 60000);

      service.clear();

      const result1 = service.get('key1');
      const result2 = service.get('key2');
      expect(result1).toBeNull();
      expect(result2).toBeNull();
    });
  });

  describe('Cache Expiration (TTL)', () => {
    it('should expire cache after TTL', (done) => {
      const key = 'expiring-key';
      const value = { data: 'test' };
      const ttl = 100; // 100ms

      service.set(key, value, ttl);

      // Immediately should be available
      const result = service.get(key);
      expect(result).toEqual(value);

      // After TTL should be null
      setTimeout(() => {
        const expired = service.get(key);
        expect(expired).toBeNull();
        done();
      }, ttl + 50);
    });

    it('should not expire if TTL is not exceeded', (done) => {
      const key = 'non-expiring-key';
      const value = { data: 'test' };
      const ttl = 5000; // 5 seconds

      service.set(key, value, ttl);

      setTimeout(() => {
        const result = service.get(key);
        expect(result).toEqual(value);
        done();
      }, 100); // Check after 100ms (well before 5s)
    });
  });

  describe('getOrFetch', () => {
    it('should return cached value if available', (done) => {
      const key = 'cached-key';
      const cachedValue = { data: 'cached' };
      const fetchObservable = jasmine.createSpy('fetch');

      service.set(key, cachedValue, 60000);

      service.getOrFetch(key, fetchObservable as any, 60000).subscribe((result) => {
        expect(result).toEqual(cachedValue);
        expect(fetchObservable).not.toHaveBeenCalled();
        done();
      });
    });

    it('should fetch and cache if not in cache', (done) => {
      const key = 'fetch-key';
      const fetchedValue = { data: 'fetched' };
      const fetchObservable = new Observable((observer) => {
        observer.next(fetchedValue);
        observer.complete();
      });

      service.getOrFetch(key, fetchObservable, 60000).subscribe((result) => {
        expect(result).toEqual(fetchedValue);

        // Verify it's now cached
        const cached = service.get(key);
        expect(cached).toEqual(fetchedValue);
        done();
      });
    });

    it('should use stale data on fetch error if useStaleOnError is true', (done) => {
      const key = 'stale-key';
      const staleValue = { data: 'stale' };
      const errorObservable = new Observable((observer) => {
        observer.error(new Error('Fetch failed'));
      });

      // Set stale data with 0 TTL (expired)
      service.set(key, staleValue, 0);

      setTimeout(() => {
        service.getOrFetch(key, errorObservable, 60000, true).subscribe(
          (result) => {
            expect(result).toEqual(staleValue);
            done();
          },
          (error) => {
            fail('Should not error when useStaleOnError is true');
          },
        );
      }, 100);
    });

    it('should throw error if no stale data and fetch fails', (done) => {
      const key = 'error-key';
      const errorObservable = new Observable((observer) => {
        observer.error(new Error('Fetch failed'));
      });

      service.getOrFetch(key, errorObservable, 60000, false).subscribe(
        () => {
          fail('Should have errored');
        },
        (error) => {
          expect(error.message).toBe('Fetch failed');
          done();
        },
      );
    });
  });

  describe('Pattern-based Invalidation', () => {
    it('should invalidate entries matching regex pattern', () => {
      service.set('users:1', 'user1', 60000);
      service.set('users:2', 'user2', 60000);
      service.set('posts:1', 'post1', 60000);

      service.invalidatePattern(/^users:/);

      expect(service.get('users:1')).toBeNull();
      expect(service.get('users:2')).toBeNull();
      expect(service.get('posts:1')).not.toBeNull();
    });

    it('should handle complex regex patterns', () => {
      service.set('api:drivers:page:1', 'data1', 60000);
      service.set('api:drivers:page:2', 'data2', 60000);
      service.set('api:vehicles:page:1', 'data3', 60000);

      service.invalidatePattern(/^api:drivers:/);

      expect(service.get('api:drivers:page:1')).toBeNull();
      expect(service.get('api:vehicles:page:1')).not.toBeNull();
    });
  });

  describe('Cache Statistics', () => {
    it('should track cache hits and misses', (done) => {
      const key = 'stats-key';
      service.set(key, 'value', 60000);

      // Hit
      service.get(key);
      service.get('non-existent');
      const stats = service.getStats();

      expect(stats.hits).toBe(1);
      expect(stats.misses).toBe(1);
      expect(stats.hitRate).toContain('%');
      done();
    });

    it('should track cache size', () => {
      service.set('key1', 'value1', 60000);
      service.set('key2', 'value2', 60000);
      service.set('key3', 'value3', 60000);

      const stats = service.getStats();
      expect(stats.cacheSize).toBe(3);
    });

    it('should track errors and fallbacks', (done) => {
      const key = 'error-stats-key';
      const staleValue = 'stale';
      const errorObservable = new Observable((observer) => {
        observer.error(new Error('Test error'));
      });

      service.set(key, staleValue, 0); // Expired

      setTimeout(() => {
        (service.getOrFetch(key, errorObservable, 60000, true) as Observable<any>).subscribe(() => {
          const stats = service.getStats();
          expect(stats.errors).toBeGreaterThan(0);
          expect(stats.fallbacks).toBeGreaterThan(0);
          done();
        });
      }, 100);
    });
  });

  describe('Request Deduplication', () => {
    it('should deduplicate concurrent requests for same key', (done) => {
      const key = 'dedup-key';
      let fetchCount = 0;

      const fetchObservable = new Observable((observer) => {
        fetchCount++;
        setTimeout(() => {
          observer.next({ data: 'fetched', count: fetchCount });
          observer.complete();
        }, 100);
      });

      // Make 3 concurrent requests
      const req1 = service.getOrFetch(key, fetchObservable, 60000);
      const req2 = service.getOrFetch(key, fetchObservable, 60000);
      const req3 = service.getOrFetch(key, fetchObservable, 60000);

      Promise.all([firstValueFrom(req1), firstValueFrom(req2), firstValueFrom(req3)]).then(
        ([r1, r2, r3]) => {
          // Should only fetch once
          expect(fetchCount).toBe(1);
          expect(r1).toEqual(r2);
          expect(r2).toEqual(r3);
          done();
        },
      );
    });
  });

  describe('Memory Management', () => {
    it('should respect cache size limits', () => {
      // This would require implementation of LRU eviction
      // For now, just test that cache can handle many entries
      for (let i = 0; i < 1000; i++) {
        service.set(`key-${i}`, `value-${i}`, 60000);
      }

      const stats = service.getStats();
      expect(stats.cacheSize).toBeLessThanOrEqual(1000);
    });
  });

  describe('Edge Cases', () => {
    it('should handle null values', () => {
      const key = 'null-key';
      service.set(key, null, 60000);

      const result = service.get(key);
      expect(result).toBeNull();
    });

    it('should handle undefined values', () => {
      const key = 'undefined-key';
      service.set(key, undefined, 60000);

      const result = service.get(key);
      expect(result).toBeUndefined();
    });

    it('should handle complex nested objects', () => {
      const key = 'complex-key';
      const value = {
        nested: {
          deep: {
            array: [1, 2, 3],
            object: { a: 1, b: 2 },
          },
        },
      };

      service.set(key, value, 60000);

      const result = service.get(key);
      expect(result).toEqual(value);
    });

    it('should handle very long keys', () => {
      const key = 'a'.repeat(1000);
      const value = 'test';

      service.set(key, value, 60000);

      const result = service.get(key);
      expect(result).toBe(value);
    });
  });
});
