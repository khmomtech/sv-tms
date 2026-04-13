package com.svtrucking.telematics.service;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.Optional;
import org.junit.jupiter.api.Test;

class TelemetryStreamConsumerTest {

    @Test
    void approximateLagEntriesReturnsEmptyForInvalidIds() {
        assertThat(TelemetryStreamConsumer.approximateLagEntries("bad", "1-1")).isEqualTo(Optional.empty());
    }

    @Test
    void approximateLagEntriesReturnsZeroWhenConsumerAtOrAhead() {
        assertThat(TelemetryStreamConsumer.approximateLagEntries("100-2", "100-1")).contains(0L);
    }

    @Test
    void approximateLagEntriesUsesSequenceDeltaWithinSameMillis() {
        assertThat(TelemetryStreamConsumer.approximateLagEntries("100-2", "100-7")).contains(5L);
    }

    @Test
    void approximateLagEntriesUsesMillisecondDeltaAcrossDifferentIds() {
        assertThat(TelemetryStreamConsumer.approximateLagEntries("100-9", "125-1")).contains(25L);
    }
}
