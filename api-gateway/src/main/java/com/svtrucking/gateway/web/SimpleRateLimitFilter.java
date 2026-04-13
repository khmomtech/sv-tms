package com.svtrucking.gateway.web;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Iterator;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpHeaders;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

@Component
public class SimpleRateLimitFilter extends OncePerRequestFilter {

    private final Map<String, WindowCounter> counters = new ConcurrentHashMap<>();
    private final int maxRequestsPerMinute;
    // Evict entries older than 2 minutes every N requests to cap memory use.
    private static final int EVICT_EVERY_N = 500;
    private final AtomicInteger evictTick = new AtomicInteger();

    public SimpleRateLimitFilter(@Value("${gateway.rate-limit.per-minute:600}") int maxRequestsPerMinute) {
        this.maxRequestsPerMinute = maxRequestsPerMinute;
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        return request.getRequestURI().startsWith("/actuator/");
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {
        long currentWindow = Instant.now().getEpochSecond() / 60;
        String key = buildKey(request, currentWindow);
        WindowCounter counter = counters.computeIfAbsent(key, k -> new WindowCounter(currentWindow));
        if (counter.requests.incrementAndGet() > maxRequestsPerMinute) {
            response.setStatus(429);
            response.setContentType("application/json");
            response.getWriter().write("{\"error\":\"RATE_LIMITED\",\"message\":\"Too many requests\"}");
            return;
        }
        // Periodically evict stale windows to prevent unbounded map growth.
        if (evictTick.incrementAndGet() % EVICT_EVERY_N == 0) {
            evictStale(currentWindow);
        }
        filterChain.doFilter(request, response);
    }

    String buildKey(HttpServletRequest request, long currentWindow) {
        return resolveIdentitySegment(request) + ":" + currentWindow;
    }

    private String resolveIdentitySegment(HttpServletRequest request) {
        String authorization = request.getHeader(HttpHeaders.AUTHORIZATION);
        if (authorization != null && authorization.regionMatches(true, 0, "Bearer ", 0, 7)) {
            String bearerToken = authorization.substring(7).trim();
            if (!bearerToken.isEmpty()) {
                return "token:" + sha256Hex(bearerToken);
            }
        }
        return "ip:" + extractClientAddress(request);
    }

    private String extractClientAddress(HttpServletRequest request) {
        String forwardedFor = request.getHeader("X-Forwarded-For");
        if (forwardedFor != null && !forwardedFor.isBlank()) {
            int comma = forwardedFor.indexOf(',');
            return (comma >= 0 ? forwardedFor.substring(0, comma) : forwardedFor).trim();
        }
        return request.getRemoteAddr();
    }

    private String sha256Hex(String value) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] bytes = digest.digest(value.getBytes(StandardCharsets.UTF_8));
            StringBuilder builder = new StringBuilder(bytes.length * 2);
            for (byte current : bytes) {
                builder.append(Character.forDigit((current >> 4) & 0xF, 16));
                builder.append(Character.forDigit(current & 0xF, 16));
            }
            return builder.toString();
        } catch (NoSuchAlgorithmException ex) {
            throw new IllegalStateException("SHA-256 not available", ex);
        }
    }

    private void evictStale(long currentWindow) {
        Iterator<Map.Entry<String, WindowCounter>> it = counters.entrySet().iterator();
        while (it.hasNext()) {
            Map.Entry<String, WindowCounter> entry = it.next();
            if (currentWindow - entry.getValue().window > 1) {
                it.remove();
            }
        }
    }

    private static final class WindowCounter {
        final long window;
        final AtomicInteger requests = new AtomicInteger();

        WindowCounter(long window) {
            this.window = window;
        }
    }
}
