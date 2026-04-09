package com.svtrucking.logistics.controller.admin;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.dto.DispatchDto;
import com.svtrucking.logistics.dto.DispatchStatusHistoryDto;
import com.svtrucking.logistics.dto.LoadProofDto;
import com.svtrucking.logistics.dto.UnloadProofDto;
import com.svtrucking.logistics.dto.dispatchflow.DispatchProofStateDto;
import com.svtrucking.logistics.dto.dispatchflow.DispatchFlowAssignDispatchRequest;
import com.svtrucking.logistics.dto.dispatchflow.DispatchWorkflowBindingDto;
import com.svtrucking.logistics.dto.response.DispatchStatusUpdateResponse;
import com.svtrucking.logistics.enums.DispatchStatus;
import com.svtrucking.logistics.modules.notification.dto.CreateNotificationRequest;
import com.svtrucking.logistics.modules.notification.service.DriverNotificationService;
import com.svtrucking.logistics.modules.notification.service.NotificationDispatchResult;
import com.svtrucking.logistics.dto.request.ReopenDispatchRequest;
import com.svtrucking.logistics.security.PermissionNames;
import com.svtrucking.logistics.service.DispatchService;
import com.svtrucking.logistics.service.ChangeTruckResult;
import com.svtrucking.logistics.service.LoadProofService;
import com.svtrucking.logistics.service.DispatchFlowAdminService;
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
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.http.HttpHeaders;
import com.svtrucking.logistics.service.SafetyChecklistPdfService;
import org.springframework.web.bind.annotation.*;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;

@Slf4j
@RestController
@RequestMapping("/api/admin/dispatches")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
public class DispatchAdminController {

    private final DispatchService dispatchService;
    private final DispatchFlowAdminService dispatchFlowAdminService;
    private final LoadProofService loadProofService;
    private final UnloadProofService unloadProofService;
    private final DriverNotificationService notificationService;
    private final SafetyChecklistPdfService safetyChecklistPdfService;

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
            return ResponseEntity.ok(
                    new ApiResponse<>(true, "បានបង្កើតបញ្ជាដឹកជញ្ជូនដោយជោគជ័យ។", createdDispatch));
        } catch (com.svtrucking.logistics.exception.InvalidDispatchDataException ex) {
            Map<String, String> fieldErrors = new HashMap<>();
            if (ex.getField() != null) {
                fieldErrors.put(ex.getField(), ex.getReason() != null ? ex.getReason() : ex.getMessage());
            } else {
                fieldErrors.put("_global", ex.getMessage());
            }
            log.error("Invalid dispatch data (admin create): {}", ex.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(new ApiResponse<>(false, "Failed to create dispatch", null, fieldErrors));
        } catch (Exception e) {
            log.error("Failed to create dispatch", e);
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(new ApiResponse<>(false, "Failed to create dispatch: " + e.getMessage(), null));
        }
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<DispatchDto>> getDispatchById(@PathVariable Long id) {
        DispatchDto dispatch = dispatchService.getDispatchById(id);
        if (dispatch == null) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(new ApiResponse<>(false, "Dispatch not found.", null));
        }

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

    @GetMapping("/{id}/proof-state")
    @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.DISPATCH_FLOW_MANAGE + "')")
    public ResponseEntity<ApiResponse<DispatchProofStateDto>> getDispatchProofState(@PathVariable Long id) {
        return ResponseEntity.ok(new ApiResponse<>(
                true,
                "Dispatch proof state fetched",
                dispatchFlowAdminService.getProofState(id)));
    }

    @GetMapping("/{id}/workflow-binding")
    @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.DISPATCH_FLOW_MANAGE + "')")
    public ResponseEntity<ApiResponse<DispatchWorkflowBindingDto>> getWorkflowBinding(@PathVariable Long id) {
        return ResponseEntity.ok(new ApiResponse<>(
                true,
                "Dispatch workflow binding fetched",
                dispatchFlowAdminService.getWorkflowBinding(id)));
    }

    @PatchMapping("/{id}/workflow-template")
    @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.DISPATCH_FLOW_MANAGE + "')")
    public ResponseEntity<ApiResponse<DispatchWorkflowBindingDto>> updateWorkflowTemplate(
            @PathVariable Long id,
            @Valid @RequestBody DispatchFlowAssignDispatchRequest request) {
        return ResponseEntity.ok(new ApiResponse<>(
                true,
                "Dispatch workflow template updated",
                dispatchFlowAdminService.assignDispatchTemplate(id, request)));
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

        // Validate date range
        if (start != null && end != null && start.isAfter(end)) {
            return ResponseEntity.badRequest()
                    .body(new ApiResponse<>(false, "កាលបរិច្ឆេទចាប់ផ្តើមត្រូវតែមុនកាលបរិច្ឆេទបញ្ចប់។", null));
        }

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
    @PreAuthorize("hasAnyAuthority('ROLE_ADMIN','ROLE_SUPERADMIN')")
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

    @GetMapping("/{id}/available-actions")
    public ResponseEntity<ApiResponse<DispatchStatusUpdateResponse>> getAvailableActions(
            @PathVariable Long id) {
        DispatchStatusUpdateResponse response = dispatchService.getAvailableActionsForDispatchAdmin(id);
        return ResponseEntity.ok(new ApiResponse<>(true, "Available actions fetched successfully.", response));
    }

    @PatchMapping("/{id}/status")
    @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.DISPATCH_STATUS_MANUAL_UPDATE + "')")
    public ResponseEntity<ApiResponse<DispatchDto>> updateDispatchStatus(
            @PathVariable Long id,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String reason,
            @RequestBody(required = false) Map<String, Object> payload) {
        String resolvedStatus = resolveStatus(status, payload);
        String resolvedReason = resolveReason(reason, payload);
        boolean forceOverride = resolveForceOverride(payload);

        if (!StringUtils.hasText(resolvedStatus)) {
            return ResponseEntity.badRequest()
                    .body(new ApiResponse<>(false, "សូមផ្តល់ស្ថានភាពសម្រាប់បញ្ជាដឹកជញ្ជូន។", null));
        }

        try {
            String key = resolvedStatus.trim().toUpperCase();
            if ("SAFETY_PASSED".equals(key) || "SAFETY_FAILED".equals(key)) {
                var safety = "SAFETY_PASSED".equals(key) ? com.svtrucking.logistics.enums.SafetyCheckStatus.PASSED
                        : com.svtrucking.logistics.enums.SafetyCheckStatus.FAILED;
                DispatchDto updated = dispatchService.updateDispatchSafetyStatus(id, safety);
                return ResponseEntity.ok(new ApiResponse<>(true, "បានធ្វើបច្ចុប្បន្នភាពសុវត្ថិភាពដោយជោគជ័យ។", updated));
            }

            DispatchDto updatedDispatch = dispatchService.updateDispatchStatus(
                    id,
                    DispatchStatus.valueOf(key),
                    resolvedReason,
                    forceOverride);
            return ResponseEntity.ok(
                    new ApiResponse<>(
                            true, "បានធ្វើបច្ចុប្បន្នភាពស្ថានភាពបញ្ជាដឹកជញ្ជូនដោយជោគជ័យ។", updatedDispatch));
        } catch (IllegalArgumentException ex) {
            return ResponseEntity.badRequest()
                    .body(new ApiResponse<>(false, "ស្ថានភាពមិនត្រឹមត្រូវ: " + resolvedStatus, null));
        }
    }

    @PatchMapping("/{id}/status/override")
    @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.DISPATCH_STATUS_OVERRIDE + "')")
    public ResponseEntity<ApiResponse<DispatchDto>> overrideDispatchStatus(
            @PathVariable Long id,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String reason,
            @RequestBody(required = false) Map<String, Object> payload) {
        String resolvedStatus = resolveStatus(status, payload);
        String resolvedReason = resolveReason(reason, payload);

        if (!StringUtils.hasText(resolvedStatus)) {
            return ResponseEntity.badRequest()
                    .body(new ApiResponse<>(false, "សូមផ្តល់ស្ថានភាពសម្រាប់បញ្ជាដឹកជញ្ជូន។", null));
        }
        if (!StringUtils.hasText(resolvedReason)) {
            return ResponseEntity.badRequest()
                    .body(new ApiResponse<>(false, "Override reason is required.", null));
        }

        try {
            DispatchDto updatedDispatch = dispatchService.updateDispatchStatus(
                    id,
                    DispatchStatus.valueOf(resolvedStatus.trim().toUpperCase()),
                    resolvedReason,
                    true);
            return ResponseEntity.ok(
                    new ApiResponse<>(true, "បានធ្វើបច្ចុប្បន្នភាពស្ថានភាព override ដោយជោគជ័យ។", updatedDispatch));
        } catch (IllegalArgumentException ex) {
            return ResponseEntity.badRequest()
                    .body(new ApiResponse<>(false, "ស្ថានភាពមិនត្រឹមត្រូវ: " + resolvedStatus, null));
        }
    }

    @PostMapping("/{id}/reopen")
    @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.DISPATCH_REOPEN + "')")
    public ResponseEntity<ApiResponse<DispatchDto>> reopenDispatch(
            @PathVariable Long id,
            @Valid @RequestBody ReopenDispatchRequest request) {
        log.info("Admin reopening dispatch: id={}, reason={}", id, request.getReason());
        DispatchDto result = dispatchService.reopenDispatch(id, request.getReason());
        return ResponseEntity.ok(new ApiResponse<>(true, "Dispatch reopened for investigation.", result));
    }

    private String resolveStatus(String status, Map<String, Object> payload) {
        if (StringUtils.hasText(status)) {
            return status;
        }
        if (payload != null && payload.get("status") != null) {
            return payload.get("status").toString();
        }
        return null;
    }

    private String resolveReason(String reason, Map<String, Object> payload) {
        if (StringUtils.hasText(reason)) {
            return reason;
        }
        if (payload == null) {
            return null;
        }
        Object fromReason = payload.get("reason");
        if (fromReason != null && StringUtils.hasText(fromReason.toString())) {
            return fromReason.toString();
        }
        Object fromRemarks = payload.get("remarks");
        if (fromRemarks != null && StringUtils.hasText(fromRemarks.toString())) {
            return fromRemarks.toString();
        }
        Object fromNote = payload.get("note");
        if (fromNote != null && StringUtils.hasText(fromNote.toString())) {
            return fromNote.toString();
        }
        return null;
    }

    private boolean resolveForceOverride(Map<String, Object> payload) {
        if (payload == null) {
            return false;
        }

        Object force = payload.get("force");
        if (force == null) {
            force = payload.get("forceOverride");
        }
        if (force == null) {
            force = payload.get("manualOverride");
        }
        if (force == null) {
            return false;
        }

        return Boolean.parseBoolean(force.toString());
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasAnyAuthority('ROLE_ADMIN','ROLE_SUPERADMIN')")
    public ResponseEntity<ApiResponse<Void>> deleteDispatch(@PathVariable Long id) {
        dispatchService.deleteDispatch(id);
        return ResponseEntity.ok(new ApiResponse<>(true, "បានលុបបញ្ជាដឹកជញ្ជូនដោយជោគជ័យ។", null));
    }

    @DeleteMapping("/bulk")
    @PreAuthorize("hasAnyAuthority('ROLE_ADMIN','ROLE_SUPERADMIN')")
    public ResponseEntity<ApiResponse<Void>> bulkDeleteDispatches(
            @RequestBody List<Long> dispatchIds) {
        if (dispatchIds == null || dispatchIds.isEmpty()) {
            return ResponseEntity.badRequest()
                    .body(new ApiResponse<>(false, "សូមជ្រើសយកបញ្ជាដឹកជញ្ជូនយ៉ាងហោចណាស់មួយ.", null));
        }
        if (dispatchIds.size() > 100) {
            return ResponseEntity.badRequest()
                    .body(new ApiResponse<>(false, "អាចលុបបានតែ 100 ឯកសារក្នុងពេលតែមួយ។", null));
        }
        dispatchService.deleteDispatches(dispatchIds);
        return ResponseEntity.ok(
                new ApiResponse<>(true, "បានលុបបញ្ជាដឹកជញ្ជូន " + dispatchIds.size() + " ឯកសារដោយជោគជ័យ។", null));
    }

    @PutMapping("/{id}/change-driver")
    @PreAuthorize("hasAnyAuthority('ROLE_ADMIN','ROLE_SUPERADMIN')")
    public ResponseEntity<ApiResponse<DispatchDto>> changeDriver(
            @PathVariable Long id,
            @RequestParam(required = false) Long driverId,
            @RequestBody(required = false) Map<String, Object> payload) {

        // Support driverId sent either as a query param or in the JSON body (frontend
        // may send { driverId }).
        if (driverId == null && payload != null && payload.get("driverId") != null) {
            try {
                driverId = Long.parseLong(payload.get("driverId").toString());
            } catch (NumberFormatException ex) {
                return ResponseEntity.badRequest()
                        .body(new ApiResponse<>(false, "Invalid driverId value", null));
            }
        }

        if (driverId == null) {
            return ResponseEntity.badRequest()
                    .body(new ApiResponse<>(false, "Missing required parameter: driverId", null));
        }

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
    @PreAuthorize("hasAnyAuthority('ROLE_ADMIN','ROLE_SUPERADMIN')")
    public ResponseEntity<ApiResponse<DispatchDto>> changeTruck(
            @PathVariable Long id, @RequestParam(required = false) Long vehicleId) {
        if (vehicleId == null) {
            return ResponseEntity.badRequest()
                    .body(new ApiResponse<>(false, "Missing required parameter: vehicleId", null));
        }

        ChangeTruckResult result = dispatchService.changeTruck(id, vehicleId);
        if (result.getWarnings() != null && !result.getWarnings().isEmpty()) {
            var warning = java.util.Map.of("warnings", result.getWarnings());
            return ResponseEntity.ok(new ApiResponse<>(true, "បានផ្លាស់ប្តូររថយន្តដោយជោគជ័យ (មិនទាន់ប្តូរប្រព័ន្ធ):",
                    result.getDispatch(), warning));
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
        } catch (Exception e) {
            log.error("Failed to submit load proof for dispatch {}: {}", dispatchId, e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new ApiResponse<>(false, "បរាជ័យក្នុងការដាក់ស្នើភស្ដុតាងពេលផ្ទុក។", null));
        }
    }

    @PostMapping(value = "/driver/load-proof/{dispatchId}/load", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @PreAuthorize("hasAuthority('ROLE_DRIVER')")
    public ResponseEntity<ApiResponse<LoadProofDto>> driverSubmitLoadProof(
            @PathVariable Long dispatchId,
            @RequestParam(required = false) String remarks,
            @RequestParam(required = false) List<MultipartFile> images,
            @RequestParam(required = false) MultipartFile signature) {
        return submitLoadProof(dispatchId, remarks, images, signature);
    }

    @PostMapping(value = "/driver/unload-proof/{dispatchId}/unload", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @PreAuthorize("hasAuthority('ROLE_DRIVER')")
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
            log.error("Failed to submit unload proof for dispatch {}: {}", dispatchId, e.getMessage(), e);
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
    public ResponseEntity<ApiResponse<Page<DispatchDto>>> getDispatchesByDriverWithDateRange(
            @PathVariable Long driverId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to,
            @PageableDefault(size = 20) Pageable pageable) {

        // TODO: Implement date range filtering in DispatchService
        // For now, return all dispatches for the driver
        Page<DispatchDto> page = dispatchService.getDispatchesByDriverId(driverId, pageable);

        return ResponseEntity.ok(
                new ApiResponse<>(true, "ទាញយកបញ្ជាដឹកជញ្ជូនបានជោគជ័យ។", page));
    }

    // 🔙 Restored old endpoint so existing clients keep working
    @GetMapping("/driver/{driverId}/status")
    public ResponseEntity<Page<DispatchDto>> getDispatchesByDriverWithStatusFilter(
            @PathVariable Long driverId,
            @RequestParam(required = false) String status,
            Pageable pageable) {

        List<DispatchStatus> statuses = null;
        if (status != null && !status.isBlank()) {
            statuses = Arrays.stream(status.split(","))
                    .map(s -> DispatchStatus.valueOf(s.trim().toUpperCase()))
                    .collect(Collectors.toList());
        }
        Page<DispatchDto> page = dispatchService.getDispatchesByDriverWithStatuses(driverId, statuses, pageable);
        return ResponseEntity.ok(page);
    }

    @PostMapping("/{id}/accept")
    @PreAuthorize("hasAuthority('ROLE_DRIVER')")
    public ResponseEntity<ApiResponse<DispatchDto>> acceptDispatch(@PathVariable Long id) {
        DispatchDto dto = dispatchService.acceptDispatch(id);
        return ResponseEntity.ok(new ApiResponse<>(true, "អ្នកបើកបរបានទទួលបញ្ជាដឹកជញ្ជូន។", dto));
    }

    @PostMapping("/{id}/reject")
    @PreAuthorize("hasAuthority('ROLE_DRIVER')")
    public ResponseEntity<ApiResponse<DispatchDto>> rejectDispatch(
            @PathVariable Long id, @RequestParam String reason) {
        DispatchDto dto = dispatchService.rejectDispatch(id, reason);
        return ResponseEntity.ok(new ApiResponse<>(true, "អ្នកបើកបរបានបដិសេធបញ្ជាដឹកជញ្ជូន។", dto));
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
    @PreAuthorize("hasAnyAuthority('ROLE_ADMIN','ROLE_SUPERADMIN')")
    public ResponseEntity<ApiResponse<DispatchDto>> planTrip(
            @RequestBody Map<String, Object> payload) {
        Long orderId = Long.parseLong(payload.get("orderId").toString());
        String tripType = payload.get("tripType").toString();
        Long vehicleId = Long.parseLong(payload.get("vehicleId").toString());
        String scheduleTime = payload.get("scheduleTime").toString();
        String estimatedDrop = payload.get("estimatedDrop").toString();

        String manualRouteCode = payload.containsKey("manualRouteCode")
                ? payload.get("manualRouteCode").toString().trim()
                : null;

        DispatchDto plannedDispatch = dispatchService.planTrip(
                orderId, tripType, vehicleId, scheduleTime, estimatedDrop, manualRouteCode);

        return ResponseEntity.ok(
                new ApiResponse<>(true, "ការធ្វើជើងដឹកត្រូវបានរៀបចំដោយជោគជ័យ។", plannedDispatch));
    }

    @PostMapping(value = "/import-bulk", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @PreAuthorize("hasAnyAuthority('ROLE_ADMIN','ROLE_SUPERADMIN')")
    public ResponseEntity<ApiResponse<String>> importBulkDispatches(
            @RequestParam("file") MultipartFile file) {
        try {
            String filename = Optional.ofNullable(file.getOriginalFilename()).map(String::toLowerCase).orElse("");
            if (file.isEmpty() || !filename.endsWith(".xlsx")) {
                return ResponseEntity.badRequest()
                        .body(new ApiResponse<>(false, "ទ្រង់ទ្រាយឯកសារ​មិនត្រឹមត្រូវ។", null));
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
    @PreAuthorize("hasAnyAuthority('ROLE_ADMIN','ROLE_SUPERADMIN')")
    public ResponseEntity<ApiResponse<DispatchDto>> assignDriverOnly(
            @PathVariable Long id, @RequestParam Long driverId) {
        try {
            // Use changeDriver to apply validation and return full details
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
        // Promote PENDING -> ASSIGNED before notifying so dispatch state matches
        // the fact that the driver has now been actively notified.
        DispatchDto result = dispatchService.assignNotifyDriverOnly(id);

        if (result == null || result.getDriverId() == null) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(new ApiResponse<>(false, "មិនមានអ្នកបើកបរត្រូវបានផ្តល់សម្រាប់ការដឹកជញ្ជូននេះ។", null));
        }

        String ref = firstNonBlank(result.getTransportOrderId(), result.getId().toString(), "-");
        NotificationDispatchResult notificationResult = notificationService.sendNotification(
                CreateNotificationRequest.builder()
                        .driverId(result.getDriverId())
                        .title("New shipment assigned")
                        .message("You have been assigned a new shipment: " + ref)
                        .type("DISPATCH")
                        .referenceId(String.valueOf(result.getId()))
                        .actionLabel("View shipment")
                        .actionUrl("/dispatches/" + result.getId())
                        .sender("system")
                        .build());

        String message = notificationResult.hasLiveDelivery()
                ? "Driver notified and shipment marked as Assigned."
                : "Shipment marked as Assigned. Notification was saved for the driver, but live delivery is currently unavailable.";

        return ResponseEntity.ok(new ApiResponse<>(true, message, result,
                notificationResult.hasLiveDelivery()
                        ? null
                        : java.util.Map.of(
                                "notificationRecorded", notificationResult.hasRecordedDelivery(),
                                "liveDelivery", false)));
    }

    @PostMapping("/{id}/assign-truck")
    @PreAuthorize("hasAnyAuthority('ROLE_ADMIN','ROLE_SUPERADMIN')")
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

    // ---- Helpers ----

    @GetMapping("/{id}/safety-pdf")
    @PreAuthorize("hasAnyAuthority('ROLE_ADMIN','ROLE_SUPERADMIN')")
    public ResponseEntity<byte[]> getSafetyPdf(@PathVariable Long id) {
        byte[] pdf = safetyChecklistPdfService.generate(id);
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_PDF);
        headers.add("Content-Disposition", "inline; filename=preloading-safety-" + id + ".pdf");
        return new ResponseEntity<>(pdf, headers, HttpStatus.OK);
    }

    @PostMapping("/{id}/message-driver")
    @PreAuthorize("hasAnyAuthority('ROLE_ADMIN','ROLE_SUPERADMIN')")
    public ResponseEntity<ApiResponse<Void>> messageDriver(
            @PathVariable Long id, @RequestBody Map<String, String> payload) {
        String title = payload.getOrDefault("title", "SVT Message");
        String message = payload.get("message");
        if (message == null || message.isBlank()) {
            return ResponseEntity.badRequest()
                    .body(new ApiResponse<>(false, "ទេីបផ្តល់សារ។", null));
        }
        DispatchDto dispatch = dispatchService.getDispatchById(id);
        if (dispatch == null || dispatch.getDriverId() == null) {
            return ResponseEntity.badRequest()
                    .body(new ApiResponse<>(false, "គ្មានអ្នកបើកបរត្រូវបានផ្តល់សម្រាប់ការដឹកជញ្ជូននេះ។", null));
        }

        safeNotify(dispatch.getDriverId(), title, message, "MESSAGE", String.valueOf(id));
        return ResponseEntity.ok(new ApiResponse<>(true, "បានផ្ញើសារទៅអ្នកបើកបរដោយជោគជ័យ។", null));
    }

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

    @org.springframework.web.bind.annotation.ExceptionHandler({ jakarta.persistence.OptimisticLockException.class })
    public ResponseEntity<ApiResponse<String>> handleOptimisticLock(Exception ex) {
        log.warn("Optimistic lock failure: {}", ex.getMessage());
        return ResponseEntity.status(HttpStatus.CONFLICT)
                .body(new ApiResponse<>(false, "Conflict: concurrent update detected. Please retry.", null));
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
