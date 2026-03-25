package com.svtrucking.logistics.controller;

import com.svtrucking.logistics.dto.DispatchApprovalHistoryDto;
import com.svtrucking.logistics.dto.DispatchApprovalSLADto;
import com.svtrucking.logistics.dto.DispatchDto;
import com.svtrucking.logistics.dto.request.DispatchApprovalRequest;
import com.svtrucking.logistics.service.DispatchApprovalService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import jakarta.validation.Valid;
import java.util.List;

/**
 * REST controller for dispatch approval workflow (Phase 2).
 * Endpoints for approving/rejecting dispatch closures before marking CLOSED.
 * 
 * Base path: /api/admin/dispatch-approval
 * Authorization: ADMIN, SUPERADMIN, all_functions
 */
@Slf4j
@RestController
@RequestMapping("/api/admin/dispatch-approval")
@RequiredArgsConstructor
public class DispatchApprovalController {

    private final DispatchApprovalService dispatchApprovalService;

    /**
     * Approve a dispatch closure
     * POST /api/admin/dispatch-approval/{dispatchId}/approve
     */
    @PostMapping("/{dispatchId}/approve")
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPERADMIN') OR hasAuthority('all_functions')")
    public ResponseEntity<DispatchDto> approveDispatchClosure(
            @PathVariable Long dispatchId,
            @Valid @RequestBody DispatchApprovalRequest request) {
        log.info("Approving dispatch closure for dispatch {}", dispatchId);
        DispatchDto result = dispatchApprovalService.approveDispatchClosure(dispatchId, request);
        return ResponseEntity.ok(result);
    }

    /**
     * Reject a dispatch closure and require rework
     * POST /api/admin/dispatch-approval/{dispatchId}/reject
     */
    @PostMapping("/{dispatchId}/reject")
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPERADMIN') OR hasAuthority('all_functions')")
    public ResponseEntity<DispatchDto> rejectDispatcclosure(
            @PathVariable Long dispatchId,
            @Valid @RequestBody DispatchApprovalRequest request) {
        log.info("Rejecting dispatch closure for dispatch {}. Reason: {}", dispatchId, request.getRemarks());
        DispatchDto result = dispatchApprovalService.rejectApproval(dispatchId, request);
        return ResponseEntity.ok(result);
    }

    /**
     * Get list of pending closures awaiting approval
     * GET /api/admin/dispatch-approval/pending
     */
    @GetMapping("/pending")
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPERADMIN', 'DISPATCH_MONITOR') OR hasAuthority('all_functions')")
    public ResponseEntity<List<DispatchApprovalHistoryDto>> getPendingClosures() {
        log.debug("Fetching pending dispatch closures");
        List<DispatchApprovalHistoryDto> pending = dispatchApprovalService.getPendingClosures();
        return ResponseEntity.ok(pending);
    }

    /**
     * Get SLA information for a dispatch
     * GET /api/admin/dispatch-approval/{dispatchId}/sla
     */
    @GetMapping("/{dispatchId}/sla")
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPERADMIN', 'DISPATCH_MONITOR') OR hasAuthority('all_functions')")
    public ResponseEntity<DispatchApprovalSLADto> getSLAInfo(@PathVariable Long dispatchId) {
        log.debug("Fetching SLA info for dispatch {}", dispatchId);
        DispatchApprovalSLADto slaInfo = dispatchApprovalService.getSLAInfo(dispatchId);
        return ResponseEntity.ok(slaInfo);
    }
}
