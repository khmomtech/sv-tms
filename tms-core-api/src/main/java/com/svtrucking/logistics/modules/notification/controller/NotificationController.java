package com.svtrucking.logistics.modules.notification.controller;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.modules.notification.dto.BroadcastNotificationRequest;
import com.svtrucking.logistics.modules.notification.dto.CreateNotificationRequest;
import com.svtrucking.logistics.modules.notification.dto.NotificationDTO;
import com.svtrucking.logistics.modules.notification.model.DriverNotification;
import com.svtrucking.logistics.modules.notification.service.AdminNotificationService;
import com.svtrucking.logistics.modules.notification.service.DriverNotificationService;
import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.springframework.data.domain.Page;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.bind.annotation.CrossOrigin;

@RestController
@RequestMapping({"/api/notifications", "/api/admin/notifications", "/api/driver/notifications"})
@CrossOrigin(origins = "*")
public class NotificationController {

  private final DriverNotificationService driverNotificationService;
  private final AdminNotificationService adminNotificationService;

  public NotificationController(
      DriverNotificationService driverNotificationService,
      AdminNotificationService adminNotificationService) {
    this.driverNotificationService = driverNotificationService;
    this.adminNotificationService = adminNotificationService;
  }

  // ============================================
  // 🔔 DRIVER NOTIFICATIONS
  // ============================================

  @PostMapping("/driver/send")
  public ResponseEntity<ApiResponse<String>> sendToDriver(
      @RequestBody CreateNotificationRequest payload) {
    try {
      driverNotificationService.sendNotification(payload);
      return ResponseEntity.ok(ApiResponse.success("Notification sent to driver"));
    } catch (Exception e) {
      return ResponseEntity.badRequest()
          .body(ApiResponse.fail("Failed to send notification: " + e.getMessage()));
    }
  }

  @PostMapping("/driver/broadcast")
  public ResponseEntity<ApiResponse<String>> broadcast(
      @RequestBody BroadcastNotificationRequest payload) {
    try {
      driverNotificationService.broadcastToTopic(payload);
      return ResponseEntity.ok(ApiResponse.success("Broadcast sent"));
    } catch (Exception e) {
      return ResponseEntity.badRequest()
          .body(ApiResponse.fail("Failed to broadcast: " + e.getMessage()));
    }
  }

  /**
   * List driver notifications. Params: - order: unreadFirst | newest (default: unreadFirst) -
   * unreadOnly: true|false (default: false) - since: ISO date-time (optional; incremental since
   * timestamp) - page, size
   */
  @GetMapping("/driver/{driverId}")
  public ResponseEntity<ApiResponse<Map<String, Object>>> getDriverNotifications(
      @PathVariable Long driverId,
      @RequestParam(defaultValue = "unreadFirst") String order,
      @RequestParam(defaultValue = "false") boolean unreadOnly,
      @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME)
          LocalDateTime since,
      @RequestParam(defaultValue = "0") int page,
      @RequestParam(defaultValue = "10") int size) {
    int safeSize = Math.min(Math.max(size, 1), 100);

    Page<DriverNotification> result;
    if (since != null) {
      result = driverNotificationService.getNewSince(driverId, since, page, safeSize);
    } else if (unreadOnly) {
      result = driverNotificationService.getUnreadNotifications(driverId, page, safeSize);
    } else if ("newest".equalsIgnoreCase(order)) {
      result = driverNotificationService.getNotificationsNewestFirst(driverId, page, safeSize);
    } else {
      result = driverNotificationService.getNotificationsUnreadFirst(driverId, page, safeSize);
    }

    List<NotificationDTO> content =
        result.getContent().stream().map(driverNotificationService::convertToDTO).toList();

    Map<String, Object> payload = new LinkedHashMap<>();
    payload.put("content", content);
    payload.put("page", result.getNumber());
    payload.put("size", result.getSize());
    payload.put("totalElements", result.getTotalElements());
    payload.put("totalPages", result.getTotalPages());
    payload.put("last", result.isLast());
    payload.put("order", order);
    payload.put("unreadOnly", unreadOnly);
    if (since != null) {
      payload.put("since", since);
    }
    payload.put("unreadCount", driverNotificationService.countUnread(driverId));

    return ResponseEntity.ok(ApiResponse.ok("Notifications loaded", payload));
  }

  /** Mark ONE notification as read (scoped by driver for safety). */
  @PutMapping("/driver/{driverId}/{notificationId}/read")
  public ResponseEntity<ApiResponse<String>> markAsRead(
      @PathVariable Long driverId, @PathVariable Long notificationId) {
    driverNotificationService.markAsRead(notificationId, driverId);
    return ResponseEntity.ok(ApiResponse.success("Notification marked as read"));
  }

  /** Legacy alias (kept): mark one as read without driverId (service will guard best-effort). */
  @PutMapping("/driver/{notificationId}/read")
  public ResponseEntity<ApiResponse<String>> markAsReadLegacy(@PathVariable Long notificationId) {
    driverNotificationService.markAsRead(notificationId, null);
    return ResponseEntity.ok(ApiResponse.success("Notification marked as read"));
  }

  @PatchMapping("/driver/{driverId}/mark-all-read")
  public ResponseEntity<ApiResponse<String>> markAllAsRead(@PathVariable Long driverId) {
    driverNotificationService.markAllAsReadByDriver(driverId);
    return ResponseEntity.ok(ApiResponse.success("All notifications marked as read"));
  }

  /** Delete ONE notification (scoped by driver for safety). */
  @DeleteMapping("/driver/{driverId}/{notificationId}")
  public ResponseEntity<ApiResponse<String>> deleteDriverNotification(
      @PathVariable Long driverId, @PathVariable Long notificationId) {
    driverNotificationService.deleteNotification(notificationId, driverId);
    return ResponseEntity.ok(ApiResponse.success("Notification deleted"));
  }

  /** Legacy alias (kept): delete by id only. */
  @DeleteMapping("/driver/{notificationId}")
  public ResponseEntity<ApiResponse<String>> deleteDriverNotificationLegacy(
      @PathVariable Long notificationId) {
    driverNotificationService.deleteNotification(notificationId, null);
    return ResponseEntity.ok(ApiResponse.success("Notification deleted"));
  }

  /** Delete ALL notifications for a driver (use carefully). */
  @DeleteMapping("/driver/{driverId}/all")
  public ResponseEntity<ApiResponse<String>> deleteAllForDriver(@PathVariable Long driverId) {
    driverNotificationService.deleteAllNotificationsForDriver(driverId);
    return ResponseEntity.ok(ApiResponse.success("All notifications deleted for driver"));
  }

  /** Delete only READ notifications for a driver. */
  @DeleteMapping("/driver/{driverId}/delete-read")
  public ResponseEntity<ApiResponse<String>> deleteReadForDriver(@PathVariable Long driverId) {
    driverNotificationService.deleteReadNotificationsForDriver(driverId);
    return ResponseEntity.ok(ApiResponse.success("All read notifications deleted for driver"));
  }

  /** Bulk delete notifications by IDs for a driver. Accepts {"ids":[...]} */
  @DeleteMapping("/driver/{driverId}/batch")
  public ResponseEntity<ApiResponse<String>> deleteBatchForDriver(
      @PathVariable Long driverId, @RequestBody IdsPayload payload) {
    driverNotificationService.deleteBatchForDriver(driverId, payload.ids());
    return ResponseEntity.ok(ApiResponse.success("Batch deletion completed"));
  }

  @GetMapping("/driver/{driverId}/count")
  public ResponseEntity<ApiResponse<Long>> countDriverUnread(@PathVariable Long driverId) {
    long count = driverNotificationService.countUnread(driverId);
    return ResponseEntity.ok(ApiResponse.ok("Unread count fetched", count));
  }

  // ============================================
  // 🛠️ ADMIN NOTIFICATIONS
  // ============================================

  @PostMapping("/admin/create")
  public ResponseEntity<ApiResponse<String>> createAdminNotification(
      @RequestBody CreateNotificationRequest payload) {
    adminNotificationService.saveNotification(
        payload.getTitle(),
        payload.getMessage(),
        payload.getType(),
        payload.getTopic(),
        payload.getReferenceId(),
        payload.getSeverity(),
        payload.getSender(),
        payload.getActionUrl(),
        payload.getActionLabel());

    // Optional bridge: also notify a specific driver if referenceId is a numeric driverId.
    try {
      if (payload.getReferenceId() != null && !payload.getReferenceId().isBlank()) {
        Long maybeDriverId = Long.valueOf(payload.getReferenceId());
        driverNotificationService.sendNotification(
            CreateNotificationRequest.builder()
                .driverId(maybeDriverId)
                .title(payload.getTitle())
                .message(payload.getMessage())
                .type(payload.getType() != null ? payload.getType() : "ADMIN")
                .referenceId(payload.getReferenceId())
                .sender(payload.getSender() != null ? payload.getSender() : "system")
                .build());
      }
    } catch (NumberFormatException ignore) {
      // referenceId isn’t a numeric driverId → skip driver push
    }

    return ResponseEntity.ok(ApiResponse.success("Admin notification created"));
  }

  @GetMapping("/admin")
  public ResponseEntity<ApiResponse<List<NotificationDTO>>> getAllAdminNotifications() {
    return ResponseEntity.ok(
        ApiResponse.ok("Admin notifications loaded", adminNotificationService.getAllAsDTOs()));
  }

  @GetMapping("/admin/count")
  public ResponseEntity<ApiResponse<Long>> countUnreadAdminNotifications() {
    long count = adminNotificationService.countUnread();
    return ResponseEntity.ok(ApiResponse.ok("Unread count fetched", count));
  }

  // (kept for compatibility; same as /admin/count)
  @GetMapping("/admin/unread")
  public ResponseEntity<ApiResponse<Long>> countUnreadsAdminNotifications() {
    long count = adminNotificationService.countUnread();
    return ResponseEntity.ok(ApiResponse.ok("Unread count fetched", count));
  }

  @PutMapping("/admin/{id}/read")
  public ResponseEntity<ApiResponse<String>> markAdminAsRead(@PathVariable Long id) {
    adminNotificationService.markAsRead(id);
    return ResponseEntity.ok(ApiResponse.success("Marked as read"));
  }

  @PatchMapping("/admin/mark-all-read")
  public ResponseEntity<ApiResponse<String>> markAllAdminAsRead() {
    adminNotificationService.markAllAsRead();
    return ResponseEntity.ok(ApiResponse.success("All marked as read"));
  }

  @DeleteMapping("/admin/{id}")
  public ResponseEntity<ApiResponse<String>> deleteAdminNotification(@PathVariable Long id) {
    adminNotificationService.delete(id);
    return ResponseEntity.ok(ApiResponse.success("Deleted"));
  }

  @DeleteMapping("/admin/all")
  public ResponseEntity<ApiResponse<String>> deleteAllAdminNotifications() {
    adminNotificationService.clearAll();
    return ResponseEntity.ok(ApiResponse.success("All admin notifications cleared"));
  }

  // ============================================
  // 🔧 Request payloads
  // ============================================

  /** JSON shape: {"ids":[1,2,3]} */
  public record IdsPayload(List<Long> ids) {}
}
