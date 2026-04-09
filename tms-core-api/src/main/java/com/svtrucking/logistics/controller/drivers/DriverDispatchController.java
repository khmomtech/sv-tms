package com.svtrucking.logistics.controller.drivers;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.dto.DispatchDto;
import com.svtrucking.logistics.dto.DriverDispatchDto;
import com.svtrucking.logistics.dto.DispatchStatusHistoryDto;
import com.svtrucking.logistics.dto.LoadProofDto;
import com.svtrucking.logistics.dto.UnloadProofDto;
import com.svtrucking.logistics.enums.DispatchStatus;
import com.svtrucking.logistics.dto.requests.PlanTripRequest;
import com.svtrucking.logistics.dto.request.BreakdownReportRequest;
import com.svtrucking.logistics.dto.request.UpdateDispatchStatusRequest;
import com.svtrucking.logistics.dto.response.DispatchStatusUpdateResponse;
import com.svtrucking.logistics.exception.InvalidDispatchDataException;
import com.svtrucking.logistics.exception.ResourceNotFoundException;
import com.svtrucking.logistics.modules.notification.dto.CreateNotificationRequest;
import com.svtrucking.logistics.modules.notification.service.DriverNotificationService;
import com.svtrucking.logistics.security.AuthenticatedUserUtil;
import com.svtrucking.logistics.service.DispatchService;
import com.svtrucking.logistics.service.ChangeTruckResult;
import com.svtrucking.logistics.service.LoadProofService;
import com.svtrucking.logistics.service.UnloadProofService;
import jakarta.validation.Valid;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
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
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

@Slf4j
@RestController
@RequestMapping("/api/driver/dispatches")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
public class DriverDispatchController {
    /**
     * Get all processing (not completed/cancelled) dispatches for a driver.
     */
    @GetMapping("/driver/{driverId}/processing")
    public ResponseEntity<ApiResponse<List<DispatchDto>>> getProcessingDispatches(
            @PathVariable Long driverId,
            @RequestParam(required = false) List<String> status,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime to,
            @RequestParam(required = false) String q) {
        // Default processing statuses
        EnumSet<DispatchStatus> processingStatuses = EnumSet.of(
                DispatchStatus.ASSIGNED,
                DispatchStatus.DRIVER_CONFIRMED,
                DispatchStatus.IN_QUEUE,
                DispatchStatus.ARRIVED_LOADING,
                DispatchStatus.LOADING,
                DispatchStatus.LOADED,
                DispatchStatus.IN_TRANSIT,
                DispatchStatus.ARRIVED_UNLOADING,
                DispatchStatus.UNLOADING,
                DispatchStatus.UNLOADED);

        // If status param is provided, override default statuses
        List<DispatchStatus> filterStatuses = new ArrayList<>(processingStatuses);
        if (status != null && !status.isEmpty()) {
            filterStatuses = status.stream()
                    .map(s -> {
                        try {
                            return DispatchStatus.valueOf(s.trim().toUpperCase());
                        } catch (Exception e) {
                            return null;
                        }
                    })
                    .filter(Objects::nonNull)
                    .collect(Collectors.toList());
        }

        // If any filter except date is provided, use filterDispatches, else use
        // getDispatchesByDriverWithStatuses
        List<DispatchDto> result;
        boolean hasFilter = (q != null && !q.isBlank());
        if (hasFilter) {
            // Use filterDispatches for advanced filtering
            result = dispatchService.filterDispatches(
                    driverId,
                    null, // vehicleId
                    filterStatuses.isEmpty() ? null : filterStatuses.get(0), // only one status supported in
                                                                             // filterDispatches
                    null, // driverName
                    null, // routeCode
                    q,
                    null, // customerName
                    null, // destinationTo
                    null, // truckPlate
                    null, // tripNo
                    from,
                    to,
                    org.springframework.data.domain.Pageable.unpaged()).getContent();
        } else {
            // Use original method for default processing list (all time)
            result = dispatchService.getDispatchesByDriverWithStatuses(
                    driverId,
                    filterStatuses,
                    org.springframework.data.domain.Pageable.unpaged()).getContent();
        }
        return ResponseEntity.ok(new ApiResponse<>(true, "ទាញយកបញ្ជាដឹកជញ្ជូនកំពុងដំណើរការ", result));
    }

    private final DispatchService dispatchService;
    private final LoadProofService loadProofService;
    private final UnloadProofService unloadProofService;
    private final DriverNotificationService notificationService;
    private final AuthenticatedUserUtil authUtil;

    @GetMapping
    public ResponseEntity<ApiResponse<Page<DispatchDto>>> getAllDispatches(Pageable pageable) {
        Page<DispatchDto> dispatches = dispatchService.getAllDispatchesWithDetails(pageable);
        return ResponseEntity.ok(new ApiResponse<>(true, "ទាញយកបញ្ជាទាំងអស់បានជោគជ័យ។", dispatches));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<DispatchDto>> createDispatch(
            @Valid @RequestBody DispatchDto dispatchDto) {
        try {
            DispatchDto createdDispatch = dispatchService.createDispatch(dispatchDto);

            var location = ServletUriComponentsBuilder.fromCurrentRequest()
                    .path("/{id}")
                    .buildAndExpand(createdDispatch.getId())
                    .toUri();

            return ResponseEntity.created(location)
                    .body(new ApiResponse<>(true, "បានបង្កើតបញ្ជាដឹកជញ្ជូនដោយជោគជ័យ។", createdDispatch));
        } catch (com.svtrucking.logistics.exception.InvalidDispatchDataException ex) {
            Map<String, String> fieldErrors = new HashMap<>();
            if (ex.getField() != null) {
                fieldErrors.put(ex.getField(), ex.getReason() != null ? ex.getReason() : ex.getMessage());
            } else {
                fieldErrors.put("_global", ex.getMessage());
            }
            log.error("Invalid dispatch data (driver endpoint): {}", ex.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(new ApiResponse<>(false, "Failed to create dispatch", null, fieldErrors));
        } catch (Exception e) {
            log.error("Failed to create dispatch (driver endpoint)", e);
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(new ApiResponse<>(false, "Failed to create dispatch: " + e.getMessage(), null));
        }
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<DispatchDto>> getDispatchById(@PathVariable Long id) {
        DispatchDto dispatch = dispatchService.getDispatchById(id);
        LoadProofDto loadProof = loadProofService.getProofByDispatchId(id);
        if (loadProof != null) {
            dispatch.setLoadingProofImages(loadProof.getImageUrls());
            dispatch.setLoadingSignature(loadProof.getSignatureUrl());
        }
        UnloadProofDto unloadProof = unloadProofService.getProofByDispatchId(id);
        if (unloadProof != null) {
            dispatch.setUnloadingProofImages(unloadProof.getImageUrls());
            dispatch.setUnloadingSignature(unloadProof.getSignatureUrl());
        }
        return ResponseEntity.ok(new ApiResponse<>(true, "រកឃើញបញ្ជាដឹកជញ្ជូន។", dispatch));
    }

    @GetMapping("/filter")
    public ResponseEntity<ApiResponse<Page<DispatchDto>>> filterDispatches(
            @RequestParam(required = false) Long driverId,
            @RequestParam(required = false) Long vehicleId,
            @RequestParam(required = false) DispatchStatus status,
            @RequestParam(required = false) String driverName,
            @RequestParam(required = false) String routeCode,
            @RequestParam(required = false) String q,
            @RequestParam(required = false) String customerName,
            @RequestParam(required = false) String destinationTo,
            @RequestParam(required = false) String truckPlate,
            @RequestParam(required = false) String tripNo,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime start,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime end,
            Pageable pageable) {

        Page<DispatchDto> filtered = dispatchService.filterDispatches(
                driverId,
                vehicleId,
                status,
                driverName,
                routeCode,
                q,
                customerName,
                destinationTo,
                truckPlate,
                tripNo,
                start,
                end,
                pageable);

        return ResponseEntity.ok(
                new ApiResponse<>(true, "ទាញយកបញ្ជាដឹកជញ្ជូនតាមលក្ខណៈត្រងបានជោគជ័យ។", filtered));
    }

    @PostMapping("/{id}/assign")
    public ResponseEntity<ApiResponse<DispatchDto>> assignDispatch(
            @PathVariable Long id, @RequestParam Long driverId, @RequestParam Long vehicleId) {
        DispatchDto assignedDispatch = dispatchService.assignDispatch(id, driverId, vehicleId);

        safeNotify(
                assignedDispatch.getDriverId(),
                "ការដឹកជញ្ជូនថ្មីត្រូវបានផ្តល់ជូន",
                "អ្នកត្រូវបានផ្តល់ការដឹកជញ្ជូនថ្មី៖ " + nullSafe(assignedDispatch.getId().toString()),
                "DISPATCH",
                String.valueOf(assignedDispatch.getId()));

        return ResponseEntity.ok(
                new ApiResponse<>(true, "ការផ្តល់ការដឹកជញ្ជូនបានជោគជ័យ។", assignedDispatch));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<DispatchDto>> updateDispatch(
            @PathVariable Long id, @RequestBody DispatchDto dispatchDetails) {
        DispatchDto updatedDispatch = dispatchService.updateDispatch(id, dispatchDetails);
        return ResponseEntity.ok(
                new ApiResponse<>(true, "បានធ្វើបច្ចុប្បន្នភាពបញ្ជាដឹកជញ្ជូនដោយជោគជ័យ។", updatedDispatch));
    }

    @GetMapping("/{id}/status-history")
    public ResponseEntity<ApiResponse<List<DispatchStatusHistoryDto>>> getDispatchStatusHistory(
            @PathVariable Long id) {
        List<DispatchStatusHistoryDto> history = dispatchService.getStatusHistory(id);
        return ResponseEntity.ok(new ApiResponse<>(true, "ទាញយកប្រវត្តិស្ថានភាពបានជោគជ័យ។", history));
    }

    @PatchMapping("/{id}/status")
    public ResponseEntity<ApiResponse<DispatchStatusUpdateResponse>> updateDispatchStatus(
            @PathVariable Long id,
            @Valid @RequestBody UpdateDispatchStatusRequest request) {
        return doUpdateDispatchStatus(id, request);
    }

    /**
     * Backward-compatible status update path.
     * Canonical endpoint remains PATCH /{id}/status.
     */
    @PatchMapping("/{id}")
    public ResponseEntity<ApiResponse<DispatchStatusUpdateResponse>> updateDispatchStatusCompatibility(
            @PathVariable Long id,
            @Valid @RequestBody UpdateDispatchStatusRequest request) {
        return doUpdateDispatchStatus(id, request);
    }

    private ResponseEntity<ApiResponse<DispatchStatusUpdateResponse>> doUpdateDispatchStatus(
            Long id, UpdateDispatchStatusRequest request) {
        if (request.getStatus() == null) {
            Map<String, String> errors = new HashMap<>();
            errors.put("status", "Status is required");
            return ResponseEntity.badRequest()
                    .body(new ApiResponse<>(false, "សូមផ្តល់ស្ថានភាពសម្រាប់បញ្ជាដឹកជញ្ជូន។", null, errors));
        }

        try {
            DispatchStatusUpdateResponse response = dispatchService.updateDispatchStatusWithResponse(
                    id,
                    request.getStatus(),
                    request.getReason(),
                    request.getMetadata());

            return ResponseEntity.ok(
                    new ApiResponse<>(
                            true,
                            "បានធ្វើបច្ចុប្បន្នភាពស្ថានភាពបញ្ជាដឹកជញ្ជូនដោយជោគជ័យ។",
                            response));
        } catch (SecurityException ex) {
            Map<String, String> errors = new HashMap<>();
            errors.put("_global", ex.getMessage());
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(new ApiResponse<>(false, ex.getMessage(), null, errors));
        } catch (InvalidDispatchDataException ex) {
            Map<String, String> errors = new HashMap<>();
            errors.put(ex.getField() != null ? ex.getField() : "_global",
                    ex.getReason() != null ? ex.getReason() : ex.getMessage());
            if (ex.getCode() != null && !ex.getCode().isBlank()) {
                errors.put("code", ex.getCode());
            }
            if (ex.getRequiredInput() != null && !ex.getRequiredInput().isBlank()) {
                errors.put("requiredInput", ex.getRequiredInput());
            }
            if (ex.getNextAllowedAction() != null && !ex.getNextAllowedAction().isBlank()) {
                errors.put("nextAllowedAction", ex.getNextAllowedAction());
            }
            return ResponseEntity.badRequest()
                    .body(new ApiResponse<>(false, ex.getMessage(), null, errors));
        } catch (IllegalArgumentException ex) {
            Map<String, String> errors = new HashMap<>();
            errors.put("status", ex.getMessage());
            return ResponseEntity.badRequest()
                    .body(new ApiResponse<>(false, "ស្ថានភាពមិនត្រឹមត្រូវ: " + request.getStatus(), null, errors));
        } catch (Exception ex) {
            Map<String, String> errors = new HashMap<>();
            errors.put("_global", ex.getMessage());
            return ResponseEntity.badRequest()
                    .body(new ApiResponse<>(false, "Failed to update dispatch status", null, errors));
        }
    }

    @GetMapping("/{id}/available-actions")
    public ResponseEntity<ApiResponse<DispatchStatusUpdateResponse>> getAvailableActions(
            @PathVariable Long id) {
        try {
            // Get the current dispatch and its available next states
            DispatchStatusUpdateResponse response = dispatchService.getAvailableActionsForDispatch(id);
            return ResponseEntity.ok(
                    new ApiResponse<>(
                            true,
                            "ទាញយកសកម្មភាពដែលមាននៅលើបានជោគជ័យ។",
                            response));
        } catch (ResourceNotFoundException ex) {
            Map<String, String> errors = new HashMap<>();
            errors.put("dispatchId", ex.getMessage());
            log.warn("Available actions dispatch not found: id={}, error={}", id, ex.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(new ApiResponse<>(false, ex.getMessage(), null, errors));
        } catch (Exception ex) {
            Map<String, String> errors = new HashMap<>();
            errors.put("_global", ex.getMessage());
            log.error("Failed to fetch available actions for dispatch {}: {}", id, ex.getMessage(), ex);
            return ResponseEntity.badRequest()
                    .body(new ApiResponse<>(false, "Failed to fetch available actions: " + ex.getMessage(), null,
                            errors));
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteDispatch(@PathVariable Long id) {
        dispatchService.deleteDispatch(id);
        return ResponseEntity.ok(new ApiResponse<>(true, "បានលុបបញ្ជាដឹកជញ្ជូនដោយជោគជ័យ។", null));
    }

    @PutMapping("/{id}/change-driver")
    public ResponseEntity<ApiResponse<DispatchDto>> changeDriver(
            @PathVariable Long id, @RequestParam Long driverId) {
        DispatchDto result = dispatchService.changeDriver(id, driverId);

        safeNotify(
                result.getDriverId(),
                "ការដឹកជញ្ជូនថ្មីត្រូវបានផ្តល់ជូន",
                "អ្នកត្រូវបានផ្តល់ការដឹកជញ្ជូនថ្មី៖ " + nullSafe(result.getId().toString()),
                "DISPATCH",
                String.valueOf(result.getId()));

        return ResponseEntity.ok(new ApiResponse<>(true, "បានផ្លាស់ប្តូរអ្នកបើកបរដោយជោគជ័យ។", result));
    }

    @PutMapping("/{id}/change-truck")
    public ResponseEntity<ApiResponse<DispatchDto>> changeTruck(
            @PathVariable Long id, @RequestParam Long vehicleId) {
        ChangeTruckResult result = dispatchService.changeTruck(id, vehicleId);
        if (!result.isDriverAssignedToNewVehicle() && result.getDispatch() != null
                && result.getDispatch().getDriverId() != null) {
            var warning = java.util.Map.of("warnings",
                    java.util.List.of("Current driver is not assigned to the new vehicle"));
            return ResponseEntity
                    .ok(new ApiResponse<>(true, "បានផ្លាស់ប្តូររថយន្តដោយជោគជ័យ។", result.getDispatch(), warning));
        }
        return ResponseEntity.ok(new ApiResponse<>(true, "បានផ្លាស់ប្តូររថយន្តដោយជោគជ័យ។", result.getDispatch()));
    }

    @PostMapping(value = "/{dispatchId}/load", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<ApiResponse<LoadProofDto>> submitLoadProof(
            @PathVariable Long dispatchId,
            @RequestParam(required = false) String remarks,
            @RequestParam(required = false) List<MultipartFile> images,
            @RequestParam(required = false) MultipartFile signature) {
        try {
            List<MultipartFile> imageList = (images != null) ? images : List.of();
            LoadProofDto proof = loadProofService.submitLoadProof(dispatchId, remarks, imageList, signature);
            return ResponseEntity.ok(new ApiResponse<>(true, "បានដាក់ស្នើភស្ដុតាងពេលផ្ទុក។", proof));
        } catch (IllegalStateException e) {
            Map<String, String> errors = new HashMap<>();
            errors.put("status", e.getMessage());
            return ResponseEntity.badRequest()
                    .body(new ApiResponse<>(false, e.getMessage(), null, errors));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new ApiResponse<>(false, "បរាជ័យក្នុងការដាក់ស្នើភស្ដុតាងពេលផ្ទុក។", null));
        }
    }

    @PostMapping(value = "/driver/load-proof/{dispatchId}/load", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<ApiResponse<LoadProofDto>> driverSubmitLoadProof(
            @PathVariable Long dispatchId,
            @RequestParam(required = false) String remarks,
            @RequestParam(required = false) List<MultipartFile> images,
            @RequestParam(required = false) MultipartFile signature) {
        List<MultipartFile> imageList = (images != null) ? images : List.of();
        return submitLoadProof(dispatchId, remarks, imageList, signature);
    }

    @PostMapping(value = "/driver/unload-proof/{dispatchId}/unload", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<ApiResponse<UnloadProofDto>> submitUnloadProof(
            @PathVariable Long dispatchId,
            @RequestParam(required = false) String remarks,
            @RequestParam(required = false) String address,
            @RequestParam(required = false) Double latitude,
            @RequestParam(required = false) Double longitude,
            @RequestParam(required = false) List<MultipartFile> images,
            @RequestParam(required = false) MultipartFile signature) {
        try {
            List<MultipartFile> imageList = (images != null) ? images : List.of();
            UnloadProofDto result = unloadProofService.submitUnloadProof(
                    dispatchId, remarks, address, latitude, longitude, imageList, signature);
            return ResponseEntity.ok(
                    new ApiResponse<>(true, "បានដាក់ស្នើភស្ដុតាងពេលផ្ទុកចេញដោយជោគជ័យ។", result));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new ApiResponse<>(false, "បរាជ័យក្នុងការដាក់ស្នើភស្ដុតាងពេលផ្ទុកចេញ។", null));
        }
    }

    @PostMapping("/{dispatchId}/unload")
    public ResponseEntity<?> markAsUnloaded(
            @PathVariable Long dispatchId,
            @RequestParam(required = false) String remarks,
            @RequestParam(required = false) String address,
            @RequestParam(required = false) Double latitude,
            @RequestParam(required = false) Double longitude,
            @RequestPart(value = "images", required = false) List<MultipartFile> images,
            @RequestPart(value = "signature", required = false) MultipartFile signature) {
        dispatchService.markAsUnloaded(
                dispatchId, remarks, address, latitude, longitude, images, signature);
        return ResponseEntity.ok(Map.of("message", "បានដាក់ស្នើព័ត៌មានផ្ទុកចេញដោយជោគជ័យ។"));
    }

    @GetMapping("/driver/{driverId}")
    public ResponseEntity<Page<DriverDispatchDto>> getDispatchesByDriverWithDateRange(
            @PathVariable Long driverId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to,
            @PageableDefault(size = 20) Pageable pageable) {
        Page<DispatchDto> page = dispatchService.getDispatchesByDriverId(driverId, pageable);
        return ResponseEntity.ok(page.map(DriverDispatchDto::from));
    }

    /**
     * Get authenticated driver's pending dispatches
     * Statuses: PLANNED, PENDING, SCHEDULED, ASSIGNED
     * Sorted by: startTime DESC
     */
    @GetMapping("/me/pending")
    public ResponseEntity<Page<DriverDispatchDto>> getMyPendingDispatches(
            @PageableDefault(sort = "startTime", direction = org.springframework.data.domain.Sort.Direction.DESC, size = 100) Pageable pageable) {

        Long driverId = authUtil.getCurrentDriverId();

        List<DispatchStatus> pendingStatuses = Arrays.asList(
                DispatchStatus.PLANNED,
                DispatchStatus.PENDING,
                DispatchStatus.SCHEDULED,
                DispatchStatus.ASSIGNED);

        Page<DispatchDto> page = dispatchService.getDispatchesByDriverWithStatuses(
                driverId,
                pendingStatuses,
                pageable);

        return ResponseEntity.ok(page.map(DriverDispatchDto::from));
    }

    /**
     * Get authenticated driver's in-progress dispatches
     * Statuses: DRIVER_CONFIRMED, APPROVED, ARRIVED_LOADING, IN_QUEUE, LOADING,
     * LOADED, AT_HUB, HUB_LOADING, IN_TRANSIT, ARRIVED_UNLOADING, UNLOADING,
     * UNLOADED, SAFETY_PASSED
     * Sorted by: startTime ASC
     */
    @GetMapping("/me/in-progress")
    public ResponseEntity<Page<DriverDispatchDto>> getMyInProgressDispatches(
            @PageableDefault(sort = "startTime", size = 100) Pageable pageable) {

        Long driverId = authUtil.getCurrentDriverId();

        List<DispatchStatus> inProgressStatuses = Arrays.asList(
                DispatchStatus.DRIVER_CONFIRMED,
                DispatchStatus.APPROVED,
                DispatchStatus.ARRIVED_LOADING,
                DispatchStatus.IN_QUEUE,
                DispatchStatus.LOADING,
                DispatchStatus.LOADED,
                DispatchStatus.AT_HUB,
                DispatchStatus.HUB_LOADING,
                DispatchStatus.IN_TRANSIT,
                DispatchStatus.ARRIVED_UNLOADING,
                DispatchStatus.UNLOADING,
                DispatchStatus.UNLOADED,
                DispatchStatus.SAFETY_PASSED);

        Page<DispatchDto> page = dispatchService.getDispatchesByDriverWithStatuses(
                driverId,
                inProgressStatuses,
                pageable);

        return ResponseEntity.ok(page.map(DriverDispatchDto::from));
    }

    /**
     * Get authenticated driver's completed dispatches
     * Statuses: DELIVERED, FINANCIAL_LOCKED, CLOSED, COMPLETED, CANCELLED,
     * REJECTED, SAFETY_FAILED
     * Sorted by: endTime DESC
     */
    @GetMapping("/me/completed")
    public ResponseEntity<Page<DriverDispatchDto>> getMyCompletedDispatches(
            @PageableDefault(sort = "endTime", direction = org.springframework.data.domain.Sort.Direction.DESC, size = 100) Pageable pageable) {

        Long driverId = authUtil.getCurrentDriverId();

        List<DispatchStatus> completedStatuses = Arrays.asList(
                DispatchStatus.DELIVERED,
                DispatchStatus.FINANCIAL_LOCKED,
                DispatchStatus.CLOSED,
                DispatchStatus.COMPLETED,
                DispatchStatus.CANCELLED,
                DispatchStatus.REJECTED,
                DispatchStatus.SAFETY_FAILED);

        Page<DispatchDto> page = dispatchService.getDispatchesByDriverWithStatuses(
                driverId,
                completedStatuses,
                pageable);

        return ResponseEntity.ok(page.map(DriverDispatchDto::from));
    }

    // 🔙 Restored old endpoint so existing clients keep working
    @GetMapping("/driver/{driverId}/status")
    public ResponseEntity<Page<DriverDispatchDto>> getDispatchesByDriverWithStatusFilter(
            @PathVariable Long driverId,
            @RequestParam(required = false) String status,
            Pageable pageable) {

        List<DispatchStatus> statuses = null;
        if (status != null && !status.isBlank()) {
            try {
                statuses = Arrays.stream(status.split(","))
                        .map(s -> DispatchStatus.valueOf(s.trim().toUpperCase()))
                        .collect(Collectors.toList());
            } catch (IllegalArgumentException ex) {
                return ResponseEntity.badRequest().body(Page.empty(pageable));
            }
        }
        Page<DispatchDto> page = dispatchService.getDispatchesByDriverWithStatuses(driverId, statuses, pageable);
        return ResponseEntity.ok(page.map(DriverDispatchDto::from));
    }

    @PostMapping("/{id}/accept")
    public ResponseEntity<ApiResponse<DispatchDto>> acceptDispatch(@PathVariable Long id) {
        try {
            DispatchDto dto = dispatchService.acceptDispatch(id);
            return ResponseEntity.ok(new ApiResponse<>(true, "អ្នកបើកបរបានទទួលបញ្ជាដឹកជញ្ជូន។", dto));
        } catch (ResourceNotFoundException ex) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(new ApiResponse<>(false, ex.getMessage()));
        } catch (InvalidDispatchDataException ex) {
            Map<String, String> errors = new HashMap<>();
            errors.put(ex.getField() != null ? ex.getField() : "_global",
                    ex.getReason() != null ? ex.getReason() : ex.getMessage());
            if (ex.getCode() != null) errors.put("code", ex.getCode());
            // Return 409 Conflict so the client knows the current state has changed
            return ResponseEntity.status(HttpStatus.CONFLICT)
                    .body(new ApiResponse<>(false, ex.getMessage(), null, errors));
        } catch (SecurityException ex) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(new ApiResponse<>(false, ex.getMessage()));
        }
    }

    @PostMapping("/{id}/reject")
    public ResponseEntity<ApiResponse<DispatchDto>> rejectDispatch(
            @PathVariable Long id, @RequestParam String reason) {
        try {
            DispatchDto dto = dispatchService.rejectDispatch(id, reason);
            return ResponseEntity.ok(new ApiResponse<>(true, "អ្នកបើកបរបានបដិសេធបញ្ជាដឹកជញ្ជូន។", dto));
        } catch (ResourceNotFoundException ex) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(new ApiResponse<>(false, ex.getMessage()));
        } catch (InvalidDispatchDataException ex) {
            Map<String, String> errors = new HashMap<>();
            errors.put(ex.getField() != null ? ex.getField() : "_global",
                    ex.getReason() != null ? ex.getReason() : ex.getMessage());
            if (ex.getCode() != null) errors.put("code", ex.getCode());
            return ResponseEntity.status(HttpStatus.CONFLICT)
                    .body(new ApiResponse<>(false, ex.getMessage(), null, errors));
        } catch (SecurityException ex) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(new ApiResponse<>(false, ex.getMessage()));
        }
    }

    @GetMapping("/proofs/load")
    public ResponseEntity<ApiResponse<List<LoadProofDto>>> getFilteredLoadProofs(
            @RequestParam(required = false) String search,
            @RequestParam(required = false) String driver,
            @RequestParam(required = false) String route,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        List<LoadProofDto> results = loadProofService.getFilteredProofs(search, driver, route, from, to);
        return ResponseEntity.ok(new ApiResponse<>(true, "ទាញយកភស្ដុតាងផ្ទុកតាមលក្ខណៈត្រង។", results));
    }

    @PostMapping("/plan-trip")
    public ResponseEntity<ApiResponse<DispatchDto>> planTrip(
            @Valid @RequestBody PlanTripRequest payload) {

        DispatchDto plannedDispatch = dispatchService.planTrip(
                payload.getOrderId(),
                payload.getTripType(),
                payload.getVehicleId(),
                payload.getScheduleTime(),
                payload.getEstimatedDrop(),
                payload.getManualRouteCode());

        return ResponseEntity.ok(
                new ApiResponse<>(true, "ការធ្វើជើងដឹកត្រូវបានរៀបចំដោយជោគជ័យ។", plannedDispatch));
    }

    @PostMapping(value = "/import-bulk", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<ApiResponse<String>> importBulkDispatches(
            @RequestParam("file") MultipartFile file) {
        try {
            if (file.isEmpty() || !file.getOriginalFilename().endsWith(".xlsx")) {
                return ResponseEntity.badRequest()
                        .body(new ApiResponse<>(false, "ទ្រង់ទ្រាយឯកសារមិនត្រឹមត្រូវ។", null));
            }

            dispatchService.importBulkDispatchesFromExcel(file, false);
            return ResponseEntity.ok(
                    new ApiResponse<>(true, "បាននាំចូលបញ្ជាដឹកជញ្ជូនជាបណ្ដុំដោយជោគជ័យ។", null));
        } catch (Exception e) {
            log.error("Failed to import bulk dispatches", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(
                            new ApiResponse<>(
                                    false, "បរាជ័យក្នុងការនាំចូលបញ្ជាដឹកជញ្ជូនជាបណ្ដុំ: " + e.getMessage(), null));
        }
    }

    @PostMapping("/{id}/assign-driver")
    public ResponseEntity<ApiResponse<DispatchDto>> assignDriverOnly(
            @PathVariable Long id, @RequestParam Long driverId) {
        try {
            DispatchDto result = dispatchService.changeDriver(id, driverId);

            String ref = firstNonBlank(result.getTransportOrderId(), result.getId().toString(), "-");
            safeNotify(
                    result.getDriverId(),
                    "ការដឹកជញ្ជូនថ្មីត្រូវបានផ្តល់ជូន",
                    "អ្នកត្រូវបានផ្តល់ការដឹកជញ្ជូនថ្មី៖ " + ref,
                    "DISPATCH",
                    String.valueOf(result.getId()));

            return ResponseEntity.ok(new ApiResponse<>(true, "ការផ្តល់អ្នកបើកបរបានជោគជ័យ។", result));
        } catch (Exception ex) {
            log.error("Failed to assign driver for dispatch {}: {}", id, ex.getMessage(), ex);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new ApiResponse<>(false, "Failed to assign driver: " + ex.getMessage(), null));
        }
    }

    @PostMapping("/{id}/notify-assigned-driver")
    public ResponseEntity<ApiResponse<DispatchDto>> notifyAssignedDriver(@PathVariable Long id) {
        // Fetch dispatch without changing assignment; only notify if a driver is
        // already assigned
        DispatchDto result = dispatchService.getDispatchById(id);

        if (result == null || result.getDriverId() == null) {
            return ResponseEntity.ok(
                    new ApiResponse<>(false, "មិនមានអ្នកបើកបរត្រូវបានផ្តល់សម្រាប់ការដឹកជញ្ជូននេះ។", null));
        }

        String ref = firstNonBlank(result.getTransportOrderId(), result.getId().toString(), "-");
        safeNotify(
                result.getDriverId(),
                "ការដឹកជញ្ជូនថ្មីត្រូវបានផ្តល់ជូន",
                "អ្នកត្រូវបានផ្តល់ការដឹកជញ្ជូនថ្មី៖ " + ref,
                "DISPATCH",
                String.valueOf(result.getId()));

        return ResponseEntity.ok(new ApiResponse<>(true, "បានជូនដំណឹងទៅអ្នកបើកបរដោយជោគជ័យ។", result));
    }

    @PostMapping("/{id}/assign-truck")
    public ResponseEntity<ApiResponse<DispatchDto>> assignTruckOnly(
            @PathVariable Long id, @RequestParam Long vehicleId) {

        DispatchDto result = dispatchService.assignTruckOnly(id, vehicleId);

        safeNotify(
                result.getDriverId(),
                "បានផ្តល់រថយន្តថ្មីសម្រាប់ការដឹកជញ្ជូន",
                "បានកំណត់រថយន្តថ្មីសម្រាប់ការដឹកជញ្ជូន៖ " + nullSafe(result.getId().toString()),
                "DISPATCH",
                String.valueOf(result.getId()));

        return ResponseEntity.ok(new ApiResponse<>(true, "បានផ្តល់រថយន្តដោយជោគជ័យ។", result));
    }

    @PostMapping("/{id}/breakdown")
    public ResponseEntity<ApiResponse<DispatchDto>> reportBreakdown(
            @PathVariable Long id,
            @Valid @RequestBody BreakdownReportRequest request) {
        log.info("Driver reporting breakdown: dispatchId={}, location={}", id, request.getLocation());
        DispatchDto result = dispatchService.reportBreakdown(
                id,
                request.getLocation(),
                request.getDescription(),
                request.getLat(),
                request.getLng());
        return ResponseEntity.ok(new ApiResponse<>(true, "Breakdown reported successfully.", result));
    }

    // ---- Helpers ----

    private void safeNotify(
            Long driverId, String title, String message, String type, String referenceId) {
        try {
            if (driverId != null) {
                notificationService.sendNotification(
                        CreateNotificationRequest.builder()
                                .driverId(driverId)
                                .title(title)
                                .message(message)
                                .type(type)
                                .referenceId(referenceId)
                                .sender("system")
                                .build());
            }
        } catch (Exception ex) {
            log.warn("Notification send failed (ignored): {}", ex.getMessage());
        }
    }

    private static String nullSafe(String s) {
        return (s == null || s.isBlank()) ? "-" : s;
    }

    private static String firstNonBlank(Object a, Object b, String fallback) {
        if (a != null) {
            String s = a.toString();
            if (!s.isBlank())
                return s;
        }
        if (b != null) {
            String s = b.toString();
            if (!s.isBlank())
                return s;
        }
        return fallback;
    }

}
