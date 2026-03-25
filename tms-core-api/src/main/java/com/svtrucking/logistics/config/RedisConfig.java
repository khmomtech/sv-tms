package com.svtrucking.logistics.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnExpression;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.redis.cache.RedisCacheConfiguration;
import org.springframework.data.redis.cache.RedisCacheManager;
import org.springframework.data.redis.connection.RedisConnectionFactory;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.serializer.GenericJackson2JsonRedisSerializer;
import org.springframework.data.redis.serializer.JdkSerializationRedisSerializer;
import org.springframework.data.redis.serializer.StringRedisSerializer;

import java.time.Duration;

/**
 * Redis configuration for live driver location caching.
 * Provides high-performance caching layer to reduce database load.
 * Disabled when spring.data.redis.host='disabled' in test profile.
 */
@Configuration
@EnableCaching
@ConditionalOnExpression("!'${spring.data.redis.host:}'.equals('disabled')")
public class RedisConfig {

        @Value("${app.cache.live-location.ttl:300000}")
        private long liveLocationTtlMs;

        @Bean
        public RedisTemplate<String, Object> redisTemplate(RedisConnectionFactory connectionFactory) {
                RedisTemplate<String, Object> template = new RedisTemplate<>();
                template.setConnectionFactory(connectionFactory);

                // Use String serializer for keys
                template.setKeySerializer(new StringRedisSerializer());
                template.setHashKeySerializer(new StringRedisSerializer());

                // Use JSON serializer for values with JSR310 support
                ObjectMapper objectMapper = new ObjectMapper();
                objectMapper.registerModule(new JavaTimeModule());
                GenericJackson2JsonRedisSerializer serializer = new GenericJackson2JsonRedisSerializer(objectMapper);

                template.setValueSerializer(serializer);
                template.setHashValueSerializer(serializer);

                template.afterPropertiesSet();
                return template;
        }

        @Bean
        public RedisCacheManager cacheManager(RedisConnectionFactory connectionFactory) {
                // Create ObjectMapper with JSR310 support for cache serialization
                ObjectMapper objectMapper = new ObjectMapper();
                objectMapper.registerModule(new JavaTimeModule());
                GenericJackson2JsonRedisSerializer serializer = new GenericJackson2JsonRedisSerializer(objectMapper);

                // Default cache configuration
                RedisCacheConfiguration defaultConfig = RedisCacheConfiguration.defaultCacheConfig()
                                .entryTtl(Duration.ofMillis(liveLocationTtlMs))
                                .serializeKeysWith(
                                                org.springframework.data.redis.serializer.RedisSerializationContext.SerializationPair
                                                                .fromSerializer(new StringRedisSerializer()))
                                .serializeValuesWith(
                                                org.springframework.data.redis.serializer.RedisSerializationContext.SerializationPair
                                                                .fromSerializer(serializer));

                // Specific cache configurations with appropriate TTLs
                java.util.Map<String, RedisCacheConfiguration> cacheConfigurations = new java.util.HashMap<>();

                // Vehicle-related caches (5 minutes TTL)
                RedisCacheConfiguration vehicleCacheConfig = defaultConfig.entryTtl(Duration.ofMinutes(5));
                cacheConfigurations.put("vehicles", vehicleCacheConfig);
                cacheConfigurations.put("allVehicles", vehicleCacheConfig);
                cacheConfigurations.put("vehicleStats", vehicleCacheConfig);

                // Driver-related caches (5 minutes TTL)
                RedisCacheConfiguration driverCacheConfig = defaultConfig.entryTtl(Duration.ofMinutes(5));
                cacheConfigurations.put("drivers", driverCacheConfig);
                cacheConfigurations.put("driverStats", driverCacheConfig);

                // Settings caches (10 minutes TTL - settings change infrequently)
                RedisCacheConfiguration settingsCacheConfig = defaultConfig.entryTtl(Duration.ofMinutes(10));
                cacheConfigurations.put("settings", settingsCacheConfig);
                cacheConfigurations.put("settings_defs", settingsCacheConfig);

                // Live location cache (5 minutes TTL from config)
                cacheConfigurations.put("liveLocations", defaultConfig);

                // Spring Security UserDetails must round-trip as the concrete type, not as a
                // generic JSON map, otherwise JwtAuthFilter gets LinkedHashMap from Redis.
                RedisCacheConfiguration userDetailsCacheConfig = defaultConfig
                                .entryTtl(Duration.ofMinutes(5))
                                .serializeValuesWith(
                                                org.springframework.data.redis.serializer.RedisSerializationContext.SerializationPair
                                                                .fromSerializer(new JdkSerializationRedisSerializer()));
                cacheConfigurations.put("userDetails", userDetailsCacheConfig);

                return RedisCacheManager.builder(connectionFactory)
                                .cacheDefaults(defaultConfig)
                                .withInitialCacheConfigurations(cacheConfigurations)
                                .build();
        }
}
