package com.svtrucking.logistics.config;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import com.svtrucking.logistics.security.JwtUtil;
import java.util.HashMap;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.server.ServletServerHttpRequest;
import org.springframework.http.server.ServletServerHttpResponse;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.web.socket.WebSocketHandler;

class JwtHandshakeInterceptorTest {

  private JwtUtil jwtUtil;
  private UserDetailsService userDetailsService;
  private JwtHandshakeInterceptor interceptor;
  private WebSocketHandler wsHandler;

  @BeforeEach
  void setUp() {
    jwtUtil = mock(JwtUtil.class);
    userDetailsService = mock(UserDetailsService.class);
    interceptor =
        new JwtHandshakeInterceptor(
            jwtUtil, userDetailsService, new String[] {"http://localhost:4200", "null"});
    wsHandler = mock(WebSocketHandler.class);
  }

  @Test
  void beforeHandshake_rejectsWhenTokenMissing() {
    MockHttpServletRequest request = baseRequest();
    MockHttpServletResponse response = new MockHttpServletResponse();
    ServletServerHttpResponse serverResponse = new ServletServerHttpResponse(response);

    boolean accepted =
        interceptor.beforeHandshake(
            new ServletServerHttpRequest(request),
            serverResponse,
            wsHandler,
            new HashMap<>());

    assertThat(accepted).isFalse();
    assertThat(response.getStatus()).isEqualTo(HttpStatus.UNAUTHORIZED.value());
    assertThat(serverResponse.getHeaders().getFirst("X-WS-Auth-Reason")).isEqualTo("missing_token");
  }

  @Test
  void beforeHandshake_rejectsWithUserNotFound() {
    MockHttpServletRequest request = baseRequest();
    request.setParameter("token", "good-token");
    MockHttpServletResponse response = new MockHttpServletResponse();
    ServletServerHttpResponse serverResponse = new ServletServerHttpResponse(response);

    when(jwtUtil.extractUsername("good-token")).thenReturn("ghost");
    when(userDetailsService.loadUserByUsername("ghost"))
        .thenThrow(new UsernameNotFoundException("not found"));

    boolean accepted =
        interceptor.beforeHandshake(
            new ServletServerHttpRequest(request),
            serverResponse,
            wsHandler,
            new HashMap<>());

    assertThat(accepted).isFalse();
    assertThat(response.getStatus()).isEqualTo(HttpStatus.UNAUTHORIZED.value());
    assertThat(serverResponse.getHeaders().getFirst("X-WS-Auth-Reason")).isEqualTo("user_not_found");
  }

  @Test
  void beforeHandshake_refreshesWhenAccessTokenExpired() {
    MockHttpServletRequest request = baseRequest();
    request.setParameter("token", "expired-token");
    request.setParameter("refreshToken", "valid-refresh");
    MockHttpServletResponse response = new MockHttpServletResponse();
    ServletServerHttpResponse serverResponse = new ServletServerHttpResponse(response);

    when(jwtUtil.extractUsername("expired-token")).thenReturn("superadmin");
    UserDetails userDetails =
        User.withUsername("superadmin").password("pw").authorities("ROLE_ADMIN").build();
    when(userDetailsService.loadUserByUsername("superadmin")).thenReturn(userDetails);
    when(jwtUtil.validateToken("expired-token", userDetails)).thenReturn(false);
    when(jwtUtil.isRefreshToken("valid-refresh")).thenReturn(true);
    when(jwtUtil.extractUsernameFromRefresh("valid-refresh")).thenReturn("superadmin");
    when(jwtUtil.generateAccessToken(userDetails)).thenReturn("new-access-token");

    boolean accepted =
        interceptor.beforeHandshake(
            new ServletServerHttpRequest(request),
            serverResponse,
            wsHandler,
            new HashMap<>());

    assertThat(accepted).isTrue();
    assertThat(serverResponse.getHeaders().getFirst("X-New-Access-Token")).isEqualTo("new-access-token");
    assertThat(serverResponse.getHeaders().getFirst("X-Access-Token")).isEqualTo("new-access-token");
  }

  private MockHttpServletRequest baseRequest() {
    MockHttpServletRequest request = new MockHttpServletRequest();
    request.setMethod("GET");
    request.setRequestURI("/ws-sockjs/info");
    request.addHeader("Origin", "http://localhost:4200");
    return request;
  }
}
