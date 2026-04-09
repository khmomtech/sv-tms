package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.LoadingEmptiesReturn;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface LoadingEmptiesReturnRepository extends JpaRepository<LoadingEmptiesReturn, Long> {
  List<LoadingEmptiesReturn> findByLoadingSessionId(Long loadingSessionId);

  void deleteByLoadingSessionId(Long loadingSessionId);
}
