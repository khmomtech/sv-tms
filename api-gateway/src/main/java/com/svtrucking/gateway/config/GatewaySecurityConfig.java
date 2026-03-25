package com.svtrucking.gateway.config;

import com.svtrucking.gateway.web.AuthHeaderValidationFilter;
import com.svtrucking.gateway.web.RequestIdFilter;
import com.svtrucking.gateway.web.SimpleRateLimitFilter;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

@Configuration
public class GatewaySecurityConfig {

    @Bean
    SecurityFilterChain filterChain(
            HttpSecurity http,
            RequestIdFilter requestIdFilter,
            AuthHeaderValidationFilter authHeaderValidationFilter,
            SimpleRateLimitFilter simpleRateLimitFilter) throws Exception {
        http.csrf(AbstractHttpConfigurer::disable)
                .cors(Customizer.withDefaults())
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers("/actuator/health", "/actuator/info").permitAll()
                        .requestMatchers("/api/public/**").permitAll()
                .requestMatchers("/ws/**").permitAll()
                .anyRequest().permitAll())
                .addFilterBefore(requestIdFilter, UsernamePasswordAuthenticationFilter.class)
                .addFilterAfter(simpleRateLimitFilter, RequestIdFilter.class)
                .addFilterAfter(authHeaderValidationFilter, RequestIdFilter.class);
        return http.build();
    }
}
