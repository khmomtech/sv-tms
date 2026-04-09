package com.svtrucking.logistics.service;

import com.svtrucking.logistics.dto.LoadProofDto;
import com.svtrucking.logistics.enums.DispatchProofReviewStatus;
import com.svtrucking.logistics.model.Dispatch;
import com.svtrucking.logistics.model.DispatchProofEvent;
import com.svtrucking.logistics.model.LoadProof;
import com.svtrucking.logistics.repository.DispatchRepository;
import com.svtrucking.logistics.repository.DispatchProofEventRepository;
import com.svtrucking.logistics.repository.LoadProofRepository;
import java.io.IOException;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;
import org.springframework.web.multipart.MultipartFile;

@Service
@RequiredArgsConstructor
public class LoadProofService {

  private final LoadProofRepository loadProofRepository;
  private final DispatchRepository dispatchRepository;
  private final FileStorageService fileStorageService;
  private final DispatchProofPolicyService dispatchProofPolicyService;
  private final DispatchProofEventRepository dispatchProofEventRepository;
  private final com.svtrucking.logistics.security.AuthenticatedUserUtil authenticatedUserUtil;

  @Transactional
  public LoadProofDto submitLoadProof(
      Long dispatchId, String remarks, List<MultipartFile> images, MultipartFile signature)
      throws IOException {

    Dispatch dispatch =
        dispatchRepository
            .findById(dispatchId)
            .orElseThrow(() -> new RuntimeException("Dispatch not found"));
    var statusAtSubmission = dispatch.getStatus();

    var proofDecision = dispatchProofPolicyService.evaluateProofSubmission(dispatch, "POL");
    if (!proofDecision.allowed()) {
      recordProofEvent(dispatch, statusAtSubmission, "POL", false, proofDecision.blockedCode(), proofDecision.blockedReason(), images.size(), proofDecision.proofPolicy());
      throw new IllegalStateException(proofDecision.blockedReason());
    }

    List<String> imagePaths = new ArrayList<>();
    String signaturePath = null;

    // Store each image in: /uploads/load-proof/{dispatchId}/filename.jpg
    for (MultipartFile file : images) {
      String imageUrl = fileStorageService.storeFileInSubfolder(file, "load-proof/" + dispatchId);
      imagePaths.add(imageUrl.replaceFirst("^/uploads/", "")); //  Corrected here
    }

    if (signature != null && !signature.isEmpty()) {
      String sigUrl =
          fileStorageService.storeFileInSubfolder(signature, "load-proof/" + dispatchId);
      signaturePath = sigUrl.replaceFirst("^/uploads/", ""); //  Corrected here
    }

    // Create or update the load proof record
    LoadProof proof = loadProofRepository.findByDispatchId(dispatchId).orElseGet(LoadProof::new);

    proof.setDispatch(dispatch);
    proof.setRemarks(remarks);
    proof.setProofImagePaths(imagePaths);
    proof.setSignaturePath(signaturePath);
    LoadProof saved = loadProofRepository.save(proof);

    // Keep the dispatch at LOADED after successful POL submission, even when
    // proof is uploaded late as part of a recovery flow.
    if (proofDecision.proofPolicy() != null
        && proofDecision.proofPolicy().getAutoAdvanceStatusAfterProof() != null) {
      dispatch.setStatus(proofDecision.proofPolicy().getAutoAdvanceStatusAfterProof());
    }
    dispatch.setPolSubmitted(true);
    dispatch.setPolSubmittedAt(LocalDateTime.now());
    dispatch.setUpdatedDate(LocalDateTime.now());
    dispatchRepository.save(dispatch);
    recordProofEvent(dispatch, statusAtSubmission, "POL", true, null, null, images.size(), proofDecision.proofPolicy());

    return LoadProofDto.fromEntity(saved);
  }

  @Transactional(readOnly = true)
  public List<LoadProofDto> getFilteredProofs(
      String search, String driver, String route, LocalDate from, LocalDate to) {
    List<LoadProof> all = loadProofRepository.findAll(Sort.by(Sort.Direction.DESC, "uploadedAt"));

    return all.stream()
        .filter(
            p -> {
              LocalDate date =
                  (p.getUploadedAt() != null) ? p.getUploadedAt().toLocalDate() : LocalDate.now();

              boolean matchSearch =
                  (search == null
                      || (String.valueOf(p.getDispatch().getId()).contains(search)
                          || p.getDispatch()
                              .getRouteCode()
                              .toLowerCase()
                              .contains(search.toLowerCase())
                          || p.getDispatch()
                              .getDriver()
                              .getFullName()
                              .toLowerCase()
                              .contains(search.toLowerCase())
                          || (p.getRemarks() != null
                              && p.getRemarks().toLowerCase().contains(search.toLowerCase()))));

              boolean matchDriver =
                  driver == null || p.getDispatch().getDriver().getFullName().equals(driver);
              boolean matchRoute =
                  route == null
                      || p.getDispatch().getRouteCode().toLowerCase().contains(route.toLowerCase());

              boolean matchFrom = from == null || !date.isBefore(from);
              boolean matchTo = to == null || !date.isAfter(to);

              return matchSearch && matchDriver && matchRoute && matchFrom && matchTo;
            })
        .map(this::initializeProofPaths)
        .map(LoadProofDto::fromEntity)
        .collect(Collectors.toList());
  }

  @Transactional(readOnly = true)
  public LoadProofDto getProofByDispatchId(Long dispatchId) {
    return loadProofRepository
        .findByDispatchId(dispatchId)
        .map(this::initializeProofPaths)
        .map(LoadProofDto::fromEntity)
        .orElse(null);
  }

  private LoadProof initializeProofPaths(LoadProof proof) {
    if (proof == null) {
      return null;
    }
    if (proof.getProofImagePaths() != null) {
      proof.getProofImagePaths().size();
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
        .collect(Collectors.joining(","));
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
