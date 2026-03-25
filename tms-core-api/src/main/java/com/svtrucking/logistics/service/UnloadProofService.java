package com.svtrucking.logistics.service;

import com.svtrucking.logistics.dto.UnloadProofDto;
import com.svtrucking.logistics.enums.DispatchProofReviewStatus;
import com.svtrucking.logistics.model.Dispatch;
import com.svtrucking.logistics.model.DispatchProofEvent;
import com.svtrucking.logistics.model.UnloadProof;
import com.svtrucking.logistics.repository.DispatchRepository;
import com.svtrucking.logistics.repository.DispatchProofEventRepository;
import com.svtrucking.logistics.repository.UnloadProofRepository;
import java.io.IOException;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;
import org.springframework.web.multipart.MultipartFile;

@Service
@RequiredArgsConstructor
@Slf4j
public class UnloadProofService {

  private final DispatchRepository dispatchRepository;
  private final UnloadProofRepository unloadProofRepository;
  private final FileStorageService fileStorageService;
  private final DispatchProofPolicyService dispatchProofPolicyService;
  private final DispatchProofEventRepository dispatchProofEventRepository;
  private final com.svtrucking.logistics.security.AuthenticatedUserUtil authenticatedUserUtil;

  @Transactional
  public UnloadProofDto submitUnloadProof(
      Long dispatchId,
      String remarks,
      String address,
      Double lat,
      Double lng,
      List<MultipartFile> images,
      MultipartFile signature)
      throws IOException {

    Dispatch dispatch =
        dispatchRepository
            .findById(dispatchId)
            .orElseThrow(() -> new RuntimeException("Dispatch not found"));
    var statusAtSubmission = dispatch.getStatus();

    var proofDecision = dispatchProofPolicyService.evaluateProofSubmission(dispatch, "POD");
    if (!proofDecision.allowed()) {
      recordProofEvent(dispatch, statusAtSubmission, "POD", false, proofDecision.blockedCode(), proofDecision.blockedReason(), images.size(), proofDecision.proofPolicy());
      throw new IllegalStateException(proofDecision.blockedReason());
    }

    List<String> imagePaths = new ArrayList<>();
    String signaturePath = null;

    for (MultipartFile file : images) {
      String imageUrl = fileStorageService.storeFileInSubfolder(file, "unload-proof/" + dispatchId);
      imagePaths.add(imageUrl.replaceFirst("^/uploads/", ""));
    }

    if (signature != null && !signature.isEmpty()) {
      String sigUrl =
          fileStorageService.storeFileInSubfolder(signature, "unload-proof/" + dispatchId);
      signaturePath = sigUrl.replaceFirst("^/uploads/", "");
    }

    UnloadProof proof =
        getCanonicalProofForDispatch(dispatchId).orElseGet(UnloadProof::new);

    proof.setDispatch(dispatch);
    proof.setRemarks(remarks);
    proof.setAddress(address);
    proof.setLatitude(lat);
    proof.setLongitude(lng);
    proof.setProofImagePaths(imagePaths);
    proof.setSignaturePath(signaturePath);
    proof.setSubmittedAt(LocalDateTime.now());

    UnloadProof saved = unloadProofRepository.save(proof);

    // Update dispatch status to UNLOADED
    if (proofDecision.proofPolicy() != null
        && proofDecision.proofPolicy().getAutoAdvanceStatusAfterProof() != null) {
      dispatch.setStatus(proofDecision.proofPolicy().getAutoAdvanceStatusAfterProof());
    }
    dispatch.setPodRequired(true);
    dispatch.setPodSubmitted(true);
    dispatch.setPodSubmittedAt(proof.getSubmittedAt());
    dispatch.setPodVerified(
        proofDecision.proofPolicy() != null
            ? !Boolean.TRUE.equals(proofDecision.proofPolicy().getProofReviewRequired())
            : Boolean.TRUE);
    dispatch.setUpdatedDate(LocalDateTime.now());
    dispatchRepository.save(dispatch); // Persist status change
    recordProofEvent(dispatch, statusAtSubmission, "POD", true, null, null, images.size(), proofDecision.proofPolicy());

    return UnloadProofDto.fromEntity(saved);
  }

  @Transactional(readOnly = true)
  public UnloadProofDto getProofByDispatchId(Long dispatchId) {
    return getCanonicalProofForDispatch(dispatchId)
        .map(this::initializeProofPaths)
        .map(UnloadProofDto::fromEntity)
        .orElse(null);
  }

  private Optional<UnloadProof> getCanonicalProofForDispatch(Long dispatchId) {
    long count = unloadProofRepository.countByDispatchId(dispatchId);
    if (count > 1) {
      log.warn(
          "Detected {} unload_proof rows for dispatchId={}; using newest canonical row.",
          count,
          dispatchId);
    }
    return unloadProofRepository.findFirstByDispatchIdOrderBySubmittedAtDescIdDesc(dispatchId);
  }

  private UnloadProof initializeProofPaths(UnloadProof proof) {
    if (proof == null) {
      return null;
    }
    if (proof.getProofImagePaths() != null) {
      proof.getProofImagePaths().size();
    }
    if (proof.getDispatch() != null) {
      proof.getDispatch().getId();
    }
    return proof;
  }

  private void recordProofEvent(
      Dispatch dispatch,
      com.svtrucking.logistics.enums.DispatchStatus dispatchStatusAtSubmission,
      String proofType,
      boolean accepted,
      String blockCode,
      String blockReason,
      int fileCount,
      com.svtrucking.logistics.dto.dispatchflow.DispatchFlowProofPolicyDto policy) {
    DispatchProofEvent event = new DispatchProofEvent();
    event.setDispatch(dispatch);
    event.setWorkflowVersionId(dispatch.getWorkflowVersionId());
    event.setProofType(proofType);
    event.setActorUserId(currentUserIdOrNull());
    event.setActorRolesSnapshot(currentRoleSnapshot());
    event.setDispatchStatusAtSubmission(dispatchStatusAtSubmission);
    event.setAccepted(accepted);
    event.setBlockCode(blockCode);
    event.setBlockReason(blockReason);
    event.setIdempotencyKey(resolveIdempotencyKey());
    event.setFileCount(fileCount);
    event.setReviewStatus(
        policy != null && Boolean.TRUE.equals(policy.getProofReviewRequired())
            ? DispatchProofReviewStatus.PENDING
            : DispatchProofReviewStatus.NOT_REQUIRED);
    dispatchProofEventRepository.save(event);
  }

  private Long currentUserIdOrNull() {
    try {
      return authenticatedUserUtil.getCurrentUserId();
    } catch (Exception ex) {
      return null;
    }
  }

  private String currentRoleSnapshot() {
    var auth = SecurityContextHolder.getContext().getAuthentication();
    if (auth == null || auth.getAuthorities() == null) {
      return null;
    }
    return auth.getAuthorities().stream()
        .map(granted -> granted.getAuthority())
        .sorted()
        .reduce((left, right) -> left + "," + right)
        .orElse(null);
  }

  private String resolveIdempotencyKey() {
    var attributes = RequestContextHolder.getRequestAttributes();
    if (!(attributes instanceof ServletRequestAttributes servletAttributes)) {
      return null;
    }
    var request = servletAttributes.getRequest();
    String key = request.getHeader(com.svtrucking.logistics.idempotency.IdempotencyFilter.IDEMPOTENCY_KEY_HEADER);
    if (key == null || key.isBlank()) {
      key = request.getParameter("idempotencyKey");
    }
    return key == null || key.isBlank() ? null : key.trim();
  }
}
