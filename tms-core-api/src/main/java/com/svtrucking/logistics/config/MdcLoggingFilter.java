package com.svtrucking.logistics.config;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.UUID;
import org.slf4j.MDC;
import org.springframework.core.annotation.Order;
import org.springframework.lang.NonNull;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

/**
 * Servlet filter that populates the SLF4J Mapped Diagnostic Context (MDC) for
 * every inbound HTTP request.
 *
 * <p>
 * MDC keys set:
 * <ul>
 * <li>{@code requestId} — random UUID generated per request
 * <li>{@code userId} — authenticated principal name (username / phone),
 * or {@code anonymous} if unauthenticated
 * <li>{@code clientIp} — real client IP (honours X-Forwarded-For)
 * </ul>
 *
 * <p>
 * The MDC is always cleared in the {@code finally} block to prevent
 * context leakage between thread-pool reuse.
 *
 * <p>
 * Order is set to {@code -1} so this runs before Spring Security filters
 * but values are available throughout the filter chain.
 */
@Component
@Order(-1)
public class MdcLoggingFilter extends OncePerRequestFilter {

  private static final String MDC_REQUEST_ID = "requestId";
  private static final String MDC_USER_ID = "userId";
  private static final String MDC_CLIENT_IP = "clientIp";

  @Override
  protected void doFilterInternal(
      @NonNull HttpServletRequest request,
      @NonNull HttpServletResponse response,
      @NonNull FilterChain filterChain) throws ServletException, IOException {

    try {
      MDC.put(MDC_REQUEST_ID, UUID.randomUUID().toString());
      MDC.put(MDC_CLIENT_IP, resolveClientIp(request));
      // userId is set after Spring Security has populated the context
      // (best-effort; may be anonymous for unauthenticated endpoints)
      MDC.put(MDC_USER_ID, resolveUserId());

      // Pass requestId downstream as a response header for tracing
      response.setHeader("X-Request-Id", MDC.get(MDC_REQUEST_ID));

      filterChain.doFilter(request, response);

      // Refresh userId after security filter chain resolves authentication
      MDC.put(MDC_USER_ID, resolveUserId());

    } finally {
      MDC.remove(MDC_REQUEST_ID);
      MDC.remove(MDC_USER_ID);
      MDC.remove(MDC_CLIENT_IP);
      // dispatchId / driverId / routeCode are set deeper in the call stack
      // by MdcContext and cleared here as a safety net
      MDC.remove("dispatchId");
      MDC.remove("driverId");
      MDC.remove("routeCode");
    }
  }

  private static String resolveUserId() {
    Authentication auth = SecurityContextHolder.getContext().getAuthentication();
    if (auth != null && auth.isAuthenticated() && !"anonymousUser".equals(auth.getPrincipal())) {
      return auth.getName();
    }
    return "anonymous";
  }

  private static String resolveClientIp(HttpServletRequest request) {
    String forwarded = request.getHeader("X-Forwarded-For");
    if (forwarded != null && !forwarded.isBlank()) {
      // X-Forwarded-For: client, proxy1, proxy2 — take only the first
      int idx = forwarded.indexOf(',');
      return (idx >= 0 ? forwarded.substring(0, idx) : forwarded).trim();
    }
    String realIp = request.getHeader("X-Real-IP");
    if (realIp != null && !realIp.isBlank()) {
      return realIp.trim();
    }
    return request.getRemoteAddr();
  }
}
