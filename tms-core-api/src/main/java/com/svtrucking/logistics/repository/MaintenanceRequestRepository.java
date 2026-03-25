package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.enums.MaintenanceRequestStatus;
import com.svtrucking.logistics.model.MaintenanceRequest;
import java.time.LocalDateTime;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface MaintenanceRequestRepository extends JpaRepository<MaintenanceRequest, Long> {

  java.util.Optional<MaintenanceRequest> findByMrNumber(String mrNumber);

  @Query(
      "SELECT mr FROM MaintenanceRequest mr WHERE mr.isDeleted = false "
          + "AND (:status IS NULL OR mr.status = :status) "
          + "AND (:vehicleId IS NULL OR mr.vehicle.id = :vehicleId) "
          + "AND (:failureCodeId IS NULL OR mr.failureCode.id = :failureCodeId) "
          + "AND (:search IS NULL OR LOWER(mr.mrNumber) LIKE LOWER(CONCAT('%', :search, '%')) "
          + "OR LOWER(mr.title) LIKE LOWER(CONCAT('%', :search, '%')))")
  Page<MaintenanceRequest> search(
      @Param("search") String search,
      @Param("status") MaintenanceRequestStatus status,
      @Param("vehicleId") Long vehicleId,
      @Param("failureCodeId") Long failureCodeId,
      Pageable pageable);

  @Query(
      "SELECT COUNT(mr) FROM MaintenanceRequest mr WHERE mr.isDeleted = false "
          + "AND mr.vehicle.id = :vehicleId "
          + "AND mr.requestedAt >= :fromDate")
  long countRecentForVehicle(@Param("vehicleId") Long vehicleId, @Param("fromDate") LocalDateTime fromDate);
}
