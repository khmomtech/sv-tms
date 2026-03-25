package com.svtrucking.logistics.service;

import java.util.Map;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

/**
 * Forwards driver telemetry requests to tms-telematics-api when
 * TELEMATICS_SERVICE_URL is configured. Used for zero-downtime migration:
 * mobile apps continue sending to tms-backend which proxies transparently.
 *
 * <p>
 * When TELEMATICS_SERVICE_URL is blank, callers fall through to the
 * existing tms-backend logic (no change in behaviour).
 */
@Service
@Slf4j
public class TelematicsProxyService {

    private final String telematicsServiceUrl;
    private final String internalApiKey;
    private final boolean compatibilityProxyEnabled;
    private final RestClient restClient;

    public TelematicsProxyService(
            @Value("${telematics.service.url:}") String telematicsServiceUrl,
            @Value("${telematics.internal.api-key:}") String internalApiKey,
            @Value("${telematics.compatibility-proxy.enabled:false}") boolean compatibilityProxyEnabled,
            @Value("${telematics.proxy.connect-timeout-ms:1000}") int connectTimeoutMs,
            @Value("${telematics.proxy.read-timeout-ms:3000}") int readTimeoutMs) {
        this.telematicsServiceUrl = telematicsServiceUrl != null ? telematicsServiceUrl.trim() : "";
        this.internalApiKey = internalApiKey != null ? internalApiKey.trim() : "";
        this.compatibilityProxyEnabled = compatibilityProxyEnabled;
        if (!this.telematicsServiceUrl.isBlank() && this.compatibilityProxyEnabled) {
            SimpleClientHttpRequestFactory requestFactory = new SimpleClientHttpRequestFactory();
            requestFactory.setConnectTimeout(connectTimeoutMs);
            requestFactory.setReadTimeout(readTimeoutMs);
            this.restClient = RestClient.builder()
                    .baseUrl(this.telematicsServiceUrl)
                    .requestFactory(requestFactory)
                    .build();
            log.info(
                    "TelematicsProxyService: compatibility proxy enabled → {} (connect={}ms read={}ms)",
                    this.telematicsServiceUrl,
                    connectTimeoutMs,
                    readTimeoutMs);
        } else {
            this.restClient = null;
            log.info("TelematicsProxyService: compatibility proxy disabled");
        }
    }

    /**
     * @return true when TELEMATICS_SERVICE_URL is configured and forwarding is
     *         active
     */
    public boolean isForwardingEnabled() {
        return compatibilityProxyEnabled && !telematicsServiceUrl.isBlank();
    }

    /**
     * Forward a JSON body to a telematics-service POST endpoint.
     *
     * @param path          e.g. "/api/driver/location/update"
     * @param authorization value of the Authorization header (may be null)
     * @param body          request body object (will be serialised to JSON)
     * @return proxied response as a {@link ResponseEntity}
     */
    public ResponseEntity<Map> forward(String path, String authorization, Object body) {
        if (restClient == null) {
            throw new IllegalStateException("Forwarding is disabled (TELEMATICS_SERVICE_URL not configured)");
        }
        try {
            RestClient.RequestBodySpec req = restClient
                    .post()
                    .uri(path)
                    .contentType(org.springframework.http.MediaType.APPLICATION_JSON);
            if (authorization != null && !authorization.isBlank()) {
                req = req.header("Authorization", authorization);
            }
            ResponseEntity<Map> resp = req
                    .body(body)
                    .retrieve()
                    .toEntity(Map.class);
            return resp;
        } catch (RestClientException e) {
            log.error("Telematics proxy error [path={}]: {}", path, e.getMessage());
            throw e;
        }
    }

    public ResponseEntity<Map> forwardGet(String path, String authorization) {
        if (restClient == null) {
            throw new IllegalStateException("Forwarding is disabled (TELEMATICS_SERVICE_URL not configured)");
        }
        try {
            var req = restClient.get().uri(path);
            if (authorization != null && !authorization.isBlank()) {
                req = req.header("Authorization", authorization);
            }
            return req.retrieve().toEntity(Map.class);
        } catch (RestClientException e) {
            log.error("Telematics proxy GET error [path={}]: {}", path, e.getMessage());
            throw e;
        }
    }

    public ResponseEntity<Object> forwardGetObject(String path, String authorization) {
        if (restClient == null) {
            throw new IllegalStateException("Forwarding is disabled (TELEMATICS_SERVICE_URL not configured)");
        }
        try {
            var req = restClient.get().uri(path);
            if (authorization != null && !authorization.isBlank()) {
                req = req.header("Authorization", authorization);
            }
            return req.retrieve().toEntity(Object.class);
        } catch (RestClientException e) {
            log.error("Telematics proxy GET error [path={}]: {}", path, e.getMessage());
            throw e;
        }
    }

    /**
     * Fire-and-forget driver snapshot sync to telematics service.
     * Sends driver name/phone/plate so telematics can resolve display names
     * without querying tms-backend per-request.
     *
     * <p>Failures are logged and swallowed — telematics degrading does not
     * block the tms-backend session flow.
     */
    public void syncDriverAsync(Long driverId, String name, String phone, String vehiclePlate) {
        if (restClient == null || driverId == null) {
            return;
        }
        try {
            Map<String, Object> body = new java.util.LinkedHashMap<>();
            body.put("driverId", driverId);
            body.put("name", name);
            body.put("phone", phone);
            body.put("vehiclePlate", vehiclePlate);

            var req = restClient.patch()
                    .uri("/api/internal/telematics/driver-sync")
                    .contentType(org.springframework.http.MediaType.APPLICATION_JSON);
            if (!internalApiKey.isBlank()) {
                req = req.header("X-Internal-Api-Key", internalApiKey);
            }
            req.body(body).retrieve().toBodilessEntity();
            log.debug("Driver snapshot synced to telematics: driverId={}", driverId);
        } catch (Exception e) {
            log.warn("Driver sync to telematics failed (non-fatal): driverId={}, error={}", driverId, e.getMessage());
        }
    }
}
