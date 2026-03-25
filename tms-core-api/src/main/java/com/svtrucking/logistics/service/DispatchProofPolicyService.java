package com.svtrucking.logistics.service;

import com.svtrucking.logistics.config.FeatureToggleConfig;
import com.svtrucking.logistics.dto.dispatchflow.DispatchFlowProofPolicyDto;
import com.svtrucking.logistics.dto.dispatchflow.DispatchProofStateDto;
import com.svtrucking.logistics.enums.DispatchStatus;
import com.svtrucking.logistics.model.Dispatch;
import com.svtrucking.logistics.model.DispatchFlowTemplate;
import com.svtrucking.logistics.model.DispatchFlowTransitionRule;
import com.svtrucking.logistics.model.DispatchFlowTransitionRuleVersion;
import com.svtrucking.logistics.model.UnloadProof;
import com.svtrucking.logistics.repository.DispatchFlowTemplateRepository;
import com.svtrucking.logistics.repository.DispatchFlowTransitionRuleRepository;
import com.svtrucking.logistics.repository.DispatchFlowTransitionRuleVersionRepository;
import com.svtrucking.logistics.repository.LoadProofRepository;
import com.svtrucking.logistics.repository.UnloadProofRepository;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
@Slf4j
public class DispatchProofPolicyService {

  private final DispatchFlowTemplateRepository templateRepository;
  private final DispatchFlowTransitionRuleRepository ruleRepository;
  private final DispatchFlowTransitionRuleVersionRepository ruleVersionRepository;
  private final DispatchFlowRuleMetadataService metadataService;
  private final LoadProofRepository loadProofRepository;
  private final UnloadProofRepository unloadProofRepository;
  private final DispatchWorkflowPolicyService dispatchWorkflowPolicyService;
  private final FeatureToggleConfig featureToggleConfig;

  public ProofPolicyDecision evaluateTransitionProofRequirement(
      Dispatch dispatch, DispatchStatus targetStatus) {
    if (dispatch == null || targetStatus == null) {
      return ProofPolicyDecision.none();
    }
    if (featureToggleConfig.isDispatchWorkflowEmergencyBypass()) {
      log.warn(
          "Emergency workflow bypass active: allowing proof-gated transition dispatchId={}, currentStatus={}, targetStatus={}",
          dispatch.getId(),
          dispatch.getStatus(),
          targetStatus);
      return ProofPolicyDecision.none();
    }

    DispatchFlowProofPolicyDto actionPolicy = resolveProofPolicyForTransition(dispatch, targetStatus);
    if (actionPolicy != null && Boolean.TRUE.equals(actionPolicy.getProofRequired())) {
      return new ProofPolicyDecision(
          actionPolicy,
          false,
          actionPolicy.getBlockCode(),
          defaultIfBlank(actionPolicy.getBlockMessage(), defaultMessageForType(actionPolicy.getProofType())));
    }

    if (needsExistingPodBeforeAdvance(targetStatus) && !hasPod(dispatch.getId())) {
      DispatchFlowProofPolicyDto podPolicy = resolveProofPolicyForType(dispatch, "POD");
      return new ProofPolicyDecision(
          podPolicy,
          false,
          "POD_REQUIRED",
          "Submit POD before completing delivery.");
    }

    if (targetStatus == DispatchStatus.IN_TRANSIT && !hasPol(dispatch)) {
      DispatchFlowProofPolicyDto polPolicy = resolveProofPolicyForType(dispatch, "POL");
      return new ProofPolicyDecision(
          polPolicy,
          false,
          "POL_REQUIRED",
          "Submit POL before updating to transit.");
    }

    return ProofPolicyDecision.none();
  }

  public ProofSubmissionDecision evaluateProofSubmission(Dispatch dispatch, String proofType) {
    if (dispatch == null || proofType == null || proofType.isBlank()) {
      return new ProofSubmissionDecision(null, false, "INVALID_PROOF_TYPE", "Proof type is required.");
    }
    if (featureToggleConfig.isDispatchWorkflowEmergencyBypass()) {
      log.warn(
          "Emergency workflow bypass active: allowing proof submission dispatchId={}, currentStatus={}, proofType={}",
          dispatch.getId(),
          dispatch.getStatus(),
          proofType);
      return new ProofSubmissionDecision(resolveProofPolicyForType(dispatch, proofType), true, null, null);
    }

    DispatchFlowProofPolicyDto policy = resolveProofPolicyForType(dispatch, proofType);
    if (policy == null) {
      return new ProofSubmissionDecision(
          null,
          false,
          "PROOF_POLICY_MISSING",
          "Proof policy is not configured for this dispatch.");
    }

    List<DispatchStatus> allowedStatuses = policy.getProofSubmissionAllowedStatuses();
    boolean allowed =
        allowedStatuses != null && dispatch.getStatus() != null && allowedStatuses.contains(dispatch.getStatus());

    String blockCode = allowed ? null : defaultIfBlank(policy.getBlockCode(), proofType.toUpperCase() + "_STATUS_BLOCKED");
    String blockMessage =
        allowed
            ? null
            : defaultIfBlank(
                policy.getBlockMessage(),
                proofType.equalsIgnoreCase("POL")
                    ? "POL cannot be submitted in the current dispatch status."
                    : "POD cannot be submitted in the current dispatch status.");

    return new ProofSubmissionDecision(policy, allowed, blockCode, blockMessage);
  }

  public DispatchProofStateDto buildProofState(Dispatch dispatch) {
    DispatchWorkflowPolicyService.VersionedTemplateResolution resolution =
        dispatchWorkflowPolicyService.resolveVersionedTemplate(dispatch);
    DispatchFlowTemplate resolvedTemplate = resolution.template();
    Optional<UnloadProof> unloadProof = unloadProofRepository.findFirstByDispatchIdOrderBySubmittedAtDescIdDesc(dispatch.getId());
    return DispatchProofStateDto.builder()
        .dispatchId(dispatch.getId())
        .currentStatus(dispatch.getStatus())
        .linkedTemplateCode(dispatch.getLoadingTypeCode())
        .resolvedTemplateCode(resolvedTemplate != null ? resolvedTemplate.getCode() : DispatchWorkflowPolicyService.DEFAULT_TEMPLATE_CODE)
        .workflowVersionId(dispatch.getWorkflowVersionId())
        .resolvedWorkflowVersionId(resolution.workflowVersionId())
        .polRequired(resolveProofPolicyForType(dispatch, "POL") != null)
        .polSubmitted(Boolean.TRUE.equals(dispatch.getPolSubmitted()) || loadProofRepository.findByDispatchId(dispatch.getId()).isPresent())
        .polSubmittedAt(dispatch.getPolSubmittedAt())
        .podRequired(resolveProofPolicyForType(dispatch, "POD") != null)
        .podSubmitted(Boolean.TRUE.equals(dispatch.getPodSubmitted()) || unloadProof.isPresent())
        .podSubmittedAt(dispatch.getPodSubmittedAt() != null ? dispatch.getPodSubmittedAt() : unloadProof.map(UnloadProof::getSubmittedAt).orElse(null))
        .podVerified(dispatch.getPodVerified())
        .loadProofPresent(loadProofRepository.findByDispatchId(dispatch.getId()).isPresent())
        .unloadProofPresent(unloadProof.isPresent())
        .build();
  }

  public DispatchFlowProofPolicyDto resolveProofPolicyForTransition(Dispatch dispatch, DispatchStatus targetStatus) {
    DispatchFlowTransitionRuleVersion versionedRule = findVersionedRuleForTransition(dispatch, targetStatus).orElse(null);
    if (versionedRule != null) {
      return metadataService.parseProofPolicy(versionedRule.getMetadataJson());
    }
    DispatchFlowTransitionRule rule = findRuleForTransition(dispatch, targetStatus).orElse(null);
    if (rule != null) {
      return metadataService.resolveProofPolicyForRule(rule);
    }
    return metadataService.defaultProofPolicy(targetStatus);
  }

  public DispatchFlowProofPolicyDto resolveProofPolicyForType(Dispatch dispatch, String proofType) {
    DispatchWorkflowPolicyService.VersionedTemplateResolution resolution =
        dispatchWorkflowPolicyService.resolveVersionedTemplate(dispatch);
    DispatchFlowTemplate template = resolution.template();
    if (resolution.workflowVersionId() != null) {
      List<DispatchFlowTransitionRuleVersion> rules =
          ruleVersionRepository.findByTemplateVersionIdOrderByPriorityAsc(resolution.workflowVersionId());
      for (DispatchFlowTransitionRuleVersion rule : rules) {
        DispatchFlowProofPolicyDto policy = metadataService.parseProofPolicy(rule.getMetadataJson());
        if (policy == null || policy.getProofType() == null) {
          continue;
        }
        if (policy.getProofType().equalsIgnoreCase(proofType)) {
          return policy;
        }
      }
    }
    if (template != null) {
      List<DispatchFlowTransitionRule> rules = ruleRepository.findByTemplateIdOrderByPriorityAsc(template.getId());
      for (DispatchFlowTransitionRule rule : rules) {
        DispatchFlowProofPolicyDto policy = metadataService.resolveProofPolicyForRule(rule);
        if (policy == null || policy.getProofType() == null) {
          continue;
        }
        if (policy.getProofType().equalsIgnoreCase(proofType)) {
          return policy;
        }
      }
    }
    return metadataService.defaultProofPolicyForType(proofType);
  }

  private Optional<DispatchFlowTransitionRule> findRuleForTransition(Dispatch dispatch, DispatchStatus targetStatus) {
    DispatchFlowTemplate template = resolveTemplateForDispatch(dispatch);
    if (template == null || dispatch == null || dispatch.getStatus() == null || targetStatus == null) {
      return Optional.empty();
    }
    return ruleRepository.findByTemplateIdAndFromStatusAndToStatusAndEnabledTrue(
        template.getId(), dispatch.getStatus(), targetStatus);
  }

  private Optional<DispatchFlowTransitionRuleVersion> findVersionedRuleForTransition(
      Dispatch dispatch, DispatchStatus targetStatus) {
    Long workflowVersionId = dispatchWorkflowPolicyService.resolveWorkflowVersionIdForDispatch(dispatch);
    if (workflowVersionId == null || dispatch == null || dispatch.getStatus() == null || targetStatus == null) {
      return Optional.empty();
    }
    return ruleVersionRepository.findByTemplateVersionIdAndFromStatusAndToStatusAndEnabledTrue(
        workflowVersionId, dispatch.getStatus(), targetStatus);
  }

  private DispatchFlowTemplate resolveTemplateForDispatch(Dispatch dispatch) {
    String code =
        Optional.ofNullable(dispatch)
            .map(Dispatch::getLoadingTypeCode)
            .filter(v -> !v.isBlank())
            .orElse(DispatchWorkflowPolicyService.DEFAULT_TEMPLATE_CODE);
    return templateRepository
        .findByCodeIgnoreCase(code)
        .filter(DispatchFlowTemplate::isActive)
        .or(() -> templateRepository.findByCodeIgnoreCase(DispatchWorkflowPolicyService.DEFAULT_TEMPLATE_CODE).filter(DispatchFlowTemplate::isActive))
        .orElse(null);
  }

  private boolean needsExistingPodBeforeAdvance(DispatchStatus targetStatus) {
    return targetStatus == DispatchStatus.DELIVERED || targetStatus == DispatchStatus.COMPLETED;
  }

  private boolean hasPol(Dispatch dispatch) {
    return Boolean.TRUE.equals(dispatch.getPolSubmitted())
        || loadProofRepository.findByDispatchId(dispatch.getId()).isPresent();
  }

  private boolean hasPod(Long dispatchId) {
    return unloadProofRepository.findFirstByDispatchIdOrderBySubmittedAtDescIdDesc(dispatchId).isPresent();
  }

  private String defaultMessageForType(String proofType) {
    if (Objects.equals("POL", proofType)) {
      return "Submit POL (proof of loading) to mark as loaded.";
    }
    if (Objects.equals("POD", proofType)) {
      return "Submit POD before completing delivery.";
    }
    return "Required proof is missing.";
  }

  private String defaultIfBlank(String value, String fallback) {
    return value == null || value.isBlank() ? fallback : value;
  }

  public record ProofPolicyDecision(
      DispatchFlowProofPolicyDto proofPolicy,
      boolean allowed,
      String blockedCode,
      String blockedReason) {
    static ProofPolicyDecision none() {
      return new ProofPolicyDecision(null, true, null, null);
    }
  }

  public record ProofSubmissionDecision(
      DispatchFlowProofPolicyDto proofPolicy,
      boolean allowed,
      String blockedCode,
      String blockedReason) {}
}
