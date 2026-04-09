package com.svtrucking.telematics.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.client.RestClient;

/**
 * HTTP client for tms-backend internal endpoints.
 * Adds X-Internal-Api-Key header automatically on each request.
 */
@Configuration
public class MainBackendHttpClientConfig {

    @Value("${main.backend.url:http://localhost:8080}")
    private String mainBackendUrl;

    @Value("${telematics.internal.api-key:}")
    private String internalApiKey;

    @Bean("mainBackendRestClient")
    public RestClient mainBackendRestClient() {
        return RestClient.builder()
                .baseUrl(mainBackendUrl)
                .defaultHeader("X-Internal-Api-Key", internalApiKey)
                .defaultHeader("Accept", "application/json")
                .build();
    }
}
