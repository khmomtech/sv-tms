package com.svtrucking.telematics.security;

import io.jsonwebtoken.ExpiredJwtException;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Claims;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.List;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

/**
 * Stateless JWT filter for tms-telematics-api.
 * No UserDetailsService — grants authority purely from token claims:
 *
 * typ=tracking → ROLE_DRIVER_TRACKING
 * typ=access → ROLE_API_USER
 */
@Component
public class TelematicsJwtAuthFilter extends OncePerRequestFilter {

    private static final Logger LOG = LoggerFactory.getLogger(TelematicsJwtAuthFilter.class);

    private static final List<String> EXCLUDED_PATHS = List.of(
            "/api/public/",
            "/tele-ws",
            "/tele-ws/",
            "/tele-ws-sockjs",
            "/tele-ws-sockjs/",
            "/actuator/",
            "/api/internal/" // guarded by InternalApiKeyFilter instead
    );

    private final TelematicsJwtUtil jwtUtil;

    public TelematicsJwtAuthFilter(TelematicsJwtUtil jwtUtil) {
        this.jwtUtil = jwtUtil;
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        String path = request.getRequestURI();
        return EXCLUDED_PATHS.stream().anyMatch(path::startsWith);
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response,
            FilterChain chain) throws ServletException, IOException {

        String token = resolveToken(request);

        if (token == null || !token.contains(".")) {
            chain.doFilter(request, response);
            return;
        }

        try {
            if (!jwtUtil.isTokenValid(token)) {
                sendInvalidTokenError(request, response, token, "JWT is invalid or expired");
                return;
            }

            if (SecurityContextHolder.getContext().getAuthentication() == null) {
                String tokenType = jwtUtil.extractTokenType(token);
                String role = "tracking".equals(tokenType)
                        ? "ROLE_DRIVER_TRACKING"
                        : "ROLE_API_USER";

                String subject = jwtUtil.extractUsername(token);
                UsernamePasswordAuthenticationToken auth = new UsernamePasswordAuthenticationToken(
                        subject,
                        null,
                        List.of(new SimpleGrantedAuthority(role)));
                SecurityContextHolder.getContext().setAuthentication(auth);
                LOG.debug("Telematics JWT auth ok: subject={} role={}", subject, role);
            }
        } catch (ExpiredJwtException e) {
            LOG.debug("JWT expired (path={}): {}", request.getRequestURI(), e.getMessage());
            sendExpiredTokenError(request, response, token, e);
            return;
        } catch (JwtException | IllegalArgumentException e) {
            LOG.warn("Invalid JWT (path={}): {}", request.getRequestURI(), e.getMessage());
            sendInvalidTokenError(request, response, token, "Invalid JWT");
            return;
        }

        chain.doFilter(request, response);
    }

    private String resolveToken(HttpServletRequest request) {
        String header = request.getHeader("Authorization");
        if (header != null && header.startsWith("Bearer ")) {
            return header.substring(7);
        }
        return request.getParameter("token");
    }

    private void sendJsonError(HttpServletResponse resp, int status, String code, String message)
            throws IOException {
        resp.setStatus(status);
        resp.setContentType("application/json");
        resp.getWriter().write("{\"error\":\"" + code + "\",\"message\":\"" + message + "\"}");
    }

    private void sendExpiredTokenError(
            HttpServletRequest request,
            HttpServletResponse response,
            String token,
            ExpiredJwtException exception) throws IOException {
        String tokenType = null;
        try {
            Claims claims = exception.getClaims() != null
                    ? exception.getClaims()
                    : jwtUtil.extractAllClaimsAllowExpired(token);
            Object rawType = claims != null ? claims.get("typ") : null;
            tokenType = rawType == null ? "access" : String.valueOf(rawType);
        } catch (Exception ignored) {
        }

        if (isRecoverableTrackingWritePath(request) && "tracking".equalsIgnoreCase(tokenType)) {
            sendJsonError(response, HttpServletResponse.SC_UNAUTHORIZED,
                    "STALE_TRACKING_TOKEN", "Tracking token expired; clear and reacquire tracking session");
            return;
        }

        sendJsonError(response, HttpServletResponse.SC_UNAUTHORIZED,
                "TOKEN_EXPIRED", "Access token expired");
    }

    private void sendInvalidTokenError(
            HttpServletRequest request,
            HttpServletResponse response,
            String token,
            String defaultMessage) throws IOException {
        String tokenType = jwtUtil.extractTokenType(token);
        if (isRecoverableTrackingWritePath(request) && "tracking".equalsIgnoreCase(tokenType)) {
            sendJsonError(response, HttpServletResponse.SC_UNAUTHORIZED,
                    "STALE_TRACKING_TOKEN", "Tracking token invalid; clear and reacquire tracking session");
            return;
        }
        sendJsonError(response, HttpServletResponse.SC_UNAUTHORIZED,
                "INVALID_TOKEN", defaultMessage);
    }

    private boolean isRecoverableTrackingWritePath(HttpServletRequest request) {
        String path = request.getRequestURI();
        return "/api/driver/location".equals(path)
                || "/api/driver/location/batch".equals(path)
                || "/api/driver/location/update".equals(path)
                || "/api/driver/location/update/batch".equals(path)
                || "/api/driver/presence/heartbeat".equals(path);
    }
}
