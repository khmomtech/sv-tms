package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.enums.LoadingQueueStatus;
import com.svtrucking.logistics.enums.WarehouseCode;
import com.svtrucking.logistics.model.LoadingQueue;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface LoadingQueueRepository extends JpaRepository<LoadingQueue, Long> {

  Optional<LoadingQueue> findByDispatchId(Long dispatchId);

  boolean existsByDispatchId(Long dispatchId);

  boolean existsByDispatchIdAndStatusIn(Long dispatchId, List<LoadingQueueStatus> statuses);

  List<LoadingQueue> findByWarehouseCodeOrderByQueuePositionAscCreatedDateAsc(WarehouseCode warehouseCode);
}
