package com.svtrucking.logistics.controller.drivers;

import com.svtrucking.logistics.application.driver.DriverAppService;
import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.dto.*;
import com.svtrucking.logistics.dto.requests.*;
import com.svtrucking.logistics.exception.DriverNotFoundException;
// import com.svtrucking.logistics.model.AssignmentVehicleToDriver; // Legacy, safe to remove
import com.svtrucking.logistics.modules.notification.dto.BroadcastNotificationRequest;
import com.svtrucking.logistics.modules.notification.dto.CreateNotificationRequest;
import com.svtrucking.logistics.modules.notification.model.DriverNotification;
import com.svtrucking.logistics.modules.notification.service.DriverNotificationService;
import com.svtrucking.logistics.security.AuthenticatedUserUtil;
import com.svtrucking.logistics.service.*;
import jakarta.validation.Valid;
import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
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
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequestMapping("/api/driver")
@CrossOrigin(origins = "*")
@Slf4j
public class DriverVTwoController {

    private final DriverAppService driverAppService;
    private final DriverService driverService;
    private final DriverNotificationService notificationService;
    private final LiveDriverQueryService liveDriverQueryService;
    private final DriverLocationService driverLocationService;
    private final LocationIngestService ingest;
    private final DriverTrackingSessionService trackingSessionService;

    public DriverVTwoController(
            DriverAppService driverAppService,
            DriverService driverService,
            DriverNotificationService notificationService,
            LiveDriverQueryService liveDriverQueryService,
            DriverLocationService driverLocationService,
            AuthenticatedUserUtil authUtil,
            LocationIngestService ingest,
            DriverTrackingSessionService trackingSessionService) {
        this.driverAppService = driverAppService;
        this.driverService = driverService;
        this.notificationService = notificationService;
        this.liveDriverQueryService = liveDriverQueryService;
        this.driverLocationService = driverLocationService;
        this.ingest = ingest;
        this.trackingSessionService = trackingSessionService;
    }

    /**
     * Normalize and validate an incoming location update before ingestion. -
     * Ensures required fields
     * are present and within bounds - Clamps or nulls obviously bad telemetry
     */
    private void sanitizeUpdate(DriverLocationUpdateDto update) {
        if (update == null) {
            throw new IllegalArgumentException("Update body is required");
        }
        // Latitude/Longitude must exist and be within valid ranges
        if (update.getLatitude() == null || update.getLongitude() == null) {
            throw new IllegalArgumentException("latitude and longitude are required");
        }
        if (update.getLatitude() < -90
                || update.getLatitude() > 90
                || update.getLongitude() < -180
                || update.getLongitude() > 180) {
            throw new IllegalArgumentException("Invalid latitude/longitude bounds");
        }
        // Battery 0..100, otherwise ignore
        if (update.getBatteryLevel() != null
                && (update.getBatteryLevel() < 0 || update.getBatteryLevel() > 100)) {
            update.setBatteryLevel(null);
        }
        // Non-negative speed / heading
        if (update.getSpeed() != null && update.getSpeed() < 0) {
            update.setSpeed(0.0);
        }
        if (update.getHeading() != null && update.getHeading() < 0) {
            update.setHeading(0.0);
        }
    }

    @PostMapping("/add")
    @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
    public ResponseEntity<ApiResponse<DriverDto>> addDriver(
            @Valid @RequestBody DriverCreateRequest request) {
        var saved = driverAppService.createDriver(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(new ApiResponse<>(true, "Driver created successfully.", saved));
    }

    @GetMapping("/list")
    @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_VIEW_ALL)"
            + " or @authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
    public ResponseEntity<ApiResponse<PageResponse<DriverDto>>> getAllDrivers(
            @RequestParam(defaultValue = "0") int page, @RequestParam(defaultValue = "5") int size) {
        Page<DriverDto> drivers = driverAppService.listDrivers(PageRequest.of(page, size));
        return ResponseEntity.ok(
                new ApiResponse<>(true, "Drivers fetched successfully.", new PageResponse<>(drivers)));
    }

    @GetMapping("/alllists")
    @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_VIEW_ALL)"
            + " or @authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
    public ResponseEntity<ApiResponse<PageResponse<DriverDto>>> getAllListDrivers(
            @RequestParam(defaultValue = "0") int page, @RequestParam(defaultValue = "5") int size) {
        Page<DriverDto> drivers = driverAppService.listDrivers(PageRequest.of(page, size));
        return ResponseEntity.ok(new ApiResponse<>(true, "Fetched", new PageResponse<>(drivers)));
    }

    @GetMapping("/all")
    @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_VIEW_ALL)"
            + " or @authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
    public ResponseEntity<ApiResponse<List<DriverDto>>> getAllDriversNoPag() {
        return ResponseEntity.ok(
                new ApiResponse<>(true, "Drivers fetched successfully.", driverAppService.quickSearch("")));
    }

    @GetMapping("/search")
    @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_VIEW_ALL)"
            + " or @authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
    public ResponseEntity<ApiResponse<List<DriverDto>>> searchDrivers(@RequestParam String query) {
        return ResponseEntity.ok(
                new ApiResponse<>(true, "Drivers found", driverAppService.quickSearch(query)));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<DriverDto>> getDriverById(@PathVariable Long id) {
        try {
            // Use DriverService directly instead of DriverAppService to avoid access guard
            // checks
            // This endpoint is driver-accessible (/api/driver) - drivers can view their own
            // profile
            var driver = driverService.getDriverById(id);
            var dto = DriverDto.fromEntity(driver, false, true);
            dto.setLatitude(dto.getLatitude() != null ? dto.getLatitude() : 0.0);
            dto.setLongitude(dto.getLongitude() != null ? dto.getLongitude() : 0.0);
            return ResponseEntity.ok(new ApiResponse<>(true, "Driver found.", dto));
        } catch (DriverNotFoundException e) {
            log.warn("Driver {} requested by ID not found: {}", id, e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(new ApiResponse<>(false, "Driver not found."));
        } catch (Exception e) {
            log.error("Failed to load driver {}: {}", id, e.getMessage(), e);
            return failure(HttpStatus.INTERNAL_SERVER_ERROR, "Failed to load driver.");
        }
    }

    @PutMapping(value = "/update/{id}", consumes = MediaType.APPLICATION_JSON_VALUE, produces = MediaType.APPLICATION_JSON_VALUE)
    @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
    public ResponseEntity<ApiResponse<DriverDto>> updateDriver(
            @PathVariable Long id, @RequestBody DriverUpdateRequest request) {
        try {
            var updatedDriver = driverAppService.updateDriver(id, request);
            return ResponseEntity.ok(new ApiResponse<>(true, "Driver updated.", updatedDriver));
        } catch (Exception e) {
            log.error("Failed to update driver {}: {}", id, e.getMessage(), e);
            return badRequest("Failed to update driver.");
        }
    }

    @DeleteMapping("/delete/{id}")
    @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
    public ResponseEntity<ApiResponse<String>> deleteDriver(@PathVariable Long id) {
        try {
            driverAppService.deleteDriver(id);
            return ResponseEntity.ok(new ApiResponse<>(true, "Driver deleted."));
        } catch (Exception e) {
            log.error("Failed to delete driver {}: {}", id, e.getMessage(), e);
            return badRequest("Failed to delete driver.");
        }
    }

    // @PostMapping("/assign") // Duplicate/legacy, removed
    // @GetMapping("/{id}/vehicles") // Duplicate/legacy, removed
    @PostMapping("/update-device-token")
    public ResponseEntity<ApiResponse<String>> updateDeviceToken(
            @RequestBody DeviceTokenRequest request) {
        try {
            driverService.updateDeviceToken(request.getDriverId(), request.getDeviceToken());
            return ResponseEntity.ok(new ApiResponse<>(true, "Token updated."));
        } catch (Exception e) {
            log.error(
                    "Failed to update device token for driver {}: {}",
                    request != null ? request.getDriverId() : null,
                    e.getMessage(),
                    e);
            return badRequest("Failed to update device token.");
        }
    }

    @GetMapping("/{id}/device-token")
    public ResponseEntity<ApiResponse<String>> getDeviceToken(@PathVariable Long id) {
        try {
            return ResponseEntity.ok(
                    new ApiResponse<>(true, "Token fetched.", driverService.getDeviceToken(id)));
        } catch (Exception e) {
            return ResponseEntity.status(404).body(new ApiResponse<>(false, "Driver not found."));
        }
    }

    @GetMapping("/{id}/location-history")
    public ResponseEntity<ApiResponse<List<LocationHistoryDto>>> getDriverLocationHistory(
            @PathVariable Long id) {
        try {
            List<LocationHistoryDto> history = driverService.getDriverLocationHistory(id);
            return ResponseEntity.ok()
                    .header("X-History-Store", driverLocationService.historyStoreName())
                    .header("X-History-Replay-Lag-Seconds",
                            String.valueOf(driverLocationService.historyReplayLagSeconds()))
                    .body(new ApiResponse<>(true, "Location history retrieved.", history));
        } catch (IllegalStateException e) {
            return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                    .header("X-History-Store", "UNAVAILABLE")
                    .body(new ApiResponse<>(false, "History store unavailable."));
        }
    }

    @PostMapping("/{driverId}/heartbeat")
    public ResponseEntity<ApiResponse<String>> driverHeartbeat(
            @PathVariable Long driverId, @RequestBody HeartbeatDto dto) {
        driverService.updateHeartbeat(driverId, dto);
        return ResponseEntity.ok(new ApiResponse<>(true, "Heartbeat updated."));
    }

    // =========================
    // 🔔 DRIVER NOTIFICATIONS
    // =========================

    @PostMapping("/send-notification")
    public ResponseEntity<ApiResponse<String>> sendNotification(
            @RequestBody CreateNotificationRequest request) {
        try {
            if (request.getDriverId() == null) {
                return ResponseEntity.badRequest().body(new ApiResponse<>(false, "driverId is required"));
            }
            notificationService.sendNotification(request);
            return ResponseEntity.ok(new ApiResponse<>(true, "Notification sent."));
        } catch (Exception e) {
            log.error(
                    "Failed to send notification for driver {}: {}",
                    request != null ? request.getDriverId() : null,
                    e.getMessage(),
                    e);
            return badRequest("Failed to send notification.");
        }
    }

    @PostMapping("/broadcast-notification")
    public ResponseEntity<ApiResponse<String>> broadcastNotification(
            @RequestBody BroadcastNotificationRequest request) {
        try {
            if (request.getTopic() == null || request.getTopic().isBlank()) {
                return ResponseEntity.badRequest().body(new ApiResponse<>(false, "topic is required"));
            }
            notificationService.broadcastToTopic(request);
            return ResponseEntity.ok(new ApiResponse<>(true, "Broadcast queued."));
        } catch (Exception e) {
            log.error(
                    "Failed to broadcast notification to topic {}: {}",
                    request != null ? request.getTopic() : null,
                    e.getMessage(),
                    e);
            return badRequest("Failed to broadcast notification.");
        }
    }

    /**
     * 🔧 Admin: Send a "force-open" command to the driver app via FCM data message.
     * The client should
     * listen for `type = FORCE_OPEN` (or data.action = FORCE_OPEN) and
     * start/restart its foreground
     * LocationService.
     */
    @PostMapping("/{driverId}/force-open")
    public ResponseEntity<ApiResponse<String>> forceOpenDriverApp(@PathVariable Long driverId) {
        try {
            // Ensure driver exists (throws if not found)
            driverService.getDriverById(driverId);

            var req = CreateNotificationRequest.builder()
                    .driverId(driverId)
                    .title("Reconnect service")
                    .message("System request to (re)start.")
                    .type("FORCE_OPEN")
                    .referenceId("force-open-" + System.currentTimeMillis())
                    .sender("admin")
                    .build();
            notificationService.sendNotification(req);

            return ResponseEntity.ok(new ApiResponse<>(true, "Force-open command sent."));
        } catch (Exception e) {
            log.error("Failed to send force-open for driver {}: {}", driverId, e.getMessage(), e);
            return badRequest("Failed to send force-open command.");
        }
    }

    @GetMapping("/{driverId}/notifications")
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
                    .map(DriverNotificationDto::fromEntity).toList();

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

            return ResponseEntity.ok(new ApiResponse<>(true, "Notifications loaded.", responseData));
        } catch (Exception e) {
            log.error("Failed to load notifications for driver {}: {}", driverId, e.getMessage(), e);
            return failure(HttpStatus.INTERNAL_SERVER_ERROR, "Failed to load notifications.");
        }
    }

    @PutMapping("/{driverId}/notifications/{notificationId}/read")
    public ResponseEntity<ApiResponse<String>> markAsRead(
            @PathVariable Long driverId, @PathVariable Long notificationId) {
        try {
            notificationService.markAsRead(notificationId, driverId);
            return ResponseEntity.ok(new ApiResponse<>(true, "Notification marked as read."));
        } catch (Exception e) {
            log.error(
                    "Failed to mark notification {} as read for driver {}: {}",
                    notificationId,
                    driverId,
                    e.getMessage(),
                    e);
            return badRequest("Failed to mark notification as read.");
        }
    }

    @PutMapping("/notifications/{notificationId}/read")
    public ResponseEntity<ApiResponse<String>> markAsReadLegacy(@PathVariable Long notificationId) {
        try {
            notificationService.markAsRead(notificationId, null);
            return ResponseEntity.ok(new ApiResponse<>(true, "Notification marked as read."));
        } catch (Exception e) {
            log.error(
                    "Failed to mark notification {} as read (legacy): {}",
                    notificationId,
                    e.getMessage(),
                    e);
            return badRequest("Failed to mark notification as read.");
        }
    }

    @PatchMapping("/{driverId}/notifications/mark-all-read")
    public ResponseEntity<ApiResponse<String>> markAllAsRead(@PathVariable Long driverId) {
        notificationService.markAllAsReadByDriver(driverId);
        return ResponseEntity.ok(new ApiResponse<>(true, "All notifications marked as read."));
    }

    @DeleteMapping("/{driverId}/notifications/{notificationId}")
    public ResponseEntity<ApiResponse<String>> deleteDriverNotification(
            @PathVariable Long driverId, @PathVariable Long notificationId) {
        try {
            notificationService.deleteNotification(notificationId, driverId);
            return ResponseEntity.ok(new ApiResponse<>(true, "Notification deleted."));
        } catch (Exception e) {
            log.error(
                    "Failed to delete notification {} for driver {}: {}",
                    notificationId,
                    driverId,
                    e.getMessage(),
                    e);
            return badRequest("Failed to delete notification.");
        }
    }

    @PostMapping("/advanced-search")
    public ResponseEntity<ApiResponse<PageResponse<DriverDto>>> advancedSearchDrivers(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "12") int size,
            @RequestBody(required = false) DriverFilterRequest filters) {
        DriverFilterRequest safeFilters = (filters != null) ? filters : new DriverFilterRequest();
        Page<DriverDto> result = driverService.advancedSearchDrivers(
                page,
                size,
                safeFilters.getQuery(),
                safeFilters.getIsActive(),
                safeFilters.getMinRating(),
                safeFilters.getMaxRating(),
                safeFilters.getZone(),
                safeFilters.getVehicleType(),
                safeFilters.getStatus(),
                safeFilters.getIsPartner());
        return ResponseEntity.ok(
                new ApiResponse<>(true, "Advanced driver filter applied.", new PageResponse<>(result)));
    }

    @GetMapping("/{driverId}/location-history/paginated")
    public ResponseEntity<ApiResponse<Page<LocationHistoryDto>>> getDriverLocationHistoryPaginated(
            @PathVariable Long driverId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        try {
            Page<LocationHistoryDto> historyPage =
                    driverService.getDriverLocationHistoryPaginated(driverId, page, size);
            return ResponseEntity.ok()
                    .header("X-History-Store", driverLocationService.historyStoreName())
                    .header("X-History-Replay-Lag-Seconds",
                            String.valueOf(driverLocationService.historyReplayLagSeconds()))
                    .body(new ApiResponse<>(true, "Paginated location history fetched", historyPage));
        } catch (IllegalStateException e) {
            return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                    .header("X-History-Store", "UNAVAILABLE")
                    .body(new ApiResponse<>(false, "History store unavailable."));
        }
    }

    // GET /api/driver/current-assignment (DriverSelfAssignmentController) is the
    // canonical driver-facing endpoint for vehicle/assignment data.

    @PostMapping(path = "/{driverId}/upload-profile", consumes = MediaType.MULTIPART_FORM_DATA_VALUE, produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<ApiResponse<String>> uploadProfilePictureAdmin(
            @PathVariable Long driverId, @RequestParam("profilePicture") MultipartFile file) {
        try {
            String fileUrl = driverService.saveProfilePicture(driverId, file);
            return ResponseEntity.ok(new ApiResponse<>(true, "Profile picture updated.", fileUrl));
        } catch (Exception e) {
            log.error("Failed to upload profile picture for driver {}: {}", driverId, e.getMessage(), e);
            return badRequest("Failed to upload profile picture.");
        }
    }

    @PostMapping(value = "/location/update", consumes = MediaType.APPLICATION_JSON_VALUE, produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<ApiResponse<String>> adminUpdateDriverLocation(
            @RequestHeader(value = "Authorization", required = false) String authorization,
            @Valid @RequestBody DriverLocationUpdateDto update) {
        try {
            // Validate and normalize input before ingest
            sanitizeUpdate(update);
            String token = DriverTrackingSessionService.extractBearerToken(authorization);
            trackingSessionService.validateLocationWriteOrThrow(
                    token, update.getDriverId(), update.getSessionId());
            ingest.accept(update);

            log.info(
                    "📍 Admin location update → driver={} latitude={} longitude={} speed={} dispatchId={} clientTime={}",
                    update.getDriverId(),
                    update.getLatitude(),
                    update.getLongitude(),
                    update.getSpeed(),
                    update.getDispatchId(),
                    update.getClientTime());

            return ResponseEntity.ok(new ApiResponse<>(true, " Location update processed."));
        } catch (ResponseStatusException e) {
            log.warn(
                    "Location update rejected [driver={}]: {}",
                    update != null ? update.getDriverId() : null,
                    e.getReason());
            return failure(
                    HttpStatus.valueOf(e.getStatusCode().value()),
                    e.getReason() == null ? "Request rejected" : e.getReason());
        } catch (Exception e) {
            log.error(
                    "Admin location update failed [driver={}]: {}",
                    update != null ? update.getDriverId() : null,
                    e.getMessage(),
                    e);
            return failure(HttpStatus.INTERNAL_SERVER_ERROR, "Server error while processing location update.");
        }
    }

    /**
     * Batch ingestion of location updates. Useful for mobile offline queue flush or
     * admin bulk
     * backfill.
     */
    @PostMapping(value = "/location/update/batch", consumes = MediaType.APPLICATION_JSON_VALUE, produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<ApiResponse<String>> adminUpdateDriverLocationBatch(
            @RequestHeader(value = "Authorization", required = false) String authorization,
            @Valid @RequestBody List<DriverLocationUpdateDto> updates) {
        try {
            int accepted = 0;
            int skipped = 0;
            String token = DriverTrackingSessionService.extractBearerToken(authorization);
            if (updates != null) {
                for (DriverLocationUpdateDto u : updates) {
                    try {
                        sanitizeUpdate(u);
                        trackingSessionService.validateLocationWriteOrThrow(
                                token, u.getDriverId(), u.getSessionId());
                        ingest.accept(u);
                        accepted++;
                    } catch (Exception perItem) {
                        skipped++;
                        log.warn(
                                "Skipped bad point for driver={} at clientTime={}: {}",
                                (u != null ? u.getDriverId() : null),
                                (u != null ? u.getClientTime() : null),
                                perItem.getMessage());
                    }
                }
            }
            String msg = " Batch processed: " + accepted + " accepted, " + skipped + " skipped";
            return ResponseEntity.ok(new ApiResponse<>(true, msg));
        } catch (ResponseStatusException e) {
            return failure(
                    HttpStatus.valueOf(e.getStatusCode().value()),
                    e.getReason() == null ? "Request rejected" : e.getReason());
        } catch (Exception e) {
            log.error("Batch location update failed: {}", e.getMessage(), e);
            return failure(HttpStatus.INTERNAL_SERVER_ERROR, "Server error while processing batch updates.");
        }
    }

    /**
     * Live drivers for the map. Params: - onlyOnline: boolean (default true) -
     * onlineSeconds: integer
     * (default 120) - south, west, north, east: optional bbox
     */
    @GetMapping("/live-drivers")
    public ResponseEntity<ApiResponse<List<LiveDriverDto>>> liveDrivers(
            @RequestParam(required = false, defaultValue = "true") Boolean onlyOnline,
            @RequestParam(required = false, defaultValue = "120") Integer onlineSeconds,
            @RequestParam(required = false) Double south,
            @RequestParam(required = false) Double west,
            @RequestParam(required = false) Double north,
            @RequestParam(required = false) Double east) {
        List<LiveDriverDto> data = liveDriverQueryService.getLiveDrivers(onlyOnline, onlineSeconds, south, west, north,
                east);
        return ResponseEntity.ok(new ApiResponse<>(true, "Fetched live drivers.", data));
    }

    /** Single driver latest (WS fallback / debugging) */
    @GetMapping("/{driverId}/latest-location")
    public ResponseEntity<ApiResponse<LiveDriverDto>> latestForDriver(@PathVariable Long driverId) {
        return liveDriverQueryService
                .getLatestForDriver(driverId)
                .map(dto -> ResponseEntity.ok(new ApiResponse<>(true, "OK", dto)))
                .orElseGet(() -> ResponseEntity.ok(new ApiResponse<>(true, "No data", null)));
    }

    private <T> ResponseEntity<ApiResponse<T>> failure(HttpStatus status, String message) {
        return ResponseEntity.status(status).body(new ApiResponse<>(false, message));
    }

    private <T> ResponseEntity<ApiResponse<T>> badRequest(String message) {
        return failure(HttpStatus.BAD_REQUEST, message);
    }
}
