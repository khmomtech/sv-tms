package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.DispatchFlowTransitionActor;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface DispatchFlowTransitionActorRepository
    extends JpaRepository<DispatchFlowTransitionActor, Long> {

  List<DispatchFlowTransitionActor> findByTransitionRuleId(Long transitionRuleId);

  List<DispatchFlowTransitionActor> findByTransitionRuleIdIn(List<Long> transitionRuleIds);

  void deleteByTransitionRuleId(Long transitionRuleId);

  void deleteByTransitionRuleIdIn(List<Long> transitionRuleIds);
}
