package com.svtrucking.logistics;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.PropertySource;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.FilterType;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@ComponentScan(basePackages = "com.svtrucking.logistics",
  excludeFilters = {
    @ComponentScan.Filter(type = FilterType.REGEX, pattern = "com\\.svtrucking\\.logistics\\.modules\\.khbupload\\..*"),
    @ComponentScan.Filter(type = FilterType.REGEX, pattern = "com\\.svtrucking\\.logistics\\.config\\.Test.*")
  })
@EnableScheduling
// @EnableJpaAuditing
@PropertySource(value = "classpath:application-uploads.properties", ignoreResourceNotFound = true)
@EnableJpaRepositories(basePackages = {
    "com.svtrucking.logistics.repository",
    "com.svtrucking.logistics.modules.notification.repository",
    "com.svtrucking.logistics.settings.repository"
})
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
