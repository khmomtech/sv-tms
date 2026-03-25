package com.svtrucking.logistics.auth;

import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.messaging.MessageChannel;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.messaging.support.ExecutorSubscribableChannel;

@Configuration
public class AuthApiMessagingFallbackConfig {

  @Bean
  @ConditionalOnMissingBean(SimpMessagingTemplate.class)
  public SimpMessagingTemplate simpMessagingTemplate() {
    MessageChannel channel = new ExecutorSubscribableChannel();
    return new SimpMessagingTemplate(channel);
  }
}
