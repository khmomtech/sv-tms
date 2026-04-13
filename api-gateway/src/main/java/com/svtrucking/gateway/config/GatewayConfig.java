package com.svtrucking.gateway.config;

import java.net.http.HttpClient;
import java.time.Duration;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.client.RestClient;
import org.springframework.http.client.JdkClientHttpRequestFactory;

@Configuration
@EnableConfigurationProperties(GatewayRoutesProperties.class)
public class GatewayConfig {

    @Bean
    HttpClient gatewayHttpClient() {
        return HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(5))
                .build();
    }

    @Bean
    RestClient gatewayRestClient(HttpClient gatewayHttpClient) {
        JdkClientHttpRequestFactory requestFactory = new JdkClientHttpRequestFactory(gatewayHttpClient);
        requestFactory.setReadTimeout(Duration.ofSeconds(120));
        return RestClient.builder()
                .requestFactory(requestFactory)
                .build();
    }
}
