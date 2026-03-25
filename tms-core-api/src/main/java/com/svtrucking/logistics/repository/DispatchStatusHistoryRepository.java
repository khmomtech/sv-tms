package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.DispatchStatusHistory;
import com.svtrucking.logistics.model.Dispatch;
import java.util.Collection;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

@Repository
public interface DispatchStatusHistoryRepository
    extends JpaRepository<DispatchStatusHistory, Long> {

  List<DispatchStatusHistory> findByDispatchIdOrderByUpdatedAtAsc(Long dispatchId);

  // Public Tracking API - find status history by Dispatch object
  List<DispatchStatusHistory> findByDispatchOrderByUpdatedAtAsc(Dispatch dispatch);

  @Modifying
  @Transactional
  @Query("DELETE FROM DispatchStatusHistory d WHERE d.dispatch.id = :dispatchId")
  void deleteByDispatchId(@Param("dispatchId") Long dispatchId);

  @Modifying
  @Transactional
  @Query("DELETE FROM DispatchStatusHistory d WHERE d.dispatch.id IN :dispatchIds")
  void deleteByDispatchIdIn(@Param("dispatchIds") Collection<Long> dispatchIds);
}
