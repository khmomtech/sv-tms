package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.PMSchedule;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.time.LocalDate;
import java.util.List;

public interface PMScheduleRepository extends JpaRepository<PMSchedule, Long> {

  Page<PMSchedule> findByActiveAndIsDeletedFalse(Boolean active, Pageable pageable);

  Page<PMSchedule> findByIsDeletedFalse(Pageable pageable);

  List<PMSchedule> findByVehicleIdAndActiveAndIsDeletedFalse(
      Long vehicleId, Boolean active);

  List<PMSchedule> findByVehicleTypeAndActiveAndIsDeletedFalse(
      String vehicleType, Boolean active);

  List<PMSchedule> findByActiveAndIsDeletedFalse(Boolean active);

  @Query(
      """
        SELECT pm FROM PMSchedule pm
        WHERE pm.isDeleted = FALSE
          AND pm.active = TRUE
          AND pm.triggerType = 'DATE'
          AND pm.nextDueDate <= :date
    """)
  List<PMSchedule> findOverdueByDate(@Param("date") LocalDate date);

  @Query(
      """
        SELECT pm FROM PMSchedule pm
        JOIN Vehicle v ON (pm.vehicle.id = v.id OR pm.vehicleType = v.type)
        WHERE pm.isDeleted = FALSE
          AND pm.active = TRUE
          AND pm.triggerType = 'KILOMETER'
          AND pm.nextDueKm <= v.mileage
    """)
  List<PMSchedule> findOverdueByKilometer();

  @Query(
      """
        SELECT pm FROM PMSchedule pm
        WHERE pm.isDeleted = FALSE
          AND pm.active = TRUE
          AND pm.triggerType = 'DATE'
          AND pm.nextDueDate BETWEEN :startDate AND :endDate
    """)
  List<PMSchedule> findDueSoonByDate(
      @Param("startDate") LocalDate startDate, @Param("endDate") LocalDate endDate);

  Long countByActiveAndIsDeletedFalse(Boolean active);
}
