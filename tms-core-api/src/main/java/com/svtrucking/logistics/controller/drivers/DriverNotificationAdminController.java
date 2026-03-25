package com.svtrucking.logistics.controller.drivers;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.dto.DriverNotificationDto;
import com.svtrucking.logistics.modules.notification.dto.BroadcastNotificationRequest;
import com.svtrucking.logistics.modules.notification.dto.CreateNotificationRequest;
import com.svtrucking.logistics.modules.notification.model.DriverNotification;
import com.svtrucking.logistics.modules.notification.service.DriverNotificationService;
import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * Controller for driver notification operations.
 * Separated from DriverController to follow Single Responsibility Principle.
 */
@RestController
@RequestMapping("/api/admin/drivers")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
@Slf4j
public class DriverNotificationAdminController {

  private final DriverNotificationService notificationService;

  /**
   * Send notification to a specific driver.
   */
  @PostMapping("/send-notification")
  @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
  public ResponseEntity<ApiResponse<String>> sendNotification(@RequestBody CreateNotificationRequest request) {
    try {
      if (request.getDriverId() == null) {
        return ResponseEntity.badRequest().body(ApiResponse.fail("driverId is required"));
      }
      notificationService.sendNotification(request);
      return ResponseEntity.ok(ApiResponse.success("Notification sent"));
    } catch (Exception e) {
      log.error("Error sending notification: {}", e.getMessage(), e);
      return ResponseEntity.status(HttpStatus.BAD_REQUEST)
          .body(ApiResponse.fail(e.getMessage()));
    }
  }

  /**
   * Broadcast notification to all drivers or topic subscribers.
   */
  @PostMapping("/broadcast-notification")
  @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
  public ResponseEntity<ApiResponse<String>> broadcastNotification(@RequestBody BroadcastNotificationRequest request) {
    try {
      if (request.getTopic() == null || request.getTopic().isBlank()) {
        return ResponseEntity.badRequest().body(ApiResponse.fail("topic is required"));
      }
      notificationService.broadcastToTopic(request);
      return ResponseEntity.ok(ApiResponse.success("Broadcast queued"));
    } catch (Exception e) {
      log.error("Error broadcasting notification: {}", e.getMessage(), e);
      return ResponseEntity.status(HttpStatus.BAD_REQUEST)
          .body(ApiResponse.fail(e.getMessage()));
    }
  }

  /**
   * Force open driver app by sending FCM command.
   */
  @PostMapping("/{driverId}/force-open")
  @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
  public ResponseEntity<ApiResponse<String>> forceOpenDriverApp(@PathVariable Long driverId) {
    try {
      // Ensure driver exists (throws if not found)
      notificationService.getDriverById(driverId);

      CreateNotificationRequest req = CreateNotificationRequest.builder()
          .driverId(driverId)
          .title("Reconnect service")
          .message("System request to (re)start.")
          .type("FORCE_OPEN")
          .referenceId("force-open-" + System.currentTimeMillis())
          .sender("admin")
          .build();
      notificationService.sendNotification(req);

      return ResponseEntity.ok(ApiResponse.success("Force-open command sent"));
    } catch (Exception e) {
      log.error("Error sending force-open command to driver {}: {}", driverId, e.getMessage(), e);
      return ResponseEntity.status(HttpStatus.BAD_REQUEST)
          .body(ApiResponse.fail("Failed to send force-open: " + e.getMessage()));
    }
  }

  /**
   * Get driver notifications with pagination and filtering.
   */
  @GetMapping("/{driverId}/notifications")
  @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_VIEW_ALL) " +
                "or @authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
  public ResponseEntity<ApiResponse<Map<String, Object>>> getDriverNotifications(
      @PathVariable Long driverId,
      @RequestParam(defaultValue = "unreadFirst") String order,
      @RequestParam(defaultValue = "false") boolean unreadOnly,
      @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime since,
      @RequestParam(defaultValue = "0") int page,
      @RequestParam(defaultValue = "10") int size) {
    try {
      int safeSize = Math.min(Math.max(size, 1), 100);

      Page<DriverNotification> pageResult;
      if (since != null) {
        pageResult = notificationService.getNewSince(driverId, since, page, safeSize);
      } else if (unreadOnly) {
        pageResult = notificationService.getUnreadNotifications(driverId, page, safeSize);
      } else if ("newest".equalsIgnoreCase(order)) {
        pageResult = notificationService.getNotificationsNewestFirst(driverId, page, safeSize);
      } else {
        pageResult = notificationService.getNotificationsUnreadFirst(driverId, page, safeSize);
      }

      List<DriverNotificationDto> dtoList = pageResult.getContent().stream()
          .map(DriverNotificationDto::fromEntity)
          .toList();

      long unreadCount = notificationService.countUnread(driverId);

      Map<String, Object> responseData = new LinkedHashMap<>();
      responseData.put("content", dtoList);
      responseData.put("page", pageResult.getNumber());
      responseData.put("size", pageResult.getSize());
      responseData.put("totalElements", pageResult.getTotalElements());
      responseData.put("totalPages", pageResult.getTotalPages());
      responseData.put("last", pageResult.isLast());
      responseData.put("order", order);
      responseData.put("unreadOnly", unreadOnly);
      if (since != null) {
        responseData.put("since", since);
      }
      responseData.put("unreadCount", unreadCount);

      return ResponseEntity.ok(ApiResponse.success("Notifications loaded", responseData));
    } catch (Exception e) {
      log.error("Error loading notifications for driver {}: {}", driverId, e.getMessage(), e);
      return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
          .body(ApiResponse.fail("Failed to load notifications: " + e.getMessage()));
    }
  }

  /**
   * Mark notification as read.
   */
  @PutMapping("/{driverId}/notifications/{notificationId}/read")
  @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
  public ResponseEntity<ApiResponse<String>> markAsRead(
      @PathVariable Long driverId, @PathVariable Long notificationId) {
    try {
      notificationService.markAsRead(notificationId, driverId);
      return ResponseEntity.ok(ApiResponse.success("Notification marked as read"));
    } catch (Exception e) {
      log.error("Error marking notification as read: {}", e.getMessage(), e);
      return ResponseEntity.status(HttpStatus.BAD_REQUEST)
          .body(ApiResponse.fail(e.getMessage()));
    }
  }

  /**
   * Mark notification as read (legacy endpoint without driverId).
   */
  @PutMapping("/notifications/{notificationId}/read")
  @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
  public ResponseEntity<ApiResponse<String>> markAsReadLegacy(@PathVariable Long notificationId) {
    try {
      notificationService.markAsRead(notificationId, null);
      return ResponseEntity.ok(ApiResponse.success("Notification marked as read"));
    } catch (Exception e) {
      log.error("Error marking notification as read (legacy): {}", e.getMessage(), e);
      return ResponseEntity.status(HttpStatus.BAD_REQUEST)
          .body(ApiResponse.fail(e.getMessage()));
    }
  }

  /**
   * Mark all notifications as read for a driver.
   */
  @PatchMapping("/{driverId}/notifications/mark-all-read")
  @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
  public ResponseEntity<ApiResponse<String>> markAllAsRead(@PathVariable Long driverId) {
    try {
      notificationService.markAllAsReadByDriver(driverId);
      return ResponseEntity.ok(ApiResponse.success("All notifications marked as read"));
    } catch (Exception e) {
      log.error("Error marking all notifications as read for driver {}: {}", driverId, e.getMessage(), e);
      return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
          .body(ApiResponse.fail("Failed to mark notifications as read: " + e.getMessage()));
    }
  }

  /**
   * Delete driver notification.
   */
  @DeleteMapping("/{driverId}/notifications/{notificationId}")
  @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
  public ResponseEntity<ApiResponse<String>> deleteDriverNotification(
      @PathVariable Long driverId, @PathVariable Long notificationId) {
    try {
      notificationService.deleteNotification(notificationId, driverId);
      return ResponseEntity.ok(ApiResponse.success("Notification deleted"));
    } catch (Exception e) {
      log.error("Error deleting notification: {}", e.getMessage(), e);
      return ResponseEntity.status(HttpStatus.BAD_REQUEST)
          .body(ApiResponse.fail(e.getMessage()));
    }
  }
}
