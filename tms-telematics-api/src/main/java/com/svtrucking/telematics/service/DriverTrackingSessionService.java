package com.svtrucking.telematics.service;

import com.svtrucking.telematics.dto.requests.TrackingSessionStartRequest;
import com.svtrucking.telematics.dto.responses.TrackingSessionResponse;
import com.svtrucking.telematics.model.DriverTrackingSession;
import com.svtrucking.telematics.repository.DriverTrackingSessionRepository;
import com.svtrucking.telematics.security.TelematicsJwtUtil;
import io.jsonwebtoken.Claims;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.List;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

/**
 * Driver tracking session manager for tms-telematics-api.
 * Adapted from tms-backend: UserRepository + DriverRepository removed.
 * The caller supplies driverId already resolved from a valid JWT claim.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class DriverTrackingSessionService {

    private final DriverTrackingSessionRepository trackingSessionRepository;
    private final TelematicsJwtUtil jwtUtil;

    @Transactional
    public TrackingSessionResponse startSession(
            Long driverId, String username, TrackingSessionStartRequest req) {

        if (driverId == null) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED,
                    "driverId not found in token — cannot start tracking session");
        }

        String deviceId = req.getDeviceId().trim();
        List<DriverTrackingSession> actives = trackingSessionRepository
                .findByDriverIdAndDeviceIdAndRevokedAtIsNullOrderByIssuedAtDesc(
                        driverId, deviceId);
        LocalDateTime now = LocalDateTime.now();
        if (!actives.isEmpty()) {
            for (DriverTrackingSession s : actives) {
                s.setRevokedAt(now);
            }
            trackingSessionRepository.saveAll(actives);
        }

        String sessionId = UUID.randomUUID().toString();
        long ttlMs = jwtUtil.getTrackingTtlMs();
        DriverTrackingSession session = DriverTrackingSession.builder()
                .sessionId(sessionId)
                .driverId(driverId)
                .deviceId(deviceId)
                .issuedAt(now)
                .expiresAt(now.plusSeconds(Math.max(1L, ttlMs / 1000L)))
                .lastSeen(now)
                .build();
        trackingSessionRepository.save(session);

        String token = jwtUtil.generateTrackingToken(username, driverId, deviceId, sessionId);

        return TrackingSessionResponse.builder()
                .sessionId(sessionId)
                .trackingToken(token)
                .scope("LOCATION_WRITE TRACKING_WS")
                .expiresAtEpochMs(session.getExpiresAt().toInstant(ZoneOffset.UTC).toEpochMilli())
                .build();
    }

    @Transactional
    public TrackingSessionResponse refreshSession(String trackingToken) {
        if (trackingToken == null || trackingToken.isBlank()) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Tracking token missing");
        }
        if (!"tracking".equalsIgnoreCase(jwtUtil.extractTokenType(trackingToken))) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Not a tracking token");
        }

        Claims claims = jwtUtil.extractAllClaims(trackingToken);
        String sessionId = jwtUtil.extractSessionId(trackingToken);
        Long driverId = jwtUtil.extractDriverId(trackingToken);
        String deviceId = jwtUtil.extractDeviceId(trackingToken);
        if (sessionId == null || driverId == null || deviceId == null) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid tracking token claims");
        }

        DriverTrackingSession session = trackingSessionRepository
                .findBySessionIdAndRevokedAtIsNull(sessionId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.UNAUTHORIZED, "Tracking session not active"));

        LocalDateTime now = LocalDateTime.now();
        if (session.getExpiresAt() != null && session.getExpiresAt().isBefore(now)) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Tracking session expired");
        }
        if (!session.getDriverId().equals(driverId) || !session.getDeviceId().equals(deviceId)) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Tracking session mismatch");
        }

        long ttlMs = jwtUtil.getTrackingTtlMs();
        session.setLastSeen(now);
        session.setExpiresAt(now.plusSeconds(Math.max(1L, ttlMs / 1000L)));
        trackingSessionRepository.save(session);

        String rotated = jwtUtil.generateTrackingToken(
                claims.getSubject(), session.getDriverId(), session.getDeviceId(), session.getSessionId());

        return TrackingSessionResponse.builder()
                .sessionId(session.getSessionId())
                .trackingToken(rotated)
                .scope("LOCATION_WRITE TRACKING_WS")
                .expiresAtEpochMs(session.getExpiresAt().toInstant(ZoneOffset.UTC).toEpochMilli())
                .build();
    }

    @Transactional
    public void stopSession(String trackingToken) {
        String sessionId = jwtUtil.extractSessionId(trackingToken);
        if (sessionId == null || sessionId.isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "sessionId missing from token");
        }
        DriverTrackingSession session = trackingSessionRepository
                .findBySessionIdAndRevokedAtIsNull(sessionId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Session not found"));
        session.setRevokedAt(LocalDateTime.now());
        trackingSessionRepository.save(session);
    }

    @Transactional
    public void validateLocationWriteOrThrow(
            String bearerToken, Long payloadDriverId, String payloadSessionId) {
        if (bearerToken == null || bearerToken.isBlank()) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Authorization token missing");
        }
        String typ = jwtUtil.extractTokenType(bearerToken);
        if (!"tracking".equalsIgnoreCase(typ)) {
            if (payloadSessionId != null && !payloadSessionId.isBlank()) {
                throw new ResponseStatusException(
                        HttpStatus.UNAUTHORIZED,
                        "Tracking token required for session-backed location writes");
            }
            return;
        }

        if (!jwtUtil.hasScope(bearerToken, "LOCATION_WRITE")) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN,
                    "Tracking scope LOCATION_WRITE required");
        }
        Long tokenDriverId = jwtUtil.extractDriverId(bearerToken);
        String tokenSessionId = jwtUtil.extractSessionId(bearerToken);
        if (tokenDriverId == null || tokenSessionId == null) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Tracking token missing claims");
        }
        if (payloadDriverId == null || !payloadDriverId.equals(tokenDriverId)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "driverId mismatch");
        }
        if (payloadSessionId != null && !payloadSessionId.isBlank()
                && !payloadSessionId.equals(tokenSessionId)) {
            log.warn(
                    "Ignoring stale payload sessionId for driver {}: payloadSessionId={}, tokenSessionId={}",
                    tokenDriverId,
                    payloadSessionId,
                    tokenSessionId);
        }

        DriverTrackingSession session = trackingSessionRepository
                .findBySessionIdAndRevokedAtIsNull(tokenSessionId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.FORBIDDEN, "Tracking session not active"));
        LocalDateTime now = LocalDateTime.now();
        if (session.getExpiresAt() != null && session.getExpiresAt().isBefore(now)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Tracking session expired");
        }
        if (!session.getDriverId().equals(tokenDriverId)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "session driver mismatch");
        }
        session.setLastSeen(now);
        session.setExpiresAt(now.plusSeconds(Math.max(1L, jwtUtil.getTrackingTtlMs() / 1000L)));
        trackingSessionRepository.save(session);
    }

    public static String extractBearerToken(String authHeader) {
        if (authHeader == null || authHeader.isBlank()) {
            return null;
        }
        String t = authHeader.trim();
        if (t.regionMatches(true, 0, "Bearer ", 0, 7)) {
            t = t.substring(7).trim();
        }
        return t.isEmpty() ? null : t;
    }
}
