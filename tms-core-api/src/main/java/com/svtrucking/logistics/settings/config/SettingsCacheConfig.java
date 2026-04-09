package com.svtrucking.logistics.settings.config;

import org.springframework.context.annotation.Configuration;

/**
 * Settings cache configuration.
 * Cache management is now handled centrally by RedisConfig.
 * The caches 'settings' and 'settings_defs' are configured in RedisConfig.
 */
@Configuration
public class SettingsCacheConfig {
  // Caching is enabled globally by RedisConfig
  // No separate CacheManager needed - using the Redis-based cache manager
}
