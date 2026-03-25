package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.LoadProof;
import java.util.List;
import java.util.Optional;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface LoadProofRepository extends JpaRepository<LoadProof, Long> {

  // Get one proof by dispatch ID
  Optional<LoadProof> findByDispatchId(Long dispatchId);

  //  For admin monitoring: return all sorted proofs
  List<LoadProof> findAll(Sort sort);

  //  Optional: if multiple proofs per dispatch are possible
  List<LoadProof> findAllByDispatchId(Long dispatchId);
}
