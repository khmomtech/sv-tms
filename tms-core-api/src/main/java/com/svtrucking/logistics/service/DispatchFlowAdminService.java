package com.svtrucking.logistics.service;

import com.svtrucking.logistics.dto.dispatchflow.DispatchFlowRuleActorsUpdateRequest;
import com.svtrucking.logistics.dto.dispatchflow.DispatchFlowAssignDispatchRequest;
import com.svtrucking.logistics.dto.dispatchflow.DispatchFlowPublishRequest;
import com.svtrucking.logistics.dto.dispatchflow.DispatchFlowTemplateVersionDto;
import com.svtrucking.logistics.dto.dispatchflow.DispatchProofEventDto;
import com.svtrucking.logistics.dto.dispatchflow.DispatchFlowResolutionDto;
import com.svtrucking.logistics.dto.dispatchflow.DispatchFlowSimulationRequest;
import com.svtrucking.logistics.dto.dispatchflow.DispatchFlowSimulationResponse;
import com.svtrucking.logistics.dto.dispatchflow.DispatchFlowRuleDto;
import com.svtrucking.logistics.dto.dispatchflow.DispatchFlowProofPolicyDto;
import com.svtrucking.logistics.dto.dispatchflow.DispatchProofStateDto;
import com.svtrucking.logistics.dto.dispatchflow.DispatchProofReviewDecisionRequest;
import com.svtrucking.logistics.dto.dispatchflow.DispatchFlowRuleReorderRequest;
import com.svtrucking.logistics.dto.dispatchflow.DispatchFlowRuleUpsertRequest;
import com.svtrucking.logistics.dto.dispatchflow.DispatchFlowTemplateDto;
import com.svtrucking.logistics.dto.dispatchflow.DispatchFlowTemplateUpsertRequest;
import com.svtrucking.logistics.dto.dispatchflow.DispatchWorkflowBindingDto;
import com.svtrucking.logistics.enums.DispatchFlowActorType;
import com.svtrucking.logistics.enums.DispatchFlowVersionStatus;
import com.svtrucking.logistics.enums.DispatchProofReviewStatus;
import com.svtrucking.logistics.enums.DispatchStatus;
import com.svtrucking.logistics.exception.ResourceNotFoundException;
import com.svtrucking.logistics.model.Dispatch;
import com.svtrucking.logistics.model.DispatchFlowTemplateVersion;
import com.svtrucking.logistics.model.DispatchFlowTemplate;
import com.svtrucking.logistics.model.DispatchFlowTransitionActor;
import com.svtrucking.logistics.model.DispatchFlowTransitionActorVersion;
import com.svtrucking.logistics.model.DispatchFlowTransitionRule;
import com.svtrucking.logistics.model.DispatchFlowTransitionRuleVersion;
import com.svtrucking.logistics.model.DispatchProofEvent;
import com.svtrucking.logistics.repository.DispatchRepository;
import com.svtrucking.logistics.repository.DispatchFlowTemplateRepository;
import com.svtrucking.logistics.repository.DispatchFlowTemplateVersionRepository;
import com.svtrucking.logistics.repository.DispatchFlowTransitionActorRepository;
import com.svtrucking.logistics.repository.DispatchFlowTransitionActorVersionRepository;
import com.svtrucking.logistics.repository.DispatchFlowTransitionRuleRepository;
import com.svtrucking.logistics.repository.DispatchFlowTransitionRuleVersionRepository;
import com.svtrucking.logistics.repository.DispatchProofEventRepository;
import java.time.LocalDateTime;
import com.svtrucking.logistics.security.AuthenticatedUserUtil;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.EnumMap;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.EnumSet;
import java.util.stream.Collectors;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class DispatchFlowAdminService {

  private final DispatchFlowTemplateRepository templateRepository;
  private final DispatchFlowTemplateVersionRepository templateVersionRepository;
  private final DispatchFlowTransitionRuleRepository ruleRepository;
  private final DispatchFlowTransitionRuleVersionRepository ruleVersionRepository;
  private final DispatchFlowTransitionActorRepository actorRepository;
  private final DispatchFlowTransitionActorVersionRepository actorVersionRepository;
  private final DispatchProofEventRepository dispatchProofEventRepository;
  private final DispatchRepository dispatchRepository;
  private final DispatchWorkflowPolicyService dispatchWorkflowPolicyService;
  private final DispatchFlowRuleMetadataService dispatchFlowRuleMetadataService;
  private final DispatchProofPolicyService dispatchProofPolicyService;
  private final DispatchService dispatchService;
  private final AuthenticatedUserUtil authenticatedUserUtil;

  @Transactional(readOnly = true)
  public List<DispatchFlowTemplateDto> listTemplates() {
    return templateRepository.findAll().stream()
        .map(DispatchFlowTemplateDto::fromEntity)
        .toList();
  }

  @Transactional(transactionManager = "jpaTransactionManager")
  public DispatchFlowTemplateDto createTemplate(DispatchFlowTemplateUpsertRequest request) {
    DispatchFlowTemplate template = new DispatchFlowTemplate();
    applyTemplateRequest(template, request);
    Long userId = currentUserIdOrNull();
    template.setCreatedBy(userId);
    template.setUpdatedBy(userId);
    DispatchFlowTemplate saved = templateRepository.saveAndFlush(template);
    return DispatchFlowTemplateDto.fromEntity(
        templateRepository.findById(saved.getId()).orElse(saved));
  }

  @Transactional(transactionManager = "jpaTransactionManager")
  public DispatchFlowTemplateDto updateTemplate(Long id, DispatchFlowTemplateUpsertRequest request) {
    DispatchFlowTemplate template = templateRepository.findById(id)
        .orElseThrow(() -> new ResourceNotFoundException("Template not found"));
    applyTemplateRequest(template, request);
    template.setUpdatedBy(currentUserIdOrNull());
    DispatchFlowTemplate saved = templateRepository.saveAndFlush(template);
    return DispatchFlowTemplateDto.fromEntity(
        templateRepository.findById(saved.getId()).orElse(saved));
  }

  @Transactional(readOnly = true)
  public List<DispatchFlowTemplateVersionDto> listVersions(Long templateId) {
    ensureTemplateExists(templateId);
    return templateVersionRepository.findByTemplateIdOrderByVersionNoDesc(templateId).stream()
        .map(DispatchFlowTemplateVersionDto::fromEntity)
        .toList();
  }

  @Transactional(transactionManager = "jpaTransactionManager")
  public DispatchFlowTemplateVersionDto publishTemplateVersion(Long templateId, DispatchFlowPublishRequest request) {
    DispatchFlowTemplate template = templateRepository.findById(templateId)
        .orElseThrow(() -> new ResourceNotFoundException("Template not found"));
    validateTemplateForPublish(templateId);

    Integer nextVersionNo = templateVersionRepository.findByTemplateIdOrderByVersionNoDesc(templateId).stream()
        .map(DispatchFlowTemplateVersion::getVersionNo)
        .findFirst()
        .map(v -> v + 1)
        .orElse(1);

    DispatchFlowTemplateVersion version = new DispatchFlowTemplateVersion();
    version.setTemplate(template);
    version.setVersionNo(nextVersionNo);
    version.setVersionLabel(
        request.getVersionLabel() == null || request.getVersionLabel().isBlank()
            ? "v" + nextVersionNo
            : request.getVersionLabel().trim());
    version.setNotes(request.getNotes());
    version.setStatus(DispatchFlowVersionStatus.PUBLISHED);
    version.setActivePublished(true);
    version.setCreatedBy(currentUserIdOrNull());
    version.setPublishedAt(LocalDateTime.now());
    version.setSourceUpdatedAt(LocalDateTime.now());
    version = templateVersionRepository.save(version);

    snapshotCurrentRules(template, version);

    final Long publishedVersionId = version.getId();
    templateVersionRepository.findByTemplateIdOrderByVersionNoDesc(templateId).stream()
        .filter(existing -> !existing.getId().equals(publishedVersionId) && existing.isActivePublished())
        .forEach(existing -> {
          existing.setActivePublished(false);
          templateVersionRepository.save(existing);
        });

    template.setActivePublishedVersionId(version.getId());
    template.setUpdatedBy(currentUserIdOrNull());
    templateRepository.save(template);
    return DispatchFlowTemplateVersionDto.fromEntity(version);
  }

  @Transactional(transactionManager = "jpaTransactionManager")
  public DispatchFlowTemplateVersionDto rollbackVersion(Long versionId, DispatchFlowPublishRequest request) {
    DispatchFlowTemplateVersion version = templateVersionRepository.findById(versionId)
        .orElseThrow(() -> new ResourceNotFoundException("Template version not found"));
    DispatchFlowTemplate template = version.getTemplate();
    templateVersionRepository.findByTemplateIdOrderByVersionNoDesc(template.getId()).stream()
        .filter(DispatchFlowTemplateVersion::isActivePublished)
        .forEach(existing -> {
          existing.setActivePublished(false);
          templateVersionRepository.save(existing);
        });
    version.setActivePublished(true);
    version.setNotes(request.getNotes());
    templateVersionRepository.save(version);
    template.setActivePublishedVersionId(version.getId());
    template.setUpdatedBy(currentUserIdOrNull());
    templateRepository.save(template);
    return DispatchFlowTemplateVersionDto.fromEntity(version);
  }

  @Transactional(readOnly = true)
  public List<DispatchFlowRuleDto> listRules(Long templateId) {
    ensureTemplateExists(templateId);
    List<DispatchFlowTransitionRule> rules = ruleRepository.findByTemplateIdOrderByPriorityAsc(templateId);
    return toRuleDtos(rules);
  }

  @Transactional(transactionManager = "jpaTransactionManager")
  public DispatchFlowRuleDto createRule(Long templateId, DispatchFlowRuleUpsertRequest request) {
    DispatchFlowTemplate template = templateRepository.findById(templateId)
        .orElseThrow(() -> new ResourceNotFoundException("Template not found"));

    DispatchFlowTransitionRule rule = new DispatchFlowTransitionRule();
    rule.setTemplate(template);
    applyRuleRequest(rule, request);

    DispatchFlowTransitionRule saved = ruleRepository.save(rule);
    return DispatchFlowRuleDto.fromEntity(
        saved,
        actorMap(saved.getId()),
        dispatchFlowRuleMetadataService.parseProofPolicy(saved.getMetadataJson()));
  }

  @Transactional(transactionManager = "jpaTransactionManager")
  public DispatchFlowRuleDto updateRule(Long ruleId, DispatchFlowRuleUpsertRequest request) {
    DispatchFlowTransitionRule rule = ruleRepository.findById(ruleId)
        .orElseThrow(() -> new ResourceNotFoundException("Rule not found"));

    applyRuleRequest(rule, request);
    DispatchFlowTransitionRule saved = ruleRepository.save(rule);
    return DispatchFlowRuleDto.fromEntity(
        saved,
        actorMap(saved.getId()),
        dispatchFlowRuleMetadataService.parseProofPolicy(saved.getMetadataJson()));
  }

  @Transactional(transactionManager = "jpaTransactionManager")
  public DispatchFlowRuleDto updateRuleActors(Long ruleId, DispatchFlowRuleActorsUpdateRequest request) {
    DispatchFlowTransitionRule rule = ruleRepository.findById(ruleId)
        .orElseThrow(() -> new ResourceNotFoundException("Rule not found"));

    List<DispatchFlowTransitionActor> existing = actorRepository.findByTransitionRuleId(ruleId);
    Map<DispatchFlowActorType, DispatchFlowTransitionActor> byType = existing.stream()
        .collect(Collectors.toMap(DispatchFlowTransitionActor::getActorType, a -> a));

    List<DispatchFlowTransitionActor> toSave = new ArrayList<>();
    for (Map.Entry<DispatchFlowActorType, Boolean> entry : request.getActors().entrySet()) {
      DispatchFlowTransitionActor actor = byType.get(entry.getKey());
      if (actor == null) {
        actor = new DispatchFlowTransitionActor();
        actor.setTransitionRule(rule);
        actor.setActorType(entry.getKey());
      }
      actor.setCanExecute(Boolean.TRUE.equals(entry.getValue()));
      toSave.add(actor);
    }
    actorRepository.saveAll(toSave);

    return DispatchFlowRuleDto.fromEntity(
        rule,
        actorMap(rule.getId()),
        dispatchFlowRuleMetadataService.parseProofPolicy(rule.getMetadataJson()));
  }

  @Transactional(transactionManager = "jpaTransactionManager")
  public List<DispatchFlowRuleDto> reorderRules(Long templateId, DispatchFlowRuleReorderRequest request) {
    ensureTemplateExists(templateId);
    List<DispatchFlowTransitionRule> rules = ruleRepository.findByTemplateIdOrderByPriorityAsc(templateId);
    if (rules.isEmpty()) {
      return List.of();
    }

    List<Long> ruleIds = request.getRuleIds();
    if (ruleIds == null || ruleIds.isEmpty()) {
      throw new IllegalArgumentException("ruleIds is required");
    }

    Set<Long> existingRuleIds = rules.stream().map(DispatchFlowTransitionRule::getId).collect(Collectors.toSet());
    Set<Long> submittedRuleIds = new HashSet<>(ruleIds);
    if (existingRuleIds.size() != submittedRuleIds.size() || !existingRuleIds.equals(submittedRuleIds)) {
      throw new IllegalArgumentException("Submitted ruleIds must match template rule set");
    }

    Map<Long, DispatchFlowTransitionRule> ruleById = new HashMap<>();
    for (DispatchFlowTransitionRule rule : rules) {
      ruleById.put(rule.getId(), rule);
    }

    int priority = 1;
    for (Long ruleId : ruleIds) {
      DispatchFlowTransitionRule rule = ruleById.get(ruleId);
      if (rule == null) {
        throw new ResourceNotFoundException("Rule not found in template: " + ruleId);
      }
      rule.setPriority(priority++);
    }

    ruleRepository.saveAll(rules);
    return listRules(templateId);
  }

  @Transactional(transactionManager = "jpaTransactionManager")
  public void deleteRule(Long ruleId) {
    if (!ruleRepository.existsById(ruleId)) {
      throw new ResourceNotFoundException("Rule not found");
    }
    actorRepository.deleteByTransitionRuleId(ruleId);
    ruleRepository.deleteById(ruleId);
  }

  @Transactional(transactionManager = "jpaTransactionManager")
  public void deleteTemplate(Long templateId) {
    DispatchFlowTemplate template = templateRepository.findById(templateId)
        .orElseThrow(() -> new ResourceNotFoundException("Template not found"));
    if (DispatchWorkflowPolicyService.DEFAULT_TEMPLATE_CODE.equalsIgnoreCase(template.getCode())) {
      throw new IllegalArgumentException("Default template GENERAL cannot be deleted");
    }

    List<DispatchFlowTransitionRule> rules = ruleRepository.findByTemplateId(templateId);
    if (!rules.isEmpty()) {
      List<Long> ruleIds = rules.stream().map(DispatchFlowTransitionRule::getId).toList();
      actorRepository.deleteByTransitionRuleIdIn(ruleIds);
      ruleRepository.deleteByTemplateId(templateId);
    }
    templateRepository.delete(template);
  }

  @Transactional(readOnly = true)
  public DispatchFlowResolutionDto resolveDispatchFlow(Long dispatchId) {
    Dispatch dispatch = dispatchRepository.findByIdWithActionDetails(dispatchId)
        .orElseThrow(() -> new ResourceNotFoundException("Dispatch not found"));

    String linkedTemplateCode = dispatch.getLoadingTypeCode();
    DispatchWorkflowPolicyService.VersionedTemplateResolution resolved =
        dispatchWorkflowPolicyService.resolveVersionedTemplate(dispatch);
    DispatchFlowTemplate resolvedTemplate = resolved.template();
    String normalizedLinkedCode = linkedTemplateCode == null || linkedTemplateCode.isBlank()
        ? DispatchWorkflowPolicyService.DEFAULT_TEMPLATE_CODE
        : linkedTemplateCode.trim().toUpperCase();

    boolean fallbackToStateMachine = resolvedTemplate == null;
    boolean fallbackToDefault = !fallbackToStateMachine
        && !DispatchWorkflowPolicyService.DEFAULT_TEMPLATE_CODE.equalsIgnoreCase(normalizedLinkedCode)
        && !resolvedTemplate.getCode().equalsIgnoreCase(normalizedLinkedCode);

    return DispatchFlowResolutionDto.builder()
        .dispatchId(dispatch.getId())
        .linkedTemplateCode(normalizedLinkedCode)
        .resolvedTemplateCode(
            resolvedTemplate != null ? resolvedTemplate.getCode() : DispatchWorkflowPolicyService.DEFAULT_TEMPLATE_CODE)
        .resolvedTemplateName(resolvedTemplate != null ? resolvedTemplate.getName() : "STATE_MACHINE_FALLBACK")
        .workflowVersionId(dispatch.getWorkflowVersionId())
        .resolvedWorkflowVersionId(resolved.workflowVersionId())
        .fallbackToDefault(fallbackToDefault)
        .fallbackToStateMachine(fallbackToStateMachine)
        .currentStatus(dispatch.getStatus())
        .proofState(dispatchProofPolicyService.buildProofState(dispatch))
        .availableActions(dispatchService.getAvailableActionsForDispatchAdmin(dispatchId).getAvailableActions())
        .build();
  }

  @Transactional(readOnly = true)
  public DispatchFlowSimulationResponse simulate(DispatchFlowSimulationRequest request) {
    Dispatch dispatch = dispatchRepository.findByIdWithActionDetails(request.getDispatchId())
        .orElseThrow(() -> new ResourceNotFoundException("Dispatch not found"));
    Set<DispatchFlowActorType> actorTypes =
        request.getActorTypes() == null || request.getActorTypes().isEmpty()
            ? dispatchWorkflowPolicyService.resolveCurrentActorTypes()
            : request.getActorTypes();

    var actions = dispatchWorkflowPolicyService.getAvailableActions(dispatch, actorTypes);
    String linkedTemplateCode = dispatch.getLoadingTypeCode();
    DispatchWorkflowPolicyService.VersionedTemplateResolution resolved =
        dispatchWorkflowPolicyService.resolveVersionedTemplate(dispatch);
    DispatchFlowTemplate resolvedTemplate = resolved.template();
    DispatchProofStateDto proofState = dispatchProofPolicyService.buildProofState(dispatch);

    boolean allowed = true;
    String blockedCode = null;
    String blockedReason = null;
    DispatchFlowProofPolicyDto proofPolicy = null;

    if (request.getTargetStatus() != null) {
      var transition = dispatchWorkflowPolicyService.evaluateTransition(dispatch, request.getTargetStatus(), actorTypes);
      allowed = transition.allowed();
      blockedReason = transition.blockedReason();
      blockedCode = allowed ? null : "ROLE_NOT_ALLOWED";
      var proofDecision = dispatchProofPolicyService.evaluateTransitionProofRequirement(dispatch, request.getTargetStatus());
      if (!proofDecision.allowed()) {
        allowed = false;
        blockedCode = proofDecision.blockedCode();
        blockedReason = proofDecision.blockedReason();
        proofPolicy = proofDecision.proofPolicy();
      } else {
        proofPolicy = dispatchProofPolicyService.resolveProofPolicyForTransition(dispatch, request.getTargetStatus());
      }
    }

    if (request.getProofType() != null && !request.getProofType().isBlank()) {
      var proofDecision = dispatchProofPolicyService.evaluateProofSubmission(dispatch, request.getProofType());
      allowed = proofDecision.allowed();
      blockedCode = proofDecision.blockedCode();
      blockedReason = proofDecision.blockedReason();
      proofPolicy = proofDecision.proofPolicy();
    }

    return DispatchFlowSimulationResponse.builder()
        .dispatchId(dispatch.getId())
        .linkedTemplateCode(linkedTemplateCode)
        .resolvedTemplateCode(
            resolvedTemplate != null ? resolvedTemplate.getCode() : DispatchWorkflowPolicyService.DEFAULT_TEMPLATE_CODE)
        .workflowVersionId(dispatch.getWorkflowVersionId())
        .resolvedWorkflowVersionId(resolved.workflowVersionId())
        .currentStatus(dispatch.getStatus())
        .targetStatus(request.getTargetStatus())
        .proofType(request.getProofType())
        .actorTypes(actorTypes)
        .allowed(allowed)
        .blockedCode(blockedCode)
        .blockedReason(blockedReason)
        .proofPolicy(proofPolicy)
        .proofState(proofState)
        .availableActions(actions)
        .build();
  }

  @Transactional(readOnly = true)
  public DispatchProofStateDto getProofState(Long dispatchId) {
    Dispatch dispatch = dispatchRepository.findByIdWithActionDetails(dispatchId)
        .orElseThrow(() -> new ResourceNotFoundException("Dispatch not found"));
    return dispatchProofPolicyService.buildProofState(dispatch);
  }

  @Transactional(readOnly = true)
  public DispatchWorkflowBindingDto getWorkflowBinding(Long dispatchId) {
    Dispatch dispatch = dispatchRepository.findByIdWithActionDetails(dispatchId)
        .orElseThrow(() -> new ResourceNotFoundException("Dispatch not found"));
    DispatchWorkflowPolicyService.VersionedTemplateResolution resolved =
        dispatchWorkflowPolicyService.resolveVersionedTemplate(dispatch);
    String linkedTemplateCode = dispatch.getLoadingTypeCode() == null || dispatch.getLoadingTypeCode().isBlank()
        ? DispatchWorkflowPolicyService.DEFAULT_TEMPLATE_CODE
        : dispatch.getLoadingTypeCode().trim().toUpperCase();
    boolean fallbackToStateMachine = resolved.template() == null;
    boolean fallbackToDefault = !fallbackToStateMachine
        && !DispatchWorkflowPolicyService.DEFAULT_TEMPLATE_CODE.equalsIgnoreCase(linkedTemplateCode)
        && !resolved.template().getCode().equalsIgnoreCase(linkedTemplateCode);
    return DispatchWorkflowBindingDto.builder()
        .dispatchId(dispatch.getId())
        .linkedTemplateCode(linkedTemplateCode)
        .workflowVersionId(dispatch.getWorkflowVersionId())
        .resolvedTemplateCode(
            resolved.template() != null ? resolved.template().getCode() : DispatchWorkflowPolicyService.DEFAULT_TEMPLATE_CODE)
        .resolvedWorkflowVersionId(resolved.workflowVersionId())
        .fallbackToDefault(fallbackToDefault)
        .fallbackToStateMachine(fallbackToStateMachine)
        .proofState(dispatchProofPolicyService.buildProofState(dispatch))
        .build();
  }

  @Transactional(transactionManager = "jpaTransactionManager")
  public DispatchWorkflowBindingDto assignDispatchTemplate(Long dispatchId, DispatchFlowAssignDispatchRequest request) {
    Dispatch dispatch = dispatchRepository.findById(dispatchId)
        .orElseThrow(() -> new ResourceNotFoundException("Dispatch not found"));
    applyDispatchTemplateBinding(dispatch, request);
    dispatchRepository.save(dispatch);
    return getWorkflowBinding(dispatchId);
  }

  @Transactional(transactionManager = "jpaTransactionManager")
  public List<DispatchWorkflowBindingDto> assignDispatchTemplates(DispatchFlowAssignDispatchRequest request) {
    if (request.getDispatchIds() == null || request.getDispatchIds().isEmpty()) {
      throw new IllegalArgumentException("dispatchIds is required");
    }
    List<DispatchWorkflowBindingDto> results = new ArrayList<>();
    for (Long dispatchId : request.getDispatchIds()) {
      results.add(assignDispatchTemplate(dispatchId, request));
    }
    return results;
  }

  @Transactional(readOnly = true)
  public List<DispatchProofEventDto> listPendingProofReview() {
    return dispatchProofEventRepository.findByReviewStatusOrderBySubmittedAtDesc(DispatchProofReviewStatus.PENDING)
        .stream()
        .map(DispatchProofEventDto::fromEntity)
        .toList();
  }

  @Transactional(transactionManager = "jpaTransactionManager")
  public DispatchProofEventDto reviewProofEvent(Long eventId, DispatchProofReviewDecisionRequest request) {
    DispatchProofEvent event = dispatchProofEventRepository.findById(eventId)
        .orElseThrow(() -> new ResourceNotFoundException("Proof event not found"));
    if (!event.isAccepted()) {
      throw new IllegalArgumentException("Blocked proof events cannot be reviewed");
    }
    DispatchProofReviewStatus targetStatus =
        Boolean.TRUE.equals(request.getApproved())
            ? DispatchProofReviewStatus.APPROVED
            : DispatchProofReviewStatus.REJECTED;
    event.setReviewStatus(targetStatus);
    event.setReviewNote(request.getAuditNote());
    event.setReviewedBy(currentUserIdOrNull());
    event.setReviewedAt(LocalDateTime.now());
    dispatchProofEventRepository.save(event);

    Dispatch dispatch = event.getDispatch();
    if ("POL".equalsIgnoreCase(event.getProofType())) {
      dispatch.setPolSubmitted(Boolean.TRUE.equals(request.getApproved()));
    } else if ("POD".equalsIgnoreCase(event.getProofType())) {
      dispatch.setPodSubmitted(Boolean.TRUE.equals(request.getApproved()));
      dispatch.setPodVerified(Boolean.TRUE.equals(request.getApproved()));
    }
    dispatch.setUpdatedDate(LocalDateTime.now());
    dispatchRepository.save(dispatch);
    return DispatchProofEventDto.fromEntity(event);
  }

  private List<DispatchFlowRuleDto> toRuleDtos(List<DispatchFlowTransitionRule> rules) {
    if (rules.isEmpty()) {
      return List.of();
    }
    List<Long> ruleIds = rules.stream().map(DispatchFlowTransitionRule::getId).toList();
    Map<Long, Map<DispatchFlowActorType, Boolean>> actorMaps = new java.util.HashMap<>();
    for (Long ruleId : ruleIds) {
      actorMaps.put(ruleId, new EnumMap<>(DispatchFlowActorType.class));
    }

    for (DispatchFlowTransitionActor actor : actorRepository.findByTransitionRuleIdIn(ruleIds)) {
      actorMaps.computeIfAbsent(actor.getTransitionRule().getId(), k -> new EnumMap<>(DispatchFlowActorType.class))
          .put(actor.getActorType(), actor.isCanExecute());
    }

    return rules.stream()
        .map(
            rule ->
                DispatchFlowRuleDto.fromEntity(
                    rule,
                    actorMaps.getOrDefault(rule.getId(), Map.of()),
                    dispatchFlowRuleMetadataService.parseProofPolicy(rule.getMetadataJson())))
        .toList();
  }

  private Map<DispatchFlowActorType, Boolean> actorMap(Long ruleId) {
    Map<DispatchFlowActorType, Boolean> map = new EnumMap<>(DispatchFlowActorType.class);
    for (DispatchFlowTransitionActor actor : actorRepository.findByTransitionRuleId(ruleId)) {
      map.put(actor.getActorType(), actor.isCanExecute());
    }
    return map;
  }

  private void ensureTemplateExists(Long templateId) {
    if (!templateRepository.existsById(templateId)) {
      throw new ResourceNotFoundException("Template not found");
    }
  }

  private void validateTemplateForPublish(Long templateId) {
    List<DispatchFlowTransitionRule> rules = ruleRepository.findByTemplateIdOrderByPriorityAsc(templateId);
    if (rules.isEmpty()) {
      throw new IllegalArgumentException("Template has no rules to publish");
    }

    List<String> errors = new ArrayList<>();
    Set<DispatchStatus> terminalStatuses = EnumSet.of(
        DispatchStatus.COMPLETED,
        DispatchStatus.CANCELLED,
        DispatchStatus.CLOSED,
        DispatchStatus.REJECTED);
    Map<DispatchStatus, List<DispatchFlowTransitionRule>> enabledByFrom = rules.stream()
        .filter(DispatchFlowTransitionRule::isEnabled)
        .collect(Collectors.groupingBy(DispatchFlowTransitionRule::getFromStatus));

    for (DispatchFlowTransitionRule rule : rules) {
      if (!rule.isEnabled()) {
        continue;
      }
      if (actorRepository.findByTransitionRuleId(rule.getId()).stream().noneMatch(DispatchFlowTransitionActor::isCanExecute)) {
        errors.add("Rule " + rule.getFromStatus() + "->" + rule.getToStatus() + " has no actor owner");
      }
      DispatchFlowProofPolicyDto policy = dispatchFlowRuleMetadataService.parseProofPolicy(rule.getMetadataJson());
      if (policy != null && Boolean.TRUE.equals(policy.getProofRequired())
          && (policy.getProofType() == null || policy.getProofType().isBlank()
              || policy.getRequiredInputType() == null || policy.getRequiredInputType().isBlank())) {
        errors.add("Rule " + rule.getFromStatus() + "->" + rule.getToStatus() + " requires proof but proof config is incomplete");
      }
      if (terminalStatuses.contains(rule.getFromStatus())) {
        errors.add("Terminal status " + rule.getFromStatus() + " cannot have outgoing transition to " + rule.getToStatus());
      }
    }

    for (DispatchStatus status : DispatchStatus.values()) {
      if (!terminalStatuses.contains(status) && enabledByFrom.containsKey(status) && enabledByFrom.get(status).isEmpty()) {
        errors.add("Status " + status + " is a dead-end non-terminal state");
      }
    }

    if (!errors.isEmpty()) {
      throw new IllegalArgumentException(String.join("; ", errors));
    }
  }

  private void snapshotCurrentRules(DispatchFlowTemplate template, DispatchFlowTemplateVersion version) {
    List<DispatchFlowTransitionRule> rules = ruleRepository.findByTemplateIdOrderByPriorityAsc(template.getId());
    for (DispatchFlowTransitionRule rule : rules) {
      DispatchFlowTransitionRuleVersion versionRule = new DispatchFlowTransitionRuleVersion();
      versionRule.setTemplateVersion(version);
      versionRule.setSourceRuleId(rule.getId());
      versionRule.setFromStatus(rule.getFromStatus());
      versionRule.setToStatus(rule.getToStatus());
      versionRule.setEnabled(rule.isEnabled());
      versionRule.setPriority(rule.getPriority());
      versionRule.setRequiresConfirmation(rule.isRequiresConfirmation());
      versionRule.setRequiresInput(rule.isRequiresInput());
      versionRule.setValidationMessage(rule.getValidationMessage());
      versionRule.setMetadataJson(rule.getMetadataJson());
      versionRule = ruleVersionRepository.save(versionRule);

      for (DispatchFlowTransitionActor actor : actorRepository.findByTransitionRuleId(rule.getId())) {
        DispatchFlowTransitionActorVersion actorVersion = new DispatchFlowTransitionActorVersion();
        actorVersion.setTransitionRuleVersion(versionRule);
        actorVersion.setActorType(actor.getActorType());
        actorVersion.setCanExecute(actor.isCanExecute());
        actorVersionRepository.save(actorVersion);
      }
    }
  }

  private void applyDispatchTemplateBinding(Dispatch dispatch, DispatchFlowAssignDispatchRequest request) {
    String templateCode = request.getTemplateCode() == null || request.getTemplateCode().isBlank()
        ? DispatchWorkflowPolicyService.DEFAULT_TEMPLATE_CODE
        : request.getTemplateCode().trim().toUpperCase();
    DispatchFlowTemplate template = templateRepository.findByCodeIgnoreCase(templateCode)
        .filter(DispatchFlowTemplate::isActive)
        .orElseThrow(() -> new IllegalArgumentException("Unknown or inactive template: " + templateCode));
    Long activeVersionId = template.getActivePublishedVersionId();
    if (activeVersionId == null) {
      activeVersionId = templateVersionRepository.findByTemplateIdAndActivePublishedTrue(template.getId())
          .map(DispatchFlowTemplateVersion::getId)
          .orElseThrow(() -> new IllegalArgumentException("Template has no active published version: " + templateCode));
    }
    boolean lateStatus = dispatch.getStatus() != null && dispatch.getStatus().ordinal() >= DispatchStatus.LOADING.ordinal();
    if (lateStatus && !Boolean.TRUE.equals(request.getAllowOperationalOverride())) {
      throw new IllegalArgumentException("Dispatch template reassignment is blocked from LOADING onwards without override");
    }
    dispatch.setLoadingTypeCode(templateCode);
    dispatch.setWorkflowVersionId(activeVersionId);
    dispatch.setUpdatedDate(LocalDateTime.now());
    if (lateStatus && (request.getAuditNote() == null || request.getAuditNote().isBlank())) {
      throw new IllegalArgumentException("Audit note is required when overriding workflow assignment after LOADING");
    }
  }

  private void applyTemplateRequest(DispatchFlowTemplate template, DispatchFlowTemplateUpsertRequest request) {
    template.setCode(request.getCode().trim().toUpperCase());
    template.setName(request.getName().trim());
    template.setDescription(request.getDescription());
    template.setActive(Boolean.TRUE.equals(request.getActive()));
  }

  private Long currentUserIdOrNull() {
    try {
      return authenticatedUserUtil.getCurrentUserId();
    } catch (Exception ex) {
      return null;
    }
  }

  private void applyRuleRequest(DispatchFlowTransitionRule rule, DispatchFlowRuleUpsertRequest request) {
    rule.setFromStatus(request.getFromStatus());
    rule.setToStatus(request.getToStatus());
    rule.setEnabled(Boolean.TRUE.equals(request.getEnabled()));
    rule.setPriority(request.getPriority() == null ? 100 : request.getPriority());
    rule.setRequiresConfirmation(Boolean.TRUE.equals(request.getRequiresConfirmation()));
    rule.setRequiresInput(Boolean.TRUE.equals(request.getRequiresInput()));
    rule.setValidationMessage(request.getValidationMessage());
    rule.setMetadataJson(
        dispatchFlowRuleMetadataService.mergeProofPolicy(
            request.getMetadataJson(),
            request.getProofPolicy()));
  }
}
