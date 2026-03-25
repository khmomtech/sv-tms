package com.svtrucking.logistics.service;

import com.svtrucking.logistics.config.FeatureToggleConfig;
import com.svtrucking.logistics.dto.DispatchApprovalHistoryDto;
import com.svtrucking.logistics.dto.DispatchApprovalSLADto;
import com.svtrucking.logistics.dto.DispatchDto;
import com.svtrucking.logistics.dto.request.DispatchApprovalRequest;
import com.svtrucking.logistics.enums.DispatchApprovalStatus;
import com.svtrucking.logistics.enums.DispatchStatus;
import com.svtrucking.logistics.exception.InvalidDispatchDataException;
import com.svtrucking.logistics.exception.ResourceNotFoundException;
import com.svtrucking.logistics.model.Dispatch;
import com.svtrucking.logistics.model.DispatchApprovalHistory;
import com.svtrucking.logistics.model.DispatchApprovalHistory.ApprovalAction;
import com.svtrucking.logistics.model.DispatchApprovalSLA;
import com.svtrucking.logistics.model.DispatchApprovalSLA.SLAStatus;
import com.svtrucking.logistics.model.User;
import com.svtrucking.logistics.repository.DispatchApprovalHistoryRepository;
import com.svtrucking.logistics.repository.DispatchApprovalSLARepository;
import com.svtrucking.logistics.repository.DispatchRepository;
import com.svtrucking.logistics.security.AuthenticatedUserUtil;
import com.svtrucking.logistics.metrics.DispatchMetricsService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.EnumSet;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Service for Dispatch Approval workflow (Phase 2).
 * Handles approval/rejection of dispatch closures before marking CLOSED.
 * Implements approval gate, SLA tracking, and rejection rework flow.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class DispatchApprovalService {

        private final DispatchRepository dispatchRepository;
        private final DispatchApprovalHistoryRepository approvalHistoryRepository;
        private final DispatchApprovalSLARepository approvalSLARepository;
        private final AuthenticatedUserUtil authenticatedUserUtil;
        private final FeatureToggleConfig featureToggleConfig;

        @Autowired(required = false)
        private DispatchMetricsService dispatchMetricsService;

        /**
         * Statuses at which an admin approval/rejection action can be taken.
         * DRIVER_CONFIRMED: pre-departure admin gate (if feature enabled).
         * DELIVERED: post-delivery closure gate (standard path).
         */
        private static final Set<DispatchStatus> APPROVABLE_STATUSES = EnumSet.of(
                        DispatchStatus.DRIVER_CONFIRMED,
                        DispatchStatus.DELIVERED);

        /**
         * Approve dispatch closure and mark as CLOSED if feature enabled.
         * Creates approval history record and updates SLA tracking.
         * 
         * @param dispatchId Dispatch ID to approve
         * @param request    Approval request with remarks and optional flags
         * @return Updated dispatch DTO
         * @throws ResourceNotFoundException    if dispatch not found
         * @throws InvalidDispatchDataException if approval not allowed
         */
        @Transactional
        public DispatchDto approveDispatchClosure(Long dispatchId, DispatchApprovalRequest request) {
                log.info("Approving dispatch closure: dispatchId={}", dispatchId);

                // Validate feature toggle
                if (!featureToggleConfig.isApprovalGateEnabled()) {
                        log.warn("Approval gate feature is disabled. Approval will be recorded but not enforced.");
                }

                Dispatch dispatch = dispatchRepository.findById(dispatchId)
                                .orElseThrow(() -> new ResourceNotFoundException("Dispatch not found: " + dispatchId));

                // Validate current status — approval allowed at DELIVERED and DRIVER_CONFIRMED gates
                if (!APPROVABLE_STATUSES.contains(dispatch.getStatus())) {
                        throw new InvalidDispatchDataException("status",
                                        "Dispatch cannot be approved at status: " + dispatch.getStatus()
                                                        + ". Expected one of: " + APPROVABLE_STATUSES);
                }

                // Check POD photo review requirement if enabled
                if (featureToggleConfig.isPodPhotoReviewRequired()) {
                        Boolean podReviewed = request.getPodPhotosReviewed();
                        if (podReviewed == null || !podReviewed) {
                                throw new InvalidDispatchDataException("podPhotosReviewed",
                                                "POD photos must be reviewed before approval");
                        }
                }

                User currentUser = authenticatedUserUtil.getCurrentUser();

                // Get previous approval status from history
                DispatchApprovalStatus previousStatus = approvalHistoryRepository
                                .findLatestByDispatchId(dispatchId)
                                .map(DispatchApprovalHistory::getToStatus)
                                .orElse(DispatchApprovalStatus.NONE);

                // If approval gate enabled, mark as CLOSED
                if (featureToggleConfig.isApprovalGateEnabled()) {
                        dispatch.setStatus(DispatchStatus.CLOSED);
                        dispatch.setClosedAt(LocalDateTime.now());
                        dispatch.setClosedBy(currentUser);
                        log.info("Marking dispatch as CLOSED after approval: dispatchId={}", dispatchId);
                }

                Dispatch saved = dispatchRepository.save(dispatch);

                // Record approval history
                DispatchApprovalHistory history = DispatchApprovalHistory.builder()
                                .dispatch(dispatch)
                                .fromStatus(previousStatus)
                                .toStatus(DispatchApprovalStatus.APPROVED)
                                .action(ApprovalAction.APPROVED)
                                .approvalRemarks(request.getRemarks())
                                .reviewedBy(currentUser)
                                .build();
                approvalHistoryRepository.save(history);
                log.debug("Created approval history: dispatchId={}, action=APPROVED", dispatchId);

                // Update SLA tracking if enabled
                if (featureToggleConfig.isClosureSlaTrackingEnabled()) {
                        updateSLAOnApproval(dispatch);
                }

                return DispatchDto.fromEntityWithDetails(saved);
        }

        /**
         * Reject dispatch closure and revert to DELIVERED for rework.
         * Driver must resubmit POD proof or provide additional documentation.
         * 
         * @param dispatchId Dispatch ID to reject
         * @param request    Rejection request with mandatory remarks
         * @return Updated dispatch DTO
         * @throws ResourceNotFoundException    if dispatch not found
         * @throws InvalidDispatchDataException if rejection not allowed
         */
        @Transactional
        public DispatchDto rejectApproval(Long dispatchId, DispatchApprovalRequest request) {
                log.info("Rejecting dispatch closure: dispatchId={}", dispatchId);

                Dispatch dispatch = dispatchRepository.findById(dispatchId)
                                .orElseThrow(() -> new ResourceNotFoundException("Dispatch not found: " + dispatchId));

                // Validate current status — rejection allowed at same gates as approval
                if (!APPROVABLE_STATUSES.contains(dispatch.getStatus())) {
                        throw new InvalidDispatchDataException("status",
                                        "Dispatch cannot be rejected at status: " + dispatch.getStatus()
                                                        + ". Expected one of: " + APPROVABLE_STATUSES);
                }

                // Enforce rejection reason (always required)
                if (request.getRemarks() == null || request.getRemarks().trim().isEmpty()) {
                        throw new InvalidDispatchDataException("remarks",
                                        "Rejection reason is required when rejecting dispatch closure");
                }

                User currentUser = authenticatedUserUtil.getCurrentUser();

                // Get previous approval status from history
                DispatchApprovalStatus previousStatus = approvalHistoryRepository
                                .findLatestByDispatchId(dispatchId)
                                .map(DispatchApprovalHistory::getToStatus)
                                .orElse(DispatchApprovalStatus.NONE);

                // Dispatch remains in DELIVERED status for rework
                Dispatch saved = dispatchRepository.save(dispatch);

                // Record rejection history
                DispatchApprovalHistory history = DispatchApprovalHistory.builder()
                                .dispatch(dispatch)
                                .fromStatus(previousStatus)
                                .toStatus(DispatchApprovalStatus.REJECTED)
                                .action(ApprovalAction.REJECTED)
                                .approvalRemarks(request.getRemarks())
                                .reviewedBy(currentUser)
                                .build();
                approvalHistoryRepository.save(history);
                log.debug("Created rejection history: dispatchId={}, action=REJECTED", dispatchId);

                return DispatchDto.fromEntityWithDetails(saved);
        }

        /**
         * Get list of pending dispatch closures awaiting approval.
         * Returns dispatches in DELIVERED status with PENDING_APPROVAL status.
         * 
         * @return List of pending approval history records
         */
        @Transactional(readOnly = true)
        public List<DispatchApprovalHistoryDto> getPendingClosures() {
                log.debug("Fetching pending dispatch closures");

                // Use targeted query — never findAll() as this is a full-table scan
                List<Dispatch> pendingDispatches = dispatchRepository.findByStatusIn(APPROVABLE_STATUSES)
                                .stream()
                                .filter(dispatch -> {
                                        DispatchApprovalHistory latest = approvalHistoryRepository
                                                        .findLatestByDispatchId(dispatch.getId())
                                                        .orElse(null);
                                        return latest == null
                                                        || latest.getToStatus() != DispatchApprovalStatus.APPROVED;
                                })
                                .toList();

                // Convert to approval history DTOs with latest history entry
                return pendingDispatches.stream()
                                .map(dispatch -> {
                                        List<DispatchApprovalHistory> histories = approvalHistoryRepository
                                                        .findByDispatchIdOrderByCreatedAtDesc(dispatch.getId());

                                        if (!histories.isEmpty()) {
                                                return DispatchApprovalHistoryDto.from(histories.get(0));
                                        }

                                        // Create synthetic history entry if none exists
                                        return DispatchApprovalHistoryDto.builder()
                                                        .dispatchId(dispatch.getId())
                                                        .fromStatus(DispatchApprovalStatus.NONE.getValue())
                                                        .toStatus(DispatchApprovalStatus.PENDING_APPROVAL.getValue())
                                                        .action("PENDING")
                                                        .createdAt(dispatch.getUpdatedDate() != null
                                                                        ? dispatch.getUpdatedDate()
                                                                        : LocalDateTime.now())
                                                        .build();
                                })
                                .collect(Collectors.toList());
        }

        /**
         * Get SLA tracking information for a dispatch.
         * Creates SLA record if not exists and SLA tracking is enabled.
         * 
         * @param dispatchId Dispatch ID
         * @return SLA tracking DTO
         * @throws ResourceNotFoundException if dispatch not found
         */
        @Transactional
        public DispatchApprovalSLADto getSLAInfo(Long dispatchId) {
                log.debug("Fetching SLA info for dispatch: {}", dispatchId);

                Dispatch dispatch = dispatchRepository.findById(dispatchId)
                                .orElseThrow(() -> new ResourceNotFoundException("Dispatch not found: " + dispatchId));

                // Find or create SLA record
                DispatchApprovalSLA sla = approvalSLARepository.findByDispatchId(dispatchId)
                                .orElseGet(() -> {
                                        if (!featureToggleConfig.isClosureSlaTrackingEnabled()) {
                                                log.warn("SLA tracking is disabled. Creating SLA record anyway for dispatch: {}",
                                                                dispatchId);
                                        }
                                        return createSLARecord(dispatch);
                                });

                return DispatchApprovalSLADto.from(sla);
        }

        /**
         * Create SLA tracking record for a dispatch.
         * 
         * @param dispatch Dispatch entity
         * @return Created SLA record
         */
        private DispatchApprovalSLA createSLARecord(Dispatch dispatch) {
                // Get latest approval status from history
                DispatchApprovalStatus currentStatus = approvalHistoryRepository
                                .findLatestByDispatchId(dispatch.getId())
                                .map(DispatchApprovalHistory::getToStatus)
                                .orElse(DispatchApprovalStatus.PENDING_APPROVAL);

                DispatchApprovalSLA sla = DispatchApprovalSLA.builder()
                                .dispatch(dispatch)
                                .status(currentStatus)
                                .deliveredAt(LocalDateTime.now())
                                .slaTargetMinutes(featureToggleConfig.getClosureSlaTargetMinutes())
                                .slaStatus(SLAStatus.PENDING)
                                .build();

                DispatchApprovalSLA saved = approvalSLARepository.save(sla);
                log.debug("Created SLA record for dispatch: dispatchId={}, targetMinutes={}", dispatch.getId(),
                                sla.getSlaTargetMinutes());
                return saved;
        }

        /**
         * Update SLA record when dispatch is approved.
         * Calculates actual time and determines if SLA was breached.
         * 
         * @param dispatch Approved dispatch
         */
        private void updateSLAOnApproval(Dispatch dispatch) {
                DispatchApprovalSLA sla = approvalSLARepository.findByDispatchId(dispatch.getId())
                                .orElseGet(() -> createSLARecord(dispatch));

                sla.setStatus(DispatchApprovalStatus.APPROVED);
                sla.setApprovedAt(LocalDateTime.now());
                sla.calculateActualMinutes();

                // Check SLA breach
                if (sla.getActualMinutes() != null && sla.getActualMinutes() > sla.getSlaTargetMinutes()) {
                        sla.setSlaStatus(SLAStatus.BREACHED);
                        log.warn("SLA BREACH: dispatchId={}, targetMinutes={}, actualMinutes={}",
                                        dispatch.getId(), sla.getSlaTargetMinutes(), sla.getActualMinutes());
                        if (dispatchMetricsService != null) {
                                String routeCode = dispatch.getRouteCode() != null
                                                ? dispatch.getRouteCode()
                                                : String.valueOf(dispatch.getId());
                                dispatchMetricsService.recordSLABreach(routeCode);
                        }
                } else {
                        sla.setSlaStatus(SLAStatus.ON_TRACK);
                        log.debug("SLA met: dispatchId={}, targetMinutes={}, actualMinutes={}",
                                        dispatch.getId(), sla.getSlaTargetMinutes(), sla.getActualMinutes());
                }

                approvalSLARepository.save(sla);
        }
}
