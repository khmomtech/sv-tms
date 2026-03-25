package com.svtrucking.logistics.core.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpHeaders;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.time.Instant;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

@Service
public class GeocodingService {

  private static final Logger LOG = LoggerFactory.getLogger(GeocodingService.class);

  @Value("${google.maps.api.key:}")
  private String googleApiKey;

  @Value("${geocode.countryBias:}")
  private String countryBias;

  @Value("${geocode.osm.enabled:true}")
  private boolean osmEnabled;

  @Value("${geocode.google.enabled:true}")
  private boolean googleEnabled;

  @Value("${geocode.photon.enabled:true}")
  private boolean photonEnabled;

  @Value("${geocode.photon.base:https://photon.komoot.io}")
  private String photonBaseUrl;

  private static final String OSM_BASE = "https://nominatim.openstreetmap.org";
  private static final String GOOGLE_BASE = "https://maps.googleapis.com/maps/api";
  private static final String PHOTON_REVERSE_PATH = "/reverse";
  private static final String UA = "SVTrucking-DriverApp/1.0 (admin@svtrucking.com)";
  private static final long CACHE_TTL_MS = 6 * 60 * 60 * 1000L;
  private static final Map<String, CacheEntry> CACHE = new ConcurrentHashMap<>();

  private final HttpClient http;
  private final ObjectMapper om;
  private final Duration requestTimeout;

  public GeocodingService(
      HttpClient http,
      ObjectMapper objectMapper,
      @Value("${geocode.http.request-timeout-ms:6000}") long requestTimeoutMs) {
    this.http = http;
    this.om = objectMapper;
    this.requestTimeout = Duration.ofMillis(Math.max(1, requestTimeoutMs));
  }

  public String reverseGeocode(double lat, double lng) {
    String cacheKey = cacheKey(lat, lng);
    String cached = getCached(cacheKey);
    if (cached != null) {
      return cached;
    }

    if (osmEnabled) {
      Optional<String> osm = reverseOsm(lat, lng);
      if (osm.isPresent()) {
        putCached(cacheKey, osm.get());
        return osm.get();
      }
    }

    if (photonEnabled) {
      Optional<String> photon = reversePhoton(lat, lng);
      if (photon.isPresent()) {
        putCached(cacheKey, photon.get());
        return photon.get();
      }
    }

    if (googleEnabled && googleApiKey != null && !googleApiKey.isBlank()) {
      Optional<String> google = reverseGoogle(lat, lng);
      if (google.isPresent()) {
        putCached(cacheKey, google.get());
        return google.get();
      }
    }

    String unknown = "Unknown location";
    putCached(cacheKey, unknown);
    return unknown;
  }

  private Optional<String> reverseOsm(double lat, double lng) {
    int[] zooms = new int[] {19, 18, 16, 14, 12};
    for (int zoom : zooms) {
      try {
        String url =
            OSM_BASE
                + "/reverse"
                + "?format=jsonv2"
                + "&lat="
                + lat
                + "&lon="
                + lng
                + "&zoom="
                + zoom
                + "&addressdetails=1"
                + "&accept-language="
                + enc("km,en,en-US")
                + (hasCountryBias()
                    ? "&countrycodes=" + enc(countryBias.toLowerCase(Locale.ROOT))
                    : "");

        HttpRequest req =
            HttpRequest.newBuilder()
                .uri(URI.create(url))
                .timeout(requestTimeout)
                .header("User-Agent", UA)
                .header("Accept", "application/json")
                .GET()
                .build();

        String body = sendWithRetry(req, 2);
        if (body == null) {
          continue;
        }

        JsonNode json = om.readTree(body);
        String display = asText(json, "display_name");
        if (notBlank(display)) {
          return Optional.of(display);
        }
        JsonNode addr = json.path("address");
        if (!addr.isMissingNode() && addr.size() > 0) {
          String composed = composeAddressKh(addr);
          if (notBlank(composed)) {
            return Optional.of(composed);
          }
        }
      } catch (Exception e) {
        LOG.debug(
            "OSM reverse geocode failed at zoom {} for {},{}: {}",
            zoom,
            lat,
            lng,
            e.toString());
      }
    }
    return Optional.empty();
  }

  private Optional<String> reversePhoton(double lat, double lng) {
    try {
      String base = notBlank(photonBaseUrl) ? photonBaseUrl.trim() : "https://photon.komoot.io";
      String baseNormalized = base.endsWith("/") ? base.substring(0, base.length() - 1) : base;
      StringBuilder url = new StringBuilder(baseNormalized);
      if (!baseNormalized.endsWith(PHOTON_REVERSE_PATH)) {
        url.append(PHOTON_REVERSE_PATH);
      }
      url.append("?lat=")
          .append(lat)
          .append("&lon=")
          .append(lng)
          .append("&lang=")
          .append(enc("km,en"));
      if (hasCountryBias()) {
        url.append("&countrycode=").append(enc(countryBias.toLowerCase(Locale.ROOT)));
      }

      HttpRequest req =
          HttpRequest.newBuilder()
              .uri(URI.create(url.toString()))
              .timeout(requestTimeout)
              .header("User-Agent", UA)
              .header("Accept", "application/json")
              .GET()
              .build();

      String body = sendWithRetry(req, 1);
      if (body == null) {
        return Optional.empty();
      }

      JsonNode json = om.readTree(body);
      JsonNode features = json.path("features");
      if (features.isArray()) {
        for (JsonNode feature : features) {
          JsonNode props = feature.path("properties");
          if (props.isMissingNode()) {
            continue;
          }

          String name = asText(props, "name");
          String street = firstNonNull(asText(props, "street"), asText(props, "road"));
          String commune =
              firstNonNull(
                  asText(props, "suburb"),
                  asText(props, "district"),
                  asText(props, "quarter"),
                  asText(props, "neighbourhood"));
          String district =
              firstNonNull(
                  asText(props, "county"),
                  asText(props, "county_code"),
                  asText(props, "state_district"));
          String city =
              firstNonNull(asText(props, "city"), asText(props, "town"), asText(props, "state"));
          String result = joinParts(name, street, commune, district, city);
          if (notBlank(result)) {
            return Optional.of(result);
          }
        }
      }
    } catch (Exception e) {
      LOG.debug("Photon reverse geocode failed for {},{}: {}", lat, lng, e.toString());
    }
    return Optional.empty();
  }

  private Optional<String> reverseGoogle(double lat, double lng) {
    try {
      String url =
          GOOGLE_BASE
              + "/geocode/json?latlng="
              + lat
              + ","
              + lng
              + "&language=km"
              + (hasCountryBias() ? "&region=" + enc(countryBias) : "")
              + "&key="
              + enc(googleApiKey);
      HttpRequest req =
          HttpRequest.newBuilder()
              .uri(URI.create(url))
              .timeout(requestTimeout)
              .header("Accept", "application/json")
              .GET()
              .build();

      String body = sendWithRetry(req, 1);
      if (body == null) {
        return Optional.empty();
      }
      JsonNode json = om.readTree(body);
      JsonNode results = json.path("results");
      if (results.isArray() && !results.isEmpty()) {
        String formatted = asText(results.get(0), "formatted_address");
        if (notBlank(formatted)) {
          return Optional.of(formatted);
        }
      }
    } catch (Exception e) {
      LOG.debug("Google reverse geocode failed for {},{}: {}", lat, lng, e.toString());
    }
    return Optional.empty();
  }

  private String sendWithRetry(HttpRequest req, int retries) {
    int attempts = Math.max(1, retries + 1);
    for (int i = 0; i < attempts; i++) {
      try {
        HttpResponse<String> resp = http.send(req, HttpResponse.BodyHandlers.ofString());
        int status = resp.statusCode();
        if (status >= 200 && status < 300) {
          return resp.body();
        }
        if (status == 429 || status >= 500) {
          sleep(250L * (i + 1));
          continue;
        }
        LOG.debug("Geocode HTTP {} for {}", status, req.uri());
        return null;
      } catch (Exception e) {
        if (i == attempts - 1) {
          return null;
        }
        sleep(250L * (i + 1));
      }
    }
    return null;
  }

  private static void sleep(long ms) {
    try {
      Thread.sleep(ms);
    } catch (InterruptedException ie) {
      Thread.currentThread().interrupt();
    }
  }

  private static String composeAddressKh(JsonNode addr) {
    String road = firstNonNull(asText(addr, "road"), asText(addr, "pedestrian"));
    String suburb =
        firstNonNull(
            asText(addr, "suburb"),
            asText(addr, "city_district"),
            asText(addr, "quarter"),
            asText(addr, "village"));
    String city =
        firstNonNull(asText(addr, "city"), asText(addr, "town"), asText(addr, "state"));
    String country = asText(addr, "country");
    return joinParts(road, suburb, city, country);
  }

  private static String joinParts(String... values) {
    StringBuilder sb = new StringBuilder();
    for (String value : values) {
      if (!notBlank(value)) {
        continue;
      }
      if (sb.length() > 0) {
        sb.append(", ");
      }
      sb.append(value.trim());
    }
    return sb.toString();
  }

  private static String asText(JsonNode node, String field) {
    if (node == null) {
      return null;
    }
    JsonNode child = node.path(field);
    return child.isMissingNode() || child.isNull() ? null : child.asText();
  }

  private boolean hasCountryBias() {
    return countryBias != null && !countryBias.isBlank();
  }

  private static String firstNonNull(String... values) {
    for (String value : values) {
      if (notBlank(value)) {
        return value;
      }
    }
    return null;
  }

  private static boolean notBlank(String value) {
    return value != null && !value.isBlank();
  }

  private static String enc(String value) {
    return URLEncoder.encode(value, StandardCharsets.UTF_8);
  }

  private static String cacheKey(double lat, double lng) {
    return String.format(Locale.ROOT, "%.4f,%.4f", lat, lng);
  }

  private static String getCached(String key) {
    CacheEntry entry = CACHE.get(key);
    if (entry == null || entry.expiresAt().isBefore(Instant.now())) {
      CACHE.remove(key);
      return null;
    }
    return entry.value();
  }

  private static void putCached(String key, String value) {
    CACHE.put(key, new CacheEntry(value, Instant.now().plusMillis(CACHE_TTL_MS)));
  }

  private record CacheEntry(String value, Instant expiresAt) {}
}
