package com.svtrucking.logistics.config;

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
    Duration timeout = Duration.ofMillis(Math.max(1, connectTimeoutMs));
    return HttpClient.newBuilder()
        .connectTimeout(timeout)
        .version(HttpClient.Version.HTTP_2)
        .build();
  }
}
