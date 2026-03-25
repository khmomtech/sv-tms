package com.svtrucking.logistics.service.impl;

import com.svtrucking.logistics.config.FeatureToggleConfig;
import com.svtrucking.logistics.dto.LoadingSessionResponse;
import com.svtrucking.logistics.dto.PreLoadingSafetyCheckRequest;
import com.svtrucking.logistics.dto.PreLoadingSafetyCheckResponse;
import com.svtrucking.logistics.enums.DispatchStatus;
import com.svtrucking.logistics.enums.LoadingQueueStatus;
import com.svtrucking.logistics.enums.SafetyResult;
import com.svtrucking.logistics.enums.WarehouseCode;
import com.svtrucking.logistics.model.Dispatch;
import com.svtrucking.logistics.model.LoadingQueue;
import com.svtrucking.logistics.model.PreLoadingSafetyCheck;
import com.svtrucking.logistics.model.User;
import com.svtrucking.logistics.repository.DispatchRepository;
import com.svtrucking.logistics.repository.DispatchStatusHistoryRepository;
import com.svtrucking.logistics.repository.LoadingDocumentRepository;
import com.svtrucking.logistics.repository.LoadingQueueRepository;
import com.svtrucking.logistics.repository.LoadingSessionRepository;
import com.svtrucking.logistics.repository.PreLoadingSafetyCheckRepository;
import com.svtrucking.logistics.repository.UserRepository;
import com.svtrucking.logistics.security.AuthenticatedUserUtil;
import com.svtrucking.logistics.service.LoadingWorkflowService;
import com.svtrucking.logistics.validator.DispatchValidator;
import java.util.Optional;
import java.util.Set;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class PreLoadingSafetyCheckServiceImplTest {

  private PreLoadingSafetyCheckServiceImpl service;
  private PreLoadingSafetyCheckRepository safetyRepo;
  private DispatchRepository dispatchRepo;
  private DispatchStatusHistoryRepository statusHistoryRepo;
  private LoadingQueueRepository loadingQueueRepository;
  private UserRepository userRepo;
  private LoadingSessionRepository loadingSessionRepository;
  private LoadingDocumentRepository loadingDocumentRepository;
  private LoadingWorkflowService loadingWorkflowService;
  private AuthenticatedUserUtil authUtil;
  private DispatchValidator dispatchValidator;
  private FeatureToggleConfig featureToggleConfig;

  @BeforeEach
  void setup() {
    safetyRepo = Mockito.mock(PreLoadingSafetyCheckRepository.class);
    dispatchRepo = Mockito.mock(DispatchRepository.class);
    statusHistoryRepo = Mockito.mock(DispatchStatusHistoryRepository.class);
    loadingQueueRepository = Mockito.mock(LoadingQueueRepository.class);
    userRepo = Mockito.mock(UserRepository.class);
    loadingSessionRepository = Mockito.mock(LoadingSessionRepository.class);
    loadingDocumentRepository = Mockito.mock(LoadingDocumentRepository.class);
    loadingWorkflowService = Mockito.mock(LoadingWorkflowService.class);
    authUtil = Mockito.mock(AuthenticatedUserUtil.class);
    dispatchValidator = Mockito.mock(DispatchValidator.class);
    featureToggleConfig = Mockito.mock(FeatureToggleConfig.class);

    service =
        new PreLoadingSafetyCheckServiceImpl(
            safetyRepo,
            dispatchRepo,
            statusHistoryRepo,
            loadingQueueRepository,
            userRepo,
            loadingSessionRepository,
            loadingDocumentRepository,
            loadingWorkflowService,
            authUtil,
            dispatchValidator,
            featureToggleConfig);

    SecurityContextHolder.getContext()
        .setAuthentication(
            new UsernamePasswordAuthenticationToken(
                "tester", "n/a", Set.of(new SimpleGrantedAuthority("ROLE_SAFETY"))));
  }

  @AfterEach
  void tearDown() {
    SecurityContextHolder.clearContext();
  }

  @Test
  void submitSafetyCheck_passInQueueKhb_autoTransitionsToLoading() {
    Dispatch dispatch = new Dispatch();
    dispatch.setId(100L);
    dispatch.setStatus(DispatchStatus.IN_QUEUE);

    Dispatch refreshed = new Dispatch();
    refreshed.setId(100L);
    refreshed.setStatus(DispatchStatus.LOADING);

    LoadingQueue queue =
        LoadingQueue.builder()
            .id(77L)
            .dispatch(dispatch)
            .status(LoadingQueueStatus.WAITING)
            .warehouseCode(WarehouseCode.KHB)
            .build();

    when(dispatchRepo.findById(100L)).thenReturn(Optional.of(dispatch), Optional.of(refreshed));
    when(dispatchRepo.save(any(Dispatch.class))).thenAnswer(inv -> inv.getArgument(0));
    when(authUtil.getCurrentUserId()).thenReturn(11L);
    when(userRepo.findById(11L)).thenReturn(Optional.of(new User()));
    when(featureToggleConfig.getPreEntrySafetyRequiredWarehouses()).thenReturn(Set.of("KHB"));
    when(loadingQueueRepository.findByDispatchId(100L)).thenReturn(Optional.of(queue));
    when(safetyRepo.save(any(PreLoadingSafetyCheck.class))).thenAnswer(inv -> inv.getArgument(0));
    when(loadingWorkflowService.startLoading(any()))
        .thenReturn(LoadingSessionResponse.builder().build());

    PreLoadingSafetyCheckResponse response = service.submitSafetyCheck(buildRequest(SafetyResult.PASS, null));

    assertTrue(Boolean.TRUE.equals(response.getAutoTransitionApplied()));
    assertEquals("LOADING", response.getDispatchStatusAfterCheck());
    assertEquals("Pre-entry passed, moved to LOADING.", response.getTransitionMessage());
    verify(loadingWorkflowService).callToBay(77L, null, "Auto-called after pre-entry PASS");
    verify(loadingWorkflowService).startLoading(any());
  }

  @Test
  void submitSafetyCheck_passWithoutQueue_throwsDeterministicConflict() {
    Dispatch dispatch = new Dispatch();
    dispatch.setId(100L);
    dispatch.setStatus(DispatchStatus.IN_QUEUE);

    when(dispatchRepo.findById(100L)).thenReturn(Optional.of(dispatch));
    when(dispatchRepo.save(any(Dispatch.class))).thenAnswer(inv -> inv.getArgument(0));
    when(authUtil.getCurrentUserId()).thenReturn(11L);
    when(userRepo.findById(11L)).thenReturn(Optional.of(new User()));
    when(featureToggleConfig.getPreEntrySafetyRequiredWarehouses()).thenReturn(Set.of("KHB"));
    when(loadingQueueRepository.findByDispatchId(100L)).thenReturn(Optional.empty());
    when(safetyRepo.save(any(PreLoadingSafetyCheck.class))).thenAnswer(inv -> inv.getArgument(0));

    IllegalStateException ex =
        assertThrows(
            IllegalStateException.class,
            () -> service.submitSafetyCheck(buildRequest(SafetyResult.PASS, null)));

    assertEquals("Queue entry required before pre-entry PASS can transition to loading.", ex.getMessage());
    verify(loadingWorkflowService, never()).startLoading(any());
  }

  @Test
  void submitSafetyCheck_fail_returnsBlockedMessageAndNoTransition() {
    Dispatch dispatch = new Dispatch();
    dispatch.setId(100L);
    dispatch.setStatus(DispatchStatus.ARRIVED_LOADING);

    when(dispatchRepo.findById(100L)).thenReturn(Optional.of(dispatch), Optional.of(dispatch));
    when(dispatchRepo.save(any(Dispatch.class))).thenAnswer(inv -> inv.getArgument(0));
    when(authUtil.getCurrentUserId()).thenReturn(11L);
    when(userRepo.findById(11L)).thenReturn(Optional.of(new User()));
    when(safetyRepo.save(any(PreLoadingSafetyCheck.class))).thenAnswer(inv -> inv.getArgument(0));

    PreLoadingSafetyCheckResponse response =
        service.submitSafetyCheck(buildRequest(SafetyResult.FAIL, "Missing PPE"));

    assertFalse(Boolean.TRUE.equals(response.getAutoTransitionApplied()));
    assertEquals(
        "Pre-entry failed. Loading progression is blocked until resolved/override.",
        response.getTransitionMessage());
    verify(loadingWorkflowService, never()).startLoading(any());
  }

  private PreLoadingSafetyCheckRequest buildRequest(SafetyResult result, String failReason) {
    PreLoadingSafetyCheckRequest req = new PreLoadingSafetyCheckRequest();
    req.setDispatchId(100L);
    req.setDriverPpeOk(true);
    req.setFireExtinguisherOk(true);
    req.setWheelChockOk(true);
    req.setTruckLeakageOk(true);
    req.setTruckCleanOk(true);
    req.setTruckConditionOk(true);
    req.setResult(result);
    req.setFailReason(failReason);
    return req;
  }
}
