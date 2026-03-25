package com.svtrucking.telematics.config;

import com.svtrucking.telematics.security.TelematicsJwtUtil;
import java.util.Arrays;
import java.util.List;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;
import org.springframework.messaging.Message;
import org.springframework.messaging.MessageChannel;
import org.springframework.messaging.simp.SimpMessageType;
import org.springframework.messaging.simp.config.ChannelRegistration;
import org.springframework.messaging.simp.config.MessageBrokerRegistry;
import org.springframework.messaging.simp.stomp.StompHeaderAccessor;
import org.springframework.messaging.support.ChannelInterceptor;
import org.springframework.scheduling.TaskScheduler;
import org.springframework.scheduling.concurrent.ThreadPoolTaskScheduler;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.web.socket.config.annotation.EnableWebSocketMessageBroker;
import org.springframework.web.socket.config.annotation.StompEndpointRegistry;
import org.springframework.web.socket.config.annotation.WebSocketMessageBrokerConfigurer;

/**
 * WebSocket/STOMP configuration for tms-telematics-api.
 * Endpoints: /tele-ws (raw) and /tele-ws-sockjs (SockJS).
 * JWT interceptor is claims-only — no UserDetailsService.
 */
@Configuration
@EnableWebSocketMessageBroker
public class TelematicsWebSocketConfig implements WebSocketMessageBrokerConfigurer {

    private final TelematicsJwtUtil jwtUtil;

    @Value("${app.websocket.allowed-origins:*}")
    private String allowedOrigins;

    public TelematicsWebSocketConfig(TelematicsJwtUtil jwtUtil) {
        this.jwtUtil = jwtUtil;
    }

    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        String[] origins = Arrays.stream(allowedOrigins.split(","))
                .map(String::trim).toArray(String[]::new);

        TelematicsJwtHandshakeInterceptor interceptor = new TelematicsJwtHandshakeInterceptor(jwtUtil, origins);

        registry.addEndpoint("/tele-ws")
                .setAllowedOriginPatterns(origins)
                .addInterceptors(interceptor);

        registry.addEndpoint("/tele-ws-sockjs")
                .setAllowedOriginPatterns(origins)
                .addInterceptors(interceptor)
                .withSockJS()
                .setClientLibraryUrl(
                        "https://cdn.jsdelivr.net/npm/sockjs-client@1/dist/sockjs.min.js");
    }

    @Override
    public void configureMessageBroker(MessageBrokerRegistry config) {
        config.enableSimpleBroker("/topic", "/queue")
                .setTaskScheduler(taskScheduler())
                .setHeartbeatValue(new long[] { 10_000, 10_000 });
        config.setApplicationDestinationPrefixes("/app");
        config.setUserDestinationPrefix("/user");
    }

    @Override
    public void configureClientInboundChannel(ChannelRegistration registration) {
        registration.interceptors(new ChannelInterceptor() {
            @Override
            public Message<?> preSend(Message<?> message, MessageChannel channel) {
                StompHeaderAccessor accessor = StompHeaderAccessor.wrap(message);
                if (SimpMessageType.CONNECT.equals(accessor.getMessageType())) {
                    String auth = accessor.getFirstNativeHeader("Authorization");
                    if (auth == null || auth.isBlank()) {
                        auth = accessor.getFirstNativeHeader("token");
                    }
                    String token = null;
                    if (auth != null) {
                        token = auth.startsWith("Bearer ") ? auth.substring(7) : auth;
                    }
                    if (token != null && !token.isBlank()) {
                        try {
                            if (jwtUtil.isTokenValid(token)) {
                                String tokenType = jwtUtil.extractTokenType(token);
                                String role = "tracking".equalsIgnoreCase(tokenType)
                                        ? "ROLE_DRIVER_TRACKING"
                                        : "ROLE_API_USER";
                                String username = jwtUtil.extractUsername(token);
                                Long driverId = jwtUtil.extractDriverId(token);
                                String principal = username != null ? username : "driver-" + driverId;
                                Authentication auth2 = new UsernamePasswordAuthenticationToken(
                                        principal, null,
                                        List.of(new SimpleGrantedAuthority(role)));
                                accessor.setUser(auth2);
                            }
                        } catch (Exception e) {
                            // Leave unauthenticated — controller-level @PreAuthorize handles it
                        }
                    }
                }
                return message;
            }
        });
    }

    @Bean
    @Primary
    public TaskScheduler taskScheduler() {
        ThreadPoolTaskScheduler scheduler = new ThreadPoolTaskScheduler();
        scheduler.setPoolSize(1);
        scheduler.setThreadNamePrefix("stomp-heartbeat-");
        scheduler.initialize();
        return scheduler;
    }
}
