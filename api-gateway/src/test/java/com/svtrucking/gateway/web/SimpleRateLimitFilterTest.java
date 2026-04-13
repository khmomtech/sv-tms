package com.svtrucking.gateway.web;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;

class SimpleRateLimitFilterTest {

    private final SimpleRateLimitFilter filter = new SimpleRateLimitFilter(600);

    @Test
    void usesForwardedIpWhenNoAuthorizationHeaderExists() {
        MockHttpServletRequest request = new MockHttpServletRequest();
        request.setRemoteAddr("172.22.0.5");
        request.addHeader("X-Forwarded-For", "103.68.45.149, 172.22.0.5");

        String key = filter.buildKey(request, 12345L);

        assertThat(key).isEqualTo("ip:103.68.45.149:12345");
    }

    @Test
    void usesBearerTokenFingerprintToAvoidNatCollisions() {
        MockHttpServletRequest request = new MockHttpServletRequest();
        request.setRemoteAddr("172.22.0.5");
        request.addHeader("X-Forwarded-For", "103.68.45.149");
        request.addHeader("Authorization", "Bearer driver-token-value");

        String key = filter.buildKey(request, 77L);

        assertThat(key)
                .startsWith("token:")
                .endsWith(":77")
                .doesNotContain("driver-token-value")
                .isNotEqualTo("ip:103.68.45.149:77");
    }
}
