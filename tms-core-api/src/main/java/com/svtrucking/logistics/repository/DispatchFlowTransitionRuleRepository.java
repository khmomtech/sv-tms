package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.enums.DispatchStatus;
import com.svtrucking.logistics.model.DispatchFlowTransitionRule;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface DispatchFlowTransitionRuleRepository extends JpaRepository<DispatchFlowTransitionRule, Long> {

  @EntityGraph(attributePaths = {"template"})
  List<DispatchFlowTransitionRule> findByTemplateIdOrderByPriorityAsc(Long templateId);

  @EntityGraph(attributePaths = {"template"})
  List<DispatchFlowTransitionRule> findByTemplateIdAndFromStatusAndEnabledTrueOrderByPriorityAsc(
      Long templateId, DispatchStatus fromStatus);

  @EntityGraph(attributePaths = {"template"})
  Optional<DispatchFlowTransitionRule>
      findByTemplateIdAndFromStatusAndToStatusAndEnabledTrue(
          Long templateId, DispatchStatus fromStatus, DispatchStatus toStatus);

  @Query(
      "select r from DispatchFlowTransitionRule r where r.template.id = :templateId and r.enabled = true order by r.priority asc")
  List<DispatchFlowTransitionRule> findEnabledByTemplate(@Param("templateId") Long templateId);

  List<DispatchFlowTransitionRule> findByTemplateId(Long templateId);

  void deleteByTemplateId(Long templateId);
}
