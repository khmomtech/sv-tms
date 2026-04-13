package com.svtrucking.gateway.web;

import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.Map;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

@Component
public class AuthHeaderValidationFilter extends OncePerRequestFilter {

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        String path = request.getRequestURI();
        return path.startsWith("/actuator/")
                || path.startsWith("/api/public/")
                || path.startsWith("/api/auth/")
                || path.startsWith("/api/driver/device/")
                || path.startsWith("/uploads/")
                || "OPTIONS".equalsIgnoreCase(request.getMethod());
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {
        String authorization = request.getHeader("Authorization");
        String internalKey = request.getHeader("X-Internal-Api-Key");
        if ((authorization == null || !authorization.startsWith("Bearer ")) && (internalKey == null || internalKey.isBlank())) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.setContentType("application/json");
            objectMapper.writeValue(response.getWriter(), Map.of(
                    "error", "UNAUTHORIZED",
                    "message", "Missing Bearer token or internal API key"));
            return;
        }
        filterChain.doFilter(request, response);
    }
}
