package com.svtrucking.logistics.utils;

import org.springframework.web.servlet.support.ServletUriComponentsBuilder;
import org.springframework.web.util.UriComponentsBuilder;

import java.net.URI;
import java.util.Locale;

public final class AssetUrlHelper {

  private AssetUrlHelper() {}

  public static String toAbsoluteUrl(String storedPath) {
    if (storedPath == null || storedPath.isBlank()) {
      return storedPath;
    }

    if (storedPath.startsWith("http://") || storedPath.startsWith("https://")) {
      return storedPath;
    }

    String normalizedPath = storedPath.startsWith("/") ? storedPath : "/" + storedPath;

    try {
      String base = ServletUriComponentsBuilder.fromCurrentContextPath().build().toUriString();
      if (isInternalBaseUrl(base)) {
        // When requests are proxied through internal service names (for example core-api:8080),
        // returning a relative URL is safer for browsers than leaking an unresolvable container host.
        return normalizedPath;
      }
      return UriComponentsBuilder.fromHttpUrl(base).path(normalizedPath).build().toUriString();
    } catch (IllegalStateException | IllegalArgumentException ex) {
      return normalizedPath;
    }
  }

  private static boolean isInternalBaseUrl(String baseUrl) {
    if (baseUrl == null || baseUrl.isBlank()) {
      return true;
    }

    try {
      URI uri = URI.create(baseUrl);
      String host = uri.getHost();
      if (host == null || host.isBlank()) {
        return true;
      }

      String normalizedHost = host.toLowerCase(Locale.ROOT);
      return "localhost".equals(normalizedHost)
          || "127.0.0.1".equals(normalizedHost)
          || "0.0.0.0".equals(normalizedHost)
          || !normalizedHost.contains(".")
          || normalizedHost.endsWith(".local");
    } catch (IllegalArgumentException ex) {
      return true;
    }
  }
}
