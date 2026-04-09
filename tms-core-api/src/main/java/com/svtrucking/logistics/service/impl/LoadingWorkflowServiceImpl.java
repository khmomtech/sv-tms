package com.svtrucking.logistics.service.impl;

import com.svtrucking.logistics.dto.*;
import com.svtrucking.logistics.enums.DispatchStatus;
import com.svtrucking.logistics.enums.LoadingDocumentType;
import com.svtrucking.logistics.enums.LoadingQueueStatus;
import com.svtrucking.logistics.enums.PreEntrySafetyStatus;
import com.svtrucking.logistics.enums.WarehouseCode;
import com.svtrucking.logistics.exception.ResourceNotFoundException;
import com.svtrucking.logistics.config.FeatureToggleConfig;
import com.svtrucking.logistics.model.*;
import com.svtrucking.logistics.repository.*;
import com.svtrucking.logistics.security.AuthenticatedUserUtil;
import com.svtrucking.logistics.service.FileStorageService;
import com.svtrucking.logistics.service.LoadingWorkflowService;
import com.svtrucking.logistics.validator.DispatchWorkflowValidator;
import com.svtrucking.logistics.validator.DispatchValidator;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.time.LocalDateTime;
import java.util.List;
import java.util.NoSuchElementException;
import java.util.Objects;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class LoadingWorkflowServiceImpl implements LoadingWorkflowService {

  private final LoadingQueueRepository queueRepository;
  private final LoadingSessionRepository sessionRepository;
  private final LoadingPalletItemRepository palletItemRepository;
  private final LoadingEmptiesReturnRepository emptiesReturnRepository;
  private final LoadingDocumentRepository loadingDocumentRepository;
  private final DispatchRepository dispatchRepository;
  private final DispatchStatusHistoryRepository dispatchStatusHistoryRepository;
  private final DispatchValidator dispatchValidator;
  private final DispatchWorkflowValidator dispatchWorkflowValidator;
  private final AuthenticatedUserUtil authUtil;
  private final FileStorageService fileStorageService;
  private final PreEntrySafetyCheckRepository preEntrySafetyCheckRepository;
  private final FeatureToggleConfig featureToggleConfig;

  @Override
  public LoadingQueueResponse enqueue(LoadingQueueRequest request) {
    Dispatch dispatch = loadDispatch(request.getDispatchId());

    if (dispatch.getStatus() == DispatchStatus.CANCELLED
        || dispatch.getStatus() == DispatchStatus.DELIVERED
        || dispatch.getStatus() == DispatchStatus.COMPLETED) {
      throw new IllegalStateException("Dispatch is in terminal state and cannot enter queue.");
    }
    dispatchWorkflowValidator.ensureCanEnterQueue(dispatch);

    LoadingQueue queue = queueRepository.findByDispatchId(dispatch.getId()).orElse(null);

    if (queue != null && (dispatch.getStatus() == DispatchStatus.LOADING || dispatch.getStatus() == DispatchStatus.LOADED)) {
      return mapQueue(queue);
    }
    if (queue != null && queue.getStatus() == LoadingQueueStatus.LOADED) {
      // Already processed, return existing snapshot
      return mapQueue(queue);
    }
    if (queue == null) {
      queue =
          LoadingQueue.builder()
              .dispatch(dispatch)
              .status(LoadingQueueStatus.WAITING)
              .build();
    }

    queue.setWarehouseCode(request.getWarehouseCode());
    queue.setQueuePosition(
        request.getQueuePosition() != null
            ? request.getQueuePosition()
            : nextQueuePosition(request.getWarehouseCode()));
    queue.setRemarks(request.getRemarks());
    queue.setCreatedBy(safeCurrentUser());
    queue.setUpdatedBy(safeCurrentUser());

    queue = queueRepository.save(queue);

    if (dispatch.getStatus() == DispatchStatus.LOADING || dispatch.getStatus() == DispatchStatus.LOADED) {
      return mapQueue(queue);
    }

    updateDispatchStatus(dispatch, DispatchStatus.IN_QUEUE, "Added to loading queue");

    log.info("Dispatch {} enqueued at warehouse {} position {}", dispatch.getId(), request.getWarehouseCode(), queue.getQueuePosition());
    return mapQueue(queue);
  }

  @Override
  public LoadingQueueResponse callToBay(Long queueId, String bay, String remarks) {
    LoadingQueue queue =
        queueRepository
            .findById(queueId)
            .orElseThrow(() -> new NoSuchElementException("Queue entry not found: " + queueId));
    if (queue.getStatus() != LoadingQueueStatus.WAITING) {
      throw new IllegalStateException("Queue entry can be called only from WAITING state.");
    }
    if (queue.getDispatch() == null || queue.getDispatch().getStatus() != DispatchStatus.IN_QUEUE) {
      throw new IllegalStateException("Dispatch must be IN_QUEUE before calling to bay.");
    }
    Dispatch dispatch = queue.getDispatch();
    ensurePreEntrySafetyGateSatisfied(dispatch, "before calling to bay");

    queue.setBay(bay);
    if (remarks != null && !remarks.isBlank()) {
      queue.setRemarks(remarks.trim());
    }
    queue.setStatus(LoadingQueueStatus.CALLED);
    queue.setCalledAt(LocalDateTime.now());
    queue.setUpdatedBy(safeCurrentUser());
    queue = queueRepository.save(queue);
    return mapQueue(queue);
  }

  @Override
  public LoadingQueueResponse updateGateInfo(Long queueId, LoadingGateUpdateRequest request) {
    LoadingQueue queue =
        queueRepository
            .findById(queueId)
            .orElseThrow(() -> new NoSuchElementException("Queue entry not found: " + queueId));

    if (queue.getStatus() == LoadingQueueStatus.LOADED) {
      throw new IllegalStateException("Gate information is read-only after loading completion.");
    }

    if (request != null) {
      if (request.getBay() != null) {
        String normalizedBay = request.getBay().trim();
        queue.setBay(normalizedBay.isEmpty() ? null : normalizedBay);
      }
      if (request.getQueuePosition() != null) {
        if (request.getQueuePosition() <= 0) {
          throw new IllegalArgumentException("Queue position must be greater than 0.");
        }
        queue.setQueuePosition(request.getQueuePosition());
      }
      if (request.getRemarks() != null) {
        String normalizedRemarks = request.getRemarks().trim();
        queue.setRemarks(normalizedRemarks.isEmpty() ? null : normalizedRemarks);
      }
    }

    queue.setUpdatedBy(safeCurrentUser());
    queue = queueRepository.save(queue);
    return mapQueue(queue);
  }

  @Override
  public LoadingSessionResponse startLoading(LoadingSessionStartRequest request) {
    Dispatch dispatch = loadDispatch(request.getDispatchId());

    ensurePreEntrySafetyGateSatisfied(dispatch, "before starting loading");
    dispatchWorkflowValidator.ensureCanStartLoading(dispatch);

    LoadingQueue queue =
        request.getQueueId() != null
            ? queueRepository
                .findById(request.getQueueId())
                .orElseThrow(() -> new NoSuchElementException("Queue not found for start loading"))
            : queueRepository.findByDispatchId(dispatch.getId()).orElse(null);

    WarehouseCode warehouse =
        request.getWarehouseCode() != null
            ? request.getWarehouseCode()
            : queue != null ? queue.getWarehouseCode() : null;

    if (warehouse == null) {
      throw new IllegalArgumentException("Warehouse code is required to start loading.");
    }
    if (queue == null) {
      throw new IllegalStateException("Queue entry is required before starting loading.");
    }
    if (queue.getStatus() != LoadingQueueStatus.CALLED
        && queue.getStatus() != LoadingQueueStatus.LOADING) {
      throw new IllegalStateException("Queue must be CALLED before starting loading.");
    }

    LoadingSession session =
        sessionRepository
            .findByDispatchId(dispatch.getId())
            .orElse(
                LoadingSession.builder()
                    .dispatch(dispatch)
                    .queue(queue)
                    .warehouseCode(warehouse)
                    .build());

    session.setBay(request.getBay() != null ? request.getBay() : session.getBay());
    session.setStartedAt(
        request.getStartedAt() != null ? request.getStartedAt() : LocalDateTime.now());
    session.setStartedBy(safeCurrentUser());
    session.setRemarks(request.getRemarks());
    session.setWarehouseCode(warehouse);

    session = sessionRepository.save(session);

    if (queue != null) {
      queue.setStatus(LoadingQueueStatus.LOADING);
      queue.setLoadingStartedAt(session.getStartedAt());
      queue.setUpdatedBy(safeCurrentUser());
      queueRepository.save(queue);
    }

    updateDispatchStatus(dispatch, DispatchStatus.LOADING, "Loading started");

    return mapSession(session);
  }

  @Override
  public LoadingSessionResponse completeLoading(LoadingSessionCompleteRequest request) {
    LoadingSession session =
        sessionRepository
            .findById(request.getSessionId())
            .orElseThrow(() -> new NoSuchElementException("Loading session not found: " + request.getSessionId()));

    Dispatch dispatch = session.getDispatch();

    session.setEndedAt(
        request.getEndedAt() != null ? request.getEndedAt() : LocalDateTime.now());
    session.setRemarks(request.getRemarks());
    session.setEndedBy(safeCurrentUser());
    session = sessionRepository.save(session);
    final LoadingSession currentSession = session;

    // Replace pallet items
    palletItemRepository.deleteByLoadingSessionId(session.getId());
    if (request.getPalletItems() != null) {
      List<LoadingPalletItem> items =
          request.getPalletItems().stream()
              .filter(Objects::nonNull)
              .map(
                  dto ->
                      LoadingPalletItem.builder()
                          .loadingSession(currentSession)
                          .itemDescription(dto.getItemDescription())
                          .palletTag(dto.getPalletTag())
                          .quantity(dto.getQuantity())
                          .unit(dto.getUnit())
                          .conditionNote(dto.getConditionNote())
                          .verifiedOk(dto.isVerifiedOk())
                          .build())
              .toList();
      palletItemRepository.saveAll(items);
    }

    // Replace empties
    emptiesReturnRepository.deleteByLoadingSessionId(session.getId());
    if (request.getEmptiesReturns() != null) {
      List<LoadingEmptiesReturn> empties =
          request.getEmptiesReturns().stream()
              .filter(Objects::nonNull)
              .map(
                  dto ->
                      LoadingEmptiesReturn.builder()
                          .loadingSession(currentSession)
                          .itemName(dto.getItemName())
                          .quantity(dto.getQuantity())
                          .unit(dto.getUnit())
                          .conditionNote(dto.getConditionNote())
                          .recordedAt(
                              dto.getRecordedAt() != null ? dto.getRecordedAt() : LocalDateTime.now())
                          .build())
              .toList();
      emptiesReturnRepository.saveAll(empties);
    }

    // Update queue entry if present
    if (session.getQueue() != null) {
      LoadingQueue queue = session.getQueue();
      queue.setStatus(LoadingQueueStatus.LOADED);
      queue.setLoadingCompletedAt(session.getEndedAt());
      queue.setUpdatedBy(safeCurrentUser());
      queueRepository.save(queue);
    }

    updateDispatchStatus(dispatch, DispatchStatus.LOADED, "Loading completed");

    return mapSession(session);
  }

  @Override
  @Transactional(readOnly = true)
  public List<LoadingQueueResponse> getQueueByWarehouse(WarehouseCode warehouseCode) {
    try {
      List<LoadingQueue> queues =
          queueRepository.findByWarehouseCodeOrderByQueuePositionAscCreatedDateAsc(warehouseCode);
      return queues.stream()
          .map(this::mapQueueSafe)
          .filter(Objects::nonNull)
          .toList();
    } catch (Exception ex) {
      log.error("Failed to load queue for warehouse {}. Returning empty list.", warehouseCode, ex);
      return List.of();
    }
  }

  @Override
  @Transactional(readOnly = true)
  public LoadingQueueResponse getQueueForDispatch(Long dispatchId) {
    return queueRepository
        .findByDispatchId(dispatchId)
        .map(this::mapQueue)
        .orElseThrow(() -> new ResourceNotFoundException("Queue not found for dispatch " + dispatchId));
  }

  @Override
  @Transactional(readOnly = true)
  public LoadingSessionResponse getSessionForDispatch(Long dispatchId) {
    return sessionRepository
        .findByDispatchId(dispatchId)
        .map(this::mapSession)
        .orElseThrow(() -> new ResourceNotFoundException("Loading session not found for dispatch " + dispatchId));
  }

  @Override
  @Transactional(readOnly = true)
  public LoadingDispatchDetailResponse getDispatchDetail(Long dispatchId) {
    Dispatch dispatch = loadDispatch(dispatchId);
    LoadingQueueResponse queue =
        queueRepository.findByDispatchId(dispatchId).map(this::mapQueueSafe).orElse(null);
    LoadingSessionResponse session =
        sessionRepository.findByDispatchId(dispatchId).map(this::mapSession).orElse(null);

    return LoadingDispatchDetailResponse.builder()
        .dispatchId(dispatchId)
        .dispatch(DispatchDto.fromEntityWithDetails(dispatch))
        .queue(queue)
        .session(session)
        .preEntrySafetyRequired(Boolean.TRUE.equals(dispatch.getPreEntrySafetyRequired()))
        .preEntrySafetyStatus(dispatch.getPreEntrySafetyStatus())
        .loadingSafetyStatus(dispatch.getSafetyStatus())
        .build();
  }

  @Override
  public LoadingDocumentDto uploadDocument(Long sessionId, LoadingDocumentType documentType, MultipartFile file) {
    if (file == null || file.isEmpty()) {
      throw new IllegalArgumentException("Document file is required.");
    }

    LoadingSession session =
        sessionRepository
            .findById(sessionId)
            .orElseThrow(() -> new NoSuchElementException("Loading session not found: " + sessionId));

    Dispatch dispatch = session.getDispatch();

    String storedPath =
        fileStorageService.storeFileInSubfolder(file, "loading-documents/" + dispatch.getId());

    LoadingDocument loadingDocument =
        LoadingDocument.builder()
            .loadingSession(session)
            .dispatch(dispatch)
            .documentType(documentType != null ? documentType : LoadingDocumentType.OTHER)
            .fileName(file.getOriginalFilename())
            .fileUrl(storedPath)
            .mimeType(file.getContentType())
            .uploadedBy(safeCurrentUser())
            .build();

    loadingDocument = loadingDocumentRepository.save(loadingDocument);
    return mapDocument(loadingDocument);
  }

  private Dispatch loadDispatch(Long dispatchId) {
    return dispatchRepository
        .findById(dispatchId)
        .orElseThrow(() -> new ResourceNotFoundException("Dispatch not found: " + dispatchId));
  }

  private void ensurePreEntrySafetyGateSatisfied(Dispatch dispatch, String operationLabel) {
    if (!Boolean.TRUE.equals(dispatch.getPreEntrySafetyRequired())) {
      return;
    }

    if (!featureToggleConfig.isPreEntrySafetyCheckEnabled() || !featureToggleConfig.isEnforcePreEntrySafetyGate()) {
      // Requirement is per-dispatch, but global feature toggles can disable hard enforcement.
      return;
    }

    PreEntrySafetyCheck safetyCheck =
        preEntrySafetyCheckRepository
            .findByDispatchId(dispatch.getId())
            .orElseThrow(
                () ->
                    new IllegalStateException(
                        "Pre-entry safety check is required " + operationLabel + "."));

    PreEntrySafetyStatus status = safetyCheck.getStatus();
    if (status == PreEntrySafetyStatus.FAILED) {
      throw new IllegalStateException(
          "Cannot proceed: pre-entry safety check FAILED. Issues must be resolved.");
    }

    if (status == PreEntrySafetyStatus.CONDITIONAL
        && safetyCheck.getOverrideApprovedAt() == null) {
      throw new IllegalStateException(
          "Cannot proceed: pre-entry safety check is CONDITIONAL and requires supervisor override.");
    }

    if (status != PreEntrySafetyStatus.PASSED && status != PreEntrySafetyStatus.CONDITIONAL) {
      throw new IllegalStateException(
          "Cannot proceed: pre-entry safety check is not completed with PASS status.");
    }
  }

  private LoadingQueueResponse mapQueue(LoadingQueue queue) {
    return LoadingQueueResponse.builder()
        .id(queue.getId())
        .dispatchId(queue.getDispatch().getId())
        .routeCode(queue.getDispatch().getRouteCode())
        .warehouseCode(queue.getWarehouseCode())
        .status(queue.getStatus())
        .queuePosition(queue.getQueuePosition())
        .bay(queue.getBay())
        .remarks(queue.getRemarks())
        .calledAt(queue.getCalledAt())
        .loadingStartedAt(queue.getLoadingStartedAt())
        .loadingCompletedAt(queue.getLoadingCompletedAt())
        .dispatchStatus(queue.getDispatch().getStatus())
        .createdDate(queue.getCreatedDate())
        .updatedDate(queue.getUpdatedDate())
        .build();
  }

  private LoadingQueueResponse mapQueueSafe(LoadingQueue queue) {
    try {
      if (queue == null || queue.getDispatch() == null || queue.getDispatch().getId() == null) {
        return null;
      }
      return mapQueue(queue);
    } catch (Exception ex) {
      log.warn("Skipping invalid queue row id={} due to mapping error: {}", queue != null ? queue.getId() : null,
          ex.getMessage());
      return null;
    }
  }

  private LoadingSessionResponse mapSession(LoadingSession session) {
    List<LoadingPalletItemDto> palletItems =
        palletItemRepository.findByLoadingSessionId(session.getId()).stream()
            .map(
                i ->
                    LoadingPalletItemDto.builder()
                        .id(i.getId())
                        .itemDescription(i.getItemDescription())
                        .palletTag(i.getPalletTag())
                        .quantity(i.getQuantity())
                        .unit(i.getUnit())
                        .conditionNote(i.getConditionNote())
                        .verifiedOk(i.isVerifiedOk())
                        .build())
            .collect(Collectors.toList());

    List<LoadingEmptiesReturnDto> empties =
        emptiesReturnRepository.findByLoadingSessionId(session.getId()).stream()
            .map(
                e ->
                    LoadingEmptiesReturnDto.builder()
                        .id(e.getId())
                        .itemName(e.getItemName())
                        .quantity(e.getQuantity())
                        .unit(e.getUnit())
                        .conditionNote(e.getConditionNote())
                        .recordedAt(e.getRecordedAt())
                        .build())
            .collect(Collectors.toList());

    List<LoadingDocumentDto> documents =
        loadingDocumentRepository.findByLoadingSessionId(session.getId()).stream()
            .map(this::mapDocument)
            .collect(Collectors.toList());

    LoadingQueue queue = session.getQueue();

    return LoadingSessionResponse.builder()
        .id(session.getId())
        .dispatchId(session.getDispatch().getId())
        .queueId(queue != null ? queue.getId() : null)
        .warehouseCode(session.getWarehouseCode())
        .bay(session.getBay())
        .startedAt(session.getStartedAt())
        .endedAt(session.getEndedAt())
        .remarks(session.getRemarks())
        .dispatchStatus(session.getDispatch().getStatus())
        .queueStatus(queue != null ? queue.getStatus() : null)
        .palletItems(palletItems)
        .emptiesReturns(empties)
        .documents(documents)
        .build();
  }

  private LoadingDocumentDto mapDocument(LoadingDocument doc) {
    return LoadingDocumentDto.builder()
        .id(doc.getId())
        .documentType(doc.getDocumentType())
        .fileName(doc.getFileName())
        .fileUrl(doc.getFileUrl())
        .mimeType(doc.getMimeType())
        .uploadedAt(doc.getUploadedAt())
        .build();
  }

  private void updateDispatchStatus(Dispatch dispatch, DispatchStatus targetStatus, String remarks) {
    if (dispatch.getStatus() != targetStatus) {
      dispatchValidator.validateStatusTransition(dispatch.getStatus(), targetStatus);
      dispatch.setStatus(targetStatus);
      dispatch.setUpdatedDate(LocalDateTime.now());
      Dispatch saved = dispatchRepository.save(dispatch);

      DispatchStatusHistory history = new DispatchStatusHistory();
      history.setDispatch(saved);
      history.setStatus(targetStatus);
      history.setRemarks(remarks);
      history.setUpdatedAt(LocalDateTime.now());
      history.setUpdatedBy(resolveCurrentUsername());
      dispatchStatusHistoryRepository.save(history);
    }
  }

  private User safeCurrentUser() {
    try {
      return authUtil.getCurrentUser();
    } catch (Exception ex) {
      log.debug("No authenticated user resolved for audit fields: {}", ex.getMessage());
      return null;
    }
  }

  private String resolveCurrentUsername() {
    var authentication = SecurityContextHolder.getContext().getAuthentication();
    return authentication != null ? authentication.getName() : "system";
  }

  private int nextQueuePosition(WarehouseCode warehouseCode) {
    List<LoadingQueue> current =
        queueRepository.findByWarehouseCodeOrderByQueuePositionAscCreatedDateAsc(warehouseCode);
    if (current == null || current.isEmpty()) {
      return 1;
    }
    Integer maxPosition =
        current.stream()
            .map(LoadingQueue::getQueuePosition)
            .filter(Objects::nonNull)
            .max(Integer::compareTo)
            .orElse(current.size());
    return maxPosition + 1;
  }
}
