package com.svtrucking.telematics.security;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.ExpiredJwtException;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import io.jsonwebtoken.security.Keys;
import java.nio.charset.StandardCharsets;
import java.security.Key;
import java.util.Arrays;
import java.util.Date;
import java.util.List;
import java.util.function.Function;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.env.Environment;
import org.springframework.stereotype.Component;

/**
 * Claims-only JWT utility for tms-telematics-api.
 * Validates HMAC-SHA256 signature and expiry — NO UserDetailsService / NO DB
 * lookup per request.
 * Uses the same JWT_ACCESS_SECRET as tms-core-api so tracking tokens issued
 * there are accepted here.
 *
 * Also generates tracking tokens (same format as tms-core-api JwtUtil.generateTrackingToken)
 * so drivers can obtain a tracking session directly from this service.
 */
@Component
public class TelematicsJwtUtil {

    private static final Logger LOG = LoggerFactory.getLogger(TelematicsJwtUtil.class);
    private static final String DEV_FALLBACK_SECRET = "svtms-local-access-secret-change-me-32bytes-min-0001";

    private final Key accessKey;
    private final long allowedClockSkewSeconds;
    private final long trackingTtlMs;

    public TelematicsJwtUtil(
            @Value("${app.security.jwt.access-secret}") String accessSecret,
            @Value("${app.security.jwt.allowed-clock-skew-seconds:0}") long allowedClockSkewSeconds,
            @Value("${app.security.jwt.tracking-ttl-ms:86400000}") long trackingTtlMs,
            Environment environment) {

        boolean isLocal = Arrays.stream(environment.getActiveProfiles())
                .anyMatch(p -> "local".equalsIgnoreCase(p));

        Key key;
        try {
            if (accessSecret == null || accessSecret.trim().isEmpty()
                    || accessSecret.getBytes(StandardCharsets.UTF_8).length < 32) {
                if (!isLocal) {
                    throw new IllegalStateException(
                            "JWT_ACCESS_SECRET is missing or too short outside local profile");
                }
                LOG.warn("JWT access secret missing/short in local profile — using local fallback key");
                key = Keys.hmacShaKeyFor(DEV_FALLBACK_SECRET.getBytes(StandardCharsets.UTF_8));
            } else {
                key = Keys.hmacShaKeyFor(accessSecret.getBytes(StandardCharsets.UTF_8));
            }
        } catch (IllegalStateException e) {
            throw e;
        } catch (Exception e) {
            if (!isLocal) {
                throw new IllegalStateException("Failed to build JWT access key outside local profile", e);
            }
            LOG.warn("Failed to build access key in local profile, using local fallback", e);
            key = Keys.hmacShaKeyFor(DEV_FALLBACK_SECRET.getBytes(StandardCharsets.UTF_8));
        }

        this.accessKey = key;
        this.allowedClockSkewSeconds = allowedClockSkewSeconds;
        this.trackingTtlMs = trackingTtlMs;
    }

    // ── Public API ─────────────────────────────────────────────────────────────

    public long getTrackingTtlMs() {
        return trackingTtlMs;
    }

    /**
     * Issues a tracking token with the same claims structure as tms-core-api's
     * JwtUtil.generateTrackingToken — drivers can use it on both services interchangeably.
     */
    public String generateTrackingToken(String username, Long driverId, String deviceId, String sessionId) {
        return Jwts.builder()
                .setSubject(username != null ? username : "driver-" + driverId)
                .claim("typ", "tracking")
                .claim("scope", "LOCATION_WRITE TRACKING_WS")
                .claim("driverId", driverId)
                .claim("deviceId", deviceId)
                .claim("sessionId", sessionId)
                .setIssuedAt(new Date())
                .setExpiration(new Date(System.currentTimeMillis() + trackingTtlMs))
                .signWith(accessKey, SignatureAlgorithm.HS256)
                .compact();
    }

    /** Returns subject (username / driver username) or null if token invalid. */
    public String extractUsername(String token) {
        try {
            return extractClaim(token, Claims::getSubject);
        } catch (Exception e) {
            return null;
        }
    }

    /**
     * Returns the token type: "tracking" for driver tracking tokens,
     * "access" for regular access tokens (null/missing typ treated as "access").
     */
    public String extractTokenType(String token) {
        try {
            Object typ = extractAllClaims(token).get("typ");
            return typ == null ? "access" : String.valueOf(typ);
        } catch (Exception e) {
            return null;
        }
    }

    public Long extractDriverId(String token) {
        try {
            Object raw = extractAllClaims(token).get("driverId");
            if (raw instanceof Number n)
                return n.longValue();
            return raw == null ? null : Long.parseLong(String.valueOf(raw));
        } catch (Exception e) {
            return null;
        }
    }

    public String extractDeviceId(String token) {
        try {
            Object raw = extractAllClaims(token).get("deviceId");
            return raw == null ? null : String.valueOf(raw);
        } catch (Exception e) {
            return null;
        }
    }

    public String extractSessionId(String token) {
        try {
            Object raw = extractAllClaims(token).get("sessionId");
            return raw == null ? null : String.valueOf(raw);
        } catch (Exception e) {
            return null;
        }
    }

    public boolean hasScope(String token, String scope) {
        if (scope == null || scope.isBlank())
            return false;
        try {
            Object raw = extractAllClaims(token).get("scope");
            if (raw instanceof String s) {
                return Arrays.stream(s.split("[,\\s]+"))
                        .anyMatch(item -> scope.equalsIgnoreCase(item.trim()));
            }
            if (raw instanceof List<?> list) {
                return list.stream().map(String::valueOf)
                        .anyMatch(item -> scope.equalsIgnoreCase(item.trim()));
            }
            return false;
        } catch (Exception e) {
            return false;
        }
    }

    /** Structural + expiry check only (no user lookup). */
    public boolean isTokenValid(String token) {
        try {
            Claims claims = extractAllClaims(token);
            Date exp = claims.getExpiration();
            return exp != null && !exp.before(new Date());
        } catch (JwtException | IllegalArgumentException e) {
            return false;
        }
    }

    public Claims extractAllClaims(String token) {
        return Jwts.parserBuilder()
                .setSigningKey(accessKey)
                .setAllowedClockSkewSeconds(allowedClockSkewSeconds)
                .build()
                .parseClaimsJws(token)
                .getBody();
    }

    public Claims extractAllClaimsAllowExpired(String token) {
        try {
            return extractAllClaims(token);
        } catch (ExpiredJwtException e) {
            return e.getClaims();
        }
    }

    public <T> T extractClaim(String token, Function<Claims, T> resolver) {
        return resolver.apply(extractAllClaims(token));
    }
}
