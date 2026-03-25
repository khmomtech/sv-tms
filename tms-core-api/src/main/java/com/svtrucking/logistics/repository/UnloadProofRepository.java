package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.UnloadProof;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface UnloadProofRepository extends JpaRepository<UnloadProof, Long> {
  Optional<UnloadProof> findByDispatchId(Long dispatchId);

  Optional<UnloadProof> findFirstByDispatchIdOrderBySubmittedAtDescIdDesc(Long dispatchId);

  long countByDispatchId(Long dispatchId);
}
