package com.svtrucking.telematics.service;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

class PresencePolicyServiceTest {

    private PresencePolicyService service;

    @BeforeEach
    void setUp() {
        service = new PresencePolicyService();
        ReflectionTestUtils.setField(service, "onlineMs", 35_000L);
        ReflectionTestUtils.setField(service, "idleMs", 180_000L);
    }

    @Test
    void resolveShouldUseConfiguredThresholds() {
        long now = System.currentTimeMillis();

        assertThat(service.resolve(now - 1_000L, now)).isEqualTo(PresencePolicyService.PresenceState.ONLINE);
        assertThat(service.resolve(now - 60_000L, now)).isEqualTo(PresencePolicyService.PresenceState.IDLE);
        assertThat(service.resolve(now - 181_000L, now)).isEqualTo(PresencePolicyService.PresenceState.OFFLINE);
    }

    @Test
    void onlineCutoffShouldDefaultToConfiguredOnlineWindow() {
        long before = System.currentTimeMillis();
        long cutoffMs = service.cutoffTimestampForSeconds(null).getTime();
        long after = System.currentTimeMillis();

        assertThat(cutoffMs).isBetween(before - 35_500L, after - 34_500L);
    }
}
