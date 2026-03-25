package com.svtrucking.logistics.service;

import com.svtrucking.logistics.config.FeatureToggleConfig;
import com.svtrucking.logistics.dto.dispatchflow.DispatchFlowProofPolicyDto;
import com.svtrucking.logistics.dto.response.DispatchActionMetadata;
import com.svtrucking.logistics.enums.DispatchFlowActorType;
import com.svtrucking.logistics.enums.DispatchStatus;
import com.svtrucking.logistics.enums.RoleType;
import com.svtrucking.logistics.model.Dispatch;
import com.svtrucking.logistics.model.DispatchFlowTemplate;
import com.svtrucking.logistics.model.DispatchFlowTransitionActor;
import com.svtrucking.logistics.model.DispatchFlowTransitionRule;
import com.svtrucking.logistics.model.DispatchFlowTransitionActorVersion;
import com.svtrucking.logistics.model.DispatchFlowTransitionRuleVersion;
import com.svtrucking.logistics.model.DispatchFlowTemplateVersion;
import com.svtrucking.logistics.model.Role;
import com.svtrucking.logistics.model.User;
import com.svtrucking.logistics.repository.DispatchFlowTemplateRepository;
import com.svtrucking.logistics.repository.DispatchFlowTemplateVersionRepository;
import com.svtrucking.logistics.repository.DispatchFlowTransitionActorRepository;
import com.svtrucking.logistics.repository.DispatchFlowTransitionActorVersionRepository;
import com.svtrucking.logistics.repository.DispatchFlowTransitionRuleRepository;
import com.svtrucking.logistics.repository.DispatchFlowTransitionRuleVersionRepository;
import com.svtrucking.logistics.security.AuthenticatedUserUtil;
import com.svtrucking.logistics.workflow.DispatchStateMachine;
import java.util.ArrayList;
import java.util.Collections;
import java.util.EnumSet;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

@Slf4j
@Service
@RequiredArgsConstructor
public class DispatchWorkflowPolicyService {

  public static final String DEFAULT_TEMPLATE_CODE = "GENERAL";

  private final DispatchFlowTemplateRepository templateRepository;
  private final DispatchFlowTemplateVersionRepository templateVersionRepository;
  private final DispatchFlowTransitionRuleRepository ruleRepository;
  private final DispatchFlowTransitionRuleVersionRepository ruleVersionRepository;
  private final DispatchFlowTransitionActorRepository actorRepository;
  private final DispatchFlowTransitionActorVersionRepository actorVersionRepository;
  private final AuthenticatedUserUtil authenticatedUserUtil;
  private final DispatchStateMachine dispatchStateMachine;
  private final DispatchFlowRuleMetadataService dispatchFlowRuleMetadataService;
  private final FeatureToggleConfig featureToggleConfig;

  public DispatchFlowTemplate resolveTemplateForDispatch(Dispatch dispatch) {
    VersionedTemplateResolution resolution = resolveVersionedTemplate(dispatch);
    return resolution.template();
  }

  public Long resolveWorkflowVersionIdForDispatch(Dispatch dispatch) {
    return resolveVersionedTemplate(dispatch).workflowVersionId();
  }

  public VersionedTemplateResolution resolveVersionedTemplate(Dispatch dispatch) {
    String code = Optional.ofNullable(dispatch)
        .map(Dispatch::getLoadingTypeCode)
        .filter(v -> !v.isBlank())
        .orElse(DEFAULT_TEMPLATE_CODE);

    DispatchFlowTemplate resolvedTemplate = templateRepository
        .findByCodeIgnoreCase(code)
        .filter(DispatchFlowTemplate::isActive)
        .or(() -> templateRepository.findByCodeIgnoreCase(DEFAULT_TEMPLATE_CODE).filter(DispatchFlowTemplate::isActive))
        .orElse(null);

    if (resolvedTemplate == null) {
      return new VersionedTemplateResolution(null, null, null);
    }

    DispatchFlowTemplateVersion resolvedVersion = null;
    if (dispatch != null && dispatch.getWorkflowVersionId() != null) {
      resolvedVersion = templateVersionRepository.findById(dispatch.getWorkflowVersionId())
          .filter(version -> version.getTemplate() != null && version.getTemplate().isActive())
          .orElse(null);
    }

    if (resolvedVersion == null) {
      Long activePublishedVersionId = resolvedTemplate.getActivePublishedVersionId();
      if (activePublishedVersionId != null) {
        resolvedVersion = templateVersionRepository.findById(activePublishedVersionId).orElse(null);
      }
    }

    if (resolvedVersion == null) {
      resolvedVersion = templateVersionRepository.findByTemplateIdAndActivePublishedTrue(resolvedTemplate.getId())
          .orElse(null);
    }

    return new VersionedTemplateResolution(
        resolvedTemplate,
        resolvedVersion,
        resolvedVersion != null ? resolvedVersion.getId() : null);
  }

  public Set<DispatchFlowActorType> resolveCurrentActorTypes() {
    try {
      User user = authenticatedUserUtil.getCurrentUser();
      Set<DispatchFlowActorType> actorTypes = EnumSet.noneOf(DispatchFlowActorType.class);
      if (user.getRoles() != null) {
        for (Role role : user.getRoles()) {
          if (role == null || role.getName() == null) {
            continue;
          }
          mapRoleToActor(role.getName()).ifPresent(actorTypes::add);
        }
      }
      if (actorTypes.isEmpty()) {
        actorTypes.add(DispatchFlowActorType.SYSTEM);
      }
      return actorTypes;
    } catch (Exception ex) {
      log.debug("Unable to resolve current actor types; fallback SYSTEM: {}", ex.getMessage());
      return EnumSet.of(DispatchFlowActorType.SYSTEM);
    }
  }

  public TransitionCheck evaluateTransition(Dispatch dispatch, DispatchStatus toStatus) {
    return evaluateTransition(dispatch, toStatus, resolveCurrentActorTypes());
  }

  public TransitionCheck evaluateTransition(
      Dispatch dispatch, DispatchStatus toStatus, Set<DispatchFlowActorType> currentActors) {
    if (dispatch == null || dispatch.getStatus() == null || toStatus == null) {
      return new TransitionCheck(false, "Invalid transition payload", Set.of());
    }

    if (featureToggleConfig.isDispatchWorkflowEmergencyBypass()) {
      log.warn(
          "Emergency workflow bypass active: allowing transition dispatchId={}, fromStatus={}, toStatus={}",
          dispatch.getId(),
          dispatch.getStatus(),
          toStatus);
      return new TransitionCheck(true, null, Set.of());
    }

    VersionedTemplateResolution resolution = resolveVersionedTemplate(dispatch);
    DispatchFlowTemplate template = resolution.template();
    if (template == null) {
      boolean allowed = dispatchStateMachine.canTransition(dispatch.getStatus(), toStatus);
      return new TransitionCheck(
          allowed,
          allowed ? null : "Transition is not allowed for current status",
          Set.of());
    }

    Optional<VersionedRuleContext> versionedRuleOpt =
        findVersionedRuleForTransition(resolution.workflowVersionId(), dispatch.getStatus(), toStatus);
    if (versionedRuleOpt.isPresent()) {
      VersionedRuleContext versionedRule = versionedRuleOpt.get();
      if (!versionedRule.enabled()) {
        return new TransitionCheck(false, "Transition is not configured for this loading type", Set.of());
      }
      Set<DispatchFlowActorType> allowedActors = resolveAllowedActorsForVersion(versionedRule.ruleVersion().getId());
      if (!allowedActors.isEmpty() && Collections.disjoint(allowedActors, currentActors)) {
        return new TransitionCheck(false, "Current user role cannot execute this transition", allowedActors);
      }
      return new TransitionCheck(true, null, allowedActors);
    }

    Optional<DispatchFlowTransitionRule> ruleOpt = ruleRepository
        .findByTemplateIdAndFromStatusAndToStatusAndEnabledTrue(template.getId(), dispatch.getStatus(), toStatus);
    if (ruleOpt.isEmpty()) {
      return new TransitionCheck(false, "Transition is not configured for this loading type", Set.of());
    }

    DispatchFlowTransitionRule rule = ruleOpt.get();
    Set<DispatchFlowActorType> allowedActors = resolveAllowedActors(rule.getId());

    if (!allowedActors.isEmpty() && Collections.disjoint(allowedActors, currentActors)) {
      return new TransitionCheck(false, "Current user role cannot execute this transition", allowedActors);
    }

    return new TransitionCheck(true, null, allowedActors);
  }

  public List<DispatchActionMetadata> getAvailableActions(Dispatch dispatch) {
    return getAvailableActions(dispatch, resolveCurrentActorTypes());
  }

  public List<DispatchActionMetadata> getAvailableActions(
      Dispatch dispatch, Set<DispatchFlowActorType> currentActors) {
    if (dispatch == null || dispatch.getStatus() == null) {
      return List.of();
    }

    VersionedTemplateResolution resolution = resolveVersionedTemplate(dispatch);
    DispatchFlowTemplate template = resolution.template();
    Map<DispatchStatus, DispatchActionMetadata> stateMachineDefaults = dispatchStateMachine
        .getActionMetadata(dispatch.getStatus())
        .stream()
        .collect(Collectors.toMap(DispatchActionMetadata::getTargetStatus, a -> a, (a, b) -> a));

    if (template == null) {
      List<DispatchActionMetadata> defaults = new ArrayList<>(stateMachineDefaults.values());
      if (featureToggleConfig.isDispatchWorkflowEmergencyBypass()) {
        defaults.forEach(this::clearBlockingForBypass);
      }
      return defaults;
    }

    List<VersionedRuleContext> versionedRules =
        findVersionedRulesForStatus(resolution.workflowVersionId(), dispatch.getStatus());
    if (!versionedRules.isEmpty()) {
      List<Long> ruleIds = versionedRules.stream().map(r -> r.ruleVersion().getId()).toList();
      Map<Long, Set<DispatchFlowActorType>> actorsByRule = resolveAllowedActorsForVersions(ruleIds);
      List<DispatchActionMetadata> actions = new ArrayList<>();
      for (VersionedRuleContext versionedRule : versionedRules) {
        DispatchFlowTransitionRuleVersion rule = versionedRule.ruleVersion();
        Set<DispatchFlowActorType> allowedActors = actorsByRule.getOrDefault(rule.getId(), Set.of());
        boolean allowedForCurrent = allowedActors.isEmpty() || !Collections.disjoint(allowedActors, currentActors);
        DispatchFlowProofPolicyDto proofPolicy =
            dispatchFlowRuleMetadataService.parseProofPolicy(rule.getMetadataJson());

        DispatchActionMetadata base = stateMachineDefaults.get(rule.getToStatus());
        DispatchActionMetadata action = base != null
            ? cloneAction(base)
            : DispatchActionMetadata.builder()
                .targetStatus(rule.getToStatus())
                .actionLabel("dispatch.action." + rule.getToStatus().name().toLowerCase())
                .priority(rule.getPriority())
                .driverInitiated(true)
                .build();

        action.setRequiresConfirmation(rule.isRequiresConfirmation());
        action.setRequiresInput(rule.isRequiresInput());
        action.setPriority(rule.getPriority());
        action.setAllowedActorTypes(allowedActors.stream().map(Enum::name).collect(Collectors.toSet()));
        action.setAllowedForCurrentUser(allowedForCurrent);
        action.setBlockedReason(allowedForCurrent ? null : "Current user role cannot execute this transition");
        action.setBlockedCode(allowedForCurrent ? null : "ROLE_NOT_ALLOWED");
        action.setTemplateCode(template.getCode());
        action.setRuleId(rule.getId());
        action.setWorkflowVersionId(resolution.workflowVersionId());
        applyProofPolicy(action, proofPolicy);
        if (featureToggleConfig.isDispatchWorkflowEmergencyBypass()) {
          clearBlockingForBypass(action);
        }
        actions.add(action);
      }
      return actions;
    }

    List<DispatchFlowTransitionRule> rules = ruleRepository
        .findByTemplateIdAndFromStatusAndEnabledTrueOrderByPriorityAsc(template.getId(), dispatch.getStatus());

    if (rules.isEmpty()) {
      // Keep action listing consistent with evaluateTransition():
      // when a loading-type template is resolved but no rule exists for this
      // from-status, transitions are "not configured for this loading type".
      // Returning state-machine defaults here would expose actions that fail at
      // execution time.
      log.warn(
          "No transition rules configured for template={} fromStatus={}; returning no available actions",
          template.getCode(),
          dispatch.getStatus());
      return List.of();
    }

    List<Long> ruleIds = rules.stream().map(DispatchFlowTransitionRule::getId).toList();
    Map<Long, Set<DispatchFlowActorType>> actorsByRule = resolveAllowedActors(ruleIds);
    List<DispatchActionMetadata> actions = new ArrayList<>();
    for (DispatchFlowTransitionRule rule : rules) {
      Set<DispatchFlowActorType> allowedActors = actorsByRule.getOrDefault(rule.getId(), Set.of());
      boolean allowedForCurrent = allowedActors.isEmpty() || !Collections.disjoint(allowedActors, currentActors);
      DispatchFlowProofPolicyDto proofPolicy =
          dispatchFlowRuleMetadataService.resolveProofPolicyForRule(rule);

      DispatchActionMetadata base = stateMachineDefaults.get(rule.getToStatus());
      DispatchActionMetadata action = base != null
          ? cloneAction(base)
          : DispatchActionMetadata.builder()
              .targetStatus(rule.getToStatus())
              .actionLabel("dispatch.action." + rule.getToStatus().name().toLowerCase())
              .priority(rule.getPriority())
              .driverInitiated(true)
              .build();

      action.setRequiresConfirmation(rule.isRequiresConfirmation());
      action.setRequiresInput(rule.isRequiresInput());
      action.setPriority(rule.getPriority());
      action.setAllowedActorTypes(allowedActors.stream().map(Enum::name).collect(Collectors.toSet()));
      action.setAllowedForCurrentUser(allowedForCurrent);
      action.setBlockedReason(allowedForCurrent ? null : "Current user role cannot execute this transition");
      action.setBlockedCode(allowedForCurrent ? null : "ROLE_NOT_ALLOWED");
      action.setTemplateCode(template.getCode());
      action.setRuleId(rule.getId());
      action.setWorkflowVersionId(resolution.workflowVersionId());
      applyProofPolicy(action, proofPolicy);
      if (featureToggleConfig.isDispatchWorkflowEmergencyBypass()) {
        clearBlockingForBypass(action);
      }

      actions.add(action);
    }

    return actions;
  }

  public Set<DispatchStatus> getNextStatuses(Dispatch dispatch) {
    return getAvailableActions(dispatch).stream()
        .map(DispatchActionMetadata::getTargetStatus)
        .collect(Collectors.toCollection(() -> EnumSet.noneOf(DispatchStatus.class)));
  }

  private Map<Long, Set<DispatchFlowActorType>> resolveAllowedActors(List<Long> ruleIds) {
    if (ruleIds == null || ruleIds.isEmpty()) {
      return Map.of();
    }

    Map<Long, Set<DispatchFlowActorType>> result = new HashMap<>();
    for (Long ruleId : ruleIds) {
      result.put(ruleId, new HashSet<>());
    }

    List<DispatchFlowTransitionActor> actors = actorRepository.findByTransitionRuleIdIn(ruleIds);
    for (DispatchFlowTransitionActor actor : actors) {
      if (!actor.isCanExecute()) {
        continue;
      }
      Long ruleId = actor.getTransitionRule().getId();
      result.computeIfAbsent(ruleId, ignored -> new HashSet<>()).add(actor.getActorType());
    }
    return result;
  }

  private Set<DispatchFlowActorType> resolveAllowedActors(Long ruleId) {
    return actorRepository.findByTransitionRuleId(ruleId).stream()
        .filter(DispatchFlowTransitionActor::isCanExecute)
        .map(DispatchFlowTransitionActor::getActorType)
        .collect(Collectors.toCollection(() -> EnumSet.noneOf(DispatchFlowActorType.class)));
  }

  private Map<Long, Set<DispatchFlowActorType>> resolveAllowedActorsForVersions(List<Long> ruleVersionIds) {
    if (ruleVersionIds == null || ruleVersionIds.isEmpty()) {
      return Map.of();
    }
    Map<Long, Set<DispatchFlowActorType>> result = new HashMap<>();
    for (Long ruleId : ruleVersionIds) {
      result.put(ruleId, new HashSet<>());
    }
    List<DispatchFlowTransitionActorVersion> actors = actorVersionRepository.findByTransitionRuleVersionIdIn(ruleVersionIds);
    for (DispatchFlowTransitionActorVersion actor : actors) {
      if (!actor.isCanExecute()) {
        continue;
      }
      Long ruleId = actor.getTransitionRuleVersion().getId();
      result.computeIfAbsent(ruleId, ignored -> new HashSet<>()).add(actor.getActorType());
    }
    return result;
  }

  private Set<DispatchFlowActorType> resolveAllowedActorsForVersion(Long ruleVersionId) {
    return actorVersionRepository.findByTransitionRuleVersionId(ruleVersionId).stream()
        .filter(DispatchFlowTransitionActorVersion::isCanExecute)
        .map(DispatchFlowTransitionActorVersion::getActorType)
        .collect(Collectors.toCollection(() -> EnumSet.noneOf(DispatchFlowActorType.class)));
  }

  private List<VersionedRuleContext> findVersionedRulesForStatus(Long workflowVersionId, DispatchStatus fromStatus) {
    if (workflowVersionId == null || fromStatus == null) {
      return List.of();
    }
    return ruleVersionRepository
        .findByTemplateVersionIdAndFromStatusAndEnabledTrueOrderByPriorityAsc(workflowVersionId, fromStatus)
        .stream()
        .map(rule -> new VersionedRuleContext(rule, true))
        .toList();
  }

  private Optional<VersionedRuleContext> findVersionedRuleForTransition(
      Long workflowVersionId,
      DispatchStatus fromStatus,
      DispatchStatus toStatus) {
    if (workflowVersionId == null || fromStatus == null || toStatus == null) {
      return Optional.empty();
    }
    return ruleVersionRepository
        .findByTemplateVersionIdAndFromStatusAndToStatusAndEnabledTrue(workflowVersionId, fromStatus, toStatus)
        .map(rule -> new VersionedRuleContext(rule, true));
  }

  private Optional<DispatchFlowActorType> mapRoleToActor(RoleType roleType) {
    return switch (roleType) {
      case DRIVER -> Optional.of(DispatchFlowActorType.DRIVER);
      case LOADING -> Optional.of(DispatchFlowActorType.LOADING);
      case SAFETY -> Optional.of(DispatchFlowActorType.SAFETY);
      case DISPATCH_MONITOR -> Optional.of(DispatchFlowActorType.DISPATCH_MONITOR);
      case ADMIN -> Optional.of(DispatchFlowActorType.ADMIN);
      case SUPERADMIN -> Optional.of(DispatchFlowActorType.SUPERADMIN);
      default -> Optional.empty();
    };
  }

  private DispatchActionMetadata cloneAction(DispatchActionMetadata action) {
    return DispatchActionMetadata.builder()
        .targetStatus(action.getTargetStatus())
        .actionLabel(action.getActionLabel())
        .actionType(action.getActionType())
        .iconName(action.getIconName())
        .buttonColor(action.getButtonColor())
        .requiresConfirmation(action.isRequiresConfirmation())
        .requiresAdminApproval(action.isRequiresAdminApproval())
        .driverInitiated(action.isDriverInitiated())
        .requiresInput(action.isRequiresInput())
        .validationMessage(action.getValidationMessage())
        .priority(action.getPriority())
        .isDestructive(action.isDestructive())
        .allowedActorTypes(action.getAllowedActorTypes())
        .allowedForCurrentUser(action.isAllowedForCurrentUser())
        .blockedReason(action.getBlockedReason())
        .blockedCode(action.getBlockedCode())
        .requiredInput(action.getRequiredInput())
        .inputRouteHint(action.getInputRouteHint())
        .templateCode(action.getTemplateCode())
        .ruleId(action.getRuleId())
        .proofSubmissionAllowedStatuses(action.getProofSubmissionAllowedStatuses())
        .proofSubmissionMode(action.getProofSubmissionMode())
        .proofReviewRequired(action.isProofReviewRequired())
        .allowLateProofRecovery(action.isAllowLateProofRecovery())
        .autoAdvanceStatusAfterProof(action.getAutoAdvanceStatusAfterProof())
        .workflowVersionId(action.getWorkflowVersionId())
        .build();
  }

  private void applyProofPolicy(
      DispatchActionMetadata action, DispatchFlowProofPolicyDto proofPolicy) {
    if (action == null) {
      return;
    }

    action.setRequiredInput("NONE");
    action.setInputRouteHint(null);
    action.setProofSubmissionAllowedStatuses(null);
    action.setProofSubmissionMode(null);
    action.setProofReviewRequired(false);
    action.setAllowLateProofRecovery(false);
    action.setAutoAdvanceStatusAfterProof(null);

    if (proofPolicy == null || !Boolean.TRUE.equals(proofPolicy.getProofRequired())) {
      return;
    }

    String requiredInput =
        proofPolicy.getRequiredInputType() == null || proofPolicy.getRequiredInputType().isBlank()
            ? "NONE"
            : proofPolicy.getRequiredInputType().trim().toUpperCase();

    action.setRequiresInput(!"NONE".equals(requiredInput));
    action.setRequiredInput(requiredInput);
    action.setInputRouteHint(switch (requiredInput) {
      case "POL" -> "LOAD_PROOF";
      case "POD" -> "UNLOAD_PROOF";
      default -> null;
    });
    action.setProofSubmissionAllowedStatuses(proofPolicy.getProofSubmissionAllowedStatuses());
    action.setProofSubmissionMode(proofPolicy.getProofSubmissionMode());
    action.setProofReviewRequired(Boolean.TRUE.equals(proofPolicy.getProofReviewRequired()));
    action.setAllowLateProofRecovery(Boolean.TRUE.equals(proofPolicy.getAllowLateProofRecovery()));
    action.setAutoAdvanceStatusAfterProof(proofPolicy.getAutoAdvanceStatusAfterProof());
  }

  private void clearBlockingForBypass(DispatchActionMetadata action) {
    if (action == null) {
      return;
    }
    action.setAllowedForCurrentUser(true);
    action.setBlockedCode(null);
    action.setBlockedReason(null);
    action.setDriverInitiated(true);
    action.setRequiresInput(false);
    action.setRequiredInput("NONE");
    action.setInputRouteHint(null);
  }

  public record TransitionCheck(
      boolean allowed,
      String blockedReason,
      Set<DispatchFlowActorType> allowedActorTypes) {}

  public record VersionedTemplateResolution(
      DispatchFlowTemplate template,
      DispatchFlowTemplateVersion version,
      Long workflowVersionId) {}

  private record VersionedRuleContext(
      DispatchFlowTransitionRuleVersion ruleVersion,
      boolean enabled) {}
}
