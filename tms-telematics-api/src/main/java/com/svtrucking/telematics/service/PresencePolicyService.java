package com.svtrucking.telematics.service;

import java.sql.Timestamp;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

@Service
public class PresencePolicyService {

    public enum PresenceState {
        ONLINE,
        IDLE,
        OFFLINE
    }

    @Value("${presence.online_ms:35000}")
    private long onlineMs;

    @Value("${presence.idle_ms:180000}")
    private long idleMs;

    public PresenceState resolve(Long lastSeenEpochMs) {
        return resolve(lastSeenEpochMs, System.currentTimeMillis());
    }

    public PresenceState resolve(Long lastSeenEpochMs, long nowMs) {
        long age = (lastSeenEpochMs == null) ? Long.MAX_VALUE : Math.max(0L, nowMs - lastSeenEpochMs);
        if (age <= onlineMs) {
            return PresenceState.ONLINE;
        }
        if (age <= idleMs) {
            return PresenceState.IDLE;
        }
        return PresenceState.OFFLINE;
    }

    public boolean isOnline(Long lastSeenEpochMs) {
        return resolve(lastSeenEpochMs) == PresenceState.ONLINE;
    }

    public Timestamp onlineCutoffTimestamp() {
        return Timestamp.from(Instant.now().minus(onlineMs, ChronoUnit.MILLIS));
    }

    public Timestamp cutoffTimestampForSeconds(Integer seconds) {
        if (seconds != null && seconds > 0) {
            return Timestamp.from(Instant.now().minus(seconds, ChronoUnit.SECONDS));
        }
        return onlineCutoffTimestamp();
    }

    public Timestamp offlineCutoffTimestamp() {
        return Timestamp.from(Instant.now().minus(idleMs, ChronoUnit.MILLIS));
    }
}
