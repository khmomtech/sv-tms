package com.svtrucking.telematics.config;

import com.svtrucking.telematics.security.TelematicsJwtUtil;
import io.jsonwebtoken.JwtException;
import jakarta.servlet.http.HttpServletRequest;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.server.ServerHttpRequest;
import org.springframework.http.server.ServerHttpResponse;
import org.springframework.http.server.ServletServerHttpRequest;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.socket.WebSocketHandler;
import org.springframework.web.socket.server.HandshakeInterceptor;

/**
 * Claims-only WebSocket handshake interceptor for tms-telematics-api.
 * No UserDetailsService — authority is derived from the "typ" claim in the JWT.
 */
@Slf4j
public class TelematicsJwtHandshakeInterceptor implements HandshakeInterceptor {

    private final TelematicsJwtUtil jwtUtil;
    private final List<String> allowedOrigins;

    public TelematicsJwtHandshakeInterceptor(TelematicsJwtUtil jwtUtil, String[] allowedOrigins) {
        this.jwtUtil = jwtUtil;
        this.allowedOrigins = Arrays.asList(allowedOrigins);
    }

    @Override
    public boolean beforeHandshake(
            ServerHttpRequest request,
            ServerHttpResponse response,
            WebSocketHandler wsHandler,
            Map<String, Object> attributes) {

        if (!(request instanceof ServletServerHttpRequest servletRequest)) {
            log.error("WS: Not a ServletServerHttpRequest");
            return false;
        }

        HttpServletRequest httpRequest = servletRequest.getServletRequest();

        // Validate Origin
        String origin = httpRequest.getHeader("Origin");
        if (origin != null && !allowedOrigins.contains("*") && !allowedOrigins.contains(origin)
                && !"null".equals(origin)) {
            log.warn("WS origin '{}' not allowed", origin);
            try {
                response.setStatusCode(HttpStatus.FORBIDDEN);
            } catch (Exception ignored) {
            }
            return false;
        }

        // Extract JWT
        String token = extractJwtToken(httpRequest);
        if (token == null || token.isBlank()) {
            rejectHandshake(response, "missing_token");
            return false;
        }

        // Validate token (structurally + expiry, no DB)
        try {
            if (!jwtUtil.isTokenValid(token)) {
                rejectHandshake(response, "expired_or_invalid_token");
                return false;
            }
            return authenticate(token, response, attributes);
        } catch (JwtException | IllegalArgumentException ex) {
            rejectHandshake(response, "invalid_signature");
            return false;
        } catch (Exception ex) {
            log.warn("WS handshake auth error: {}", ex.getMessage());
            rejectHandshake(response, "auth_error");
            return false;
        }
    }

    @Override
    public void afterHandshake(
            ServerHttpRequest request, ServerHttpResponse response,
            WebSocketHandler wsHandler, Exception exception) {
        log.debug("WS handshake finished");
    }

    private boolean authenticate(String token, ServerHttpResponse response,
            Map<String, Object> attributes) {
        String tokenType = jwtUtil.extractTokenType(token);
        String role = "tracking".equalsIgnoreCase(tokenType)
                ? "ROLE_DRIVER_TRACKING"
                : "ROLE_API_USER";

        String username = jwtUtil.extractUsername(token);
        Long driverId = jwtUtil.extractDriverId(token);

        var auth = new UsernamePasswordAuthenticationToken(
                username != null ? username : "driver-" + driverId,
                null,
                List.of(new SimpleGrantedAuthority(role)));
        SecurityContextHolder.getContext().setAuthentication(auth);

        attributes.put("username", username);
        attributes.put("driverId", driverId);
        attributes.put("role", role);

        try {
            response.getHeaders().set("X-Access-Token", token);
        } catch (Exception ignored) {
        }

        log.info("WS handshake OK: driverId={} role={}", driverId, role);
        return true;
    }

    private void rejectHandshake(ServerHttpResponse response, String reason) {
        log.warn("WS handshake rejected: {}", reason);
        try {
            response.getHeaders().set("WWW-Authenticate", "Bearer error=\"" + reason + "\"");
            response.getHeaders().set("X-WS-Auth-Reason", reason);
            response.setStatusCode(HttpStatus.UNAUTHORIZED);
        } catch (Exception ignored) {
        }
    }

    private String extractJwtToken(HttpServletRequest request) {
        String token = request.getParameter("token");
        if (token == null || token.isBlank()) {
            token = request.getParameter("access_token");
        }
        token = sanitize(token);
        if (token != null)
            return token;

        token = sanitize(request.getHeader("Authorization"));
        if (token != null)
            return token;

        return sanitize(request.getHeader("Sec-WebSocket-Protocol"));
    }

    private static String sanitize(String raw) {
        if (raw == null)
            return null;
        String t = raw.trim();
        if (t.isEmpty())
            return null;
        if (t.regionMatches(true, 0, "Bearer ", 0, 7)) {
            t = t.substring(7).trim();
        }
        return t.isEmpty() ? null : t;
    }
}
