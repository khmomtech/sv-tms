package com.svtrucking.gateway.service;

import jakarta.servlet.http.HttpServletRequest;
import java.net.URI;
import java.util.Arrays;
import java.util.Collections;
import java.util.Enumeration;
import java.util.List;
import java.util.Locale;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientResponseException;

@Service
public class ProxyService {
    private static final List<String> HOP_BY_HOP_RESPONSE_HEADERS = Arrays.asList(
            HttpHeaders.CONNECTION,
            HttpHeaders.TRANSFER_ENCODING,
            HttpHeaders.CONTENT_LENGTH,
            "Keep-Alive",
            HttpHeaders.PROXY_AUTHENTICATE,
            HttpHeaders.PROXY_AUTHORIZATION,
            "TE",
            HttpHeaders.TRAILER,
            HttpHeaders.UPGRADE);

    private final RestClient restClient;
    private final RouteResolver routeResolver;

    public ProxyService(RestClient gatewayRestClient, RouteResolver routeResolver) {
        this.restClient = gatewayRestClient;
        this.routeResolver = routeResolver;
    }

    public ResponseEntity<byte[]> forward(HttpServletRequest request, byte[] body) {
        String requestUri = request.getRequestURI();
        String query = request.getQueryString();
        URI baseUri = routeResolver.resolve(requestUri);
        URI targetUri = URI.create(baseUri.toString() + requestUri + (query == null ? "" : "?" + query));
        HttpMethod method = HttpMethod.valueOf(request.getMethod());
        HttpHeaders outboundHeaders = copyHeaders(request);

        try {
            ResponseEntity<byte[]> upstream = restClient.method(method)
                    .uri(targetUri)
                    .headers(headers -> headers.addAll(outboundHeaders))
                    .contentType(resolveContentType(request))
                    .body(body == null ? new byte[0] : body)
                    .retrieve()
                    .toEntity(byte[].class);

            return ResponseEntity.status(upstream.getStatusCode())
                    .headers(filterResponseHeaders(upstream.getHeaders()))
                    .body(upstream.getBody());
        } catch (RestClientResponseException ex) {
            // Preserve actual upstream status and response body for client-side handling.
            HttpHeaders upstreamHeaders = ex.getResponseHeaders() != null ? ex.getResponseHeaders() : new HttpHeaders();
            return ResponseEntity.status(ex.getRawStatusCode())
                    .headers(filterResponseHeaders(upstreamHeaders))
                    .body(ex.getResponseBodyAsByteArray());
        } catch (ResourceAccessException ex) {
            // Backend unreachable (DNS/connection timeout).
            return ResponseEntity.status(504)
                    .body(ex.getMessage().getBytes());
        }

    }

    private HttpHeaders copyHeaders(HttpServletRequest request) {
        HttpHeaders headers = new HttpHeaders();
        Enumeration<String> names = request.getHeaderNames();
        for (String name : Collections.list(names)) {
            if (HttpHeaders.HOST.equalsIgnoreCase(name) || HttpHeaders.CONTENT_LENGTH.equalsIgnoreCase(name)) {
                continue;
            }
            List<String> values = Collections.list(request.getHeaders(name));
            headers.put(name, values);
        }
        return headers;
    }

    private MediaType resolveContentType(HttpServletRequest request) {
        String contentType = request.getContentType();
        if (contentType == null || contentType.isBlank()) {
            return MediaType.APPLICATION_OCTET_STREAM;
        }
        return MediaType.parseMediaType(contentType);
    }

    private HttpHeaders filterResponseHeaders(HttpHeaders upstreamHeaders) {
        HttpHeaders filtered = new HttpHeaders();
        upstreamHeaders.forEach((name, values) -> {
            String normalized = name == null ? "" : name.toLowerCase(Locale.ROOT);
            boolean skip = HOP_BY_HOP_RESPONSE_HEADERS.stream()
                    .map(header -> header.toLowerCase(Locale.ROOT))
                    .anyMatch(normalized::equals);
            if (!skip) {
                filtered.put(name, values);
            }
        });
        return filtered;
    }
}
