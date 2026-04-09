package com.svtrucking.logistics.security;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import org.springframework.boot.autoconfigure.condition.ConditionalOnWebApplication;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.env.Environment;
import org.springframework.http.HttpMethod;
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
import com.svtrucking.logistics.service.CustomUserDetailsService;
import com.svtrucking.logistics.security.PermissionNames;

@Configuration
@ConditionalOnWebApplication(type = ConditionalOnWebApplication.Type.SERVLET)
@EnableMethodSecurity(prePostEnabled = true)
public class SecurityConfig {

    private final JwtAuthFilter jwtAuthFilter;
    private final ApiKeyFilter apiKeyFilter;
    private final CustomUserDetailsService userDetailsService;
    private final Environment environment;

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
    public SecurityFilterChain filterChain(HttpSecurity http,
            @Value("${app.cors.allowed-origins:http://localhost:4200}") String allowedOrigins) throws Exception {
        // Dev bypass flag: set environment variable DEV_SECURITY_BYPASS=true (non-prod
        // only) to permit
        // anonymous access to the driver location update endpoint for local testing.
        final boolean isProd = Arrays.stream(environment.getActiveProfiles()).anyMatch(p -> "prod".equalsIgnoreCase(p));
        final boolean isLocalLike = Arrays.stream(environment.getActiveProfiles())
                .anyMatch(
                        p -> "local".equalsIgnoreCase(p)
                                || "dev".equalsIgnoreCase(p)
                                || "test".equalsIgnoreCase(p));
        final boolean devBypass;
        {
            boolean tmp = false;
            try {
                String envVal = System.getenv().getOrDefault("DEV_SECURITY_BYPASS", "false");
                boolean requestedBypass = Boolean.parseBoolean(envVal);
                if (requestedBypass && !isLocalLike) {
                    throw new IllegalStateException(
                            "DEV_SECURITY_BYPASS=true is only allowed for local/dev/test profiles.");
                }
                tmp = requestedBypass && !isProd;
            } catch (Exception e) {
                throw e;
            }
            devBypass = tmp;
        }

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
                                    request.getRequestURI()));
                        })
                        .accessDeniedHandler((request, response, accessDeniedException) -> {
                            response.setStatus(jakarta.servlet.http.HttpServletResponse.SC_FORBIDDEN);
                            response.setContentType("application/json");
                            response.getWriter().write(String.format(
                                    "{\"timestamp\":\"%s\",\"status\":403,\"error\":\"Forbidden\",\"message\":\"Access is denied\",\"path\":\"%s\"}",
                                    java.time.LocalDateTime.now().toString(),
                                    request.getRequestURI()));
                        }))
                .authorizeHttpRequests(authz -> {
                    if (devBypass) {
                        authz.requestMatchers("/api/driver/location/update").permitAll();
                    }
                    // Explicitly permit auth entrypoints and error dispatch to avoid accidental
                    // auth interception on login flows.
                    authz.requestMatchers(
                            "/error",
                            "/api/auth/login",
                            "/api/auth/refresh",
                            "/api/auth/driver/login",
                            "/api/auth/driver/**")
                            .permitAll();
                    authz.requestMatchers(
                            "/api/auth/**",
                            "/ws",
                            "/ws/**",
                            "/v3/api-docs/**",
                            "/swagger-ui/**",
                            "/ws-sockjs/**",
                            "/actuator/health",
                            "/actuator/health/**",
                            "/actuator/info",
                            "/actuator/prometheus",
                            "/api/health/**",
                            "/uploads/**",
                            "/privacy.html",
                            "/terms.html")
                            .permitAll()

                            // Internal server-to-server endpoints (guarded by X-Internal-Api-Key in
                            // controller)
                            .requestMatchers("/api/internal/**").permitAll()

                            .requestMatchers("/api/public/**").permitAll()
                            .requestMatchers("/api/debug/**").hasAnyAuthority(
                                    "ROLE_" + RoleType.ADMIN.name(),
                                    "ROLE_" + RoleType.SUPERADMIN.name())
                            .requestMatchers("/api/driver/device/register", "/api/driver/device/request-approval")
                            .permitAll()
                            // Allow admins/superadmins to manage driver devices (needed for test
                            // provisioning)
                            .requestMatchers("/api/driver/device/**")
                            .hasAnyAuthority("ROLE_" + RoleType.ADMIN.name(), "ROLE_" + RoleType.SUPERADMIN.name())
                            .requestMatchers(HttpMethod.GET, "/api/admin/dispatches/**")
                            .hasAnyAuthority(
                                    "ROLE_" + RoleType.ADMIN.name(),
                                    "ROLE_" + RoleType.SUPERADMIN.name(),
                                    "ROLE_" + RoleType.DISPATCH_MONITOR.name(),
                                    "ROLE_" + RoleType.LOADING.name(),
                                    "all_functions")
                            .requestMatchers("/api/admin/dispatches/**")
                            .hasAnyAuthority("ROLE_" + RoleType.ADMIN.name(), "ROLE_" + RoleType.SUPERADMIN.name())
                            .requestMatchers("/api/admin/work-orders/**").hasAnyAuthority(
                                    "ROLE_" + RoleType.ADMIN.name(),
                                    "ROLE_" + RoleType.SUPERADMIN.name(),
                                    "ROLE_" + RoleType.MANAGER.name(),
                                    "ROLE_" + RoleType.TECHNICIAN.name(),
                                    "ROLE_" + RoleType.DISPATCH_MONITOR.name(),
                                    PermissionNames.MAINTENANCE_WORKORDER_READ,
                                    PermissionNames.MAINTENANCE_WORKORDER_WRITE,
                                    PermissionNames.ALL_FUNCTIONS)
                            // Geofence endpoints: MANAGER also allowed (live-map and geofence management)
                            .requestMatchers("/api/admin/geofences", "/api/admin/geofences/**").hasAnyAuthority(
                                    "ROLE_" + RoleType.ADMIN.name(),
                                    "ROLE_" + RoleType.SUPERADMIN.name(),
                                    "ROLE_" + RoleType.MANAGER.name(),
                                    PermissionNames.ALL_FUNCTIONS)
                            .requestMatchers("/api/admin/**").hasAnyAuthority(
                                    "ROLE_" + RoleType.ADMIN.name(),
                                    "ROLE_" + RoleType.SUPERADMIN.name(),
                                    "all_functions")
                            .anyRequest().authenticated();
                })

                .sessionManagement(sess -> sess.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authenticationProvider(authenticationProvider())
                .addFilterBefore(jwtAuthFilter,
                        org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter.class)
                .addFilterBefore(apiKeyFilter, JwtAuthFilter.class);

        return http.build();
    }

    // DAO-based authentication provider
    @Bean
    public DaoAuthenticationProvider authenticationProvider() {
        DaoAuthenticationProvider authProvider = new DaoAuthenticationProvider(passwordEncoder());
        authProvider.setUserDetailsService(userDetailsService);
        return authProvider;
    }

    // Authentication manager bean
    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration config) throws Exception {
        return config.getAuthenticationManager();
    }

    // Password encoder (BCrypt)
    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    CorsConfigurationSource appCorsConfigurationSource(
            @Value("${app.cors.allowed-origins:http://localhost:4200}") String allowedOrigins) {
        CorsConfiguration cors = new CorsConfiguration();
        // Parse comma-separated allowlist. "*" is supported only when credentials are
        // disabled.
        List<String> origins = parseAllowedOrigins(allowedOrigins);
        boolean allowAnyOrigin = origins.stream().anyMatch(o -> "*".equals(o));
        if (allowAnyOrigin) {
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
            return List.of("http://localhost:4200");
        }
        String[] parts = raw.split(",");
        List<String> out = new ArrayList<>();
        for (String p : parts) {
            String v = p == null ? "" : p.trim();
            if (!v.isEmpty()) {
                out.add(v);
            }
        }
        return out.isEmpty() ? List.of("http://localhost:4200") : out;
    }
}
