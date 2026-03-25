package com.svtrucking.telematics.service;

import com.github.benmanes.caffeine.cache.Cache;
import com.github.benmanes.caffeine.cache.Caffeine;
import com.svtrucking.telematics.dto.DispatchContextDto;
import jakarta.annotation.PostConstruct;
import java.util.concurrent.TimeUnit;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

/**
 * Fetches dispatch context from tms-backend and caches results in a
 * Caffeine in-process cache with a configurable TTL (default 30s).
 *
 * This replaces the 3 JPA repository injections that the original
 * PublicTrackingController had in tms-backend.
 */
@Service
@Slf4j
public class DispatchContextCacheService {

    private final RestClient mainBackendRestClient;
    private final long ttlSeconds;
    private Cache<String, DispatchContextDto> cache;

    public DispatchContextCacheService(
            @Qualifier("mainBackendRestClient") RestClient mainBackendRestClient,
            @Value("${dispatch.context.cache.ttl-seconds:30}") long ttlSeconds) {
        this.mainBackendRestClient = mainBackendRestClient;
        this.ttlSeconds = ttlSeconds;
    }

    @PostConstruct
    void init() {
        cache = Caffeine.newBuilder()
                .expireAfterWrite(ttlSeconds, TimeUnit.SECONDS)
                .maximumSize(2_000)
                .recordStats()
                .build();
        log.info("DispatchContextCacheService initialized with TTL={}s and maxSize=2000", ttlSeconds);
    }

    /**
     * Returns dispatch context for the given order reference.
     * Fetches from tms-backend if not cached.
     * Returns null when tms-backend is unreachable or the reference doesn't exist.
     */
    public DispatchContextDto getByOrderReference(String orderRef) {
        if (orderRef == null || orderRef.isBlank())
            return null;
        String key = orderRef.trim().toUpperCase();
        return cache.get(key, k -> fetchFromBackend(k));
    }

    /** Force-evict a reference (e.g., after status change). */
    public void evict(String orderRef) {
        if (orderRef != null)
            cache.invalidate(orderRef.trim().toUpperCase());
    }

    /** Force-evict all cached entries. */
    public void evictAll() {
        cache.invalidateAll();
    }

    // ── Private ───────────────────────────────────────────────────────────────

    private DispatchContextDto fetchFromBackend(String orderRef) {
        try {
            return mainBackendRestClient.get()
                    .uri("/api/internal/telematics/dispatch/by-reference?ref={ref}", orderRef)
                    .retrieve()
                    .body(DispatchContextDto.class);
        } catch (RestClientException e) {
            log.warn("[dispatch-ctx] Fetch failed for ref={}: {}", orderRef, e.getMessage());
            return null;
        } catch (Exception e) {
            log.warn("[dispatch-ctx] Unexpected error for ref={}: {}", orderRef, e.getMessage());
            return null;
        }
    }
}
