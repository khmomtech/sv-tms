package com.svtrucking.logistics.security;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import com.svtrucking.logistics.model.AppVersion;
import com.svtrucking.logistics.model.Driver;
import com.svtrucking.logistics.repository.DriverRepository;
import com.svtrucking.logistics.service.AppVersionService;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockFilterChain;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

class DriverAppVersionEnforcementFilterTest {

  private AppVersionService appVersionService;
  private DriverRepository driverRepository;
  private DriverAppVersionEnforcementFilter filter;

  @BeforeEach
  void setUp() {
    appVersionService = mock(AppVersionService.class);
    driverRepository = mock(DriverRepository.class);
    filter = new DriverAppVersionEnforcementFilter(appVersionService, driverRepository);
    SecurityContextHolder.clearContext();
  }

  @Test
  void blocksDriverLoginWhenAndroidVersionIsBelowMandatoryOverride() throws Exception {
    AppVersion latest = new AppVersion();
    latest.setLatestVersion("2.0.0");
    latest.setMandatoryUpdate(false);
    latest.setAndroidLatestVersion("2.5.0");
    latest.setAndroidMandatoryUpdate(true);
    latest.setPlaystoreUrl("https://play.example/app");
    when(appVersionService.getLatestVersion()).thenReturn(latest);

    MockHttpServletRequest request = new MockHttpServletRequest("POST", "/api/auth/driver/login");
    request.addHeader("X-Device-Os", "Android");
    request.addHeader("X-App-Version", "2.4.0");
    MockHttpServletResponse response = new MockHttpServletResponse();

    filter.doFilter(request, response, new MockFilterChain());

    assertThat(response.getStatus()).isEqualTo(426);
    assertThat(response.getHeader("X-Min-Supported-Version")).isEqualTo("2.5.0");
  }

  @Test
  void blocksAuthenticatedDriverRequestUsingStoredDriverVersionWhenHeaderMissing() throws Exception {
    AppVersion latest = new AppVersion();
    latest.setLatestVersion("3.0.0");
    latest.setMinSupportedVersion("2.9.5");
    latest.setMandatoryUpdate(true);
    latest.setPlaystoreUrl("https://play.example/app");
    when(appVersionService.getLatestVersion()).thenReturn(latest);

    Driver driver = new Driver();
    driver.setAppVersion("2.9.0");
    when(driverRepository.findByUsername("driver1")).thenReturn(Optional.of(driver));

    SecurityContextHolder.getContext().setAuthentication(
        new UsernamePasswordAuthenticationToken("driver1", "n/a"));

    MockHttpServletRequest request = new MockHttpServletRequest("GET", "/api/driver-app/bootstrap");
    MockHttpServletResponse response = new MockHttpServletResponse();

    filter.doFilter(request, response, new MockFilterChain());

    assertThat(response.getStatus()).isEqualTo(426);
    assertThat(response.getHeader("X-Latest-Version")).isEqualTo("3.0.0");
    assertThat(response.getHeader("X-Min-Supported-Version")).isEqualTo("2.9.5");
  }

  @Test
  void allowsRequestWhenCurrentVersionMeetsRequiredVersion() throws Exception {
    AppVersion latest = new AppVersion();
    latest.setLatestVersion("3.0.0");
    latest.setMandatoryUpdate(true);
    when(appVersionService.getLatestVersion()).thenReturn(latest);

    MockHttpServletRequest request = new MockHttpServletRequest("POST", "/api/auth/driver/login");
    request.addHeader("X-App-Version", "3.0.0");
    MockHttpServletResponse response = new MockHttpServletResponse();
    MockFilterChain chain = new MockFilterChain();

    filter.doFilter(request, response, chain);

    assertThat(response.getStatus()).isEqualTo(200);
  }
}
