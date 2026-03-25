package com.svtrucking.logistics;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.PropertySource;
import org.springframework.boot.autoconfigure.domain.EntityScan;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;

@SpringBootApplication
// @EnableScheduling
// @EnableJpaAuditing
@PropertySource("classpath:application-uploads.properties")
@EntityScan(basePackages = {"com.svtrucking.logistics.identity.domain", "com.svtrucking.logistics.safety.domain"})
@EnableJpaRepositories(
    basePackages = {"com.svtrucking.logistics.identity.repository", "com.svtrucking.logistics.safety.repository"})
public class Application {
  public static void main(String[] args) {
    SpringApplication.run(Application.class, args);
  }
  
  /**
   * Redis repository configuration disabled.
   * Redis is used only for caching via @Cacheable annotations, not as a data store.
   * This prevents unnecessary repository scanning warnings on startup.
   */
  // @Profile("!test")
  // @EnableRedisRepositories(basePackages = "com.svtrucking.logistics.redis")
  // static class RedisRepositoryConfig {
  // }
}
