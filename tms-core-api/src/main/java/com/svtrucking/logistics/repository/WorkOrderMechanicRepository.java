package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.WorkOrderMechanic;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface WorkOrderMechanicRepository extends JpaRepository<WorkOrderMechanic, Long> {
  List<WorkOrderMechanic> findByWorkOrderId(Long workOrderId);
  void deleteByWorkOrderId(Long workOrderId);
}

