package com.svtrucking.logistics.websocket;

import java.time.Duration;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnBean;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.event.EventListener;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.messaging.simp.stomp.StompHeaderAccessor;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.messaging.SessionConnectedEvent;
import org.springframework.web.socket.messaging.SessionDisconnectEvent;

/**
 * Tracks active STOMP WebSocket sessions in Redis.
 *
 * <p>
 * Key pattern: {@code ws:session:{sessionId}} — TTL 30 s.
 *
 * <p>
 * The TTL is intentionally short; STOMP heartbeat frames (every 10 s)
 * do NOT refresh this key — it is set once on connect and removed on
 * disconnect. If the broker does not fire a disconnect event (e.g., network
 * drop) the key expires after 30 s, preventing stale "connected" entries.
 *
 * <p>
 * This service never throws; all Redis errors are swallowed and logged so
 * that a Redis outage cannot affect the STOMP broker.
 */
@Component
@RequiredArgsConstructor
@Slf4j
@ConditionalOnBean(RedisTemplate.class)
@ConditionalOnProperty(name = "websocket.enabled", havingValue = "true", matchIfMissing = true)
public class WebSocketPresenceService {

  private static final String KEY_PREFIX = "ws:session:";
  private static final Duration SESSION_TTL = Duration.ofSeconds(30);

  private final RedisTemplate<String, Object> redisTemplate;

  @EventListener
  public void onConnect(SessionConnectedEvent event) {
    String sessionId = extractSessionId(event.getMessage());
    if (sessionId == null)
      return;
    try {
      redisTemplate.opsForValue().set(KEY_PREFIX + sessionId, "1", SESSION_TTL);
      log.debug("WS session connected: id={}", sessionId);
    } catch (Exception ex) {
      log.warn("Failed to record WS session {}: {}", sessionId, ex.getMessage());
    }
  }

  @EventListener
  public void onDisconnect(SessionDisconnectEvent event) {
    String sessionId = extractSessionId(event.getMessage());
    if (sessionId == null)
      return;
    try {
      redisTemplate.delete(KEY_PREFIX + sessionId);
      log.debug("WS session disconnected: id={}", sessionId);
    } catch (Exception ex) {
      log.warn("Failed to remove WS session {}: {}", sessionId, ex.getMessage());
    }
  }

  /**
   * Returns {@code true} if a STOMP session with this ID is currently tracked.
   * Returns {@code false} on any Redis error (fail-open: callers should not rely
   * on this as a security gate).
   */
  public boolean isConnected(String sessionId) {
    if (sessionId == null)
      return false;
    try {
      return Boolean.TRUE.equals(redisTemplate.hasKey(KEY_PREFIX + sessionId));
    } catch (Exception ex) {
      log.warn("Redis check for WS session {} failed: {}", sessionId, ex.getMessage());
      return false;
    }
  }

  private static String extractSessionId(org.springframework.messaging.Message<?> message) {
    if (message == null)
      return null;
    StompHeaderAccessor sha = StompHeaderAccessor.wrap(message);
    return sha.getSessionId();
  }
}
