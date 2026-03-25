package com.svtrucking.logistics.service;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.when;

import com.svtrucking.logistics.dto.response.DispatchActionMetadata;
import com.svtrucking.logistics.config.FeatureToggleConfig;
import com.svtrucking.logistics.enums.DispatchFlowActorType;
import com.svtrucking.logistics.enums.DispatchStatus;
import com.svtrucking.logistics.enums.RoleType;
import com.svtrucking.logistics.model.Dispatch;
import com.svtrucking.logistics.model.DispatchFlowTemplate;
import com.svtrucking.logistics.model.DispatchFlowTemplateVersion;
import com.svtrucking.logistics.model.DispatchFlowTransitionActor;
import com.svtrucking.logistics.model.DispatchFlowTransitionRule;
import com.svtrucking.logistics.model.DispatchFlowTransitionActorVersion;
import com.svtrucking.logistics.model.DispatchFlowTransitionRuleVersion;
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
import java.util.List;
import java.util.Optional;
import java.util.Set;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class DispatchWorkflowPolicyServiceTest {

  @Mock private DispatchFlowTemplateRepository templateRepository;
  @Mock private DispatchFlowTemplateVersionRepository templateVersionRepository;
  @Mock private DispatchFlowTransitionRuleRepository ruleRepository;
  @Mock private DispatchFlowTransitionRuleVersionRepository ruleVersionRepository;
  @Mock private DispatchFlowTransitionActorRepository actorRepository;
  @Mock private DispatchFlowTransitionActorVersionRepository actorVersionRepository;
  @Mock private AuthenticatedUserUtil authenticatedUserUtil;
  @Mock private DispatchStateMachine dispatchStateMachine;
  @Mock private DispatchFlowRuleMetadataService dispatchFlowRuleMetadataService;
  @Mock private FeatureToggleConfig featureToggleConfig;

  private DispatchWorkflowPolicyService service;

  @BeforeEach
  void setUp() {
    service = new DispatchWorkflowPolicyService(
        templateRepository,
        templateVersionRepository,
        ruleRepository,
        ruleVersionRepository,
        actorRepository,
        actorVersionRepository,
        authenticatedUserUtil,
        dispatchStateMachine,
        dispatchFlowRuleMetadataService,
        featureToggleConfig);
  }

  @Test
  void evaluateTransition_deniesActorNotInMatrix() {
    Dispatch dispatch = new Dispatch();
    dispatch.setLoadingTypeCode("KHBL");
    dispatch.setStatus(DispatchStatus.IN_QUEUE);

    DispatchFlowTemplate template = template(2L, "KHBL");
    DispatchFlowTransitionRule rule = rule(99L, template, DispatchStatus.IN_QUEUE, DispatchStatus.LOADING);

    when(templateRepository.findByCodeIgnoreCase("KHBL")).thenReturn(Optional.of(template));
    when(ruleRepository.findByTemplateIdAndFromStatusAndToStatusAndEnabledTrue(
            2L, DispatchStatus.IN_QUEUE, DispatchStatus.LOADING))
        .thenReturn(Optional.of(rule));
    when(actorRepository.findByTransitionRuleId(99L))
        .thenReturn(List.of(actor(rule, DispatchFlowActorType.LOADING, true)));
    when(authenticatedUserUtil.getCurrentUser()).thenReturn(user(RoleType.DRIVER));

    var result = service.evaluateTransition(dispatch, DispatchStatus.LOADING);

    assertFalse(result.allowed());
    assertEquals("Current user role cannot execute this transition", result.blockedReason());
    assertTrue(result.allowedActorTypes().contains(DispatchFlowActorType.LOADING));
  }

  @Test
  void evaluateTransition_allowsConfiguredActor() {
    Dispatch dispatch = new Dispatch();
    dispatch.setLoadingTypeCode("KHBL");
    dispatch.setStatus(DispatchStatus.IN_QUEUE);

    DispatchFlowTemplate template = template(2L, "KHBL");
    DispatchFlowTransitionRule rule = rule(99L, template, DispatchStatus.IN_QUEUE, DispatchStatus.LOADING);

    when(templateRepository.findByCodeIgnoreCase("KHBL")).thenReturn(Optional.of(template));
    when(ruleRepository.findByTemplateIdAndFromStatusAndToStatusAndEnabledTrue(
            2L, DispatchStatus.IN_QUEUE, DispatchStatus.LOADING))
        .thenReturn(Optional.of(rule));
    when(actorRepository.findByTransitionRuleId(99L))
        .thenReturn(List.of(actor(rule, DispatchFlowActorType.LOADING, true)));
    when(authenticatedUserUtil.getCurrentUser()).thenReturn(user(RoleType.LOADING));

    var result = service.evaluateTransition(dispatch, DispatchStatus.LOADING);

    assertTrue(result.allowed());
    assertNull(result.blockedReason());
  }

  @Test
  void evaluateTransition_fallsBackToStateMachineWhenTemplateMissing() {
    Dispatch dispatch = new Dispatch();
    dispatch.setLoadingTypeCode("GENERAL");
    dispatch.setStatus(DispatchStatus.ASSIGNED);

    when(templateRepository.findByCodeIgnoreCase("GENERAL")).thenReturn(Optional.empty());
    when(dispatchStateMachine.canTransition(DispatchStatus.ASSIGNED, DispatchStatus.DRIVER_CONFIRMED))
        .thenReturn(true);

    var result = service.evaluateTransition(dispatch, DispatchStatus.DRIVER_CONFIRMED);

    assertTrue(result.allowed());
    assertTrue(result.allowedActorTypes().isEmpty());
  }

  @Test
  void getAvailableActions_marksBlockedActionForCurrentActor() {
    Dispatch dispatch = new Dispatch();
    dispatch.setLoadingTypeCode("KHBL");
    dispatch.setStatus(DispatchStatus.IN_QUEUE);

    DispatchFlowTemplate template = template(2L, "KHBL");
    DispatchFlowTransitionRule rule = rule(99L, template, DispatchStatus.IN_QUEUE, DispatchStatus.LOADING);
    rule.setPriority(5);

    DispatchActionMetadata base = DispatchActionMetadata.builder()
        .targetStatus(DispatchStatus.LOADING)
        .actionLabel("dispatch.action.start_loading")
        .priority(1)
        .driverInitiated(true)
        .build();

    when(templateRepository.findByCodeIgnoreCase("KHBL")).thenReturn(Optional.of(template));
    when(ruleRepository.findByTemplateIdAndFromStatusAndEnabledTrueOrderByPriorityAsc(
            2L, DispatchStatus.IN_QUEUE))
        .thenReturn(List.of(rule));
    when(actorRepository.findByTransitionRuleIdIn(List.of(99L)))
        .thenReturn(List.of(actor(rule, DispatchFlowActorType.LOADING, true)));
    when(dispatchStateMachine.getActionMetadata(DispatchStatus.IN_QUEUE)).thenReturn(List.of(base));
    when(authenticatedUserUtil.getCurrentUser()).thenReturn(user(RoleType.DRIVER));

    List<DispatchActionMetadata> actions = service.getAvailableActions(dispatch);

    assertEquals(1, actions.size());
    assertFalse(actions.get(0).isAllowedForCurrentUser());
    assertEquals("Current user role cannot execute this transition", actions.get(0).getBlockedReason());
    assertEquals(Set.of("LOADING"), actions.get(0).getAllowedActorTypes());
  }

  @Test
  void getAvailableActions_exposesConfiguredProofPolicyMetadata() {
    Dispatch dispatch = new Dispatch();
    dispatch.setLoadingTypeCode("GENERAL");
    dispatch.setStatus(DispatchStatus.LOADING);

    DispatchFlowTemplate template = template(1L, "GENERAL");
    DispatchFlowTransitionRule rule = rule(77L, template, DispatchStatus.LOADING, DispatchStatus.LOADED);

    DispatchActionMetadata base = DispatchActionMetadata.builder()
        .targetStatus(DispatchStatus.LOADED)
        .actionLabel("dispatch.action.loaded")
        .priority(1)
        .driverInitiated(true)
        .build();

    var proofPolicy = com.svtrucking.logistics.dto.dispatchflow.DispatchFlowProofPolicyDto.builder()
        .proofRequired(Boolean.TRUE)
        .requiredInputType("POL")
        .proofType("POL")
        .proofSubmissionMode("RECOVERY_ALLOWED")
        .allowLateProofRecovery(Boolean.TRUE)
        .autoAdvanceStatusAfterProof(DispatchStatus.LOADED)
        .proofSubmissionAllowedStatuses(List.of(DispatchStatus.LOADING, DispatchStatus.LOADED))
        .build();

    when(templateRepository.findByCodeIgnoreCase("GENERAL")).thenReturn(Optional.of(template));
    when(ruleRepository.findByTemplateIdAndFromStatusAndEnabledTrueOrderByPriorityAsc(1L, DispatchStatus.LOADING))
        .thenReturn(List.of(rule));
    when(actorRepository.findByTransitionRuleIdIn(List.of(77L))).thenReturn(List.of());
    when(dispatchStateMachine.getActionMetadata(DispatchStatus.LOADING)).thenReturn(List.of(base));
    when(authenticatedUserUtil.getCurrentUser()).thenReturn(user(RoleType.DRIVER));
    when(dispatchFlowRuleMetadataService.resolveProofPolicyForRule(rule)).thenReturn(proofPolicy);

    List<DispatchActionMetadata> actions = service.getAvailableActions(dispatch);

    assertEquals(1, actions.size());
    assertEquals("GENERAL", actions.get(0).getTemplateCode());
    assertEquals(77L, actions.get(0).getRuleId());
    assertEquals("POL", actions.get(0).getRequiredInput());
    assertEquals("LOAD_PROOF", actions.get(0).getInputRouteHint());
    assertEquals("RECOVERY_ALLOWED", actions.get(0).getProofSubmissionMode());
    assertTrue(actions.get(0).isAllowLateProofRecovery());
  }

  private DispatchFlowTemplate template(Long id, String code) {
    DispatchFlowTemplate t = new DispatchFlowTemplate();
    t.setId(id);
    t.setCode(code);
    t.setName(code);
    t.setActive(true);
    return t;
  }

  private DispatchFlowTransitionRule rule(
      Long id, DispatchFlowTemplate template, DispatchStatus from, DispatchStatus to) {
    DispatchFlowTransitionRule rule = new DispatchFlowTransitionRule();
    rule.setId(id);
    rule.setTemplate(template);
    rule.setFromStatus(from);
    rule.setToStatus(to);
    rule.setEnabled(true);
    return rule;
  }

  private DispatchFlowTransitionActor actor(
      DispatchFlowTransitionRule rule, DispatchFlowActorType actorType, boolean canExecute) {
    DispatchFlowTransitionActor actor = new DispatchFlowTransitionActor();
    actor.setTransitionRule(rule);
    actor.setActorType(actorType);
    actor.setCanExecute(canExecute);
    return actor;
  }

  private User user(RoleType roleType) {
    User user = new User();
    Role role = new Role();
    role.setName(roleType);
    user.setRoles(Set.of(role));
    return user;
  }
}
