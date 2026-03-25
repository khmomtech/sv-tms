package com.svtrucking.logistics.service.impl;

import com.svtrucking.logistics.dto.PreLoadingSafetyCheckRequest;
import com.svtrucking.logistics.dto.PreLoadingSafetyCheckResponse;
import com.svtrucking.logistics.dto.LoadingSessionStartRequest;
import com.svtrucking.logistics.config.FeatureToggleConfig;
import com.svtrucking.logistics.enums.DispatchStatus;
import com.svtrucking.logistics.enums.LoadingQueueStatus;
import com.svtrucking.logistics.enums.SafetyCheckStatus;
import com.svtrucking.logistics.enums.SafetyResult;
import com.svtrucking.logistics.enums.WarehouseCode;
import com.svtrucking.logistics.model.Dispatch;
import com.svtrucking.logistics.model.PreLoadingSafetyCheck;
import com.svtrucking.logistics.model.DispatchStatusHistory;
import com.svtrucking.logistics.model.LoadingQueue;
import com.svtrucking.logistics.model.User;
import com.svtrucking.logistics.repository.DispatchRepository;
import com.svtrucking.logistics.repository.PreLoadingSafetyCheckRepository;
import com.svtrucking.logistics.repository.DispatchStatusHistoryRepository;
import com.svtrucking.logistics.repository.LoadingQueueRepository;
import com.svtrucking.logistics.repository.UserRepository;
import com.svtrucking.logistics.security.AuthenticatedUserUtil;
import com.svtrucking.logistics.service.LoadingWorkflowService;
import com.svtrucking.logistics.service.PreLoadingSafetyCheckService;
import com.svtrucking.logistics.validator.DispatchValidator;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.access.AccessDeniedException;

import java.time.LocalDateTime;
import java.util.EnumSet;
import java.util.List;
import java.util.NoSuchElementException;
import java.util.Set;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class PreLoadingSafetyCheckServiceImpl implements PreLoadingSafetyCheckService {
  private static final String AUTO_CALL_REMARKS = "Auto-called after pre-entry PASS";
  private static final String AUTO_TRANSITION_NOTE =
      "Pre-entry safety PASSED -> auto transition to LOADING (KHB).";
  private static final String QUEUE_REQUIRED_TRANSITION_MESSAGE =
      "Queue entry required before pre-entry PASS can transition to loading.";

  private final PreLoadingSafetyCheckRepository safetyRepo;
  private final DispatchRepository dispatchRepo;
  private final DispatchStatusHistoryRepository dispatchStatusHistoryRepository;
  private final LoadingQueueRepository loadingQueueRepository;
  private final UserRepository userRepo;
  private final com.svtrucking.logistics.repository.LoadingSessionRepository loadingSessionRepository;
  private final com.svtrucking.logistics.repository.LoadingDocumentRepository loadingDocumentRepository;
  private final LoadingWorkflowService loadingWorkflowService;
  private final AuthenticatedUserUtil authUtil;
  private final DispatchValidator dispatchValidator;
  private final FeatureToggleConfig featureToggleConfig;

  private static final Set<DispatchStatus> ALLOWED_STATUSES =
      EnumSet.of(
        DispatchStatus.ASSIGNED,
        DispatchStatus.ARRIVED_LOADING,
        DispatchStatus.IN_QUEUE);

  @Override
  public PreLoadingSafetyCheckResponse submitSafetyCheck(PreLoadingSafetyCheckRequest request) {
    ensureSafetyRole();

    Dispatch dispatch = dispatchRepo.findById(request.getDispatchId())
        .orElseThrow(() -> new NoSuchElementException("Dispatch not found: " + request.getDispatchId()));
    ensureStatusAllowed(dispatch);

    if (request.getResult() == SafetyResult.FAIL &&
        (request.getFailReason() == null || request.getFailReason().isBlank())) {
      throw new IllegalArgumentException("Fail reason is required when result is FAIL");
    }

    // Idempotency: if clientUuid provided and already exists, return existing record
    if (request.getClientUuid() != null && !request.getClientUuid().isBlank()) {
      var existing = safetyRepo.findByClientUuid(request.getClientUuid());
      if (existing.isPresent()) {
        return map(existing.get());
      }
    }

    Long currentUserId = request.getCheckedByUserId() != null
        ? request.getCheckedByUserId()
        : authUtil.getCurrentUserId();
    User checker = currentUserId != null ? userRepo.findById(currentUserId).orElse(null) : null;
    LocalDateTime checkedAt = request.getCheckedAt() != null ? request.getCheckedAt() : LocalDateTime.now();

    PreLoadingSafetyCheck.PreLoadingSafetyCheckBuilder builder = PreLoadingSafetyCheck.builder()
        .dispatch(dispatch)
        .driverPpeOk(Boolean.TRUE.equals(request.getDriverPpeOk()))
        .fireExtinguisherOk(Boolean.TRUE.equals(request.getFireExtinguisherOk()))
        .wheelChockOk(Boolean.TRUE.equals(request.getWheelChockOk()))
        .truckLeakageOk(Boolean.TRUE.equals(request.getTruckLeakageOk()))
        .truckCleanOk(Boolean.TRUE.equals(request.getTruckCleanOk()))
        .truckConditionOk(Boolean.TRUE.equals(request.getTruckConditionOk()))
        .result(request.getResult())
        .failReason(request.getFailReason())
        .checkedBy(checker)
        .checkedAt(checkedAt)
        .clientUuid(request.getClientUuid())
        .locationLat(request.getLocationLat() != null ? new java.math.BigDecimal(request.getLocationLat()) : null)
        .locationLng(request.getLocationLng() != null ? new java.math.BigDecimal(request.getLocationLng()) : null)
        .synced(false)
        .checkedBy(checker)
        .checkedAt(checkedAt);

    if (request.getLoadingSessionId() != null) {
      loadingSessionRepository.findById(request.getLoadingSessionId()).ifPresent(builder::loadingSession);
    }
    if (request.getProofDocumentId() != null) {
      loadingDocumentRepository.findById(request.getProofDocumentId()).ifPresent(builder::proofDocument);
    }

    PreLoadingSafetyCheck entity = builder.build();

    entity = safetyRepo.save(entity);

    // Record safety result on the dispatch (separate from lifecycle status) and keep audit history
    SafetyCheckStatus newSafety = request.getResult() == SafetyResult.PASS ? SafetyCheckStatus.PASSED : SafetyCheckStatus.FAILED;
    updateDispatchSafety(dispatch, newSafety, "Pre-loading safety check: " + request.getResult().name());

    boolean autoTransitionApplied = false;
    String transitionMessage = null;
    if (request.getResult() == SafetyResult.PASS) {
      AutoTransitionResult result = autoTransitionToLoadingIfEligible(dispatch);
      autoTransitionApplied = result.applied();
      transitionMessage = result.message();
    } else {
      transitionMessage =
          "Pre-entry failed. Loading progression is blocked until resolved/override.";
    }

    Dispatch dispatchAfterCheck = dispatchRepo.findById(dispatch.getId()).orElse(dispatch);

    log.info("Safety check recorded for dispatch {} -> {}", dispatch.getId(), request.getResult());
    return map(
        entity,
        dispatchAfterCheck.getStatus() != null ? dispatchAfterCheck.getStatus().name() : null,
        autoTransitionApplied,
        transitionMessage);
  }

  @Override
  @Transactional(readOnly = true)
  public PreLoadingSafetyCheckResponse getLatestByDispatch(Long dispatchId) {
    PreLoadingSafetyCheck latest =
        safetyRepo
            .findTopByDispatchIdOrderByCheckedAtDesc(dispatchId)
            .or(() -> safetyRepo.findTopByDispatchIdOrderByCheckedAtDescCreatedDateDesc(dispatchId))
            .orElseThrow(
                () -> new NoSuchElementException("No safety check found for dispatch " + dispatchId));
    return map(latest);
  }

  @Override
  @Transactional(readOnly = true)
  public List<PreLoadingSafetyCheckResponse> getHistory(Long dispatchId) {
    return safetyRepo.findByDispatchIdOrderByCheckedAtDescCreatedDateDesc(dispatchId).stream()
        .map(this::map)
        .toList();
  }

  private void ensureStatusAllowed(Dispatch dispatch) {
    // Allow when lifecycle status is ASSIGNED/ARRIVED_LOADING, or when a prior safety result exists
    if (!ALLOWED_STATUSES.contains(dispatch.getStatus()) && dispatch.getSafetyStatus() == null) {
      throw new IllegalStateException(
          "Pre-entry safety check allowed only when dispatch is ASSIGNED, ARRIVED_LOADING, IN_QUEUE, or re-checking safety status.");
    }
  }

  private void updateDispatchSafety(Dispatch dispatch, SafetyCheckStatus safety, String remarks) {
    // If safety result unchanged, do nothing
    if (dispatch.getSafetyStatus() == safety) return;
    dispatch.setSafetyStatus(safety);
    dispatch.setUpdatedDate(LocalDateTime.now());
    Dispatch saved = dispatchRepo.save(dispatch);

    // Keep existing DispatchStatusHistory audit records using the legacy SAFETY_* markers
    DispatchStatus historyStatus = safety == SafetyCheckStatus.PASSED ? DispatchStatus.SAFETY_PASSED : DispatchStatus.SAFETY_FAILED;
    DispatchStatusHistory history = new DispatchStatusHistory();
    history.setDispatch(saved);
    history.setStatus(historyStatus);
    history.setRemarks(remarks);
    history.setUpdatedAt(LocalDateTime.now());
    history.setUpdatedBy(resolveCurrentUsername());
    dispatchStatusHistoryRepository.save(history);
  }

  private void ensureSafetyRole() {
    var auth = SecurityContextHolder.getContext().getAuthentication();
    if (auth == null || auth.getAuthorities() == null) {
      throw new AccessDeniedException("Unauthorized: safety role required");
    }
    boolean allowed =
        auth.getAuthorities().stream()
            .map(granted -> granted.getAuthority())
            .anyMatch(
                name ->
                    "ROLE_SAFETY".equalsIgnoreCase(name)
                        || "ROLE_SUPERADMIN".equalsIgnoreCase(name)
                        || "ROLE_ADMIN".equalsIgnoreCase(name)
                        || "all_functions".equalsIgnoreCase(name));
    if (!allowed) {
      throw new AccessDeniedException("Only safety team can submit safety checks");
    }
  }

  private PreLoadingSafetyCheckResponse map(PreLoadingSafetyCheck entity) {
    return map(entity, null, null, null);
  }

  private PreLoadingSafetyCheckResponse map(
      PreLoadingSafetyCheck entity,
      String dispatchStatusAfterCheck,
      Boolean autoTransitionApplied,
      String transitionMessage) {
    return PreLoadingSafetyCheckResponse.builder()
        .id(entity.getId())
        .dispatchId(entity.getDispatch().getId())
        .driverPpeOk(entity.isDriverPpeOk())
        .fireExtinguisherOk(entity.isFireExtinguisherOk())
        .wheelChockOk(entity.isWheelChockOk())
        .truckLeakageOk(entity.isTruckLeakageOk())
        .truckCleanOk(entity.isTruckCleanOk())
        .truckConditionOk(entity.isTruckConditionOk())
        .result(entity.getResult())
        .failReason(entity.getFailReason())
        .checkedByUserId(entity.getCheckedBy() != null ? entity.getCheckedBy().getId() : null)
        .checkedByName(entity.getCheckedBy() != null ? entity.getCheckedBy().getUsername() : null)
        .checkedByUsername(entity.getCheckedBy() != null ? entity.getCheckedBy().getUsername() : null)
        .checkedAt(entity.getCheckedAt())
        .createdDate(entity.getCreatedDate())
          .clientUuid(entity.getClientUuid())
          .locationLat(entity.getLocationLat() != null ? entity.getLocationLat().doubleValue() : null)
          .locationLng(entity.getLocationLng() != null ? entity.getLocationLng().doubleValue() : null)
          .loadingSessionId(entity.getLoadingSession() != null ? entity.getLoadingSession().getId() : null)
          .proofDocumentId(entity.getProofDocument() != null ? entity.getProofDocument().getId() : null)
          .synced(entity.isSynced())
        .dispatchStatusAfterCheck(dispatchStatusAfterCheck)
        .autoTransitionApplied(autoTransitionApplied)
        .transitionMessage(transitionMessage)
        .build();
  }

  private AutoTransitionResult autoTransitionToLoadingIfEligible(Dispatch dispatch) {
    if (dispatch.getStatus() != DispatchStatus.IN_QUEUE) {
      return new AutoTransitionResult(
          false,
          String.format(
              "Pre-entry PASS recorded. Dispatch remains %s; auto-transition requires IN_QUEUE.",
              dispatch.getStatus()));
    }

    LoadingQueue queue =
        loadingQueueRepository
            .findByDispatchId(dispatch.getId())
            .orElseThrow(() -> new IllegalStateException(QUEUE_REQUIRED_TRANSITION_MESSAGE));

    String warehouseCode =
        queue.getWarehouseCode() != null ? queue.getWarehouseCode().name() : null;
    if (!isAutoTransitionWarehouse(warehouseCode)) {
      return new AutoTransitionResult(
          false, "Pre-entry PASS recorded. Auto-transition to LOADING is not enabled for this warehouse.");
    }

    if (queue.getStatus() == LoadingQueueStatus.WAITING) {
      loadingWorkflowService.callToBay(queue.getId(), queue.getBay(), AUTO_CALL_REMARKS);
    } else if (queue.getStatus() != LoadingQueueStatus.CALLED
        && queue.getStatus() != LoadingQueueStatus.LOADING) {
      throw new IllegalStateException(
          "Cannot auto transition to loading from queue status: " + queue.getStatus());
    }

    LoadingSessionStartRequest startRequest = new LoadingSessionStartRequest();
    startRequest.setDispatchId(dispatch.getId());
    startRequest.setQueueId(queue.getId());
    startRequest.setWarehouseCode(queue.getWarehouseCode());
    startRequest.setBay(queue.getBay());
    startRequest.setRemarks(AUTO_TRANSITION_NOTE);
    loadingWorkflowService.startLoading(startRequest);
    appendAutoTransitionHistory(dispatch);

    return new AutoTransitionResult(true, "Pre-entry passed, moved to LOADING.");
  }

  private boolean isAutoTransitionWarehouse(String warehouseCode) {
    if (warehouseCode == null || warehouseCode.isBlank()) {
      return false;
    }
    String normalized = normalizeWarehouseCode(warehouseCode);
    Set<String> configured = featureToggleConfig.getPreEntrySafetyRequiredWarehouses();
    if (configured == null || configured.isEmpty()) {
      return "KHB".equals(normalized);
    }
    return configured.stream()
        .filter(code -> code != null && !code.isBlank())
        .map(this::normalizeWarehouseCode)
        .anyMatch(normalized::equals);
  }

  private String normalizeWarehouseCode(String warehouseCode) {
    WarehouseCode parsed = WarehouseCode.from(warehouseCode);
    if (parsed != null) {
      return parsed.name();
    }
    return warehouseCode.trim().toUpperCase();
  }

  private void appendAutoTransitionHistory(Dispatch dispatch) {
    DispatchStatusHistory history = new DispatchStatusHistory();
    history.setDispatch(dispatch);
    history.setStatus(DispatchStatus.LOADING);
    history.setRemarks(AUTO_TRANSITION_NOTE);
    history.setUpdatedAt(LocalDateTime.now());
    history.setUpdatedBy(resolveCurrentUsername());
    dispatchStatusHistoryRepository.save(history);
  }

  private record AutoTransitionResult(boolean applied, String message) {}

  private void updateDispatchStatus(Dispatch dispatch, DispatchStatus targetStatus, String remarks) {
    if (dispatch.getStatus() != targetStatus) {
      dispatchValidator.validateStatusTransition(dispatch.getStatus(), targetStatus);
      dispatch.setStatus(targetStatus);
      dispatch.setUpdatedDate(LocalDateTime.now());
      Dispatch saved = dispatchRepo.save(dispatch);

      DispatchStatusHistory history = new DispatchStatusHistory();
      history.setDispatch(saved);
      history.setStatus(targetStatus);
      history.setRemarks(remarks);
      history.setUpdatedAt(LocalDateTime.now());
      history.setUpdatedBy(resolveCurrentUsername());
      dispatchStatusHistoryRepository.save(history);
    }
  }

  private String resolveCurrentUsername() {
    var authentication = SecurityContextHolder.getContext().getAuthentication();
    return authentication != null ? authentication.getName() : "system";
  }
}
