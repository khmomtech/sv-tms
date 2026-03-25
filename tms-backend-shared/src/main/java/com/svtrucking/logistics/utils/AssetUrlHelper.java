package com.svtrucking.logistics.utils;

import org.springframework.web.servlet.support.ServletUriComponentsBuilder;
import org.springframework.web.util.UriComponentsBuilder;

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
      return UriComponentsBuilder.fromHttpUrl(base).path(normalizedPath).build().toUriString();
    } catch (IllegalStateException | IllegalArgumentException ex) {
      return storedPath;
    }
  }
}
