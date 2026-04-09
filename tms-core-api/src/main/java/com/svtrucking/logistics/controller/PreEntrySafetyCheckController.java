package com.svtrucking.logistics.controller;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.dto.PreEntrySafetyCheckDto;
import com.svtrucking.logistics.dto.request.PreEntrySafetyCheckSubmitRequest;
import com.svtrucking.logistics.dto.request.SafetyConditionalOverrideRequest;
import com.svtrucking.logistics.enums.PreEntrySafetyStatus;
import com.svtrucking.logistics.service.PreEntrySafetyCheckService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import jakarta.validation.Valid;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;

/**
 * REST controller for pre-entry safety checks (Phase 3).
 * Endpoints for safety inspections before warehouse arrival/loading.
 * 
 * Base path: /api/admin/pre-entry-safety or /api/field-checker/pre-entry-safety
 * Authorization: SAFETY, ADMIN, SUPERADMIN, all_functions
 */
@Slf4j
@RestController
@RequestMapping("/api/admin/pre-entry-safety")
@RequiredArgsConstructor
public class PreEntrySafetyCheckController {

    private final PreEntrySafetyCheckService preEntrySafetyCheckService;

    /**
     * Submit pre-entry safety check for a dispatch
     * POST /api/admin/pre-entry-safety/submit
     * 
     * Typically called by field checker/safety personnel when vehicle arrives at
     * gate
     */
    @PostMapping("/submit")
    @PreAuthorize("hasAnyRole('SAFETY', 'ADMIN', 'SUPERADMIN') OR hasAuthority('all_functions')")
    public ResponseEntity<PreEntrySafetyCheckDto> submitSafetyCheck(
            @Valid @RequestBody PreEntrySafetyCheckSubmitRequest request) {
        log.info("Submitting pre-entry safety check for dispatch {}", request.getDispatchId());
        PreEntrySafetyCheckDto result = preEntrySafetyCheckService.submitSafetyCheck(request);
        return ResponseEntity.ok(result);
    }

    /**
     * Approve conditional override for safety check
     * POST /api/admin/pre-entry-safety/{checkId}/override
     * 
     * Allows supervisor to approve vehicle with minor safety issues (CONDITIONAL
     * status)
     */
    @PostMapping("/{checkId}/override")
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPERADMIN', 'MANAGER') OR hasAuthority('all_functions')")
    public ResponseEntity<PreEntrySafetyCheckDto> approveConditionalOverride(
            @PathVariable Long checkId,
            @Valid @RequestBody SafetyConditionalOverrideRequest request) {
        log.info("Processing conditional override for safety check {}", checkId);
        request.setSafetyCheckId(checkId);
        PreEntrySafetyCheckDto result = preEntrySafetyCheckService.approveConditionalOverride(request);
        return ResponseEntity.ok(result);
    }

    /**
     * Get pre-entry safety check for a dispatch
     * GET /api/admin/pre-entry-safety/dispatch/{dispatchId}
     */
    @GetMapping("/dispatch/{dispatchId}")
    @PreAuthorize("hasAnyRole('SAFETY', 'ADMIN', 'SUPERADMIN', 'DISPATCH_MONITOR') OR hasAuthority('all_functions')")
    public ResponseEntity<PreEntrySafetyCheckDto> getByDispatchId(@PathVariable Long dispatchId) {
        log.debug("Fetching pre-entry safety check for dispatch {}", dispatchId);
        PreEntrySafetyCheckDto result = preEntrySafetyCheckService.getByDispatchId(dispatchId);
        return ResponseEntity.ok(result);
    }

    /**
     * Get all pending conditional overrides awaiting supervisor approval
     * GET /api/admin/pre-entry-safety/pending-overrides
     */
    @GetMapping("/pending-overrides")
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPERADMIN', 'MANAGER') OR hasAuthority('all_functions')")
    public ResponseEntity<List<PreEntrySafetyCheckDto>> getPendingConditionalOverrides() {
        log.debug("Fetching pending conditional overrides");
        List<PreEntrySafetyCheckDto> pending = preEntrySafetyCheckService.getPendingConditionalOverrides();
        return ResponseEntity.ok(pending);
    }

    /**
     * Upload pre-entry inspection photo.
     * POST /api/admin/pre-entry-safety/photos/upload
     */
    @PostMapping(value = "/photos/upload", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @PreAuthorize("hasAnyRole('SAFETY', 'ADMIN', 'SUPERADMIN') OR hasAuthority('all_functions')")
    public ResponseEntity<ApiResponse<Map<String, String>>> uploadPreEntryPhoto(@RequestPart("file") MultipartFile file) {
        String url = preEntrySafetyCheckService.uploadInspectionPhoto(file);
        return ResponseEntity.ok(ApiResponse.ok("Photo uploaded", Map.of("url", url)));
    }

    /**
     * List pre-entry safety checks with optional filters.
     * GET /api/admin/pre-entry-safety
     */
    @GetMapping
    @PreAuthorize("hasAnyRole('SAFETY', 'ADMIN', 'SUPERADMIN', 'DISPATCH_MONITOR') OR hasAuthority('all_functions')")
    public ResponseEntity<List<PreEntrySafetyCheckDto>> list(
            @RequestParam(required = false) PreEntrySafetyStatus status,
            @RequestParam(required = false) String warehouseCode,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate fromDate,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate toDate,
            @RequestParam(required = false) List<Long> dispatchIds) {
        return ResponseEntity.ok(preEntrySafetyCheckService.listSafetyChecks(status, warehouseCode, fromDate, toDate, dispatchIds));
    }

    /**
     * Get pre-entry safety check by id.
     * GET /api/admin/pre-entry-safety/{checkId}
     */
    @GetMapping("/{checkId:\\d+}")
    @PreAuthorize("hasAnyRole('SAFETY', 'ADMIN', 'SUPERADMIN', 'DISPATCH_MONITOR') OR hasAuthority('all_functions')")
    public ResponseEntity<PreEntrySafetyCheckDto> getById(@PathVariable Long checkId) {
        return ResponseEntity.ok(preEntrySafetyCheckService.getById(checkId));
    }

    /**
     * Replace an existing pre-entry safety check.
     * PUT /api/admin/pre-entry-safety/{checkId}
     */
    @PutMapping("/{checkId:\\d+}")
    @PreAuthorize("hasAnyRole('SAFETY', 'ADMIN', 'SUPERADMIN') OR hasAuthority('all_functions')")
    public ResponseEntity<PreEntrySafetyCheckDto> updateSafetyCheck(
            @PathVariable Long checkId,
            @Valid @RequestBody PreEntrySafetyCheckSubmitRequest request) {
        return ResponseEntity.ok(preEntrySafetyCheckService.updateSafetyCheck(checkId, request));
    }

    /**
     * Delete pre-entry safety check.
     * DELETE /api/admin/pre-entry-safety/{checkId}
     */
    @DeleteMapping("/{checkId:\\d+}")
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPERADMIN') OR hasAuthority('all_functions')")
    public ResponseEntity<Void> deleteSafetyCheck(@PathVariable Long checkId) {
        preEntrySafetyCheckService.deleteSafetyCheck(checkId);
        return ResponseEntity.noContent().build();
    }
}
