package com.svtrucking.telematics.service;

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

    @Value("${geocode.google.enabled:false}")
    private boolean googleEnabled;

    @Value("${geocode.photon.enabled:true}")
    private boolean photonEnabled;

    @Value("${geocode.photon.base:https://photon.komoot.io}")
    private String photonBaseUrl;

    private static final String OSM_BASE = "https://nominatim.openstreetmap.org";
    private static final String GOOGLE_BASE = "https://maps.googleapis.com/maps/api";
    private static final String PHOTON_REVERSE_PATH = "/reverse";
    private static final String UA = "SVTrucking-TelematicsService/1.0 (admin@svtrucking.com)";
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
        if (cached != null)
            return cached;

        if (osmEnabled) {
            Optional<String> osm = reverseOsm(lat, lng);
            if (osm.isPresent()) {
                putCached(cacheKey, osm.get());
                return osm.get();
            }
        }

        if (photonEnabled) {
            Optional<String> ph = reversePhoton(lat, lng);
            if (ph.isPresent()) {
                putCached(cacheKey, ph.get());
                return ph.get();
            }
        }

        if (googleEnabled && googleApiKey != null && !googleApiKey.isBlank()) {
            Optional<String> g = reverseGoogle(lat, lng);
            if (g.isPresent()) {
                putCached(cacheKey, g.get());
                return g.get();
            }
        }

        LOG.debug("No geocoding results for lat={}, lng={}", lat, lng);
        String unknown = "Unknown location";
        putCached(cacheKey, unknown);
        return unknown;
    }

    private Optional<String> reverseOsm(double lat, double lng) {
        int[] zooms = { 19, 18, 16, 14, 12 };
        for (int zoom : zooms) {
            try {
                String url = OSM_BASE + "/reverse"
                        + "?format=jsonv2&lat=" + lat + "&lon=" + lng
                        + "&zoom=" + zoom + "&addressdetails=1"
                        + "&accept-language=" + enc("km,en,en-US")
                        + (hasCountryBias() ? "&countrycodes=" + enc(countryBias.toLowerCase(Locale.ROOT)) : "");

                HttpRequest req = HttpRequest.newBuilder().uri(URI.create(url))
                        .timeout(requestTimeout).header("User-Agent", UA)
                        .header("Accept", "application/json").GET().build();

                String body = sendWithRetry(req, 2);
                if (body == null)
                    continue;

                JsonNode json = om.readTree(body);
                String display = asText(json, "display_name");
                if (notBlank(display))
                    return Optional.of(display);

                JsonNode addr = json.path("address");
                if (!addr.isMissingNode() && addr.size() > 0) {
                    String composed = composeAddressKh(addr);
                    if (notBlank(composed))
                        return Optional.of(composed);
                }
            } catch (Exception e) {
                LOG.debug("OSM reverse failed at zoom {} for {},{}: {}", zoom, lat, lng, e.toString());
            }
        }
        return Optional.empty();
    }

    private Optional<String> reversePhoton(double lat, double lng) {
        try {
            String base = notBlank(photonBaseUrl) ? photonBaseUrl.trim() : "https://photon.komoot.io";
            String baseN = base.endsWith("/") ? base.substring(0, base.length() - 1) : base;
            StringBuilder url = new StringBuilder(baseN);
            if (!baseN.endsWith(PHOTON_REVERSE_PATH))
                url.append(PHOTON_REVERSE_PATH);
            url.append("?lat=").append(lat).append("&lon=").append(lng).append("&lang=").append(enc("km,en"));
            if (hasCountryBias())
                url.append("&countrycode=").append(enc(countryBias.toLowerCase(Locale.ROOT)));

            HttpRequest req = HttpRequest.newBuilder().uri(URI.create(url.toString()))
                    .timeout(requestTimeout).header("User-Agent", UA)
                    .header("Accept", "application/json").GET().build();

            String body = sendWithRetry(req, 1);
            if (body == null)
                return Optional.empty();

            JsonNode json = om.readTree(body);
            JsonNode features = json.path("features");
            if (features.isArray()) {
                for (JsonNode feature : features) {
                    JsonNode props = feature.path("properties");
                    if (props.isMissingNode())
                        continue;
                    String name = asText(props, "name");
                    String street = firstNonNull(asText(props, "street"), asText(props, "road"));
                    String commune = firstNonNull(asText(props, "suburb"), asText(props, "district"),
                            asText(props, "quarter"), asText(props, "neighbourhood"));
                    String district = firstNonNull(asText(props, "county"), asText(props, "county_code"),
                            asText(props, "state_district"));
                    String city = firstNonNull(asText(props, "city"), asText(props, "town"), asText(props, "locality"));
                    String province = asText(props, "state");
                    ObjectNode addr = om.createObjectNode();
                    if (notBlank(commune))
                        addr.put("sublocality", commune);
                    if (notBlank(district))
                        addr.put("district", district);
                    if (notBlank(city))
                        addr.put("city", city);
                    if (notBlank(province))
                        addr.put("state", province);
                    String khAddress = composeAddressKh(addr);
                    String formatted = dedupJoin(", ", name, street, khAddress, asText(props, "country"));
                    if (notBlank(formatted))
                        return Optional.of(formatted);
                }
            }
        } catch (Exception e) {
            LOG.debug("Photon reverse failed for {},{}: {}", lat, lng, e.toString());
        }
        return Optional.empty();
    }

    private Optional<String> reverseGoogle(double lat, double lng) {
        try {
            String url = GOOGLE_BASE + "/geocode/json?latlng=" + lat + "," + lng
                    + "&language=" + enc("km")
                    + (hasCountryBias() ? "&region=" + enc(countryBias.toLowerCase(Locale.ROOT)) : "")
                    + "&key=" + enc(googleApiKey);
            HttpRequest req = HttpRequest.newBuilder().uri(URI.create(url))
                    .timeout(requestTimeout).header("Accept", "application/json").GET().build();
            String body = sendWithRetry(req, 2);
            if (body == null)
                return Optional.empty();
            JsonNode json = om.readTree(body);
            if (!"OK".equals(asText(json, "status")))
                return Optional.empty();
            JsonNode results = json.path("results");
            if (results.isArray() && results.size() > 0) {
                JsonNode best = results.get(0);
                for (JsonNode r : results) {
                    String types = r.path("types").toString();
                    if (types.contains("street_address") || types.contains("route")) {
                        best = r;
                        break;
                    }
                }
                String formatted = asText(best, "formatted_address");
                if (notBlank(formatted))
                    return Optional.of(formatted);
            }
        } catch (Exception e) {
            LOG.debug("Google reverse failed: {}", e.toString());
        }
        return Optional.empty();
    }

    private String sendWithRetry(HttpRequest req, int retries) {
        int attempt = 0;
        while (true) {
            attempt++;
            try {
                HttpResponse<String> resp = http.send(req, HttpResponse.BodyHandlers.ofString());
                int code = resp.statusCode();
                if (code == 429 || (code >= 500 && code < 600)) {
                    if (attempt <= retries + 1)
                        sleep(backoffMs(attempt));
                    else
                        return null;
                } else if (code >= 200 && code < 300) {
                    return resp.body();
                } else {
                    return null;
                }
            } catch (Exception ex) {
                if (attempt <= retries + 1)
                    sleep(backoffMs(attempt));
                else {
                    LOG.debug("Geocode request failed after {} attempts: {}", attempt, ex.toString());
                    return null;
                }
            }
        }
    }

    private static long backoffMs(int attempt) {
        return 300L << Math.min(attempt - 1, 4);
    }

    private static void sleep(long ms) {
        try {
            Thread.sleep(ms);
        } catch (InterruptedException ignored) {
        }
    }

    private static String composeAddressKh(JsonNode addr) {
        String communeRaw = firstNonNull(asText(addr, "commune"), asText(addr, "sangkat"),
                asText(addr, "suburb"), asText(addr, "sublocality"));
        String districtRaw = firstNonNull(asText(addr, "khan"), asText(addr, "district"),
                asText(addr, "county"), asText(addr, "municipality"));
        String cityRaw = firstNonNull(asText(addr, "city"), asText(addr, "town"));
        String provinceRaw = firstNonNull(asText(addr, "province"), asText(addr, "state"));
        boolean isPP = equalsAnyIgnoreCase(provinceRaw, "Phnom Penh") || equalsAnyIgnoreCase(cityRaw, "Phnom Penh");
        String commune = notBlank(communeRaw) ? (isPP ? "សង្កាត់ " : "ឃុំ ") + communeRaw : null;
        String district = notBlank(districtRaw) ? (isPP ? "ខណ្ឌ " : "ស្រុក ") + districtRaw : null;
        String province = isPP ? "រាជធានីភ្នំពេញ" : (notBlank(provinceRaw) ? "ខេត្ត " + provinceRaw : null);
        return dedupJoin(", ", commune, district, province);
    }

    private static String cacheKey(double lat, double lng) {
        return round(lat, 4) + "|" + round(lng, 4);
    }

    private static double round(double v, int dp) {
        double m = Math.pow(10, dp);
        return Math.round(v * m) / m;
    }

    private static String getCached(String key) {
        CacheEntry e = CACHE.get(key);
        if (e == null)
            return null;
        if (Instant.now().toEpochMilli() - e.storedAtMs > CACHE_TTL_MS) {
            CACHE.remove(key);
            return null;
        }
        return e.value;
    }

    private static void putCached(String key, String value) {
        CACHE.put(key, new CacheEntry(value, Instant.now().toEpochMilli()));
    }

    private record CacheEntry(String value, long storedAtMs) {
    }

    private boolean hasCountryBias() {
        return countryBias != null && !countryBias.isBlank();
    }

    private static String asText(JsonNode node, String field) {
        if (node == null || node.isMissingNode())
            return null;
        JsonNode n = node.path(field);
        return n.isMissingNode() || n.isNull() ? null : n.asText(null);
    }

    private static boolean notBlank(String s) {
        return s != null && !s.isBlank();
    }

    private static boolean equalsAnyIgnoreCase(String candidate, String... comparisons) {
        if (!notBlank(candidate) || comparisons == null)
            return false;
        String lhs = candidate.trim();
        for (String c : comparisons) {
            if (notBlank(c) && lhs.equalsIgnoreCase(c.trim()))
                return true;
        }
        return false;
    }

    private static String firstNonNull(String... vals) {
        for (String v : vals)
            if (notBlank(v))
                return v;
        return null;
    }

    private static String dedupJoin(String sep, String... parts) {
        StringBuilder sb = new StringBuilder();
        String last = null;
        for (String p : parts) {
            String t = normalizeToken(p);
            if (!notBlank(t))
                continue;
            if (last != null && last.equalsIgnoreCase(t))
                continue;
            if (sb.length() > 0)
                sb.append(sep);
            sb.append(t);
            last = t;
        }
        return sb.toString();
    }

    private static String normalizeToken(String s) {
        if (s == null)
            return null;
        String t = s.trim().replaceAll("\\s+", " ").replaceAll(",+", ",").replaceAll("^[, ]+|[, ]+$", "");
        return t.isEmpty() ? null : t;
    }

    private static String enc(String v) {
        return URLEncoder.encode(v, StandardCharsets.UTF_8);
    }
}
