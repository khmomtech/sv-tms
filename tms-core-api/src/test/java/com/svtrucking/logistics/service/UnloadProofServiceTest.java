package com.svtrucking.logistics.service;

import com.svtrucking.logistics.dto.UnloadProofDto;
import com.svtrucking.logistics.enums.DispatchStatus;
import com.svtrucking.logistics.model.Dispatch;
import com.svtrucking.logistics.model.UnloadProof;
import com.svtrucking.logistics.repository.DispatchProofEventRepository;
import com.svtrucking.logistics.repository.DispatchRepository;
import com.svtrucking.logistics.repository.UnloadProofRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class UnloadProofServiceTest {

  @Mock
  private DispatchRepository dispatchRepository;

  @Mock
  private UnloadProofRepository unloadProofRepository;

  @Mock
  private DispatchProofEventRepository dispatchProofEventRepository;

  @Mock
  private DispatchProofPolicyService dispatchProofPolicyService;

  @InjectMocks
  private UnloadProofService unloadProofService;

  @Test
  void submitUnloadProof_reusesLatestProofRowForDispatch() throws Exception {
    Dispatch dispatch = Dispatch.builder()
        .id(2L)
        .status(DispatchStatus.UNLOADING)
        .build();

    UnloadProof existing = UnloadProof.builder().id(9L).build();

    when(dispatchRepository.findById(2L)).thenReturn(Optional.of(dispatch));
    when(unloadProofRepository.countByDispatchId(2L)).thenReturn(2L);
    when(unloadProofRepository.findFirstByDispatchIdOrderBySubmittedAtDescIdDesc(2L))
        .thenReturn(Optional.of(existing));
    when(unloadProofRepository.save(any(UnloadProof.class))).thenAnswer(inv -> inv.getArgument(0));
    when(dispatchRepository.save(any(Dispatch.class))).thenAnswer(inv -> inv.getArgument(0));
    when(dispatchProofPolicyService.evaluateProofSubmission(dispatch, "POD"))
        .thenReturn(new DispatchProofPolicyService.ProofSubmissionDecision(
            com.svtrucking.logistics.dto.dispatchflow.DispatchFlowProofPolicyDto.builder()
                .autoAdvanceStatusAfterProof(DispatchStatus.UNLOADED)
                .build(),
            true,
            null,
            null));

    UnloadProofDto dto = unloadProofService.submitUnloadProof(
        2L,
        "done",
        "addr",
        11.0,
        104.0,
        List.<MultipartFile>of(),
        null);

    ArgumentCaptor<UnloadProof> proofCaptor = ArgumentCaptor.forClass(UnloadProof.class);
    verify(unloadProofRepository).save(proofCaptor.capture());
    verify(unloadProofRepository).countByDispatchId(2L);
    assertEquals(9L, proofCaptor.getValue().getId());
    assertNotNull(dto);
    assertEquals(DispatchStatus.UNLOADED, dispatch.getStatus());
  }

  @Test
  void getProofByDispatchId_usesCanonicalRowWhenDuplicatesExist() {
    Dispatch dispatch = Dispatch.builder().id(7L).build();
    UnloadProof latest = UnloadProof.builder().id(11L).dispatch(dispatch).build();

    when(unloadProofRepository.countByDispatchId(7L)).thenReturn(3L);
    when(unloadProofRepository.findFirstByDispatchIdOrderBySubmittedAtDescIdDesc(7L))
        .thenReturn(Optional.of(latest));

    UnloadProofDto dto = unloadProofService.getProofByDispatchId(7L);

    assertNotNull(dto);
    assertEquals(11L, dto.getId());
    verify(unloadProofRepository).countByDispatchId(7L);
  }

  @Test
  void submitUnloadProof_acceptsLatePodWhenAlreadyDelivered() {
    Dispatch dispatch = Dispatch.builder()
        .id(8L)
        .status(DispatchStatus.DELIVERED)
        .build();

    when(dispatchRepository.findById(8L)).thenReturn(Optional.of(dispatch));
    when(unloadProofRepository.countByDispatchId(8L)).thenReturn(0L);
    when(unloadProofRepository.findFirstByDispatchIdOrderBySubmittedAtDescIdDesc(8L))
        .thenReturn(Optional.empty());
    when(unloadProofRepository.save(any(UnloadProof.class))).thenAnswer(inv -> inv.getArgument(0));
    when(dispatchRepository.save(any(Dispatch.class))).thenAnswer(inv -> inv.getArgument(0));
    when(dispatchProofPolicyService.evaluateProofSubmission(dispatch, "POD"))
        .thenReturn(new DispatchProofPolicyService.ProofSubmissionDecision(
            com.svtrucking.logistics.dto.dispatchflow.DispatchFlowProofPolicyDto.builder()
                .autoAdvanceStatusAfterProof(DispatchStatus.UNLOADED)
                .build(),
            true,
            null,
            null));

    assertDoesNotThrow(() -> unloadProofService.submitUnloadProof(
        8L,
        "late pod",
        "addr",
        11.0,
        104.0,
        List.<MultipartFile>of(),
        null));
  }
}
