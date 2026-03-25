package com.svtrucking.logistics.service;

import com.svtrucking.logistics.enums.DispatchStatus;
import com.svtrucking.logistics.model.Dispatch;
import com.svtrucking.logistics.model.LoadProof;
import com.svtrucking.logistics.repository.DispatchProofEventRepository;
import com.svtrucking.logistics.repository.DispatchRepository;
import com.svtrucking.logistics.repository.LoadProofRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class LoadProofServiceTest {

  @Mock
  private LoadProofRepository loadProofRepository;

  @Mock
  private DispatchRepository dispatchRepository;

  @Mock
  private FileStorageService fileStorageService;
  @Mock
  private DispatchProofPolicyService dispatchProofPolicyService;

  @Mock
  private DispatchProofEventRepository dispatchProofEventRepository;

  @InjectMocks
  private LoadProofService loadProofService;

  @Test
  void submitLoadProof_requiresLoadingStatus() {
    Dispatch dispatch = Dispatch.builder()
        .id(10L)
        .status(DispatchStatus.IN_QUEUE)
        .build();

    when(dispatchRepository.findById(10L)).thenReturn(Optional.of(dispatch));
    when(dispatchProofPolicyService.evaluateProofSubmission(dispatch, "POL"))
        .thenReturn(new DispatchProofPolicyService.ProofSubmissionDecision(
            null,
            false,
            "POL_STATUS_BLOCKED",
            "POL can be submitted only when dispatch is in LOADING or LOADED status."));

    IllegalStateException ex = assertThrows(
        IllegalStateException.class,
        () -> loadProofService.submitLoadProof(10L, "ok", List.of(), null));

    assertEquals("POL can be submitted only when dispatch is in LOADING or LOADED status.", ex.getMessage());
    verify(loadProofRepository, never()).save(any());
    verify(dispatchRepository, never()).save(any(Dispatch.class));
  }

  @Test
  void submitLoadProof_acceptsLatePolWhenAlreadyLoaded() throws Exception {
    Dispatch dispatch = Dispatch.builder()
        .id(12L)
        .status(DispatchStatus.LOADED)
        .polSubmitted(false)
        .build();

    when(dispatchRepository.findById(12L)).thenReturn(Optional.of(dispatch));
    when(loadProofRepository.findByDispatchId(12L)).thenReturn(Optional.empty());
    when(loadProofRepository.save(any(LoadProof.class))).thenAnswer(inv -> inv.getArgument(0));
    when(dispatchRepository.save(any(Dispatch.class))).thenAnswer(inv -> inv.getArgument(0));
    when(dispatchProofPolicyService.evaluateProofSubmission(dispatch, "POL"))
        .thenReturn(new DispatchProofPolicyService.ProofSubmissionDecision(
            com.svtrucking.logistics.dto.dispatchflow.DispatchFlowProofPolicyDto.builder()
                .autoAdvanceStatusAfterProof(DispatchStatus.LOADED)
                .build(),
            true,
            null,
            null));

    loadProofService.submitLoadProof(12L, "late pol", List.of(), null);

    ArgumentCaptor<Dispatch> dispatchCaptor = ArgumentCaptor.forClass(Dispatch.class);
    verify(dispatchRepository).save(dispatchCaptor.capture());
    Dispatch saved = dispatchCaptor.getValue();

    assertEquals(DispatchStatus.LOADED, saved.getStatus());
    assertTrue(Boolean.TRUE.equals(saved.getPolSubmitted()));
    assertNotNull(saved.getPolSubmittedAt());
  }

  @Test
  void submitLoadProof_setsLoadedAndPolFlags() throws Exception {
    Dispatch dispatch = Dispatch.builder()
        .id(11L)
        .status(DispatchStatus.LOADING)
        .polSubmitted(false)
        .build();

    when(dispatchRepository.findById(11L)).thenReturn(Optional.of(dispatch));
    when(loadProofRepository.findByDispatchId(11L)).thenReturn(Optional.empty());
    when(loadProofRepository.save(any(LoadProof.class))).thenAnswer(inv -> inv.getArgument(0));
    when(dispatchRepository.save(any(Dispatch.class))).thenAnswer(inv -> inv.getArgument(0));
    when(dispatchProofPolicyService.evaluateProofSubmission(dispatch, "POL"))
        .thenReturn(new DispatchProofPolicyService.ProofSubmissionDecision(
            com.svtrucking.logistics.dto.dispatchflow.DispatchFlowProofPolicyDto.builder()
                .autoAdvanceStatusAfterProof(DispatchStatus.LOADED)
                .build(),
            true,
            null,
            null));

    loadProofService.submitLoadProof(11L, "done", List.of(), null);

    ArgumentCaptor<Dispatch> dispatchCaptor = ArgumentCaptor.forClass(Dispatch.class);
    verify(dispatchRepository).save(dispatchCaptor.capture());
    Dispatch saved = dispatchCaptor.getValue();

    assertEquals(DispatchStatus.LOADED, saved.getStatus());
    assertTrue(Boolean.TRUE.equals(saved.getPolSubmitted()));
    assertNotNull(saved.getPolSubmittedAt());
  }
}
