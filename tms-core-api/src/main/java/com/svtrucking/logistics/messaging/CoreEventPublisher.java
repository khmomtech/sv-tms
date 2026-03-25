package com.svtrucking.logistics.messaging;

import com.svtrucking.tms.events.AuditEvent;
import com.svtrucking.tms.events.DispatchEvent;
import com.svtrucking.tms.events.DriverEvent;
import com.svtrucking.tms.events.EventTopics;
import com.svtrucking.tms.events.NotificationEvent;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;
import lombok.extern.slf4j.Slf4j;

@Service
@Slf4j
public class CoreEventPublisher {

  private final KafkaTemplate<String, Object> kafkaTemplate;
  private final boolean kafkaPublishingEnabled;

  public CoreEventPublisher(
      ObjectProvider<KafkaTemplate<String, Object>> kafkaTemplateProvider,
      @Value("${app.messaging.kafka.enabled:false}") boolean kafkaPublishingEnabled) {
    this.kafkaTemplate = kafkaTemplateProvider.getIfAvailable();
    this.kafkaPublishingEnabled = kafkaPublishingEnabled;
  }

  public void publishNotification(String key, NotificationEvent event) {
    send(EventTopics.NOTIFICATION_EVENTS, key, event);
  }

  public void publishDriver(String key, DriverEvent event) {
    send(EventTopics.DRIVER_EVENTS, key, event);
  }

  public void publishDispatch(String key, DispatchEvent event) {
    send(EventTopics.DISPATCH_EVENTS, key, event);
  }

  public void publishAudit(String key, AuditEvent event) {
    send(EventTopics.SYSTEM_AUDIT_EVENTS, key, event);
  }

  private void send(String topic, String key, Object payload) {
    if (!kafkaPublishingEnabled || kafkaTemplate == null || payload == null) {
      return;
    }
    try {
      kafkaTemplate.send(topic, key, payload);
    } catch (Exception ex) {
      log.warn("Kafka publish skipped for topic={} key={}: {}", topic, key, ex.getMessage());
    }
  }
}
