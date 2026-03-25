package com.svtrucking.logistics.infrastructure.security;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import io.jsonwebtoken.security.Keys;
import java.nio.charset.StandardCharsets;
import java.security.Key;
import java.util.Arrays;
import java.util.Date;
import java.util.function.Function;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.env.Environment;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.stereotype.Component;

/**
 * Backward-compatible JWT utility: - Access & Refresh tokens (separate keys + expirations) - Legacy
 * methods kept for existing call sites (generateToken, validateToken, etc.)
 */
@Component
public class JwtUtil {
  private static final Logger LOG = LoggerFactory.getLogger(JwtUtil.class);

  private final Key accessKey;
  private final Key refreshKey;
  private final long accessTtlMs;
  private final long refreshTtlMs;
  private final UserDetailsService userDetailsService;
  private final long allowedClockSkewSeconds;
  private final boolean prodProfile;

  public JwtUtil(
      @Value("${app.security.jwt.access-secret}") String accessSecret,
      @Value("${app.security.jwt.refresh-secret}") String refreshSecret,
      @Value("${app.security.jwt.access-ttl-ms}") long accessTtlMs,
      @Value("${app.security.jwt.refresh-ttl-ms}") long refreshTtlMs,
      @Value("${app.security.jwt.allowed-clock-skew-seconds:0}") long allowedClockSkewSeconds,
      Environment environment,
      UserDetailsService userDetailsService) {
    this.prodProfile =
        Arrays.stream(environment.getActiveProfiles()).anyMatch(p -> "prod".equalsIgnoreCase(p));
    // Defensive handling: ensure provided secrets are large enough for HMAC-SHA256 (>=256 bits / 32 bytes).
    Key ak;
    try {
      if (accessSecret == null || accessSecret.trim().isEmpty() ||
          accessSecret.getBytes(StandardCharsets.UTF_8).length < 32) {
        if (prodProfile) {
          throw new IllegalStateException("JWT access secret is missing or too short for prod");
        }
        LOG.warn("JWT access secret is missing or too short ({} bytes). Generating a secure fallback key.",
            accessSecret == null ? 0 : accessSecret.getBytes(StandardCharsets.UTF_8).length);
        ak = Keys.secretKeyFor(SignatureAlgorithm.HS256);
      } else {
        ak = Keys.hmacShaKeyFor(accessSecret.getBytes(StandardCharsets.UTF_8));
      }
    } catch (Exception e) {
      LOG.warn("Failed to build access key from configured secret, falling back to generated key", e);
      ak = Keys.secretKeyFor(SignatureAlgorithm.HS256);
    }

    Key rk;
    try {
      if (refreshSecret == null || refreshSecret.trim().isEmpty() ||
          refreshSecret.getBytes(StandardCharsets.UTF_8).length < 32) {
        if (prodProfile) {
          throw new IllegalStateException("JWT refresh secret is missing or too short for prod");
        }
        LOG.warn("JWT refresh secret is missing or too short ({} bytes). Generating a secure fallback key.",
            refreshSecret == null ? 0 : refreshSecret.getBytes(StandardCharsets.UTF_8).length);
        rk = Keys.secretKeyFor(SignatureAlgorithm.HS256);
      } else {
        rk = Keys.hmacShaKeyFor(refreshSecret.getBytes(StandardCharsets.UTF_8));
      }
    } catch (Exception e) {
      LOG.warn("Failed to build refresh key from configured secret, falling back to generated key", e);
      rk = Keys.secretKeyFor(SignatureAlgorithm.HS256);
    }

    this.accessKey = ak;
    this.refreshKey = rk;
    this.accessTtlMs = accessTtlMs;
    this.refreshTtlMs = refreshTtlMs;
    this.userDetailsService = userDetailsService;
    this.allowedClockSkewSeconds = allowedClockSkewSeconds;
  }

  // ====== ACCESS TOKEN API ======
  public String generateAccessToken(UserDetails user) {
    return Jwts.builder()
        .setSubject(user.getUsername())
        .setIssuedAt(new Date())
        .setExpiration(new Date(System.currentTimeMillis() + accessTtlMs))
        .signWith(accessKey, SignatureAlgorithm.HS256)
        .compact();
  }

  public String extractUsername(String token) {
    return extractClaim(token, Claims::getSubject);
  }

  public boolean isTokenExpired(String token) {
    Date exp = extractClaim(token, Claims::getExpiration);
    return exp.before(new Date());
  }

  /** Structural + expiry check only (no user lookup). Used by WS handshake, etc. */
  public boolean isTokenValid(String token) {
    try {
      extractAllClaims(token); // will throw if signature invalid
      return !isTokenExpired(token);
    } catch (JwtException | IllegalArgumentException e) {
      return false;
    }
  }

  /** Full validation with user lookup (used in filters). */
  public boolean validateToken(String token, UserDetails userDetails) {
    String username = extractUsername(token);
    return username != null && username.equals(userDetails.getUsername()) && !isTokenExpired(token);
  }

  public UserDetails getUserFromToken(String token) {
    String username = extractUsername(token);
    return userDetailsService.loadUserByUsername(username);
  }

  // ====== REFRESH TOKEN API ======
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
      Claims c =
          Jwts.parserBuilder().setSigningKey(refreshKey).build().parseClaimsJws(token).getBody();
      // treat as refresh if signed with refresh key and typ=refresh
      Object typ = c.get("typ");
      return "refresh".equals(typ) && !isRefreshExpired(c);
    } catch (JwtException | IllegalArgumentException e) {
      return false;
    }
  }

  public String extractUsernameFromRefresh(String refreshToken) {
    Claims c =
        Jwts.parserBuilder()
            .setSigningKey(refreshKey)
            .build()
            .parseClaimsJws(refreshToken)
            .getBody();
    return c.getSubject();
  }

  /** Extract the expiration date from a refresh token (returns null if invalid). */
  public Date extractRefreshExpiration(String refreshToken) {
    try {
      Claims c =
          Jwts.parserBuilder()
              .setSigningKey(refreshKey)
              .build()
              .parseClaimsJws(refreshToken)
              .getBody();
      return c.getExpiration();
    } catch (JwtException | IllegalArgumentException e) {
      return null;
    }
  }

  /** Extract issued-at date from refresh token or null if invalid. */
  public Date extractRefreshIssuedAt(String refreshToken) {
    try {
      Claims c =
          Jwts.parserBuilder()
              .setSigningKey(refreshKey)
              .build()
              .parseClaimsJws(refreshToken)
              .getBody();
      return c.getIssuedAt();
    } catch (JwtException | IllegalArgumentException e) {
      return null;
    }
  }

  private boolean isRefreshExpired(Claims c) {
    Date exp = c.getExpiration();
    return exp == null || exp.before(new Date());
  }

  // ====== Helpers ======
  public <T> T extractClaim(String token, Function<Claims, T> resolver) {
    Claims claims = extractAllClaims(token);
    return resolver.apply(claims);
  }

  private Claims extractAllClaims(String token) {
    // Access-token claims parser (use ACCESS_KEY)
    return Jwts.parserBuilder()
        .setSigningKey(accessKey)
        .setAllowedClockSkewSeconds(allowedClockSkewSeconds)
        .build()
        .parseClaimsJws(token)
        .getBody();
  }

  // ====== Legacy aliases (keep old call sites compiling) ======
  /** Legacy alias: many classes call generateToken(userDetails) expecting an access token */
  public String generateToken(UserDetails userDetails) {
    return generateAccessToken(userDetails);
  }
}
