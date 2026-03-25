package com.svtrucking.logistics.infrastructure.configuration;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.info.Contact;
import org.springdoc.core.models.GroupedOpenApi;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;

/**
 * OpenAPI configuration for generating client-isolated API documentation.
 * Generates separate specs for customer, driver, and admin clients.
 * 
 * Access specs at:
 * - /v3/api-docs/customer - Customer mobile app endpoints
 * - /v3/api-docs/driver - Driver mobile app endpoints
 * - /v3/api-docs/admin - Admin/dispatcher web panel endpoints
 * - /v3/api-docs/auth - Authentication endpoints (shared)
 */
@Profile({"dev","export"})
@Configuration
public class OpenApiConfig {

  @Bean
  public OpenAPI openAPI() {
    return new OpenAPI()
        .info(new Info()
            .title("SV Trucking TMS API")
            .description("Transport Management System API with client-isolated endpoints")
            .version("v1.0.0")
            .contact(new Contact()
                .name("SV Trucking")
                .email("support@svtrucking.com")));
  }

  /**
   * Customer mobile app API group.
   * Contains only /api/customer/** endpoints accessible by customer role.
   */
  @Bean
  public GroupedOpenApi customerApi() {
    return GroupedOpenApi.builder()
        .group("customer")
        .pathsToMatch("/api/customer/**", "/api/auth/**")
        .displayName("Customer Mobile App API")
        .build();
  }

  /**
   * Driver mobile app API group.
   * Contains only /api/driver/** endpoints accessible by driver role.
   */
  @Bean
  public GroupedOpenApi driverApi() {
    return GroupedOpenApi.builder()
        .group("driver")
        .pathsToMatch("/api/driver/**", "/api/auth/**")
        .displayName("Driver Mobile App API")
        .build();
  }

  /**
   * Admin/dispatcher web panel API group.
   * Contains /api/admin/** endpoints requiring admin or dispatcher roles.
   */
  @Bean
  public GroupedOpenApi adminApi() {
    return GroupedOpenApi.builder()
        .group("admin")
        .pathsToMatch("/api/admin/**", "/api/auth/**")
        .displayName("Admin & Dispatcher Web Panel API")
        .build();
  }

  /**
   * Authentication API group (shared by all clients).
   * Contains /api/auth/** endpoints for login, signup, token refresh.
   */
  @Bean
  public GroupedOpenApi authApi() {
    return GroupedOpenApi.builder()
        .group("auth")
        .pathsToMatch("/api/auth/**")
        .displayName("Authentication API")
        .build();
  }
}
