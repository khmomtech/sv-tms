package com.svtrucking.logistics.utils;

import org.springframework.web.servlet.support.ServletUriComponentsBuilder;
import org.springframework.web.util.UriComponentsBuilder;

/**
 * Utility for resolving stored upload paths into fully qualified URLs when a request context is
 * available. Returns the original value when no context is present or the path already looks
 * absolute.
 */
public final class AssetUrlHelper {

  private AssetUrlHelper() {}

  /**
   * @param storedPath relative path stored in the database (e.g. "/uploads/profiles/driver.jpg")
   * @return absolute URL (http://host/uploads/...) if the request context exists, otherwise the
   *     original storedPath.
   */
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
