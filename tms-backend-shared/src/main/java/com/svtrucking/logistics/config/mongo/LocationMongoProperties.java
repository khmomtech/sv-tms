package com.svtrucking.logistics.config.mongo;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;

@Getter
@Setter
@ConfigurationProperties(prefix = "location.mongo")
public class LocationMongoProperties {
  private boolean enabled = false;
  private String uri;
  private String database = "sv_tms";
  private int ttlDays = 0;
}
