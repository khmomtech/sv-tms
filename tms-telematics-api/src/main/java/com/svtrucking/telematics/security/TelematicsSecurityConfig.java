package com.svtrucking.telematics.security;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

/**
 * Stateless security config for tms-telematics-api.
 * No DaoAuthenticationProvider / no UserDetailsService — all auth is
 * claims-based.
 */
@Configuration
@EnableMethodSecurity(prePostEnabled = true)
public class TelematicsSecurityConfig {

    private final TelematicsJwtAuthFilter jwtAuthFilter;
    private final InternalApiKeyFilter internalApiKeyFilter;

    public TelematicsSecurityConfig(TelematicsJwtAuthFilter jwtAuthFilter,
            InternalApiKeyFilter internalApiKeyFilter) {
        this.jwtAuthFilter = jwtAuthFilter;
        this.internalApiKeyFilter = internalApiKeyFilter;
    }

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http,
            @Value("${app.cors.allowed-origins:http://localhost:4200}") String allowedOrigins)
            throws Exception {

        http
                .csrf(AbstractHttpConfigurer::disable)
                .cors(cors -> cors.configurationSource(corsConfigurationSource(allowedOrigins)))
                .exceptionHandling(ex -> ex
                        .authenticationEntryPoint((req, res, e) -> {
                            res.setStatus(jakarta.servlet.http.HttpServletResponse.SC_UNAUTHORIZED);
                            res.setContentType("application/json");
                            res.getWriter().write(String.format(
                                    "{\"status\":401,\"error\":\"Unauthorized\",\"message\":\"%s\",\"path\":\"%s\"}",
                                    e.getMessage(), req.getRequestURI()));
                        })
                        .accessDeniedHandler((req, res, e) -> {
                            res.setStatus(jakarta.servlet.http.HttpServletResponse.SC_FORBIDDEN);
                            res.setContentType("application/json");
                            res.getWriter().write(String.format(
                                    "{\"status\":403,\"error\":\"Forbidden\",\"message\":\"Access is denied\",\"path\":\"%s\"}",
                                    req.getRequestURI()));
                        }))
                .authorizeHttpRequests(authz -> authz
                        // Public endpoints — no auth required
                        .requestMatchers(
                                "/error",
                                "/actuator/health",
                                "/actuator/health/**",
                                "/actuator/info",
                                "/actuator/prometheus",
                                "/v3/api-docs/**",
                                "/swagger-ui/**",
                                "/api/public/**",
                                "/tele-ws",
                                "/tele-ws/**",
                                "/tele-ws-sockjs",
                                "/tele-ws-sockjs/**")
                        .permitAll()
                        // Internal endpoints — guarded by InternalApiKeyFilter (not JWT)
                        .requestMatchers("/api/internal/**").permitAll()
                        .requestMatchers(HttpMethod.POST,
                                "/api/driver/tracking-session/start",
                                "/api/driver/tracking/session/start")
                        .hasAuthority("ROLE_API_USER")
                        .requestMatchers(HttpMethod.POST,
                                "/api/driver/location/update",
                                "/api/driver/presence/heartbeat",
                                "/api/driver/logout",
                                "/api/locations/spoofing-alert",
                                "/api/driver/tracking-session/refresh",
                                "/api/driver/tracking/session/refresh",
                                "/api/driver/tracking-session/stop",
                                "/api/driver/tracking/session/stop")
                        .hasAnyAuthority("ROLE_DRIVER_TRACKING", "ROLE_API_USER")
                        // Admin live-track and geofences — requires API user token
                        .requestMatchers("/api/admin/telematics/**", "/api/admin/geofences/**")
                        .hasAuthority("ROLE_API_USER")
                        .anyRequest().authenticated())
                .sessionManagement(sess -> sess.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .addFilterBefore(internalApiKeyFilter, UsernamePasswordAuthenticationFilter.class)
                .addFilterBefore(jwtAuthFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }

    @Bean
    CorsConfigurationSource corsConfigurationSource(
            @Value("${app.cors.allowed-origins:http://localhost:4200}") String allowedOrigins) {
        CorsConfiguration cors = new CorsConfiguration();
        List<String> origins = parseOrigins(allowedOrigins);
        boolean wildcard = origins.stream().anyMatch("*"::equals);
        if (wildcard) {
            cors.setAllowedOriginPatterns(List.of("*"));
            cors.setAllowCredentials(false);
        } else {
            cors.setAllowedOrigins(origins);
            cors.setAllowCredentials(true);
        }
        cors.setAllowedMethods(Arrays.asList("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS", "HEAD"));
        cors.setAllowedHeaders(Arrays.asList(
                "Authorization", "Content-Type", "X-Requested-With", "Accept",
                "Origin", "Cache-Control", "X-Internal-Api-Key"));
        cors.setExposedHeaders(List.of("Authorization"));
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", cors);
        return source;
    }

    private static List<String> parseOrigins(String raw) {
        if (raw == null || raw.isBlank())
            return List.of("http://localhost:4200");
        List<String> out = new ArrayList<>();
        for (String p : raw.split(",")) {
            String v = p.trim();
            if (!v.isEmpty())
                out.add(v);
        }
        return out.isEmpty() ? List.of("http://localhost:4200") : out;
    }
}
