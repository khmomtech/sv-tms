package com.svtrucking.logistics.infrastructure.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import io.jsonwebtoken.ExpiredJwtException;
import io.jsonwebtoken.JwtException;
import java.io.IOException;
import java.util.List;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Counter;
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

    //  List of endpoints to skip JWT filtering
    // Only exclude specific public device endpoints (register/request-approval). Previously
    // excluding the entire `/api/device/` prefix caused admin-protected device endpoints to be
    // unauthenticated and return 403. Keep auth endpoints and public uploads/public paths.
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
        // Allow actuator health and info endpoints without JWT
        "/actuator/",
        "/api/actuator/");

  public JwtAuthFilter(JwtUtil jwtUtil, UserDetailsService userDetailsService, MeterRegistry meterRegistry) {
    this.jwtUtil = jwtUtil;
    this.userDetailsService = userDetailsService;
    this.expiredCounter = meterRegistry.counter("jwt.expired");
    this.invalidCounter = meterRegistry.counter("jwt.invalid");
  }

  //  Skip filter for public and login URLs
  @Override
  protected boolean shouldNotFilter(HttpServletRequest request) {
    String path = request.getRequestURI();
    return EXCLUDED_PATHS.stream().anyMatch(path::startsWith);
  }

  //  Main filter logic
  @Override
  protected void doFilterInternal(
      HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
      throws ServletException, IOException {

    String token = null;

    // 🔍 Step 1: Try Authorization header
    final String authorizationHeader = request.getHeader("Authorization");
    if (authorizationHeader != null && authorizationHeader.startsWith("Bearer ")) {
      token = authorizationHeader.substring(7); // Remove 'Bearer ' prefix
    }

    // 🔍 Step 2: Fallback to query parameter (e.g., WebSocket SockJS)
    if (token == null || token.trim().isEmpty()) {
      token = request.getParameter("token");
    }

    // If token is missing or malformed, skip auth (will be blocked by security config if not
    // permitted)
    if (token == null || token.trim().isEmpty() || !token.contains(".")) {
      logger.debug("⛔ No valid JWT token found in header or query param.");
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
          logger.warn(" Invalid JWT token for user: {}", username);
          response.sendError(HttpServletResponse.SC_UNAUTHORIZED, "Invalid JWT token");
          return;
        }
      }
    } catch (ExpiredJwtException e) {
      expiredCounter.increment();
      logger.debug("Access token expired (path={}): {}", request.getRequestURI(), e.getMessage());
      sendJsonError(response, HttpServletResponse.SC_UNAUTHORIZED, "TOKEN_EXPIRED", "Access token expired");
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
