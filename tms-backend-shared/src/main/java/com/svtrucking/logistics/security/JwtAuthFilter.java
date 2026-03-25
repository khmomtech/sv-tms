package com.svtrucking.logistics.security;

import io.jsonwebtoken.ExpiredJwtException;
import io.jsonwebtoken.JwtException;
import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.List;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

@Component
public class JwtAuthFilter extends OncePerRequestFilter {

  private static final Logger logger = LoggerFactory.getLogger(JwtAuthFilter.class);

  private final JwtUtil jwtUtil;
  private final UserDetailsService userDetailsService;
  private final Counter expiredCounter;
  private final Counter invalidCounter;

  // Only exclude true public paths and login/device bootstrap endpoints.
  private static final List<String> EXCLUDED_PATHS =
      List.of(
          "/api/auth/",
          "/api/device/register",
          "/api/device/request-approval",
          "/device/register",
          "/device/request-approval",
          "/api/public/",
          "/public/",
          "/uploads/",
          "/ws",
          "/ws/",
          "/ws-sockjs",
          "/ws-sockjs/",
          "/actuator/",
          "/api/actuator/");

  public JwtAuthFilter(
      JwtUtil jwtUtil, UserDetailsService userDetailsService, MeterRegistry meterRegistry) {
    this.jwtUtil = jwtUtil;
    this.userDetailsService = userDetailsService;
    this.expiredCounter = meterRegistry.counter("jwt.expired");
    this.invalidCounter = meterRegistry.counter("jwt.invalid");
  }

  @Override
  protected boolean shouldNotFilter(HttpServletRequest request) {
    String path = request.getRequestURI();
    return EXCLUDED_PATHS.stream().anyMatch(path::startsWith);
  }

  @Override
  protected void doFilterInternal(
      HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
      throws ServletException, IOException {

    String token = null;

    String authorizationHeader = request.getHeader("Authorization");
    if (authorizationHeader != null && authorizationHeader.startsWith("Bearer ")) {
      token = authorizationHeader.substring(7);
    }

    if (token == null || token.trim().isEmpty()) {
      token = request.getParameter("token");
    }

    if (token == null || token.trim().isEmpty() || !token.contains(".")) {
      logger.debug("No valid JWT token found in header or query param.");
      filterChain.doFilter(request, response);
      return;
    }

    try {
      String username = jwtUtil.extractUsername(token);
      if (username != null && SecurityContextHolder.getContext().getAuthentication() == null) {
        UserDetails userDetails = userDetailsService.loadUserByUsername(username);

        if (jwtUtil.validateToken(token, userDetails)) {
          UsernamePasswordAuthenticationToken authToken =
              new UsernamePasswordAuthenticationToken(
                  userDetails, null, userDetails.getAuthorities());
          authToken.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
          SecurityContextHolder.getContext().setAuthentication(authToken);
          logger.debug("JWT authentication successful for user: {}", username);
        } else {
          if (jwtUtil.isTokenExpired(token)) {
            expiredCounter.increment();
            logger.debug("Access token expired in clock-skew window (path={})", request.getRequestURI());
            sendJsonError(
                response,
                HttpServletResponse.SC_UNAUTHORIZED,
                "TOKEN_EXPIRED",
                "Access token expired");
          } else {
            logger.warn("Invalid JWT token for user: {}", username);
            sendJsonError(
                response,
                HttpServletResponse.SC_UNAUTHORIZED,
                "INVALID_TOKEN",
                "Invalid JWT token");
          }
          return;
        }
      }
    } catch (ExpiredJwtException e) {
      expiredCounter.increment();
      logger.debug("Access token expired (path={}): {}", request.getRequestURI(), e.getMessage());
      sendJsonError(
          response, HttpServletResponse.SC_UNAUTHORIZED, "TOKEN_EXPIRED", "Access token expired");
      return;
    } catch (JwtException | IllegalArgumentException e) {
      invalidCounter.increment();
      logger.warn("Invalid JWT (path={}): {}", request.getRequestURI(), e.getMessage());
      sendJsonError(response, HttpServletResponse.SC_UNAUTHORIZED, "INVALID_TOKEN", "Invalid JWT");
      return;
    }

    filterChain.doFilter(request, response);
  }

  private void sendJsonError(HttpServletResponse resp, int status, String code, String message)
      throws IOException {
    resp.setStatus(status);
    resp.setContentType("application/json");
    resp.getWriter().write("{\"error\":\"" + code + "\",\"message\":\"" + message + "\"}");
  }
}
