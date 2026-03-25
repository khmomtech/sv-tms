package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.WorkOrder;
import com.svtrucking.logistics.enums.WorkOrderStatus;
import com.svtrucking.logistics.enums.WorkOrderType;
import com.svtrucking.logistics.enums.Priority;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

public interface WorkOrderRepository extends JpaRepository<WorkOrder, Long> {

  Optional<WorkOrder> findByWoNumber(String woNumber);

  Page<WorkOrder> findByIsDeletedFalse(Pageable pageable);

  Page<WorkOrder> findByStatusAndIsDeletedFalse(WorkOrderStatus status, Pageable pageable);

  Page<WorkOrder> findByTypeAndIsDeletedFalse(WorkOrderType type, Pageable pageable);

  Page<WorkOrder> findByVehicleIdAndIsDeletedFalse(Long vehicleId, Pageable pageable);

  Optional<WorkOrder> findByMaintenanceRequestId(Long maintenanceRequestId);
  List<WorkOrder> findByMaintenanceRequestIdIn(List<Long> maintenanceRequestIds);

  Page<WorkOrder> findByAssignedTechnicianIdAndIsDeletedFalse(Long technicianId, Pageable pageable);

  List<WorkOrder> findByStatusAndIsDeletedFalse(WorkOrderStatus status);

  @Query(
      """
        SELECT w FROM WorkOrder w
        WHERE w.isDeleted = FALSE
          AND (:status IS NULL OR w.status = :status)
          AND (:type IS NULL OR w.type = :type)
          AND (:priority IS NULL OR w.priority = :priority)
          AND (:vehicleId IS NULL OR w.vehicle.id = :vehicleId)
          AND (:technicianId IS NULL OR w.assignedTechnician.id = :technicianId)
          AND (:scheduledAfter IS NULL OR w.scheduledDate >= :scheduledAfter)
          AND (:scheduledBefore IS NULL OR w.scheduledDate <= :scheduledBefore)
    """)
  Page<WorkOrder> filterWorkOrders(
      @Param("status") WorkOrderStatus status,
      @Param("type") WorkOrderType type,
      @Param("priority") Priority priority,
      @Param("vehicleId") Long vehicleId,
      @Param("technicianId") Long technicianId,
      @Param("scheduledAfter") LocalDateTime scheduledAfter,
      @Param("scheduledBefore") LocalDateTime scheduledBefore,
      Pageable pageable);

  @Query(
      """
        SELECT w FROM WorkOrder w
        WHERE w.isDeleted = FALSE
          AND w.status IN ('OPEN', 'IN_PROGRESS')
          AND w.priority = 'URGENT'
        ORDER BY w.scheduledDate ASC
    """)
  List<WorkOrder> findUrgentWorkOrders();

  @Query(
      """
        SELECT w FROM WorkOrder w
        WHERE w.isDeleted = FALSE
          AND w.requiresApproval = TRUE
          AND w.approved = FALSE
          AND w.status = 'COMPLETED'
    """)
  List<WorkOrder> findPendingApproval();

  @Query("SELECT MAX(CAST(SUBSTRING(w.woNumber, 9) AS integer)) FROM WorkOrder w WHERE w.woNumber LIKE :yearPrefix")
  Integer findMaxWoNumberForYear(@Param("yearPrefix") String yearPrefix);

  Long countByStatusAndIsDeletedFalse(WorkOrderStatus status);

  Long countByTypeAndIsDeletedFalse(WorkOrderType type);

  @Query(
      "SELECT COUNT(w) FROM WorkOrder w WHERE w.isDeleted = FALSE "
          + "AND w.vehicle.id = :vehicleId "
          + "AND w.status IN ('OPEN', 'IN_PROGRESS', 'WAITING_PARTS')")
  long countActiveForVehicle(@Param("vehicleId") Long vehicleId);
}
