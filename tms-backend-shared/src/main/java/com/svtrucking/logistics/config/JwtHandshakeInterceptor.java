package com.svtrucking.logistics.config;

import com.svtrucking.logistics.security.JwtUtil;
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
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.web.socket.WebSocketHandler;
import org.springframework.web.socket.server.HandshakeInterceptor;

@Slf4j
public class JwtHandshakeInterceptor implements HandshakeInterceptor {

  private final JwtUtil jwtUtil;
  private final UserDetailsService userDetailsService;
  private final List<String> allowedOrigins;

  public JwtHandshakeInterceptor(
      JwtUtil jwtUtil, UserDetailsService userDetailsService, String[] allowedOrigins) {
    this.jwtUtil = jwtUtil;
    this.userDetailsService = userDetailsService;
    this.allowedOrigins = Arrays.asList(allowedOrigins);
  }

  @Override
  public boolean beforeHandshake(
      ServerHttpRequest request,
      ServerHttpResponse response,
      WebSocketHandler wsHandler,
      Map<String, Object> attributes) {

    if (!(request instanceof ServletServerHttpRequest servletRequest)) {
      log.error("WebSocket: Not a ServletServerHttpRequest");
      return false;
    }

    HttpServletRequest httpRequest = servletRequest.getServletRequest();

    String origin = httpRequest.getHeader("Origin");
    log.debug("Origin = {}", origin);
    if (origin != null && !allowedOrigins.contains(origin) && !"null".equals(origin)) {
      log.warn("Origin '{}' not allowed. Allowed = {}", origin, allowedOrigins);
      try {
        response.setStatusCode(HttpStatus.FORBIDDEN);
      } catch (Exception ignored) {
      }
      return false;
    }

    String token = extractJwtToken(httpRequest);
    if (token == null || token.isBlank()) {
      rejectHandshake(response, HttpStatus.UNAUTHORIZED, "missing_token", "JWT token is required");
      return false;
    }

    String failureReason = null;
    try {
      String username = jwtUtil.extractUsername(token);
      UserDetails userDetails = userDetailsService.loadUserByUsername(username);
      if (jwtUtil.validateToken(token, userDetails)) {
        return authenticate(username, userDetails, token, response, attributes);
      }
      failureReason = "expired_token";
    } catch (UsernameNotFoundException ex) {
      failureReason = "user_not_found";
    } catch (JwtException | IllegalArgumentException ex) {
      failureReason = isExpiredToken(token) ? "expired_token" : "invalid_signature";
    }

    if ("expired_token".equals(failureReason)) {
      String refreshToken = extractRefreshToken(httpRequest);
      if (refreshToken != null && jwtUtil.isRefreshToken(refreshToken)) {
        try {
          String username = jwtUtil.extractUsernameFromRefresh(refreshToken);
          UserDetails userDetails = userDetailsService.loadUserByUsername(username);
          String newAccess = jwtUtil.generateAccessToken(userDetails);
          response.getHeaders().set("X-New-Access-Token", newAccess);
          log.info("WebSocket handshake auth refreshed for username={}", username);
          return authenticate(username, userDetails, newAccess, response, attributes);
        } catch (UsernameNotFoundException ex) {
          failureReason = "user_not_found";
        } catch (JwtException | IllegalArgumentException ex) {
          failureReason = "invalid_signature";
        }
      }
    }

    rejectHandshake(response, HttpStatus.UNAUTHORIZED, failureReason, "JWT authentication failed");
    return false;
  }

  @Override
  public void afterHandshake(
      ServerHttpRequest request,
      ServerHttpResponse response,
      WebSocketHandler wsHandler,
      Exception exception) {
    log.debug("WebSocket handshake finished.");
  }

  private String extractJwtToken(HttpServletRequest request) {
    String token = request.getParameter("token");
    if (token == null || token.isBlank()) {
      token = request.getParameter("access_token");
    }
    token = sanitizeToken(token);
    if (token != null && !token.isBlank()) {
      return token;
    }

    String authHeader = request.getHeader("Authorization");
    token = sanitizeToken(authHeader);
    if (token != null && !token.isBlank()) {
      return token;
    }

    String protocolHeader = request.getHeader("Sec-WebSocket-Protocol");
    token = sanitizeToken(protocolHeader);
    if (token != null && !token.isBlank()) {
      return token;
    }

    return null;
  }

  private String sanitizeToken(String raw) {
    if (raw == null) {
      return null;
    }
    String token = raw.trim();
    if (token.isEmpty()) {
      return null;
    }
    if (token.regionMatches(true, 0, "Bearer ", 0, 7)) {
      token = token.substring(7).trim();
    }
    return token.isEmpty() ? null : token;
  }

  private String extractRefreshToken(HttpServletRequest request) {
    String refreshToken = request.getParameter("refreshToken");
    if (refreshToken != null && !refreshToken.isBlank()) {
      return refreshToken;
    }

    String authHeader = request.getHeader("Authorization");
    if (authHeader != null && authHeader.startsWith("Refresh ")) {
      return authHeader.substring(8);
    }

    String header = request.getHeader("X-Refresh-Token");
    if (header != null && !header.isBlank()) {
      return header;
    }
    return null;
  }

  private boolean authenticate(
      String username,
      UserDetails userDetails,
      String token,
      ServerHttpResponse response,
      Map<String, Object> attributes) {
    UsernamePasswordAuthenticationToken authentication =
        new UsernamePasswordAuthenticationToken(
            userDetails, null, userDetails.getAuthorities());

    SecurityContextHolder.getContext().setAuthentication(authentication);

    attributes.put("username", userDetails.getUsername());
    attributes.put("roles", userDetails.getAuthorities());

    log.info("WebSocket handshake auth passed for username={}", username);
    try {
      response.getHeaders().set("X-Access-Token", token);
    } catch (Exception ignored) {
    }
    return true;
  }

  private void rejectHandshake(
      ServerHttpResponse response, HttpStatus status, String reason, String details) {
    String normalizedReason = (reason == null || reason.isBlank()) ? "invalid_signature" : reason;
    log.warn("WebSocket handshake rejected reason={} details={}", normalizedReason, details);
    try {
      response.getHeaders().set("WWW-Authenticate", "Bearer error=\"" + normalizedReason + "\"");
      response.getHeaders().set("X-WS-Auth-Reason", normalizedReason);
      response.setStatusCode(status);
    } catch (Exception ignored) {
    }
  }

  private boolean isExpiredToken(String token) {
    try {
      return jwtUtil.isTokenExpired(token);
    } catch (Exception ex) {
      return false;
    }
  }
}
