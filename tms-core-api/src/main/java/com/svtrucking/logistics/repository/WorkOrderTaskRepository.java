package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.WorkOrderTask;
import java.util.Optional;
import com.svtrucking.logistics.enums.TaskStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.List;

public interface WorkOrderTaskRepository extends JpaRepository<WorkOrderTask, Long> {

  List<WorkOrderTask> findByWorkOrderId(Long workOrderId);

  Optional<WorkOrderTask> findByIdAndWorkOrderId(Long id, Long workOrderId);

  List<WorkOrderTask> findByAssignedTechnicianId(Long technicianId);

  List<WorkOrderTask> findByWorkOrderIdAndStatus(Long workOrderId, TaskStatus status);

  @Query(
      """
        SELECT t FROM WorkOrderTask t
        WHERE t.assignedTechnician.id = :technicianId
          AND t.status IN ('OPEN', 'IN_PROGRESS')
        ORDER BY t.workOrder.priority DESC, t.createdAt ASC
    """)
  List<WorkOrderTask> findTechnicianPendingTasks(@Param("technicianId") Long technicianId);

  @Query("SELECT COUNT(t) FROM WorkOrderTask t WHERE t.workOrder.id = :workOrderId AND t.status = 'COMPLETED'")
  Long countCompletedTasks(@Param("workOrderId") Long workOrderId);

  @Query("SELECT COUNT(t) FROM WorkOrderTask t WHERE t.workOrder.id = :workOrderId")
  Long countTotalTasks(@Param("workOrderId") Long workOrderId);
}
