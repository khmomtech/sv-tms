package com.svtrucking.logistics.modules.notification.provider;

import com.svtrucking.logistics.modules.notification.queue.NotificationPayload;
import com.svtrucking.logistics.settings.event.SettingChangedEvent;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.ApplicationContext;
import org.springframework.context.event.EventListener;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;

import jakarta.annotation.PostConstruct;
import java.util.Map;
import java.util.NoSuchElementException;

/**
 * Runtime-switchable push provider.
 *
 * <p>This is the <em>primary</em> {@link PushProvider} bean.  On every {@code send()} call it
 * reads the configured provider name and delegates to the matching implementation bean.
 * The resolution happens at call time (not startup), so an admin can change the
 * {@code notification.push.provider} setting via the Admin Settings UI and the new
 * provider takes effect on the next notification without restarting the application.
 *
 * <h3>How to switch at runtime</h3>
 * <pre>
 *   POST /api/admin/settings/value
 *   {
 *     "groupCode": "notification",
 *     "keyCode":   "push.provider",
 *     "value":     "kafka",
 *     "scope":     "GLOBAL",
 *     "reason":    "Switch to Kafka for load testing"
 *   }
 * </pre>
 *
 * <h3>Supported values</h3>
 * <ul>
 *   <li>{@code kafka} — Publish to Kafka; a downstream consumer forwards to FCM/APNS (<b>default</b>)</li>
 *   <li>{@code fcm}   — Firebase Cloud Messaging direct send</li>
 *   <li>{@code none}  — No-op; log and discard</li>
 * </ul>
 *
 * <p>The value is resolved in this order:
 * <ol>
 *   <li>DB-backed {@code SettingService} (group={@code notification}, key={@code push.provider})</li>
 *   <li>{@code application.properties}: {@code notification.push.provider}</li>
 *   <li>Hard default: {@code kafka}</li>
 * </ol>
 *
 * <p>If none of the three concrete provider beans is registered (e.g. Firebase and Kafka
 * are both disabled), {@link NullPushProvider} is used as a safe fallback so the
 * application context never fails to start.
 */
@Component
@org.springframework.context.annotation.Primary
@Slf4j
public class DynamicPushProvider implements PushProvider {

  private static final String NOTIFICATION_GROUP = "notification";
  private static final String PROVIDER_KEY       = "push.provider";

  private final ApplicationContext ctx;

  /** Properties-file fallback (used when the DB row does not exist yet). */
  @Value("${notification.push.provider:kafka}")
  private String propertyFallback;

  // Optional SettingService — absent in test slices that don't load the full context.
  @Autowired(required = false)
  private com.svtrucking.logistics.settings.service.SettingService settingService;

  // Cached provider name — refreshed on SettingChangedEvent and on first use.
  private volatile String cachedProviderName;

  public DynamicPushProvider(ApplicationContext ctx) {
    this.ctx = ctx;
  }

  @PostConstruct
  void init() {
    cachedProviderName = resolveProviderName();
    log.info("[DynamicPushProvider] Active push provider: {}", cachedProviderName);
  }

  // ── PushProvider ──────────────────────────────────────────────────────────

  @Override
  public boolean send(NotificationPayload payload) {
    return resolve().send(payload);
  }

  // ── Settings change listener ─────────────────────────────────────────────

  /**
   * Invalidates the cached provider name whenever the {@code notification.push.provider}
   * setting is updated through the Admin Settings UI.
   */
  @EventListener
  @Order(1)
  public void onSettingChanged(SettingChangedEvent event) {
    if (NOTIFICATION_GROUP.equals(event.groupCode) && PROVIDER_KEY.equals(event.keyCode)) {
      String previous = cachedProviderName;
      cachedProviderName = resolveProviderName();
      log.info("[DynamicPushProvider] Push provider changed: {} → {}", previous, cachedProviderName);
    }
  }

  // ── Internals ────────────────────────────────────────────────────────────

  private PushProvider resolve() {
    String name = cachedProviderName != null ? cachedProviderName : resolveProviderName();
    return lookupProvider(name);
  }

  /** Read the provider name from DB settings → properties → hard default. */
  private String resolveProviderName() {
    if (settingService != null) {
      try {
        Object val = settingService.getValue(NOTIFICATION_GROUP, PROVIDER_KEY, "GLOBAL", null);
        if (val instanceof String s && !s.isBlank()) {
          return s.trim().toLowerCase();
        }
      } catch (NoSuchElementException ignored) {
        // SettingDef not seeded yet; fall through to properties.
      } catch (Exception e) {
        log.debug("[DynamicPushProvider] DB setting lookup failed (using property fallback): {}", e.getMessage());
      }
    }
    return propertyFallback != null ? propertyFallback.trim().toLowerCase() : "kafka";
  }

  /**
   * Looks up the concrete provider bean by name.  Falls back to {@link NullPushProvider}
   * if the requested provider is not registered (e.g. Firebase disabled and someone
   * tries to set provider=fcm).
   */
  private PushProvider lookupProvider(String name) {
    // Map setting values → bean types
    Map<String, Class<? extends PushProvider>> registry = Map.of(
        "fcm",   FirebasePushProvider.class,
        "kafka", KafkaPushProvider.class,
        "none",  NullPushProvider.class
    );

    Class<? extends PushProvider> type = registry.get(name);
    if (type == null) {
      log.warn("[DynamicPushProvider] Unknown provider '{}'; falling back to NullPushProvider", name);
      return safeGet(NullPushProvider.class);
    }

    try {
      return ctx.getBean(type);
    } catch (Exception e) {
      log.warn("[DynamicPushProvider] Provider bean '{}' not available ({}); falling back to NullPushProvider",
          name, e.getMessage());
      return safeGet(NullPushProvider.class);
    }
  }

  private PushProvider safeGet(Class<? extends PushProvider> type) {
    try {
      return ctx.getBean(type);
    } catch (Exception e) {
      // Last resort: inline no-op so we never NPE
      return payload -> {
        log.warn("[DynamicPushProvider] All providers unavailable; discarding: type={}", payload.getType());
        return true;
      };
    }
  }
}
