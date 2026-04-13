package com.svtrucking.logistics.security;

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
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.stereotype.Component;

/**
 * Backward-compatible JWT utility:
 * - Access and refresh tokens with separate keys and expirations
 * - Legacy methods kept for existing call sites
 */
@Component
public class JwtUtil {
  private static final Logger LOG = LoggerFactory.getLogger(JwtUtil.class);
  private static final String DEV_FALLBACK_ACCESS_SECRET =
      "svtms-dev-access-secret-change-me-32bytes-min-0001";
  private static final String DEV_FALLBACK_REFRESH_SECRET =
      "svtms-dev-refresh-secret-change-me-32bytes-min-0001";

  private final Key accessKey;
  private final Key refreshKey;
  private final long accessTtlMs;
  private final long refreshTtlMs;
  private final long trackingTtlMs;
  private final UserDetailsService userDetailsService;
  private final long allowedClockSkewSeconds;

  public JwtUtil(
      @Value("${app.security.jwt.access-secret:}") String accessSecret,
      @Value("${app.security.jwt.refresh-secret:}") String refreshSecret,
      @Value("${app.security.jwt.access-ttl-ms:900000}") long accessTtlMs,
      @Value("${app.security.jwt.refresh-ttl-ms:2592000000}") long refreshTtlMs,
      @Value("${app.security.jwt.tracking-ttl-ms:86400000}") long trackingTtlMs,
      @Value("${app.security.jwt.allowed-clock-skew-seconds:300}") long allowedClockSkewSeconds,
      Environment environment,
      UserDetailsService userDetailsService) {
    boolean prodProfile =
        Arrays.stream(environment.getActiveProfiles()).anyMatch(p -> "prod".equalsIgnoreCase(p));

    Key ak;
    try {
      if (accessSecret == null
          || accessSecret.trim().isEmpty()
          || accessSecret.getBytes(StandardCharsets.UTF_8).length < 32) {
        if (prodProfile) {
          throw new IllegalStateException("JWT access secret is missing or too short for prod");
        }
        LOG.warn(
            "JWT access secret is missing or too short ({} bytes). Using deterministic dev fallback key.",
            accessSecret == null ? 0 : accessSecret.getBytes(StandardCharsets.UTF_8).length);
        ak = Keys.hmacShaKeyFor(DEV_FALLBACK_ACCESS_SECRET.getBytes(StandardCharsets.UTF_8));
      } else {
        ak = Keys.hmacShaKeyFor(accessSecret.getBytes(StandardCharsets.UTF_8));
      }
    } catch (Exception e) {
      LOG.warn(
          "Failed to build access key from configured secret, using deterministic dev fallback key",
          e);
      ak = Keys.hmacShaKeyFor(DEV_FALLBACK_ACCESS_SECRET.getBytes(StandardCharsets.UTF_8));
    }

    Key rk;
    try {
      if (refreshSecret == null
          || refreshSecret.trim().isEmpty()
          || refreshSecret.getBytes(StandardCharsets.UTF_8).length < 32) {
        if (prodProfile) {
          throw new IllegalStateException("JWT refresh secret is missing or too short for prod");
        }
        LOG.warn(
            "JWT refresh secret is missing or too short ({} bytes). Using deterministic dev fallback key.",
            refreshSecret == null ? 0 : refreshSecret.getBytes(StandardCharsets.UTF_8).length);
        rk = Keys.hmacShaKeyFor(DEV_FALLBACK_REFRESH_SECRET.getBytes(StandardCharsets.UTF_8));
      } else {
        rk = Keys.hmacShaKeyFor(refreshSecret.getBytes(StandardCharsets.UTF_8));
      }
    } catch (Exception e) {
      LOG.warn(
          "Failed to build refresh key from configured secret, using deterministic dev fallback key",
          e);
      rk = Keys.hmacShaKeyFor(DEV_FALLBACK_REFRESH_SECRET.getBytes(StandardCharsets.UTF_8));
    }

    this.accessKey = ak;
    this.refreshKey = rk;
    this.accessTtlMs = accessTtlMs;
    this.refreshTtlMs = refreshTtlMs;
    this.trackingTtlMs = trackingTtlMs;
    this.userDetailsService = userDetailsService;
    this.allowedClockSkewSeconds = allowedClockSkewSeconds;
  }

  public String generateAccessToken(UserDetails user) {
    return Jwts.builder()
        .setSubject(user.getUsername())
        .setIssuedAt(new Date())
        .setExpiration(new Date(System.currentTimeMillis() + accessTtlMs))
        .signWith(accessKey, SignatureAlgorithm.HS256)
        .compact();
  }

  public String generateTrackingToken(
      UserDetails user, Long driverId, String deviceId, String sessionId) {
    return Jwts.builder()
        .setSubject(user.getUsername())
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

  public Claims extractAccessClaims(String token) {
    return extractAllClaims(token);
  }

  public Claims extractAccessClaimsAllowExpired(String token) {
    try {
      return extractAllClaims(token);
    } catch (ExpiredJwtException e) {
      return e.getClaims();
    }
  }

  public String extractTokenType(String token) {
    try {
      Object typ = extractAllClaims(token).get("typ");
      return typ == null ? "access" : String.valueOf(typ);
    } catch (Exception e) {
      return null;
    }
  }

  public Long extractDriverIdClaim(String token) {
    try {
      Object raw = extractAllClaims(token).get("driverId");
      if (raw instanceof Number number) {
        return number.longValue();
      }
      return raw == null ? null : Long.parseLong(String.valueOf(raw));
    } catch (Exception e) {
      return null;
    }
  }

  public String extractDeviceIdClaim(String token) {
    try {
      Object raw = extractAllClaims(token).get("deviceId");
      return raw == null ? null : String.valueOf(raw);
    } catch (Exception e) {
      return null;
    }
  }

  public String extractSessionIdClaim(String token) {
    try {
      Object raw = extractAllClaims(token).get("sessionId");
      return raw == null ? null : String.valueOf(raw);
    } catch (Exception e) {
      return null;
    }
  }

  public boolean hasScope(String token, String scope) {
    if (scope == null || scope.isBlank()) {
      return false;
    }
    try {
      Object raw = extractAllClaims(token).get("scope");
      if (raw instanceof String value) {
        return Arrays.stream(value.split("[,\\s]+"))
            .anyMatch(item -> scope.equalsIgnoreCase(item.trim()));
      }
      if (raw instanceof List<?> list) {
        return list.stream()
            .map(String::valueOf)
            .anyMatch(item -> scope.equalsIgnoreCase(item.trim()));
      }
      return false;
    } catch (Exception e) {
      return false;
    }
  }

  public String extractUsername(String token) {
    return extractClaim(token, Claims::getSubject);
  }

  public boolean isTokenExpired(String token) {
    Date exp = extractClaim(token, Claims::getExpiration);
    return exp.before(new Date());
  }

  public boolean isTokenValid(String token) {
    try {
      extractAllClaims(token);
      return !isTokenExpired(token);
    } catch (JwtException | IllegalArgumentException e) {
      return false;
    }
  }

  public boolean validateToken(String token, UserDetails userDetails) {
    String username = extractUsername(token);
    return username != null && username.equals(userDetails.getUsername()) && !isTokenExpired(token);
  }

  public UserDetails getUserFromToken(String token) {
    String username = extractUsername(token);
    return userDetailsService.loadUserByUsername(username);
  }

  public String generateRefreshToken(UserDetails user) {
    return Jwts.builder()
        .setSubject(user.getUsername())
        .claim("typ", "refresh")
        .setIssuedAt(new Date())
        .setExpiration(new Date(System.currentTimeMillis() + refreshTtlMs))
        .signWith(refreshKey, SignatureAlgorithm.HS256)
        .compact();
  }

  public boolean isRefreshToken(String token) {
    try {
      Claims claims =
          Jwts.parserBuilder().setSigningKey(refreshKey).build().parseClaimsJws(token).getBody();
      Object typ = claims.get("typ");
      return "refresh".equals(typ) && !isRefreshExpired(claims);
    } catch (JwtException | IllegalArgumentException e) {
      return false;
    }
  }

  public String extractUsernameFromRefresh(String refreshToken) {
    Claims claims =
        Jwts.parserBuilder()
            .setSigningKey(refreshKey)
            .build()
            .parseClaimsJws(refreshToken)
            .getBody();
    return claims.getSubject();
  }

  public Date extractRefreshExpiration(String refreshToken) {
    try {
      Claims claims =
          Jwts.parserBuilder()
              .setSigningKey(refreshKey)
              .build()
              .parseClaimsJws(refreshToken)
              .getBody();
      return claims.getExpiration();
    } catch (JwtException | IllegalArgumentException e) {
      return null;
    }
  }

  public Date extractRefreshIssuedAt(String refreshToken) {
    try {
      Claims claims =
          Jwts.parserBuilder()
              .setSigningKey(refreshKey)
              .build()
              .parseClaimsJws(refreshToken)
              .getBody();
      return claims.getIssuedAt();
    } catch (JwtException | IllegalArgumentException e) {
      return null;
    }
  }

  private boolean isRefreshExpired(Claims claims) {
    Date exp = claims.getExpiration();
    return exp == null || exp.before(new Date());
  }

  public <T> T extractClaim(String token, Function<Claims, T> resolver) {
    Claims claims = extractAllClaims(token);
    return resolver.apply(claims);
  }

  private Claims extractAllClaims(String token) {
    return Jwts.parserBuilder()
        .setSigningKey(accessKey)
        .setAllowedClockSkewSeconds(allowedClockSkewSeconds)
        .build()
        .parseClaimsJws(token)
        .getBody();
  }

  public String generateToken(UserDetails userDetails) {
    return generateAccessToken(userDetails);
  }
}
