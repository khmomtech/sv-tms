package com.svtrucking.logistics.config;

import com.svtrucking.logistics.security.AuthenticatedUserUtil;
import com.svtrucking.logistics.security.AuthorizationService;
import com.svtrucking.logistics.model.User;
import com.svtrucking.logistics.model.Permission;
// import com.svtrucking.logistics.model.Role;
// import com.svtrucking.logistics.enums.RoleType;
import java.util.Set;
import java.util.HashSet;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Primary;
import org.springframework.context.annotation.Profile;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import static org.mockito.Mockito.*;

import java.util.Arrays;

/**
 * Test security configuration that bypasses authorization checks.
 * NOTE: SecurityFilterChain is provided by TestAuthConfig in main/security package.
 */
@TestConfiguration
@Profile("test")
public class TestSecurityConfig {

    /**
     * CORS configuration for tests.
     */
    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();
        configuration.setAllowedOrigins(Arrays.asList("http://localhost:4200", "http://localhost:8080"));
        configuration.setAllowedMethods(Arrays.asList("GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"));
        configuration.setAllowedHeaders(Arrays.asList("*"));
        configuration.setAllowCredentials(true);
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        return source;
    }

    /**
     * Mock AuthenticatedUserUtil that returns a test user with all permissions.
     */
    @Bean
    @Primary
    public AuthenticatedUserUtil testAuthenticatedUserUtil() {
        AuthenticatedUserUtil mock = mock(AuthenticatedUserUtil.class);
        
        // Create a test user with all_functions permission
        User testUser = new User();
        testUser.setId(1L);
        testUser.setUsername("testuser");
        testUser.setEmail("test@example.com");
        
        // Create permission
        Permission allFunctionsPermission = new Permission();
        allFunctionsPermission.setId(1L);
        allFunctionsPermission.setName("all_functions");
        
        // Create role with the permission (following RBAC model)
        com.svtrucking.logistics.model.Role testRole = new com.svtrucking.logistics.model.Role();
        testRole.setId(1L);
        testRole.setName(com.svtrucking.logistics.enums.RoleType.ADMIN);
        Set<Permission> permissions = new HashSet<>();
        permissions.add(allFunctionsPermission);
        testRole.setPermissions(permissions);
        
        // Assign role to user
        Set<com.svtrucking.logistics.model.Role> roles = new HashSet<>();
        roles.add(testRole);
        testUser.setRoles(roles);
        
        when(mock.getCurrentUser()).thenReturn(testUser);
        when(mock.getCurrentDriverId()).thenReturn(1L);
        
        return mock;
    }

    /**
     * Mock AuthorizationService that allows all permission checks.
     */
    @Bean
    @Primary
    public AuthorizationService testAuthorizationService() {
        AuthorizationService mock = mock(AuthorizationService.class);
        
        // Allow permission checks only when there is an authenticated principal.
        when(mock.hasPermission(anyString())).thenAnswer(invocation -> {
            var auth = org.springframework.security.core.context.SecurityContextHolder.getContext().getAuthentication();
            return auth != null && auth.isAuthenticated() && !"anonymousUser".equals(auth.getName());
        });
        when(mock.hasAnyPermission(any())).thenAnswer(invocation -> {
            var auth = org.springframework.security.core.context.SecurityContextHolder.getContext().getAuthentication();
            return auth != null && auth.isAuthenticated() && !"anonymousUser".equals(auth.getName());
        });
        when(mock.hasRole(anyString())).thenAnswer(invocation -> {
            var auth = org.springframework.security.core.context.SecurityContextHolder.getContext().getAuthentication();
            return auth != null && auth.isAuthenticated() && !"anonymousUser".equals(auth.getName());
        });
        
        return mock;
    }
}
