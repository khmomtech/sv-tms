package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.PreLoadingSafetyCheck;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface PreLoadingSafetyCheckRepository extends JpaRepository<PreLoadingSafetyCheck, Long> {
  Optional<PreLoadingSafetyCheck> findTopByDispatchIdOrderByCheckedAtDesc(Long dispatchId);

  Optional<PreLoadingSafetyCheck> findTopByDispatchIdOrderByCheckedAtDescCreatedDateDesc(Long dispatchId);

  java.util.List<PreLoadingSafetyCheck> findByDispatchIdOrderByCheckedAtDescCreatedDateDesc(Long dispatchId);

  Optional<PreLoadingSafetyCheck> findByClientUuid(String clientUuid);
}
