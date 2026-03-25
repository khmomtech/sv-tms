package com.svtrucking.logistics.modules.notification.controller;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.modules.notification.queue.NotificationQueueService;
import java.util.Map;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Admin endpoints for inspecting the notification queue state.
 */
@RestController
@RequestMapping("/api/admin/notification-queue")
@ConditionalOnProperty(name = "notification.queue.enabled", havingValue = "true")
public class NotificationQueueController {

  @org.springframework.beans.factory.annotation.Autowired(required = false)
  private NotificationQueueService queueService;

  @GetMapping("/status")
  public ResponseEntity<ApiResponse<Map<String, Object>>> status() {
    if (queueService == null) {
      return ResponseEntity.status(503).body(ApiResponse.fail("Notification queue is unavailable"));
    }
    long depth = queueService.queueDepth();
    boolean enabled = queueService.isEnabled();
    Map<String, Object> payload = Map.of(
        "enabled", enabled,
        "depth", depth
    );
    return ResponseEntity.ok(ApiResponse.ok("Notification queue status", payload));
  }

  @DeleteMapping("/purge")
  public ResponseEntity<ApiResponse<String>> purge() {
    if (queueService == null) {
      return ResponseEntity.status(503).body(ApiResponse.fail("Notification queue is unavailable"));
    }
    long removed = queueService.purgeAll();
    return ResponseEntity.ok(ApiResponse.success("Purged notification queue", String.valueOf(removed)));
  }
}
