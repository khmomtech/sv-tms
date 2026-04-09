package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.enums.DispatchStatus;
import com.svtrucking.logistics.model.DispatchFlowTransitionRuleVersion;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

public interface DispatchFlowTransitionRuleVersionRepository
    extends JpaRepository<DispatchFlowTransitionRuleVersion, Long> {

  @EntityGraph(attributePaths = {"templateVersion", "templateVersion.template"})
  List<DispatchFlowTransitionRuleVersion> findByTemplateVersionIdOrderByPriorityAsc(Long templateVersionId);

  @EntityGraph(attributePaths = {"templateVersion", "templateVersion.template"})
  List<DispatchFlowTransitionRuleVersion>
      findByTemplateVersionIdAndFromStatusAndEnabledTrueOrderByPriorityAsc(
          Long templateVersionId, DispatchStatus fromStatus);

  @EntityGraph(attributePaths = {"templateVersion", "templateVersion.template"})
  Optional<DispatchFlowTransitionRuleVersion>
      findByTemplateVersionIdAndFromStatusAndToStatusAndEnabledTrue(
          Long templateVersionId, DispatchStatus fromStatus, DispatchStatus toStatus);
}
