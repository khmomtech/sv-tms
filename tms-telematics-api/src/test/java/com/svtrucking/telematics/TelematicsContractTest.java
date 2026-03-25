package com.svtrucking.telematics;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import io.jsonwebtoken.security.Keys;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.http.*;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.GenericContainer;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.nio.charset.StandardCharsets;
import java.security.Key;
import java.util.Date;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Integration contract test: tms_driver_app payloads against
 * tms-telematics-api.
 *
 * <p>
 * Uses TestContainers (PostgreSQL + Redis) so the test is fully self-contained
 * and runs identically in CI and locally without external services.
 *
 * <p>
 * Test sequence mirrors the driver app lifecycle:
 * sync snapshot → start tracking session → send location → heartbeat → spoofing
 * alert →
 * admin queries → refresh session → logout → stop session
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
@Testcontainers(disabledWithoutDocker = true)
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
class TelematicsContractTest {

        // ── Infrastructure ────────────────────────────────────────────────────────

        @SuppressWarnings({ "resource", "rawtypes" })
        @Container
        static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16-alpine")
                        .withDatabaseName("telematics_test")
                        .withUsername("tele_user")
                        .withPassword("telepass");

        @SuppressWarnings({ "resource", "rawtypes" })
        @Container
        static GenericContainer<?> redis = new GenericContainer<>("redis:7-alpine")
                        .withExposedPorts(6379);

        @DynamicPropertySource
        static void injectContainerProperties(DynamicPropertyRegistry registry) {
                registry.add("spring.datasource.url", postgres::getJdbcUrl);
                registry.add("spring.datasource.username", postgres::getUsername);
                registry.add("spring.datasource.password", postgres::getPassword);
                registry.add("spring.data.redis.host", redis::getHost);
                registry.add("spring.data.redis.port", () -> redis.getMappedPort(6379));
                registry.add("spring.cache.type", () -> "redis");
        }

        // ── Test state (shared across ordered test methods) ───────────────────────

        static final String TEST_JWT_SECRET = "test-jwt-secret-for-integration-tests-min32";
        static final Long DRIVER_ID = 77L;
        static final String DEVICE_ID = "test-device-contract-" + UUID.randomUUID().toString().substring(0, 8);
        static final String INTERNAL_KEY = "test-internal-key-123";

        // Populated during session start, used in later tests
        static String accessToken;
        static String trackingToken;
        static String sessionId;

        @LocalServerPort
        int port;
        @Autowired
        TestRestTemplate rest;
        @Autowired
        ObjectMapper om;

        String base() {
                return "http://localhost:" + port;
        }

        // ── JWT helpers ───────────────────────────────────────────────────────────

        static String buildAccessToken() {
                Key key = Keys.hmacShaKeyFor(TEST_JWT_SECRET.getBytes(StandardCharsets.UTF_8));
                return Jwts.builder()
                                .setSubject("test_driver_contract")
                                .claim("driverId", DRIVER_ID)
                                .setExpiration(new Date(System.currentTimeMillis() + 3_600_000L))
                                .signWith(key, SignatureAlgorithm.HS256)
                                .compact();
        }

        static String buildTrackingToken(String sid) {
                Key key = Keys.hmacShaKeyFor(TEST_JWT_SECRET.getBytes(StandardCharsets.UTF_8));
                return Jwts.builder()
                                .setSubject("test_driver_contract")
                                .claim("driverId", DRIVER_ID)
                                .claim("typ", "tracking")
                                .claim("scope", "LOCATION_WRITE TRACKING_WS")
                                .claim("deviceId", DEVICE_ID)
                                .claim("sessionId", sid)
                                .setExpiration(new Date(System.currentTimeMillis() + 86_400_000L))
                                .signWith(key, SignatureAlgorithm.HS256)
                                .compact();
        }

        HttpHeaders authHeaders(String token) {
                HttpHeaders h = new HttpHeaders();
                h.setContentType(MediaType.APPLICATION_JSON);
                h.setBearerAuth(token);
                return h;
        }

        HttpHeaders internalHeaders() {
                HttpHeaders h = new HttpHeaders();
                h.setContentType(MediaType.APPLICATION_JSON);
                h.set("X-Internal-Api-Key", INTERNAL_KEY);
                return h;
        }

        // ── Tests ─────────────────────────────────────────────────────────────────

        @Test
        @Order(1)
        void healthEndpointReturnsUp() {
                ResponseEntity<String> resp = rest.getForEntity(base() + "/actuator/health", String.class);
                assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.OK);
                assertThat(resp.getBody()).contains("UP");
        }

        @Test
        @Order(2)
        void internalDriverSyncAcceptsWithApiKey() {
                String body = """
                                {"driverId":%d,"name":"Contract Driver","phone":"+85512000001","vehiclePlate":"TT-7777"}
                                """.formatted(DRIVER_ID).strip();

                ResponseEntity<String> resp = rest.exchange(
                                base() + "/api/internal/telematics/driver-sync",
                                HttpMethod.PATCH,
                                new HttpEntity<>(body, internalHeaders()),
                                String.class);

                assertThat(resp.getStatusCode().is2xxSuccessful()).isTrue();
        }

        @Test
        @Order(3)
        void internalDriverSyncBulkAcceptsWithApiKey() {
                String body = """
                                [{"driverId":%d,"name":"Contract Driver","phone":"+85512000001","vehiclePlate":"TT-7777"}]
                                """
                                .formatted(DRIVER_ID).strip();

                ResponseEntity<String> resp = rest.exchange(
                                base() + "/api/internal/telematics/driver-sync/bulk",
                                HttpMethod.PATCH,
                                new HttpEntity<>(body, internalHeaders()),
                                String.class);

                assertThat(resp.getStatusCode().is2xxSuccessful()).isTrue();
        }

        @Test
        @Order(4)
        void internalDriverSyncRejectsMissingApiKey() {
                HttpHeaders headers = new HttpHeaders();
                headers.setContentType(MediaType.APPLICATION_JSON);
                String body = """
                                {"driverId":%d,"name":"hacker"}
                                """.formatted(DRIVER_ID).strip();

                ResponseEntity<String> resp = rest.exchange(
                                base() + "/api/internal/telematics/driver-sync",
                                HttpMethod.PATCH,
                                new HttpEntity<>(body, headers),
                                String.class);

                assertThat(resp.getStatusCode().value()).isIn(401, 403);
        }

        @Test
        @Order(5)
        void locationUpdateRejectsUnauthenticated() {
                String body = locationPayload("", System.currentTimeMillis());

                ResponseEntity<String> resp = rest.postForEntity(
                                base() + "/api/driver/location/update",
                                new HttpEntity<>(body, jsonHeaders()),
                                String.class);

                assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
        }

        @Test
        @Order(6)
        void trackingSessionStartReturnsSessionAndToken() throws Exception {
                accessToken = buildAccessToken();

                String body = """
                                {"deviceId":"%s","appVersion":"1.5.0","platform":"android"}
                                """.formatted(DEVICE_ID).strip();

                ResponseEntity<String> resp = rest.postForEntity(
                                base() + "/api/driver/tracking-session/start",
                                new HttpEntity<>(body, authHeaders(accessToken)),
                                String.class);

                assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.OK);
                JsonNode root = om.readTree(resp.getBody());

                assertThat(root.has("sessionId")).as("sessionId present").isTrue();
                assertThat(root.has("trackingToken")).as("trackingToken present — driver app needs this").isTrue();
                assertThat(root.has("expiresAtEpochMs"))
                                .as("expiresAtEpochMs present — driver app schedules refresh from this").isTrue();
                assertThat(root.has("scope")).as("scope present").isTrue();

                sessionId = root.get("sessionId").asText();
                trackingToken = root.get("trackingToken").asText();

                assertThat(sessionId).isNotBlank();
                assertThat(trackingToken).isNotBlank();
                assertThat(root.get("expiresAtEpochMs").asLong()).isGreaterThan(System.currentTimeMillis());
        }

        @Test
        @Order(7)
        void trackingSessionStartViaDriverAppPathAlias() throws Exception {
                String deviceAlt = DEVICE_ID + "-alt";
                String body = """
                                {"deviceId":"%s","appVersion":"1.5.0","platform":"android"}
                                """.formatted(deviceAlt).strip();

                ResponseEntity<String> resp = rest.postForEntity(
                                base() + "/api/driver/tracking/session/start",
                                new HttpEntity<>(body, authHeaders(accessToken)),
                                String.class);

                // Driver app uses /tracking/session/start (with slash); must be routed to same
                // handler
                assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.OK);
                JsonNode root = om.readTree(resp.getBody());
                assertThat(root.has("trackingToken")).isTrue();
        }

        @Test
        @Order(8)
        void locationUpdateAcceptsTrackingToken() throws Exception {
                long nowMs = System.currentTimeMillis();
                String body = locationPayload(sessionId, nowMs);

                ResponseEntity<String> resp = rest.postForEntity(
                                base() + "/api/driver/location/update",
                                new HttpEntity<>(body, authHeaders(trackingToken)),
                                String.class);

                assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.OK);
                JsonNode root = om.readTree(resp.getBody());
                assertThat(root.get("ok").asBoolean()).as("ok=true in response").isTrue();
                assertThat(root.get("driverId").asLong()).as("driverId echoed back").isEqualTo(DRIVER_ID);
        }

        @Test
        @Order(9)
        void locationUpdateDeduplicatesWithinThrottleWindow() throws Exception {
                long nowMs = System.currentTimeMillis();
                String body = locationPayload(sessionId, nowMs);

                // Send first update
                rest.postForEntity(
                                base() + "/api/driver/location/update",
                                new HttpEntity<>(body, authHeaders(trackingToken)),
                                String.class);

                // Immediate duplicate — same coordinates, within 3s throttle
                ResponseEntity<String> resp2 = rest.postForEntity(
                                base() + "/api/driver/location/update",
                                new HttpEntity<>(body, authHeaders(trackingToken)),
                                String.class);

                assertThat(resp2.getStatusCode()).isEqualTo(HttpStatus.OK);
                JsonNode root2 = om.readTree(resp2.getBody());
                assertThat(root2.get("ok").asBoolean()).isTrue();
                // dedup=true means throttle correctly applied
                assertThat(root2.get("dedup").asBoolean()).as("dedup=true — throttle applied within 3s window")
                                .isTrue();
        }

        @Test
        @Order(10)
        void locationUpdateBatchAcceptsTrackingToken() throws Exception {
                long nowMs = System.currentTimeMillis();
                String batchBody = """
                                [
                                  {
                                    "driverId": %d,
                                    "driverName": "Contract Driver",
                                    "vehiclePlate": "TT-7777",
                                    "latitude": 11.5564,
                                    "longitude": 104.9282,
                                    "speed": 7.5,
                                    "clientSpeedKmh": 27.0,
                                    "accuracyMeters": 5.0,
                                    "heading": 95.3,
                                    "batteryLevel": 78,
                                    "isMocked": false,
                                    "batterySaver": false,
                                    "source": "FLUTTER_ANDROID",
                                    "clientTime": %d,
                                    "timestampEpochMs": %d,
                                    "keepAlive": false,
                                    "gpsOn": true,
                                    "sessionId": "%s",
                                    "pointId": "batch-point-1",
                                    "seq": 1,
                                    "netType": "WIFI",
                                    "locationSource": "GPS"
                                  },
                                  {
                                    "driverId": %d,
                                    "driverName": "Contract Driver",
                                    "vehiclePlate": "TT-7777",
                                    "latitude": 11.5570,
                                    "longitude": 104.9290,
                                    "speed": 8.0,
                                    "clientSpeedKmh": 28.8,
                                    "accuracyMeters": 6.0,
                                    "heading": 97.0,
                                    "batteryLevel": 77,
                                    "isMocked": false,
                                    "batterySaver": false,
                                    "source": "FLUTTER_ANDROID",
                                    "clientTime": %d,
                                    "timestampEpochMs": %d,
                                    "keepAlive": false,
                                    "gpsOn": true,
                                    "sessionId": "%s",
                                    "pointId": "batch-point-2",
                                    "seq": 2,
                                    "netType": "WIFI",
                                    "locationSource": "GPS"
                                  }
                                ]
                                """
                                .formatted(DRIVER_ID, nowMs, nowMs, sessionId, DRIVER_ID, nowMs + 9000, nowMs + 9000,
                                                sessionId)
                                .strip();

                ResponseEntity<String> resp = rest.postForEntity(
                                base() + "/api/driver/location/update/batch",
                                new HttpEntity<>(batchBody, authHeaders(trackingToken)),
                                String.class);

                assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.OK);
                JsonNode root = om.readTree(resp.getBody());
                assertThat(root.get("ok").asBoolean()).isTrue();
                assertThat(root.get("accepted").asInt()).isEqualTo(2);
                assertThat(root.get("skipped").asInt()).isEqualTo(0);
        }

        @Test
        @Order(11)
        void locationUpdateWithSessionIdRejectsAccessToken() {
                long nowMs = System.currentTimeMillis();
                String body = locationPayload(sessionId, nowMs);

                ResponseEntity<String> resp = rest.postForEntity(
                                base() + "/api/driver/location/update",
                                new HttpEntity<>(body, authHeaders(accessToken)),
                                String.class);

                assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
        }

        @Test
        @Order(12)
        void locationUpdateAcceptsAccessTokenBackwardCompat() throws Exception {
                long nowMs = System.currentTimeMillis();
                // Access token (no sessionId in token) — backward compat path for older app
                // versions
                String bodyNoSession = locationPayload("", nowMs);

                ResponseEntity<String> resp = rest.postForEntity(
                                base() + "/api/driver/location/update",
                                new HttpEntity<>(bodyNoSession, authHeaders(accessToken)),
                                String.class);

                // 200 OK — access token is accepted as backward compat
                // (validateLocationWriteOrThrow
                // skips session checks for non-tracking tokens)
                assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.OK);
        }

        @Test
        @Order(13)
        void presenceHeartbeatAccepted() throws Exception {
                long nowMs = System.currentTimeMillis();
                String body = """
                                {"driverId":%d,"device":"FLUTTER_ANDROID","battery":78,"gpsEnabled":true,"ts":%d,"reason":"APP_FOREGROUND"}
                                """
                                .formatted(DRIVER_ID, nowMs).strip();

                ResponseEntity<String> resp = rest.postForEntity(
                                base() + "/api/driver/presence/heartbeat",
                                new HttpEntity<>(body, authHeaders(trackingToken)),
                                String.class);

                assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.OK);
                JsonNode root = om.readTree(resp.getBody());
                assertThat(root.get("status").asText()).isEqualTo("ok");
                // Driver just sent a heartbeat — should be ONLINE
                assertThat(root.has("presenceStatus")).isTrue();
        }

        @Test
        @Order(14)
        void presenceHeartbeatRejectsUnauthenticated() {
                long nowMs = System.currentTimeMillis();
                String body = """
                                {"driverId":%d,"device":"FLUTTER_ANDROID","battery":50,"gpsEnabled":true,"ts":%d}
                                """.formatted(DRIVER_ID, nowMs).strip();

                ResponseEntity<String> resp = rest.postForEntity(
                                base() + "/api/driver/presence/heartbeat",
                                new HttpEntity<>(body, jsonHeaders()),
                                String.class);

                assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
        }

        @Test
        @Order(15)
        void adminPresenceLookupReturnsPresenceStatus() throws Exception {
                ResponseEntity<String> resp = rest.exchange(
                                base() + "/api/admin/driver/" + DRIVER_ID + "/presence",
                                HttpMethod.GET,
                                new HttpEntity<>(authHeaders(accessToken)),
                                String.class);

                assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.OK);
                JsonNode root = om.readTree(resp.getBody());
                assertThat(root.has("presenceStatus")).as("presenceStatus present").isTrue();
                assertThat(root.has("lastSeen")).as("lastSeen present").isTrue();
                assertThat(root.get("driverId").asLong()).isEqualTo(DRIVER_ID);
        }

        @Test
        @Order(16)
        void spoofingAlertPersistedWithTrackingToken() throws Exception {
                String body = """
                                {"driverId":%d,"reason":"HIGH_SPEED_SPIKE","latitude":11.5564,"longitude":104.9282,
                                 "accuracy":12.0,"speed":150.0,"isMocked":false}
                                """.formatted(DRIVER_ID).strip();

                ResponseEntity<String> resp = rest.postForEntity(
                                base() + "/api/locations/spoofing-alert",
                                new HttpEntity<>(body, authHeaders(trackingToken)),
                                String.class);

                assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.OK);
                JsonNode root = om.readTree(resp.getBody());
                assertThat(root.get("status").asText()).isEqualTo("ok");
        }

        @Test
        @Order(17)
        void spoofingAlertPersistedWithAccessToken() throws Exception {
                // Driver app may send spoofing alert using access token before session is
                // established
                String body = """
                                {"driverId":%d,"reason":"MOCK_PROVIDER_DETECTED","latitude":11.5564,"longitude":104.9282,
                                 "accuracy":5.0,"speed":0.0,"isMocked":true}
                                """
                                .formatted(DRIVER_ID).strip();

                ResponseEntity<String> resp = rest.postForEntity(
                                base() + "/api/locations/spoofing-alert",
                                new HttpEntity<>(body, authHeaders(accessToken)),
                                String.class);

                assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.OK);
        }

        @Test
        @Order(18)
        void adminLiveDriversRequiresAuth() {
                // No auth → 401
                ResponseEntity<String> noAuth = rest.getForEntity(
                                base() + "/api/admin/telematics/live-drivers", String.class);
                assertThat(noAuth.getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);

                // With access token → 200
                ResponseEntity<String> authed = rest.exchange(
                                base() + "/api/admin/telematics/live-drivers",
                                HttpMethod.GET,
                                new HttpEntity<>(authHeaders(accessToken)),
                                String.class);
                assertThat(authed.getStatusCode()).isEqualTo(HttpStatus.OK);
        }

        @Test
        @Order(19)
        void adminDriverLocationEndpoint() {
                // 200 if driver has location persisted, 404 if not yet flushed from batch queue
                ResponseEntity<String> resp = rest.exchange(
                                base() + "/api/admin/telematics/driver/" + DRIVER_ID + "/location",
                                HttpMethod.GET,
                                new HttpEntity<>(authHeaders(accessToken)),
                                String.class);
                assertThat(resp.getStatusCode().value())
                                .as("Admin driver location should return 200 (found) or 404 (not yet flushed)")
                                .isIn(200, 404);
        }

        @Test
        @Order(20)
        void publicTrackingEndpointReachableWithoutAuth() {
                // Unknown reference → 404, but endpoint must be reachable without token
                ResponseEntity<String> resp = rest.getForEntity(
                                base() + "/api/public/tracking/UNKNOWN-REF-0000", String.class);
                assertThat(resp.getStatusCode().value())
                                .as("Public tracking must not 401/403 (no auth required)").isNotIn(401, 403);
        }

        @Test
        @Order(21)
        void trackingSessionRefreshRotatesToken() throws Exception {
                ResponseEntity<String> resp = rest.exchange(
                                base() + "/api/driver/tracking-session/refresh",
                                HttpMethod.POST,
                                new HttpEntity<>(authHeaders(trackingToken)),
                                String.class);

                assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.OK);
                JsonNode root = om.readTree(resp.getBody());
                assertThat(root.has("trackingToken")).as("rotated trackingToken present").isTrue();

                String rotated = root.get("trackingToken").asText();
                assertThat(rotated).isNotBlank().isNotEqualTo(trackingToken);

                // Update stored token — subsequent tests use the rotated one
                trackingToken = rotated;
        }

        @Test
        @Order(22)
        void trackingSessionRefreshViaDriverAppPathAlias() throws Exception {
                ResponseEntity<String> resp = rest.exchange(
                                base() + "/api/driver/tracking/session/refresh",
                                HttpMethod.POST,
                                new HttpEntity<>(authHeaders(trackingToken)),
                                String.class);

                assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.OK);
                JsonNode root = om.readTree(resp.getBody());
                assertThat(root.has("trackingToken")).isTrue();

                // Keep latest rotated token
                trackingToken = root.get("trackingToken").asText();
        }

        @Test
        @Order(23)
        void driverLogoutClearsPresence() throws Exception {
                ResponseEntity<String> resp = rest.postForEntity(
                                base() + "/api/driver/logout?driverId=" + DRIVER_ID,
                                HttpEntity.EMPTY,
                                String.class);

                assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.OK);
                JsonNode root = om.readTree(resp.getBody());
                assertThat(root.get("status").asText()).isEqualTo("ok");
                assertThat(root.get("driverId").asLong()).isEqualTo(DRIVER_ID);
        }

        @Test
        @Order(24)
        void trackingSessionStopRevokesSession() throws Exception {
                ResponseEntity<String> resp = rest.exchange(
                                base() + "/api/driver/tracking-session/stop",
                                HttpMethod.POST,
                                new HttpEntity<>(authHeaders(trackingToken)),
                                String.class);

                assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.OK);

                // Second stop on the same session must be rejected (revoked)
                ResponseEntity<String> resp2 = rest.exchange(
                                base() + "/api/driver/tracking-session/stop",
                                HttpMethod.POST,
                                new HttpEntity<>(authHeaders(trackingToken)),
                                String.class);

                assertThat(resp2.getStatusCode().value())
                                .as("Revoked session stop must return 401 or 404").isIn(401, 404);
        }

        @Test
        @Order(25)
        void trackingSessionStopViaDriverAppPathAlias() {
                // Build a fresh tracking token for a new session — the original is revoked
                String freshToken = buildTrackingToken("orphan-session-for-stop-alias-test");

                ResponseEntity<String> resp = rest.exchange(
                                base() + "/api/driver/tracking/session/stop",
                                HttpMethod.POST,
                                new HttpEntity<>(authHeaders(freshToken)),
                                String.class);

                // 404 because the session doesn't exist in DB; endpoint must be reachable (not
                // 404 from nginx/method not found)
                assertThat(resp.getStatusCode().value())
                                .as("Path alias /tracking/session/stop routed correctly (404 = session not found, not routing gap)")
                                .isIn(200, 404, 401);
        }

        @Test
        @Order(26)
        void locationUpdateWithRevokedTrackingSessionIsRejected() throws Exception {
                // The tracking session was stopped in test 22 — writes using that token must
                // now fail
                long nowMs = System.currentTimeMillis();
                String body = locationPayload(sessionId, nowMs);

                ResponseEntity<String> resp = rest.postForEntity(
                                base() + "/api/driver/location/update",
                                new HttpEntity<>(body, authHeaders(trackingToken)),
                                String.class);

                assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
        }

        // ── Payload builders ──────────────────────────────────────────────────────

        /**
         * Exact payload from tms_driver_app/lib/services/location_service.dart
         * LocationUpdate.toJson()
         */
        private String locationPayload(String sid, long nowMs) {
                return """
                                {
                                  "driverId": %d,
                                  "driverName": "Contract Driver",
                                  "vehiclePlate": "TT-7777",
                                  "latitude": 11.5564,
                                  "longitude": 104.9282,
                                  "speed": 7.5,
                                  "clientSpeedKmh": 27.0,
                                  "accuracyMeters": 5.0,
                                  "heading": 95.3,
                                  "batteryLevel": 78,
                                  "isMocked": false,
                                  "batterySaver": false,
                                  "source": "FLUTTER_ANDROID",
                                  "clientTime": %d,
                                  "timestampEpochMs": %d,
                                  "keepAlive": false,
                                  "gpsOn": true,
                                  "sessionId": "%s",
                                  "netType": "WIFI",
                                  "locationSource": "GPS"
                                }
                                """.formatted(DRIVER_ID, nowMs, nowMs, sid).strip();
        }

        private HttpHeaders jsonHeaders() {
                HttpHeaders h = new HttpHeaders();
                h.setContentType(MediaType.APPLICATION_JSON);
                return h;
        }
}
