package com.svtrucking.logistics.modules.notification.queue;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.svtrucking.logistics.settings.event.SettingChangedEvent;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnBean;
import org.springframework.context.event.EventListener;
import org.springframework.core.annotation.Order;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.Map;
import java.util.NoSuchElementException;

/**
 * Simple Redis-backed notification queue.
 *
 * <p>Uses a Redis list to enqueue notification payloads and a scheduled consumer to drain.
 *
 * <p>{@code queue.enabled} is read at startup from {@code application.properties} and can
 * be toggled at runtime without a restart by updating the DB setting:
 * <pre>
 *   POST /api/admin/settings/value
 *   { "groupCode": "notification", "keyCode": "queue.enabled",
 *     "value": "false", "scope": "GLOBAL", "reason": "Maintenance" }
 * </pre>
 * The change takes effect on the next enqueue/poll call.
 */
@Service
@ConditionalOnBean(name = "redisTemplate")
@Slf4j
@RequiredArgsConstructor
public class NotificationQueueService {

  private static final String NOTIFICATION_GROUP = "notification";
  private static final String QUEUE_ENABLED_KEY  = "queue.enabled";

  private final RedisTemplate<String, Object> redisTemplate;
  private final ObjectMapper objectMapper;

  // Optional SettingService — absent in test slices that don't load the full context.
  @Autowired(required = false)
  private com.svtrucking.logistics.settings.service.SettingService settingService;

  /** Properties-file fallback, overridden by DB setting when available. */
  @Value("${notification.queue.enabled:true}")
  private boolean propertyQueueEnabled;

  /** Volatile so changes from SettingChangedEvent are immediately visible to all threads. */
  private volatile Boolean cachedQueueEnabled = null;

  @Value("${notification.queue.key:notifications:queue}")
  private String queueKey;

  // ── Queue operations ─────────────────────────────────────────────────────

  public boolean enqueue(NotificationPayload payload) {
    if (!isEnabled()) {
      return false;
    }
    payload.setCreatedAt(Instant.now());
    try {
      redisTemplate.opsForList().leftPush(queueKey, payload);
      return true;
    } catch (Exception e) {
      log.warn("Failed to enqueue notification payload to Redis queue: {}", e.getMessage(), e);
      return false;
    }
  }

  public NotificationPayload poll() {
    if (!isEnabled()) {
      return null;
    }
    try {
      Object obj = redisTemplate.opsForList().rightPop(queueKey);
      if (obj instanceof NotificationPayload np) {
        return np;
      }
      if (obj instanceof Map<?, ?> map) {
        try {
          return objectMapper.convertValue(map, NotificationPayload.class);
        } catch (IllegalArgumentException ex) {
          log.warn("Failed to convert queued map payload to NotificationPayload: {}", ex.getMessage());
          return null;
        }
      }
      if (obj != null) {
        log.warn("Unexpected object in notification queue: {}", obj.getClass());
      }
      return null;
    } catch (Exception e) {
      log.warn("Failed to poll notification queue: {}", e.getMessage(), e);
      return null;
    }
  }

  public long queueDepth() {
    try {
      Long size = redisTemplate.opsForList().size(queueKey);
      return size == null ? 0 : size;
    } catch (Exception e) {
      log.warn("Failed to get notification queue depth: {}", e.getMessage(), e);
      return -1;
    }
  }

  public boolean isEnabled() {
    if (cachedQueueEnabled == null) {
      cachedQueueEnabled = resolveQueueEnabled();
    }
    return cachedQueueEnabled;
  }

  public long purgeAll() {
    try {
      Long size = redisTemplate.opsForList().size(queueKey);
      redisTemplate.delete(queueKey);
      return size == null ? 0 : size;
    } catch (Exception e) {
      log.warn("Failed to purge notification queue: {}", e.getMessage(), e);
      return -1;
    }
  }

  // ── Live settings reload ─────────────────────────────────────────────────

  /**
   * Invalidates the cached {@code queue.enabled} flag when an admin updates the setting
   * via {@code POST /api/admin/settings/value}.  The new value takes effect on the next
   * enqueue or poll call with no restart required.
   */
  @EventListener
  @Order(2)
  public void onSettingChanged(SettingChangedEvent event) {
    if (NOTIFICATION_GROUP.equals(event.groupCode) && QUEUE_ENABLED_KEY.equals(event.keyCode)) {
      boolean previous = isEnabled();
      cachedQueueEnabled = resolveQueueEnabled();
      log.info("[NotificationQueue] queue.enabled changed: {} → {}", previous, cachedQueueEnabled);
    }
  }

  // ── Internals ────────────────────────────────────────────────────────────

  private boolean resolveQueueEnabled() {
    if (settingService != null) {
      try {
        Object val = settingService.getValue(NOTIFICATION_GROUP, QUEUE_ENABLED_KEY, "GLOBAL", null);
        if (val instanceof Boolean b) return b;
        if (val instanceof String s && !s.isBlank()) return Boolean.parseBoolean(s.trim());
      } catch (NoSuchElementException ignored) {
        // SettingDef not seeded yet; fall through to property.
      } catch (Exception e) {
        log.debug("[NotificationQueue] DB lookup failed, using property fallback: {}", e.getMessage());
      }
    }
    return propertyQueueEnabled;
  }
}
