package com.svtrucking.logistics.controller.drivers;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.dto.requests.*;
import jakarta.validation.Valid;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.core.io.Resource;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;

/**
 * Legacy driver controller - methods moved to specialized controllers.
 * This controller is deprecated and will be removed in future versions.
 * Use the specific controllers instead:
 * - DriverManagementController for CRUD operations
 * - DriverNotificationController for notifications
 * - DriverDocumentController for documents
 * - DriverLocationAdminController for location history
 * - DriverAssignmentController for assignments
 */
@RestController
@ConditionalOnProperty(name = "app.legacy-controllers.enabled", havingValue = "true", matchIfMissing = false)
@RequestMapping("/api/admin/legacy/drivers")
@CrossOrigin(origins = "*")
@Slf4j
@Deprecated
public class DriverController {

  // All functionality has been moved to specialized controllers
  // This class is kept for backward compatibility during transition

  /**
   * @deprecated Use DriverManagementController.addDriver instead
   */
  @PostMapping("/add")
  @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
  @Deprecated
  public ResponseEntity<ApiResponse<String>> addDriver(@Valid @RequestBody DriverCreateRequest request) {
    return ResponseEntity.status(HttpStatus.GONE)
        .body(ApiResponse.fail("This endpoint has been moved to DriverManagementController"));
  }

  /**
   * @deprecated Use DriverManagementController.getAllDrivers instead
   */
  @GetMapping("/list")
  @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_VIEW_ALL) " +
                "or @authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
  @Deprecated
  public ResponseEntity<ApiResponse<String>> getAllDrivers() {
    return ResponseEntity.status(HttpStatus.GONE)
        .body(ApiResponse.fail("This endpoint has been moved to DriverManagementController"));
  }

  /**
   * @deprecated Use DriverManagementController.getAllDriversNoPag instead
   */
  @GetMapping("/all")
  @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_VIEW_ALL) " +
                "or @authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
  @Deprecated
  public ResponseEntity<ApiResponse<String>> getAllDriversNoPag() {
    return ResponseEntity.status(HttpStatus.GONE)
        .body(ApiResponse.fail("This endpoint has been moved to DriverManagementController"));
  }

  /**
   * @deprecated Use DriverManagementController.searchDrivers instead
   */
  @GetMapping("/search")
  @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_VIEW_ALL) " +
                "or @authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
  @Deprecated
  public ResponseEntity<ApiResponse<String>> searchDrivers() {
    return ResponseEntity.status(HttpStatus.GONE)
        .body(ApiResponse.fail("This endpoint has been moved to DriverManagementController"));
  }

  /**
   * @deprecated Use DriverManagementController.getDriverById instead
   */
  @GetMapping("/{id}")
  @Deprecated
  public ResponseEntity<ApiResponse<String>> getDriverById() {
    return ResponseEntity.status(HttpStatus.GONE)
        .body(ApiResponse.fail("This endpoint has been moved to DriverManagementController"));
  }

  /**
   * @deprecated Use DriverManagementController.updateDriver instead
   */
  @PutMapping("/update/{id}")
  @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
  @Deprecated
  public ResponseEntity<ApiResponse<String>> updateDriver() {
    return ResponseEntity.status(HttpStatus.GONE)
        .body(ApiResponse.fail("This endpoint has been moved to DriverManagementController"));
  }

  /**
   * @deprecated Use DriverManagementController.deleteDriver instead
   */
  @DeleteMapping("/delete/{id}")
  @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
  @Deprecated
  public ResponseEntity<ApiResponse<String>> deleteDriver() {
    return ResponseEntity.status(HttpStatus.GONE)
        .body(ApiResponse.fail("This endpoint has been moved to DriverManagementController"));
  }

  /**
   * @deprecated Use DriverNotificationAdminController.sendNotification instead
   */
  @PostMapping("/send-notification")
  @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
  @Deprecated
  public ResponseEntity<ApiResponse<String>> sendNotification() {
    return ResponseEntity.status(HttpStatus.GONE)
        .body(ApiResponse.fail("This endpoint has been moved to DriverNotificationAdminController"));
  }

  /**
   * @deprecated Use DriverNotificationAdminController.broadcastNotification instead
   */
  @PostMapping("/broadcast-notification")
  @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
  @Deprecated
  public ResponseEntity<ApiResponse<String>> broadcastNotification() {
    return ResponseEntity.status(HttpStatus.GONE)
        .body(ApiResponse.fail("This endpoint has been moved to DriverNotificationAdminController"));
  }

  /**
   * @deprecated Use DriverNotificationAdminController.forceOpenDriverApp instead
   */
  @PostMapping("/{driverId}/force-open")
  @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
  @Deprecated
  public ResponseEntity<ApiResponse<String>> forceOpenDriverApp() {
    return ResponseEntity.status(HttpStatus.GONE)
        .body(ApiResponse.fail("This endpoint has been moved to DriverNotificationAdminController"));
  }

  /**
   * @deprecated Use DriverNotificationAdminController.getDriverNotifications instead
   */
  @GetMapping("/{driverId}/notifications")
  @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_VIEW_ALL) " +
                "or @authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
  @Deprecated
  public ResponseEntity<ApiResponse<String>> getDriverNotifications() {
    return ResponseEntity.status(HttpStatus.GONE)
        .body(ApiResponse.fail("This endpoint has been moved to DriverNotificationAdminController"));
  }

  /**
   * @deprecated Use DriverNotificationAdminController.markAsRead instead
   */
  @PutMapping("/{driverId}/notifications/{notificationId}/read")
  @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
  @Deprecated
  public ResponseEntity<ApiResponse<String>> markAsRead() {
    return ResponseEntity.status(HttpStatus.GONE)
        .body(ApiResponse.fail("This endpoint has been moved to DriverNotificationAdminController"));
  }

  /**
   * @deprecated Use DriverNotificationAdminController.markAllAsRead instead
   */
  @PatchMapping("/{driverId}/notifications/mark-all-read")
  @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
  @Deprecated
  public ResponseEntity<ApiResponse<String>> markAllAsRead() {
    return ResponseEntity.status(HttpStatus.GONE)
        .body(ApiResponse.fail("This endpoint has been moved to DriverNotificationAdminController"));
  }

  /**
   * @deprecated Use DriverNotificationAdminController.deleteDriverNotification instead
   */
  @DeleteMapping("/{driverId}/notifications/{notificationId}")
  @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
  @Deprecated
  public ResponseEntity<ApiResponse<String>> deleteDriverNotification() {
    return ResponseEntity.status(HttpStatus.GONE)
        .body(ApiResponse.fail("This endpoint has been moved to DriverNotificationAdminController"));
  }

  /**
   * @deprecated Use DriverManagementController.advancedSearchDrivers instead
   */
  @PostMapping("/advanced-search")
  @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_VIEW_ALL) " +
                "or @authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
  @Deprecated
  public ResponseEntity<ApiResponse<String>> advancedSearchDrivers() {
    return ResponseEntity.status(HttpStatus.GONE)
        .body(ApiResponse.fail("This endpoint has been moved to DriverManagementController"));
  }

  /**
   * @deprecated Use DriverLocationAdminController.getDriverLocationHistory instead
   */
  @GetMapping("/{id}/location-history")
  @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_VIEW_ALL) " +
                "or @authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
  @Deprecated
  public ResponseEntity<ApiResponse<String>> getDriverLocationHistory() {
    return ResponseEntity.status(HttpStatus.GONE)
        .body(ApiResponse.fail("This endpoint has been moved to DriverLocationAdminController"));
  }

  /**
   * @deprecated Use DriverLocationAdminController.getDriverLocationHistoryPaginated instead
   */
  @GetMapping("/{driverId}/location-history/paginated")
  @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_VIEW_ALL) " +
                "or @authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
  @Deprecated
  public ResponseEntity<ApiResponse<String>> getDriverLocationHistoryPaginated() {
    return ResponseEntity.status(HttpStatus.GONE)
        .body(ApiResponse.fail("This endpoint has been moved to DriverLocationAdminController"));
  }

  /**
   * @deprecated Use DriverManagementController.uploadProfilePictureAdmin instead
   */
  @PostMapping(path = "/{driverId}/upload-profile", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
  @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
  @Deprecated
  public ResponseEntity<ApiResponse<String>> uploadProfilePictureAdmin() {
    return ResponseEntity.status(HttpStatus.GONE)
        .body(ApiResponse.fail("This endpoint has been moved to DriverManagementController"));
  }

  /**
   * @deprecated Use DriverManagementController.updateDeviceToken instead
   */
  @PostMapping("/update-device-token")
  @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
  @Deprecated
  public ResponseEntity<ApiResponse<String>> updateDeviceToken() {
    return ResponseEntity.status(HttpStatus.GONE)
        .body(ApiResponse.fail("This endpoint has been moved to DriverManagementController"));
  }

  /**
   * @deprecated Use DriverManagementController.getDeviceToken instead
   */
  @GetMapping("/{id}/device-token")
  @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_VIEW_ALL) " +
                "or @authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
  @Deprecated
  public ResponseEntity<ApiResponse<String>> getDeviceToken() {
    return ResponseEntity.status(HttpStatus.GONE)
        .body(ApiResponse.fail("This endpoint has been moved to DriverManagementController"));
  }

  /**
   * @deprecated Use DriverManagementController.driverHeartbeat instead
   */
  @PostMapping("/{driverId}/heartbeat")
  @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
  @Deprecated
  public ResponseEntity<ApiResponse<String>> driverHeartbeat() {
    return ResponseEntity.status(HttpStatus.GONE)
        .body(ApiResponse.fail("This endpoint has been moved to DriverManagementController"));
  }

  // ==================== DRIVER DOCUMENTS ENDPOINTS ====================

  /**
   * @deprecated Use DriverDocumentController.updateDocument instead
   */
  @PutMapping("/documents/{documentId}")
  @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
  @Deprecated
  public ResponseEntity<ApiResponse<String>> updateDocument() {
    return ResponseEntity.status(HttpStatus.GONE)
        .body(ApiResponse.fail("This endpoint has been moved to DriverDocumentController"));
  }

  /**
   * @deprecated Use DriverDocumentController.deleteDocument instead
   */
  @DeleteMapping("/documents/{documentId}")
  @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
  @Deprecated
  public ResponseEntity<ApiResponse<String>> deleteDocument() {
    return ResponseEntity.status(HttpStatus.GONE)
        .body(ApiResponse.fail("This endpoint has been moved to DriverDocumentController"));
  }

  /**
   * @deprecated Use DriverDocumentController.getDocumentsByCategory instead
   */
  @GetMapping("/{driverId}/documents/category/{category}")
  @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_VIEW_ALL) " +
                "or @authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
  @Deprecated
  public ResponseEntity<ApiResponse<String>> getDocumentsByCategory() {
    return ResponseEntity.status(HttpStatus.GONE)
        .body(ApiResponse.fail("This endpoint has been moved to DriverDocumentController"));
  }

  /**
   * @deprecated Use DriverDocumentController.getExpiredDocuments instead
   */
  @GetMapping("/{driverId}/documents/expired")
  @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_VIEW_ALL) " +
                "or @authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
  @Deprecated
  public ResponseEntity<ApiResponse<String>> getExpiredDocuments() {
    return ResponseEntity.status(HttpStatus.GONE)
        .body(ApiResponse.fail("This endpoint has been moved to DriverDocumentController"));
  }

  /**
   * @deprecated Use DriverDocumentController.getExpiringDocuments instead
   */
  @GetMapping("/{driverId}/documents/expiring")
  @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_VIEW_ALL) " +
                "or @authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
  @Deprecated
  public ResponseEntity<ApiResponse<String>> getExpiringDocuments() {
    return ResponseEntity.status(HttpStatus.GONE)
        .body(ApiResponse.fail("This endpoint has been moved to DriverDocumentController"));
  }

  /**
   * @deprecated Use DriverDocumentController.getRequiredDocuments instead
   */
  @GetMapping("/{driverId}/documents/required")
  @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_VIEW_ALL) " +
                "or @authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
  @Deprecated
  public ResponseEntity<ApiResponse<String>> getRequiredDocuments() {
    return ResponseEntity.status(HttpStatus.GONE)
        .body(ApiResponse.fail("This endpoint has been moved to DriverDocumentController"));
  }

  /**
   * @deprecated Use DriverDocumentController.uploadDocument instead
   */
  @PostMapping("/{driverId}/documents/upload")
  @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
  @Deprecated
  public ResponseEntity<ApiResponse<String>> uploadDocument() {
    return ResponseEntity.status(HttpStatus.GONE)
        .body(ApiResponse.fail("This endpoint has been moved to DriverDocumentController"));
  }

  /**
   * @deprecated Use DriverDocumentController.downloadDriverDocument instead
   */
  @GetMapping("/{driverId}/documents/{documentId}/download")
  @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_VIEW_ALL) " +
                "or @authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
  @Deprecated
  public ResponseEntity<Resource> downloadDriverDocument() {
    return ResponseEntity.status(HttpStatus.GONE).build();
  }

  /**
   * @deprecated Use DriverDocumentController.getDocumentAudit instead
   */
  @GetMapping("/{driverId}/documents/{documentId}/audit")
  @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_VIEW_ALL) " +
                "or @authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
  @Deprecated
  public ResponseEntity<ApiResponse<String>> getDocumentAudit() {
    return ResponseEntity.status(HttpStatus.GONE)
        .body(ApiResponse.fail("This endpoint has been moved to DriverDocumentController"));
  }
}
