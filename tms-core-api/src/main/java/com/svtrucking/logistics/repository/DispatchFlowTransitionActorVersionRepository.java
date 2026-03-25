package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.DispatchFlowTransitionActorVersion;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface DispatchFlowTransitionActorVersionRepository
    extends JpaRepository<DispatchFlowTransitionActorVersion, Long> {

  List<DispatchFlowTransitionActorVersion> findByTransitionRuleVersionId(Long transitionRuleVersionId);

  List<DispatchFlowTransitionActorVersion> findByTransitionRuleVersionIdIn(List<Long> transitionRuleVersionIds);
}
