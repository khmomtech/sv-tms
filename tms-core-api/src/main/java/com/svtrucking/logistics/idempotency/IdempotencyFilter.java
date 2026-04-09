package com.svtrucking.logistics.idempotency;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.core.annotation.Order;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;
import org.springframework.web.util.ContentCachingResponseWrapper;

import java.io.IOException;
import java.nio.charset.StandardCharsets;

/**
 * Enforces idempotency on critical driver-initiated endpoints.
 *
 * If a request carries an {@code X-Idempotency-Key} header, this filter:
 * 1. Checks Redis for a previously cached response for the same client + key.
 * 2. On cache hit: returns the cached response immediately with
 * {@code X-Idempotency-Replay: true} — no business logic re-executed.
 * 3. On cache miss: lets the request through, captures the response body,
 * and caches it for future replays.
 *
 * Idempotency is only enforced on mutating HTTP methods (POST, PUT, PATCH).
 * GET and DELETE are always allowed to pass through unchanged.
 *
 * This prevents double-submissions from mobile clients with unstable
 * connections.
 */
@Slf4j
@Component
@Order(10)
@RequiredArgsConstructor
@ConditionalOnProperty(name = "idempotency.enabled", havingValue = "true", matchIfMissing = true)
public class IdempotencyFilter extends OncePerRequestFilter {

    public static final String IDEMPOTENCY_KEY_HEADER = "X-Idempotency-Key";
    public static final String IDEMPOTENCY_REPLAY_HEADER = "X-Idempotency-Replay";
    public static final String IDEMPOTENCY_KEY_PARAM = "idempotencyKey";

    private final IdempotencyService idempotencyService;

    @Override
    protected void doFilterInternal(HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain) throws ServletException, IOException {

        String idempotencyKey = resolveIdempotencyKey(request);

        // Only enforce on mutating requests that supply the header
        if (idempotencyKey == null || idempotencyKey.isBlank()
                || isReadMethod(request.getMethod())) {
            filterChain.doFilter(request, response);
            return;
        }

        String clientId = resolveClientId(request);
        String compositeKey = request.getMethod() + ":" + request.getRequestURI();

        // Check for cached response
        var cached = idempotencyService.get(clientId, compositeKey + ":" + idempotencyKey);
        if (cached.isPresent()) {
            log.debug("Idempotency replay: method={}, uri={}, key={}",
                    request.getMethod(), request.getRequestURI(), idempotencyKey);
            IdempotentResponse hit = cached.get();
            response.setStatus(hit.getStatus());
            response.setContentType(hit.getContentType() != null ? hit.getContentType() : "application/json");
            response.setHeader(IDEMPOTENCY_REPLAY_HEADER, "true");
            if (hit.getBody() != null) {
                response.getWriter().write(hit.getBody());
            }
            return;
        }

        // Wrap the response so we can capture the body after execution
        ContentCachingResponseWrapper wrappedResponse = new ContentCachingResponseWrapper(response);
        filterChain.doFilter(request, wrappedResponse);

        // Cache the response only for successful outcomes (2xx)
        int status = wrappedResponse.getStatus();
        if (status >= 200 && status < 300) {
            byte[] bodyBytes = wrappedResponse.getContentAsByteArray();
            String body = new String(bodyBytes, StandardCharsets.UTF_8);
            String contentType = wrappedResponse.getContentType();
            idempotencyService.store(clientId, compositeKey + ":" + idempotencyKey,
                    new IdempotentResponse(status, body, contentType));
            log.debug("Idempotency response cached: method={}, uri={}, status={}",
                    request.getMethod(), request.getRequestURI(), status);
        }

        // Always copy buffered response body to the actual response
        wrappedResponse.copyBodyToResponse();
    }

    private boolean isReadMethod(String method) {
        return "GET".equalsIgnoreCase(method) || "HEAD".equalsIgnoreCase(method)
                || "OPTIONS".equalsIgnoreCase(method);
    }

    private String resolveClientId(HttpServletRequest request) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth != null && auth.isAuthenticated() && auth.getName() != null
                && !"anonymousUser".equals(auth.getName())) {
            return "user:" + auth.getName();
        }
        // Fall back to IP address for unauthenticated requests
        String xForwardedFor = request.getHeader("X-Forwarded-For");
        if (xForwardedFor != null && !xForwardedFor.isBlank()) {
            return "ip:" + xForwardedFor.split(",")[0].trim();
        }
        return "ip:" + request.getRemoteAddr();
    }

    private String resolveIdempotencyKey(HttpServletRequest request) {
        String key = request.getHeader(IDEMPOTENCY_KEY_HEADER);
        if (key == null || key.isBlank()) {
            key = request.getParameter(IDEMPOTENCY_KEY_PARAM);
        }
        return key;
    }
}
