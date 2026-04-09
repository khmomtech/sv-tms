package com.svtrucking.logistics.interceptor;

import com.svtrucking.logistics.model.AuditTrail;
import com.svtrucking.logistics.service.AuditTrailService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.time.LocalDateTime;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

@Component
public class AuditTrailInterceptor implements HandlerInterceptor {

  private final AuditTrailService auditTrailService;

  public AuditTrailInterceptor(AuditTrailService auditTrailService) {
    this.auditTrailService = auditTrailService;
  }

  @Override
  public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler)
      throws Exception {
    // Log the request
    String method = request.getMethod();
    String uri = request.getRequestURI();
    String queryString = request.getQueryString();
    String fullUrl = queryString != null ? uri + "?" + queryString : uri;

    // Get user information if available
    String username = "anonymous";
    Long userId = null;
    Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
    if (authentication != null
        && authentication.isAuthenticated()
        && !"anonymousUser".equals(authentication.getPrincipal())) {
      username = authentication.getName();
      // In a real implementation, you would get the user ID from the authentication object
    }

    // Create audit trail
    AuditTrail auditTrail = new AuditTrail();
    auditTrail.setUserId(userId);
    auditTrail.setUsername(username);
    auditTrail.setAction(method + "_REQUEST");
    auditTrail.setResourceType("API");
    auditTrail.setResourceName(fullUrl);
    auditTrail.setTimestamp(LocalDateTime.now());
    auditTrail.setDetails("API request: " + method + " " + fullUrl);
    auditTrail.setIpAddress(request.getRemoteAddr());
    auditTrail.setUserAgent(request.getHeader("User-Agent"));

    auditTrailService.createAuditTrail(auditTrail);

    return true;
  }
}
