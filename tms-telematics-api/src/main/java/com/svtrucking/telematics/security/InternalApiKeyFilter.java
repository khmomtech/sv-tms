package com.svtrucking.telematics.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.Arrays;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.env.Environment;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

/**
 * Guards /api/internal/** with a shared secret header (X-Internal-Api-Key).
 * Only tms-core-api (or other trusted internal services) should know this key.
 */
@Component
public class InternalApiKeyFilter extends OncePerRequestFilter {

    private static final Logger LOG = LoggerFactory.getLogger(InternalApiKeyFilter.class);
    private static final String INTERNAL_PATH_PREFIX = "/api/internal/";
    private static final String HEADER_NAME = "X-Internal-Api-Key";

    @Value("${telematics.internal.api-key:}")
    private String internalApiKey;

    private final boolean localProfile;

    public InternalApiKeyFilter(Environment environment) {
        this.localProfile = Arrays.stream(environment.getActiveProfiles())
                .anyMatch(profile -> "local".equalsIgnoreCase(profile));
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        // Only run this filter for internal paths
        return !request.getRequestURI().startsWith(INTERNAL_PATH_PREFIX);
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response,
            FilterChain chain) throws IOException, ServletException {

        if (internalApiKey == null || internalApiKey.isBlank()) {
            String message = "TELEMATICS_INTERNAL_API_KEY is not configured";
            if (localProfile) {
                LOG.warn("{} in local profile; allowing internal request path={}", message, request.getRequestURI());
                chain.doFilter(request, response);
                return;
            }
            LOG.error("{} outside local profile; rejecting internal request path={}", message, request.getRequestURI());
            reject(response, HttpServletResponse.SC_UNAUTHORIZED, message);
            return;
        }

        String provided = request.getHeader(HEADER_NAME);
        if (provided == null || !provided.equals(internalApiKey)) {
            LOG.warn("Internal API key mismatch for path={}", request.getRequestURI());
            reject(response, HttpServletResponse.SC_UNAUTHORIZED, "Invalid internal API key");
            return;
        }

        chain.doFilter(request, response);
    }

    private void reject(HttpServletResponse response, int status, String message) throws IOException {
        response.setStatus(status);
        response.setContentType("application/json");
        response.getWriter().write("{\"error\":\"UNAUTHORIZED\",\"message\":\"" + message + "\"}");
    }
}
