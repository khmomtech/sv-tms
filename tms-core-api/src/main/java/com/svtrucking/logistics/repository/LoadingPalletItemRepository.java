package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.LoadingPalletItem;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface LoadingPalletItemRepository extends JpaRepository<LoadingPalletItem, Long> {
  List<LoadingPalletItem> findByLoadingSessionId(Long loadingSessionId);

  void deleteByLoadingSessionId(Long loadingSessionId);
}
