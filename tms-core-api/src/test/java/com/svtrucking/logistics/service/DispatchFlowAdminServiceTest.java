package com.svtrucking.logistics.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.svtrucking.logistics.dto.dispatchflow.DispatchFlowRuleReorderRequest;
import com.svtrucking.logistics.exception.ResourceNotFoundException;
import com.svtrucking.logistics.model.DispatchFlowTemplate;
import com.svtrucking.logistics.model.DispatchFlowTransitionRule;
import com.svtrucking.logistics.repository.DispatchRepository;
import com.svtrucking.logistics.repository.DispatchFlowTemplateVersionRepository;
import com.svtrucking.logistics.repository.DispatchFlowTemplateRepository;
import com.svtrucking.logistics.repository.DispatchFlowTransitionActorRepository;
import com.svtrucking.logistics.repository.DispatchFlowTransitionActorVersionRepository;
import com.svtrucking.logistics.repository.DispatchFlowTransitionRuleRepository;
import com.svtrucking.logistics.repository.DispatchFlowTransitionRuleVersionRepository;
import com.svtrucking.logistics.repository.DispatchProofEventRepository;
import com.svtrucking.logistics.security.AuthenticatedUserUtil;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class DispatchFlowAdminServiceTest {

  @Mock private DispatchFlowTemplateRepository templateRepository;
  @Mock private DispatchFlowTemplateVersionRepository templateVersionRepository;
  @Mock private DispatchFlowTransitionRuleRepository ruleRepository;
  @Mock private DispatchFlowTransitionRuleVersionRepository ruleVersionRepository;
  @Mock private DispatchFlowTransitionActorRepository actorRepository;
  @Mock private DispatchFlowTransitionActorVersionRepository actorVersionRepository;
  @Mock private DispatchProofEventRepository dispatchProofEventRepository;
  @Mock private DispatchRepository dispatchRepository;
  @Mock private DispatchWorkflowPolicyService dispatchWorkflowPolicyService;
  @Mock private DispatchFlowRuleMetadataService dispatchFlowRuleMetadataService;
  @Mock private DispatchProofPolicyService dispatchProofPolicyService;
  @Mock private DispatchService dispatchService;
  @Mock private AuthenticatedUserUtil authenticatedUserUtil;

  private DispatchFlowAdminService service;

  @BeforeEach
  void setUp() {
    service = new DispatchFlowAdminService(
        templateRepository,
        templateVersionRepository,
        ruleRepository,
        ruleVersionRepository,
        actorRepository,
        actorVersionRepository,
        dispatchProofEventRepository,
        dispatchRepository,
        dispatchWorkflowPolicyService,
        dispatchFlowRuleMetadataService,
        dispatchProofPolicyService,
        dispatchService,
        authenticatedUserUtil);
  }

  @Test
  void reorderRules_reassignsPrioritySequentially() {
    Long templateId = 10L;
    DispatchFlowTemplate template = template(templateId, "GENERAL");
    DispatchFlowTransitionRule r1 = rule(1L, template, 99);
    DispatchFlowTransitionRule r2 = rule(2L, template, 55);
    DispatchFlowTransitionRule r3 = rule(3L, template, 10);

    DispatchFlowRuleReorderRequest request = new DispatchFlowRuleReorderRequest();
    request.setRuleIds(List.of(2L, 3L, 1L));

    when(templateRepository.existsById(templateId)).thenReturn(true);
    when(ruleRepository.findByTemplateIdOrderByPriorityAsc(templateId)).thenReturn(List.of(r1, r2, r3));
    when(ruleRepository.saveAll(any())).thenAnswer(invocation -> invocation.getArgument(0));
    when(actorRepository.findByTransitionRuleIdIn(List.of(1L, 2L, 3L))).thenReturn(List.of());

    var result = service.reorderRules(templateId, request);

    assertEquals(3, result.size());
    assertEquals(1, r2.getPriority());
    assertEquals(2, r3.getPriority());
    assertEquals(3, r1.getPriority());
    verify(ruleRepository).saveAll(any());
  }

  @Test
  void reorderRules_throwsWhenRuleSetMismatch() {
    Long templateId = 10L;
    DispatchFlowTemplate template = template(templateId, "GENERAL");
    DispatchFlowTransitionRule r1 = rule(1L, template, 1);
    DispatchFlowTransitionRule r2 = rule(2L, template, 2);

    DispatchFlowRuleReorderRequest request = new DispatchFlowRuleReorderRequest();
    request.setRuleIds(List.of(1L));

    when(templateRepository.existsById(templateId)).thenReturn(true);
    when(ruleRepository.findByTemplateIdOrderByPriorityAsc(templateId)).thenReturn(List.of(r1, r2));

    assertThrows(IllegalArgumentException.class, () -> service.reorderRules(templateId, request));
    verify(ruleRepository, never()).saveAll(any());
  }

  @Test
  void deleteRule_removesActorsThenRule() {
    when(ruleRepository.existsById(8L)).thenReturn(true);

    service.deleteRule(8L);

    verify(actorRepository).deleteByTransitionRuleId(8L);
    verify(ruleRepository).deleteById(8L);
  }

  @Test
  void deleteTemplate_throwsWhenMissing() {
    when(templateRepository.findById(99L)).thenReturn(Optional.empty());

    assertThrows(ResourceNotFoundException.class, () -> service.deleteTemplate(99L));
  }

  @Test
  void deleteTemplate_removesRulesAndActors() {
    Long templateId = 10L;
    DispatchFlowTemplate template = template(templateId, "KHBL");
    DispatchFlowTransitionRule r1 = rule(1L, template, 1);
    DispatchFlowTransitionRule r2 = rule(2L, template, 2);

    when(templateRepository.findById(templateId)).thenReturn(Optional.of(template));
    when(ruleRepository.findByTemplateId(templateId)).thenReturn(List.of(r1, r2));

    service.deleteTemplate(templateId);

    verify(actorRepository).deleteByTransitionRuleIdIn(eq(List.of(1L, 2L)));
    verify(ruleRepository).deleteByTemplateId(templateId);
    verify(templateRepository).delete(template);
  }

  @Test
  void deleteTemplate_rejectsDefaultGeneralTemplate() {
    Long templateId = 11L;
    DispatchFlowTemplate template = template(templateId, "GENERAL");
    when(templateRepository.findById(templateId)).thenReturn(Optional.of(template));

    assertThrows(IllegalArgumentException.class, () -> service.deleteTemplate(templateId));
    verify(ruleRepository, never()).deleteByTemplateId(any());
    verify(templateRepository, never()).delete(any());
  }

  private DispatchFlowTemplate template(Long id, String code) {
    DispatchFlowTemplate t = new DispatchFlowTemplate();
    t.setId(id);
    t.setCode(code);
    t.setName(code);
    t.setActive(true);
    return t;
  }

  private DispatchFlowTransitionRule rule(Long id, DispatchFlowTemplate template, int priority) {
    DispatchFlowTransitionRule r = new DispatchFlowTransitionRule();
    r.setId(id);
    r.setTemplate(template);
    r.setPriority(priority);
    return r;
  }
}
