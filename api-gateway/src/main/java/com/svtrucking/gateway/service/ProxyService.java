package com.svtrucking.gateway.service;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.Part;
import java.io.IOException;
import java.io.InputStream;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.Collection;
import java.util.Collections;
import java.util.Enumeration;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.http.ContentDisposition;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.http.client.ClientHttpResponse;
import org.springframework.stereotype.Service;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.util.StreamUtils;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestClient;

@Service
@Slf4j
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
            if (isMultipartRequest(request)) {
                return restClient.method(method)
                        .uri(targetUri)
                        .headers(headers -> headers.addAll(stripMultipartContentHeaders(outboundHeaders)))
                        .contentType(MediaType.MULTIPART_FORM_DATA)
                        .body(buildMultipartBody(request.getParts()))
                        .exchange((clientRequest, response) -> toResponseEntity(response));
            }
            return restClient.method(method)
                    .uri(targetUri)
                    .headers(headers -> headers.addAll(outboundHeaders))
                    .contentType(resolveContentType(request))
                    .body(body == null ? new byte[0] : body)
                    .exchange((clientRequest, response) -> toResponseEntity(response));
        } catch (IOException | jakarta.servlet.ServletException ex) {
            log.error("Gateway failed to forward multipart request: method={}, targetUri={}, error={}",
                    method, targetUri, ex.getMessage(), ex);
            return ResponseEntity.status(500)
                    .body(("Gateway multipart forwarding failed: " + ex.getMessage()).getBytes(StandardCharsets.UTF_8));
        } catch (ResourceAccessException ex) {
            // Backend unreachable (DNS/connection timeout).
            log.error("Gateway upstream timeout/unreachable: method={}, targetUri={}, error={}",
                    method, targetUri, ex.getMessage());
            return ResponseEntity.status(504)
                    .body(ex.getMessage().getBytes());
        }

    }

    private boolean isMultipartRequest(HttpServletRequest request) {
        String contentType = request.getContentType();
        return contentType != null && contentType.toLowerCase(Locale.ROOT).startsWith(MediaType.MULTIPART_FORM_DATA_VALUE);
    }

    private HttpHeaders stripMultipartContentHeaders(HttpHeaders headers) {
        HttpHeaders sanitized = new HttpHeaders();
        sanitized.addAll(headers);
        sanitized.remove(HttpHeaders.CONTENT_TYPE);
        sanitized.remove(HttpHeaders.CONTENT_LENGTH);
        return sanitized;
    }

    private MultiValueMap<String, Object> buildMultipartBody(Collection<Part> parts) throws IOException {
        MultiValueMap<String, Object> body = new LinkedMultiValueMap<>();
        Map<String, Integer> partCounts = new LinkedHashMap<>();

        for (Part part : parts) {
            String partName = part.getName();
            partCounts.merge(partName, 1, Integer::sum);

            if (part.getSubmittedFileName() == null || part.getSubmittedFileName().isBlank()) {
                body.add(partName, StreamUtils.copyToString(part.getInputStream(), StandardCharsets.UTF_8));
                continue;
            }

            byte[] bytes;
            try (InputStream inputStream = part.getInputStream()) {
                bytes = inputStream.readAllBytes();
            }
            HttpHeaders partHeaders = new HttpHeaders();
            if (part.getContentType() != null && !part.getContentType().isBlank()) {
                partHeaders.setContentType(MediaType.parseMediaType(part.getContentType()));
            }
            partHeaders.setContentDisposition(ContentDisposition.formData()
                    .name(partName)
                    .filename(part.getSubmittedFileName())
                    .build());

            body.add(partName, new HttpEntity<>(new NamedByteArrayResource(bytes, part.getSubmittedFileName()), partHeaders));
        }

        log.info("Gateway forwarding multipart request with parts={}", partCounts);
        return body;
    }

    private static final class NamedByteArrayResource extends ByteArrayResource {
        private final String filename;

        private NamedByteArrayResource(byte[] byteArray, String filename) {
            super(byteArray);
            this.filename = filename;
        }

        @Override
        public String getFilename() {
            return filename;
        }
    }

    private ResponseEntity<byte[]> toResponseEntity(ClientHttpResponse response) throws java.io.IOException {
        HttpHeaders upstreamHeaders = response.getHeaders();
        byte[] responseBody = StreamUtils.copyToByteArray(response.getBody());
        return ResponseEntity.status(response.getStatusCode())
                .headers(filterResponseHeaders(upstreamHeaders))
                .body(responseBody);
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
