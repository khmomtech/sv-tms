package com.svtrucking.logistics.idempotency;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnBean;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.util.Optional;

/**
 * Redis-backed idempotency store for critical driver-initiated endpoints.
 *
 * Key format: idempotency:{clientId}:{idempotencyKey}
 * TTL: 24 hours
 *
 * Prevents duplicate submissions from mobile clients with unstable connections
 * (e.g., double-submitting load proof or safety check on retry).
 */
@Slf4j
@Service
@RequiredArgsConstructor
@ConditionalOnBean(RedisTemplate.class)
@ConditionalOnProperty(name = "idempotency.enabled", havingValue = "true", matchIfMissing = true)
public class IdempotencyService {

    private static final String KEY_PREFIX = "idempotency:";
    private static final Duration TTL = Duration.ofHours(24);

    private final RedisTemplate<String, Object> redisTemplate;

    /**
     * Check if a response was already stored for this idempotency key.
     *
     * @param clientId       Caller identity (user ID or IP)
     * @param idempotencyKey Client-supplied idempotency token
     * @return Stored response if exists
     */
    public Optional<IdempotentResponse> get(String clientId, String idempotencyKey) {
        String redisKey = buildKey(clientId, idempotencyKey);
        Object value = redisTemplate.opsForValue().get(redisKey);
        if (value instanceof IdempotentResponse response) {
            log.debug("Idempotency cache hit: key={}", redisKey);
            return Optional.of(response);
        }
        return Optional.empty();
    }

    /**
     * Store a response for replay on duplicate requests.
     *
     * @param clientId       Caller identity
     * @param idempotencyKey Client-supplied idempotency token
     * @param response       Response to cache
     */
    public void store(String clientId, String idempotencyKey, IdempotentResponse response) {
        String redisKey = buildKey(clientId, idempotencyKey);
        redisTemplate.opsForValue().set(redisKey, response, TTL);
        log.debug("Idempotency response cached: key={}, status={}", redisKey, response.getStatus());
    }

    private String buildKey(String clientId, String idempotencyKey) {
        return KEY_PREFIX + clientId + ":" + idempotencyKey;
    }
}
