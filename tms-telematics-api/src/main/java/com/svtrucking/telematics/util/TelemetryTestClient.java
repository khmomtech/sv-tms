package com.svtrucking.telematics.util;

import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import io.jsonwebtoken.security.Keys;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.security.Key;
import java.time.Instant;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;

/**
 * Simple standalone test client that generates a tracking JWT and sends a sample
 * location update to the telematics service.
 *
 * Run with:
 * mvn -pl tms-telematics-api exec:java -Dexec.mainClass=com.svtrucking.telematics.util.TelemetryTestClient
 */
public class TelemetryTestClient {

    public static void main(String[] args) throws Exception {
        long driverId = 1;
        double lat = 11.5564;
        double lng = 104.9282;
        String secret = System.getenv().getOrDefault("JWT_ACCESS_SECRET", "changeme-dev-secret-32-chars-min!!!");
        Key key = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));

        // Access token (ROLE_API_USER) used to start a tracking session
        String accessToken = Jwts.builder()
                .setSubject("driver-" + driverId)
                .claim("typ", "access")
                .claim("scope", "API_USER")
                .claim("driverId", driverId)
                .claim("deviceId", "fake-device-1")
                .setIssuedAt(new Date())
                .setExpiration(Date.from(Instant.now().plusSeconds(3600)))
                .signWith(key, SignatureAlgorithm.HS256)
                .compact();

        String baseUrl = System.getenv().getOrDefault("TELEMATICS_URL", "http://localhost:8082");

        // Start a tracking session
        Map<String, Object> startReq = new HashMap<>();
        startReq.put("deviceId", "fake-device-1");
        String startJson = new com.fasterxml.jackson.databind.ObjectMapper().writeValueAsString(startReq);

        HttpRequest startRequest = HttpRequest.newBuilder()
                .uri(URI.create(baseUrl + "/api/driver/tracking-session/start"))
                .header("Content-Type", "application/json")
                .header("Authorization", "Bearer " + accessToken)
                .POST(HttpRequest.BodyPublishers.ofString(startJson))
                .build();

        HttpClient client = HttpClient.newHttpClient();
        HttpResponse<String> startResp = client.send(startRequest, HttpResponse.BodyHandlers.ofString());
        System.out.println("tracking start status=" + startResp.statusCode());
        System.out.println(startResp.body());

        Map<String, Object> startBody = new com.fasterxml.jackson.databind.ObjectMapper().readValue(startResp.body(), Map.class);
        String trackingToken = (String) startBody.getOrDefault("trackingToken", accessToken);
        String sessionId = (String) startBody.get("sessionId");

        // Send a location update using the tracking token and sessionId
        Map<String, Object> body = new HashMap<>();
        body.put("driverId", driverId);
        body.put("sessionId", sessionId);
        body.put("latitude", lat);
        body.put("longitude", lng);
        body.put("speed", 3.3);
        body.put("heading", 120);
        body.put("batteryLevel", 88);
        body.put("clientTime", Instant.now().toEpochMilli());

        String json = new com.fasterxml.jackson.databind.ObjectMapper().writeValueAsString(body);

        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(baseUrl + "/api/driver/location/update"))
                .header("Content-Type", "application/json")
                .header("Authorization", "Bearer " + trackingToken)
                .POST(HttpRequest.BodyPublishers.ofString(json))
                .build();

        HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());
        System.out.println("location update status=" + response.statusCode());
        System.out.println(response.body());
    }
}
