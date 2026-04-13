package com.svtrucking.logistics.security;

import com.svtrucking.logistics.model.AppVersion;
import com.svtrucking.logistics.model.Driver;
import com.svtrucking.logistics.repository.DriverRepository;
import com.svtrucking.logistics.service.AppVersionService;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.Locale;
import java.util.Optional;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

@Component
public class DriverAppVersionEnforcementFilter extends OncePerRequestFilter {

  private final AppVersionService appVersionService;
  private final DriverRepository driverRepository;

  public DriverAppVersionEnforcementFilter(
      AppVersionService appVersionService, DriverRepository driverRepository) {
    this.appVersionService = appVersionService;
    this.driverRepository = driverRepository;
  }

  @Override
  protected boolean shouldNotFilter(HttpServletRequest request) {
    final String path = request.getRequestURI();
    if (path == null || path.isBlank()) {
      return true;
    }
    if ("/api/auth/driver/login".equals(path)) {
      return false;
    }
    if (path.startsWith("/api/driver-app/")) {
      return false;
    }
    if (path.startsWith("/api/driver/")) {
      return path.startsWith("/api/driver/device/");
    }
    return true;
  }

  @Override
  protected void doFilterInternal(
      HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
      throws ServletException, IOException {

    final AppVersion latest = appVersionService.getLatestVersion();
    if (latest == null) {
      filterChain.doFilter(request, response);
      return;
    }

    final EnforcementRule rule = resolveRule(latest, request);
    if (!rule.enforced()) {
      filterChain.doFilter(request, response);
      return;
    }

    final String currentVersion = resolveCurrentVersion(request).orElse("");
    if (currentVersion.isBlank() || isLower(currentVersion, rule.requiredVersion())) {
      sendUpgradeRequired(response, rule, latest);
      return;
    }

    filterChain.doFilter(request, response);
  }

  private EnforcementRule resolveRule(AppVersion latest, HttpServletRequest request) {
    final String platform = Optional.ofNullable(request.getHeader("X-Device-Os"))
        .map(v -> v.trim().toLowerCase(Locale.ROOT))
        .orElse("");

    if (platform.contains("android")
        && latest.isAndroidMandatoryUpdate()
        && notBlank(latest.getAndroidLatestVersion())) {
      return new EnforcementRule(
          latest.getAndroidLatestVersion().trim(),
          latest.getPlaystoreUrl(),
          "ANDROID_VERSION_UNSUPPORTED");
    }

    if ((platform.contains("ios") || platform.contains("iphone") || platform.contains("ipad"))
        && latest.isIosMandatoryUpdate()
        && notBlank(latest.getIosLatestVersion())) {
      return new EnforcementRule(
          latest.getIosLatestVersion().trim(),
          latest.getAppstoreUrl(),
          "IOS_VERSION_UNSUPPORTED");
    }

    if (latest.isMandatoryUpdate() && notBlank(latest.getLatestVersion())) {
      return new EnforcementRule(
          requiredGlobalVersion(latest),
          preferredStoreUrl(latest),
          "APP_VERSION_UNSUPPORTED");
    }

    return EnforcementRule.disabled();
  }

  private Optional<String> resolveCurrentVersion(HttpServletRequest request) {
    final String headerVersion = trimToNull(request.getHeader("X-App-Version"));
    if (headerVersion != null) {
      return Optional.of(headerVersion);
    }

    final Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
    if (authentication == null || authentication.getName() == null || authentication.getName().isBlank()) {
      return Optional.empty();
    }

    return driverRepository.findByUsername(authentication.getName())
        .map(Driver::getAppVersion)
        .map(this::trimToNull);
  }

  private void sendUpgradeRequired(
      HttpServletResponse response, EnforcementRule rule, AppVersion latest) throws IOException {
    response.setStatus(426);
    response.setContentType(MediaType.APPLICATION_JSON_VALUE);
    response.setHeader("X-Min-Supported-Version", rule.requiredVersion());
    response.setHeader("X-Latest-Version", trimToEmpty(latest.getLatestVersion()));
    response.setHeader("X-Update-Required", "true");
    if (notBlank(rule.storeUrl())) {
      response.setHeader("X-Store-Url", rule.storeUrl().trim());
    }
    response.getWriter().write(
        """
        {"error":"%s","message":"Driver app version is no longer supported. Please update the app to continue.","minSupportedVersion":"%s","latestVersion":"%s","storeUrl":"%s"}
        """
            .formatted(
                rule.errorCode(),
                escapeJson(rule.requiredVersion()),
                escapeJson(trimToEmpty(latest.getLatestVersion())),
                escapeJson(trimToEmpty(rule.storeUrl()))));
  }

  private boolean isLower(String current, String required) {
    int[] a = parseVersion(current);
    int[] b = parseVersion(required);
    for (int i = 0; i < 3; i++) {
      if (a[i] != b[i]) {
        return a[i] < b[i];
      }
    }
    return false;
  }

  private int[] parseVersion(String raw) {
    String core = trimToEmpty(raw);
    int hyphen = core.indexOf('-');
    if (hyphen >= 0) {
      core = core.substring(0, hyphen);
    }
    int plus = core.indexOf('+');
    if (plus >= 0) {
      core = core.substring(0, plus);
    }
    String[] parts = core.split("\\.");
    int[] out = new int[] {0, 0, 0};
    for (int i = 0; i < Math.min(parts.length, 3); i++) {
      String digits = parts[i].replaceAll("[^0-9]", "");
      if (!digits.isEmpty()) {
        try {
          out[i] = Integer.parseInt(digits);
        } catch (NumberFormatException ignored) {
          out[i] = 0;
        }
      }
    }
    return out;
  }

  private String preferredStoreUrl(AppVersion latest) {
    if (notBlank(latest.getPlaystoreUrl())) {
      return latest.getPlaystoreUrl();
    }
    return trimToEmpty(latest.getAppstoreUrl());
  }

  private String requiredGlobalVersion(AppVersion latest) {
    if (notBlank(latest.getMinSupportedVersion())) {
      return latest.getMinSupportedVersion().trim();
    }
    return latest.getLatestVersion().trim();
  }

  private boolean notBlank(String value) {
    return value != null && !value.trim().isEmpty();
  }

  private String trimToEmpty(String value) {
    return value == null ? "" : value.trim();
  }

  private String trimToNull(String value) {
    if (value == null) {
      return null;
    }
    String trimmed = value.trim();
    return trimmed.isEmpty() ? null : trimmed;
  }

  private String escapeJson(String value) {
    return value.replace("\\", "\\\\").replace("\"", "\\\"");
  }

  private record EnforcementRule(String requiredVersion, String storeUrl, String errorCode) {
    static EnforcementRule disabled() {
      return new EnforcementRule("", "", "");
    }

    boolean enforced() {
      return requiredVersion != null && !requiredVersion.isBlank();
    }
  }
}
