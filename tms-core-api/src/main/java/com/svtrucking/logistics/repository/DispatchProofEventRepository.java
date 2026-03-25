package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.enums.DispatchProofReviewStatus;
import com.svtrucking.logistics.model.DispatchProofEvent;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

public interface DispatchProofEventRepository extends JpaRepository<DispatchProofEvent, Long> {

  @EntityGraph(attributePaths = {"dispatch"})
  List<DispatchProofEvent> findByReviewStatusOrderBySubmittedAtDesc(DispatchProofReviewStatus reviewStatus);

  @EntityGraph(attributePaths = {"dispatch"})
  List<DispatchProofEvent> findByDispatchIdOrderBySubmittedAtDesc(Long dispatchId);

  Optional<DispatchProofEvent> findFirstByDispatchIdAndProofTypeAndIdempotencyKeyOrderBySubmittedAtDesc(
      Long dispatchId, String proofType, String idempotencyKey);
}
