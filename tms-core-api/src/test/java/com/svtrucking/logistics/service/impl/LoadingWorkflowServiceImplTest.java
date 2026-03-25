package com.svtrucking.logistics.service.impl;

import com.svtrucking.logistics.config.FeatureToggleConfig;
import com.svtrucking.logistics.dto.LoadingQueueRequest;
import com.svtrucking.logistics.dto.LoadingQueueResponse;
import com.svtrucking.logistics.dto.LoadingSessionStartRequest;
import com.svtrucking.logistics.enums.DispatchStatus;
import com.svtrucking.logistics.enums.LoadingQueueStatus;
import com.svtrucking.logistics.enums.PreEntrySafetyStatus;
import com.svtrucking.logistics.enums.SafetyCheckStatus;
import com.svtrucking.logistics.enums.WarehouseCode;
import com.svtrucking.logistics.model.Dispatch;
import com.svtrucking.logistics.model.LoadingQueue;
import com.svtrucking.logistics.model.PreEntrySafetyCheck;
import com.svtrucking.logistics.repository.DispatchRepository;
import com.svtrucking.logistics.repository.DispatchStatusHistoryRepository;
import com.svtrucking.logistics.repository.LoadingDocumentRepository;
import com.svtrucking.logistics.repository.LoadingEmptiesReturnRepository;
import com.svtrucking.logistics.repository.LoadingPalletItemRepository;
import com.svtrucking.logistics.repository.LoadingQueueRepository;
import com.svtrucking.logistics.repository.LoadingSessionRepository;
import com.svtrucking.logistics.repository.PreEntrySafetyCheckRepository;
import com.svtrucking.logistics.security.AuthenticatedUserUtil;
import com.svtrucking.logistics.service.FileStorageService;
import com.svtrucking.logistics.validator.DispatchValidator;
import com.svtrucking.logistics.validator.DispatchWorkflowValidator;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.when;

class LoadingWorkflowServiceImplTest {

  private LoadingWorkflowServiceImpl service;
  private LoadingQueueRepository queueRepository;
  private LoadingSessionRepository sessionRepository;
  private LoadingPalletItemRepository palletItemRepository;
  private LoadingEmptiesReturnRepository emptiesReturnRepository;
  private LoadingDocumentRepository loadingDocumentRepository;
  private DispatchRepository dispatchRepository;
  private DispatchStatusHistoryRepository dispatchStatusHistoryRepository;
  private DispatchValidator dispatchValidator;
  private DispatchWorkflowValidator dispatchWorkflowValidator;
  private AuthenticatedUserUtil authUtil;
  private FileStorageService fileStorageService;
  private PreEntrySafetyCheckRepository preEntrySafetyCheckRepository;
  private FeatureToggleConfig featureToggleConfig;

  @BeforeEach
  void setup() {
    queueRepository = Mockito.mock(LoadingQueueRepository.class);
    sessionRepository = Mockito.mock(LoadingSessionRepository.class);
    palletItemRepository = Mockito.mock(LoadingPalletItemRepository.class);
    emptiesReturnRepository = Mockito.mock(LoadingEmptiesReturnRepository.class);
    loadingDocumentRepository = Mockito.mock(LoadingDocumentRepository.class);
    dispatchRepository = Mockito.mock(DispatchRepository.class);
    dispatchStatusHistoryRepository = Mockito.mock(DispatchStatusHistoryRepository.class);
    dispatchValidator = Mockito.mock(DispatchValidator.class);
    dispatchWorkflowValidator = Mockito.mock(DispatchWorkflowValidator.class);
    authUtil = Mockito.mock(AuthenticatedUserUtil.class);
    fileStorageService = Mockito.mock(FileStorageService.class);
    preEntrySafetyCheckRepository = Mockito.mock(PreEntrySafetyCheckRepository.class);
    featureToggleConfig = Mockito.mock(FeatureToggleConfig.class);

    service =
        new LoadingWorkflowServiceImpl(
            queueRepository,
            sessionRepository,
            palletItemRepository,
            emptiesReturnRepository,
            loadingDocumentRepository,
            dispatchRepository,
            dispatchStatusHistoryRepository,
            dispatchValidator,
            dispatchWorkflowValidator,
            authUtil,
            fileStorageService,
            preEntrySafetyCheckRepository,
            featureToggleConfig);
  }

  @Test
  void enqueue_allowsWhenPreEntrySafetyMissing() {
    Dispatch dispatch = baseDispatch(11L);
    dispatch.setStatus(DispatchStatus.ARRIVED_LOADING);
    dispatch.setSafetyStatus(SafetyCheckStatus.PASSED);
    LoadingQueueRequest request = baseRequest(11L);

    when(featureToggleConfig.isPreEntrySafetyCheckEnabled()).thenReturn(true);
    when(featureToggleConfig.isEnforcePreEntrySafetyGate()).thenReturn(true);
    when(dispatchRepository.findById(11L)).thenReturn(Optional.of(dispatch));
    when(queueRepository.findByDispatchId(11L)).thenReturn(Optional.empty());
    when(queueRepository.findByWarehouseCodeOrderByQueuePositionAscCreatedDateAsc(WarehouseCode.W1))
        .thenReturn(List.of());
    when(queueRepository.save(any(LoadingQueue.class))).thenAnswer(inv -> inv.getArgument(0));
    when(dispatchRepository.save(any(Dispatch.class))).thenAnswer(inv -> inv.getArgument(0));

    LoadingQueueResponse response = service.enqueue(request);

    assertEquals(DispatchStatus.IN_QUEUE, response.getDispatchStatus());
    assertEquals(LoadingQueueStatus.WAITING, response.getStatus());
    verify(queueRepository).save(any(LoadingQueue.class));
  }

  @Test
  void callToBay_blocksWhenPreEntryRequiredButNotPassed() {
    Dispatch dispatch = baseDispatch(12L);
    dispatch.setStatus(DispatchStatus.IN_QUEUE);
    dispatch.setSafetyStatus(SafetyCheckStatus.PASSED);
    dispatch.setPreEntrySafetyRequired(true);

    LoadingQueue queue =
        LoadingQueue.builder()
            .id(120L)
            .dispatch(dispatch)
            .status(LoadingQueueStatus.WAITING)
            .warehouseCode(WarehouseCode.KHB)
            .queuePosition(1)
            .build();

    when(featureToggleConfig.isPreEntrySafetyCheckEnabled()).thenReturn(true);
    when(featureToggleConfig.isEnforcePreEntrySafetyGate()).thenReturn(true);
    when(queueRepository.findById(120L)).thenReturn(Optional.of(queue));
    when(preEntrySafetyCheckRepository.findByDispatchId(12L)).thenReturn(Optional.empty());

    IllegalStateException ex =
        assertThrows(IllegalStateException.class, () -> service.callToBay(120L, "G01", "note"));

    assertTrue(ex.getMessage().contains("Pre-entry safety check is required before calling to bay"));
    verify(queueRepository).findById(120L);
    verify(queueRepository, never()).save(any(LoadingQueue.class));
  }

  @Test
  void callToBay_allowsWhenPreEntryAndDailySafetyPassed() {
    Dispatch dispatch = baseDispatch(13L);
    dispatch.setStatus(DispatchStatus.IN_QUEUE);
    dispatch.setSafetyStatus(SafetyCheckStatus.PASSED);
    dispatch.setPreEntrySafetyRequired(true);

    PreEntrySafetyCheck passedCheck = PreEntrySafetyCheck.builder().status(PreEntrySafetyStatus.PASSED).build();
    LoadingQueue queue =
        LoadingQueue.builder()
            .id(130L)
            .dispatch(dispatch)
            .status(LoadingQueueStatus.WAITING)
            .warehouseCode(WarehouseCode.KHB)
            .queuePosition(5)
            .build();

    when(featureToggleConfig.isPreEntrySafetyCheckEnabled()).thenReturn(true);
    when(featureToggleConfig.isEnforcePreEntrySafetyGate()).thenReturn(true);
    when(queueRepository.findById(130L)).thenReturn(Optional.of(queue));
    when(preEntrySafetyCheckRepository.findByDispatchId(13L)).thenReturn(Optional.of(passedCheck));
    when(queueRepository.save(any(LoadingQueue.class))).thenAnswer(inv -> inv.getArgument(0));

    LoadingQueueResponse response = service.callToBay(130L, "B-01", "call");

    assertEquals(LoadingQueueStatus.CALLED, response.getStatus());
    assertEquals("B-01", response.getBay());
    verify(queueRepository).save(any(LoadingQueue.class));
  }

  @Test
  void startLoading_blocksWhenQueueNotCalled() {
    Dispatch dispatch = baseDispatch(14L);
    dispatch.setStatus(DispatchStatus.IN_QUEUE);
    dispatch.setSafetyStatus(SafetyCheckStatus.PASSED);
    dispatch.setPreEntrySafetyRequired(false);
    LoadingQueue queue =
        LoadingQueue.builder()
            .id(140L)
            .dispatch(dispatch)
            .status(LoadingQueueStatus.WAITING)
            .warehouseCode(WarehouseCode.KHB)
            .queuePosition(3)
            .build();
    LoadingSessionStartRequest request = new LoadingSessionStartRequest();
    request.setDispatchId(14L);
    request.setQueueId(140L);
    request.setWarehouseCode(WarehouseCode.KHB);

    when(dispatchRepository.findById(14L)).thenReturn(Optional.of(dispatch));
    when(queueRepository.findById(140L)).thenReturn(Optional.of(queue));

    IllegalStateException ex =
        assertThrows(IllegalStateException.class, () -> service.startLoading(request));

    assertEquals("Queue must be CALLED before starting loading.", ex.getMessage());
    verifyNoInteractions(sessionRepository);
  }

  private Dispatch baseDispatch(Long id) {
    Dispatch dispatch = new Dispatch();
    dispatch.setId(id);
    dispatch.setStatus(DispatchStatus.ARRIVED_LOADING);
    dispatch.setPreEntrySafetyRequired(true);
    dispatch.setPreEntrySafetyStatus(PreEntrySafetyStatus.NOT_STARTED);
    return dispatch;
  }

  private LoadingQueueRequest baseRequest(Long dispatchId) {
    LoadingQueueRequest request = new LoadingQueueRequest();
    request.setDispatchId(dispatchId);
    request.setWarehouseCode(WarehouseCode.W1);
    request.setRemarks("test");
    return request;
  }
}
