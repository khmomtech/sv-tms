package com.svtrucking.telematics.config;

import java.net.http.HttpClient;
import java.time.Duration;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class GeocodingHttpClientConfig {

    @Bean
    public HttpClient geocodingHttpClient(
            @Value("${geocode.http.connect-timeout-ms:5000}") long connectTimeoutMs) {
        return HttpClient.newBuilder()
                .connectTimeout(Duration.ofMillis(connectTimeoutMs))
                .build();
    }
}
