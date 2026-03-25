package com.svtrucking.logistics.infrastructure.security;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import org.springframework.boot.autoconfigure.condition.ConditionalOnWebApplication;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.env.Environment;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.dao.DaoAuthenticationProvider;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import com.svtrucking.logistics.enums.RoleType;
import com.svtrucking.logistics.identity.service.CustomUserDetailsService;

@Configuration
@ConditionalOnWebApplication(type = ConditionalOnWebApplication.Type.SERVLET)
@EnableMethodSecurity(prePostEnabled = true)
public class SecurityConfig {

  private final JwtAuthFilter jwtAuthFilter;
  private final ApiKeyFilter apiKeyFilter;
  private final CustomUserDetailsService userDetailsService;
  private final Environment environment;

  // Safety-only allowlist. Everything else is denied at the filter chain level.
  private static final String[] PERMIT_ALL = {
      "/api/auth/**",
      "/v3/api-docs/**",
      "/swagger-ui/**",
      // Legacy path: pre-loading safety feature removed from this service. Permit so it returns 404.
      "/api/pre-loading-safety/**",
      "/actuator/health",
      "/actuator/health/**",
      "/actuator/info",
      "/actuator/prometheus",
      "/uploads/**",
      "/privacy.html",
      "/terms.html",
      // device onboarding (used by driver-app login flows; keep if you still use device approval)
      "/api/driver/device/register",
      "/api/driver/device/request-approval",
      // public safety portal endpoints
      "/api/public/safety-checks/**"
  };

  private static final String[] SAFETY_API = {
      "/api/dispatch/safety-eligibility",
      "/api/driver/safety-checks/**",
      "/api/admin/safety-checks/**",
      "/api/admin/safety-master/**"
  };

  public SecurityConfig(
      JwtAuthFilter jwtAuthFilter,
      ApiKeyFilter apiKeyFilter,
      CustomUserDetailsService userDetailsService,
      Environment environment) {
    this.jwtAuthFilter = jwtAuthFilter;
    this.apiKeyFilter = apiKeyFilter;
    this.userDetailsService = userDetailsService;
    this.environment = environment;
  }

  // NOTE: SockJS endpoints are explicitly permitted in `filterChain(...)`.

  @Bean
  public SecurityFilterChain filterChain(
      HttpSecurity http, @Value("${app.cors.allowed-origins:}") String allowedOrigins)
      throws Exception {
    http
        .csrf(AbstractHttpConfigurer::disable)
        .cors(cors -> cors.configurationSource(appCorsConfigurationSource(allowedOrigins)))
        .exceptionHandling(exceptions -> exceptions
            .authenticationEntryPoint((request, response, authException) -> {
                response.setStatus(jakarta.servlet.http.HttpServletResponse.SC_UNAUTHORIZED);
                response.setContentType("application/json");
                response.getWriter().write(String.format(
                    "{\"timestamp\":\"%s\",\"status\":401,\"error\":\"Unauthorized\",\"message\":\"%s\",\"path\":\"%s\"}",
                    java.time.LocalDateTime.now().toString(),
                    authException.getMessage(),
                    request.getRequestURI()
                ));
            })
            .accessDeniedHandler((request, response, accessDeniedException) -> {
                response.setStatus(jakarta.servlet.http.HttpServletResponse.SC_FORBIDDEN);
                response.setContentType("application/json");
                response.getWriter().write(String.format(
                    "{\"timestamp\":\"%s\",\"status\":403,\"error\":\"Forbidden\",\"message\":\"Access is denied\",\"path\":\"%s\"}",
                    java.time.LocalDateTime.now().toString(),
                    request.getRequestURI()
                ));
            })
        )
        .authorizeHttpRequests(authz -> authz
            .requestMatchers(PERMIT_ALL).permitAll()
            // Allow admins/superadmins to manage driver devices (optional; used for provisioning).
            .requestMatchers("/api/driver/device/**").hasAnyAuthority(
                "ROLE_" + RoleType.ADMIN.name(),
                "ROLE_" + RoleType.SUPERADMIN.name())
            // Safety-only API surface. Method-level @PreAuthorize handles fine-grained permissions.
            .requestMatchers(SAFETY_API).authenticated()
            // Everything else is explicitly disabled in this service.
            .anyRequest().denyAll())
        
        .sessionManagement(sess -> sess.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
        .authenticationProvider(authenticationProvider())
        .addFilterBefore(jwtAuthFilter, org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter.class)
        .addFilterBefore(apiKeyFilter, JwtAuthFilter.class);

    return http.build();
  }

  //  DAO-based authentication provider
  @Bean
  public DaoAuthenticationProvider authenticationProvider() {
    DaoAuthenticationProvider authProvider = new DaoAuthenticationProvider(passwordEncoder());
    authProvider.setUserDetailsService(userDetailsService);
    return authProvider;
  }

  //  Authentication manager bean
  @Bean
  public AuthenticationManager authenticationManager(AuthenticationConfiguration config) throws Exception {
    return config.getAuthenticationManager();
  }

  //  Password encoder (BCrypt)
  @Bean
  public PasswordEncoder passwordEncoder() {
    return new BCryptPasswordEncoder();
  }

  @Bean
  CorsConfigurationSource appCorsConfigurationSource(
      @Value("${app.cors.allowed-origins:}") String allowedOrigins) {
    final boolean isProd =
        Arrays.stream(environment.getActiveProfiles()).anyMatch(p -> "prod".equalsIgnoreCase(p));

    CorsConfiguration cors = new CorsConfiguration();
    // Parse comma-separated allowlist. "*" is supported only when credentials are disabled.
    List<String> origins = parseAllowedOrigins(allowedOrigins);
    if (origins.isEmpty()) {
      if (isProd) {
        throw new IllegalStateException("Missing required CORS allowlist: app.cors.allowed-origins");
      }
      origins = List.of("http://localhost:4200");
    }
    boolean allowAnyOrigin = origins.stream().anyMatch(o -> "*".equals(o));
    if (allowAnyOrigin) {
      if (isProd) {
        throw new IllegalStateException("CORS wildcard '*' is not allowed in prod");
      }
      cors.setAllowedOriginPatterns(List.of("*"));
      cors.setAllowCredentials(false);
    } else {
      cors.setAllowedOrigins(origins);
      cors.setAllowCredentials(true);
    }
    cors.setAllowedMethods(
        Arrays.asList("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS", "HEAD"));
    cors.setAllowedHeaders(
        Arrays.asList(
            "Authorization",
            "Content-Type",
            "X-Requested-With",
            "Accept",
            "Origin",
            "Cache-Control",
            "Pragma",
            "x-request-id",
            "x-retried"));
    cors.setExposedHeaders(Arrays.asList("Authorization", "Content-Disposition"));

    UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
    source.registerCorsConfiguration("/**", cors);
    return source;
  }

  private static List<String> parseAllowedOrigins(String raw) {
    if (raw == null || raw.trim().isEmpty()) {
      return List.of();
    }
    String[] parts = raw.split(",");
    List<String> out = new ArrayList<>();
    for (String p : parts) {
      String v = p == null ? "" : p.trim();
      if (!v.isEmpty()) {
        out.add(v);
      }
    }
    return out;
  }
}
