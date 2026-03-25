package com.svtrucking.logistics.infrastructure.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

@Component
public class ApiKeyFilter extends OncePerRequestFilter {

  @Value("${app.api.key:}")
  private String validApiKey;

  @Override
  protected void doFilterInternal(
      HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
      throws IOException, ServletException {

    if (request.getRequestURI().startsWith("/api/v1/integrations/")) {
      // If no api key is configured (e.g., in tests or local), skip validation
      if (validApiKey == null || validApiKey.isBlank()) {
        filterChain.doFilter(request, response);
        return;
      }

      String apiKey = request.getHeader("x-api-key");
      if (apiKey == null || !apiKey.equals(validApiKey)) {
        response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
        response.setContentType("application/json");
        response.getWriter().write("{\"error\":\"Invalid API Key\"}");
        return;
      }
    }

    filterChain.doFilter(request, response);
  }
}
