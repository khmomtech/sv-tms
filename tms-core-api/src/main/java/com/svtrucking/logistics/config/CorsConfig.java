package com.svtrucking.logistics.config;

import java.util.Arrays;
import java.util.List;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
import org.springframework.web.filter.CorsFilter;

/**
 * Global CORS configuration for allowing cross-origin requests. Reads allowed origins from
 * application properties.
 */
@Configuration
public class CorsConfig {

  @Value("${app.cors.allowed-origins:http://localhost:4200,http://localhost:8080,http://127.0.0.1:4200,http://127.0.0.1:8080}")
  private String allowedOrigins; // e.g., "https://svtms.svtrucking.biz,http://localhost:4200"

  @Bean
  CorsFilter corsFilter() {
    CorsConfiguration config = new CorsConfiguration();

    // Allow specific origins from config
    config.setAllowedOrigins(Arrays.asList(allowedOrigins.split(",")));

    // Allow standard HTTP methods
    config.setAllowedMethods(List.of("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));

    // Allow standard headers including auth tokens
    config.setAllowedHeaders(
        List.of(
            "Origin",
            "Content-Type",
            "Accept",
            "Authorization",
            "X-Requested-With",
            "Access-Control-Allow-Headers",
            "x-client",
            "x-request-id",
            "x-retried"));

    // Expose headers to the frontend (optional but helpful)
    config.setExposedHeaders(List.of("Authorization", "Content-Disposition"));

    // Allow credentials like cookies or Authorization headers
    config.setAllowCredentials(true);

    // Register CORS config for all endpoints
    UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
    source.registerCorsConfiguration("/**", config);

    return new CorsFilter(source);
  }
}
