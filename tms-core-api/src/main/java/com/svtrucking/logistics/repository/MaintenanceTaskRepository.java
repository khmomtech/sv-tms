package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.MaintenanceTask;
import java.time.LocalDate;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface MaintenanceTaskRepository extends JpaRepository<MaintenanceTask, Long> {

  /**
   * Returns all tasks for a given vehicle ordered by dueDate ascending (overdue
   * tasks surface first).
   */
  java.util.List<MaintenanceTask> findByVehicleIdOrderByDueDateAsc(Long vehicleId);

  Page<MaintenanceTask> findByTitleContainingIgnoreCase(String keyword, Pageable pageable);

  /** 🔎 Advanced filtering query for maintenance tasks */
  @Query("""
          SELECT t FROM MaintenanceTask t
          WHERE (:keyword IS NULL OR LOWER(t.title) LIKE LOWER(CONCAT('%', :keyword, '%')))
            AND (:status IS NULL OR t.status = :status)
            AND (:vehicleId IS NULL OR t.vehicle.id = :vehicleId)
            AND (:dueBefore IS NULL OR t.dueDate <= :dueBefore)
            AND (:dueAfter IS NULL OR t.dueDate >= :dueAfter)
      """)
  Page<MaintenanceTask> filterTasks(
      @Param("keyword") String keyword,
      @Param("status") String status,
      @Param("dueBefore") LocalDate dueBefore,
      @Param("dueAfter") LocalDate dueAfter,
      @Param("vehicleId") Long vehicleId,
      Pageable pageable);
}
