package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.WorkOrderPart;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.List;
import java.util.Optional;

public interface WorkOrderPartRepository extends JpaRepository<WorkOrderPart, Long> {

  List<WorkOrderPart> findByWorkOrderId(Long workOrderId);

  List<WorkOrderPart> findByTaskId(Long taskId);

  boolean existsByTaskId(Long taskId);

  Optional<WorkOrderPart> findByIdAndWorkOrderId(Long id, Long workOrderId);

  List<WorkOrderPart> findByPartId(Long partId);

  @Query(
      """
        SELECT p.part.partCode, p.part.partName, SUM(p.quantity) as totalQty, SUM(p.totalCost) as totalCost
        FROM WorkOrderPart p
        WHERE p.workOrder.isDeleted = FALSE
          AND p.workOrder.completedAt BETWEEN :startDate AND :endDate
        GROUP BY p.part.id, p.part.partCode, p.part.partName
        ORDER BY totalQty DESC
    """)
  List<Object[]> findMostUsedParts(
      @Param("startDate") java.time.LocalDateTime startDate,
      @Param("endDate") java.time.LocalDateTime endDate);
}
