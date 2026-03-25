package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.VehicleDocument;
import com.svtrucking.logistics.enums.VehicleDocumentType;
import java.time.LocalDateTime;
import java.util.List;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface DocumentRepository extends JpaRepository<VehicleDocument, Long> {
  List<VehicleDocument> findByVehicleId(Long vehicleId);

  // @Query("SELECT d FROM VehicleDocument d WHERE d.expiryDate <= CURRENT_DATE + 30")
  // List<VehicleDocument> findExpiringDocuments();

  @Query(
      """
        SELECT d FROM VehicleDocument d
        JOIN d.vehicle v
        WHERE (:vehicleId IS NULL OR v.id = :vehicleId)
          AND (:docType IS NULL OR d.documentType = :docType)
          AND (:search IS NULL OR LOWER(v.licensePlate) LIKE LOWER(CONCAT('%', :search, '%'))
               OR LOWER(d.documentNumber) LIKE LOWER(CONCAT('%', :search, '%'))
               OR LOWER(d.notes) LIKE LOWER(CONCAT('%', :search, '%')))
          AND d.createdAt BETWEEN :from AND :to
      """)
  Page<VehicleDocument> reportByCreatedAt(
      @Param("vehicleId") Long vehicleId,
      @Param("docType") VehicleDocumentType docType,
      @Param("search") String search,
      @Param("from") LocalDateTime from,
      @Param("to") LocalDateTime to,
      Pageable pageable);

  @Query(
      """
        SELECT d FROM VehicleDocument d
        JOIN d.vehicle v
        WHERE (:vehicleId IS NULL OR v.id = :vehicleId)
          AND (:docType IS NULL OR d.documentType = :docType)
          AND (:search IS NULL OR LOWER(v.licensePlate) LIKE LOWER(CONCAT('%', :search, '%'))
               OR LOWER(d.documentNumber) LIKE LOWER(CONCAT('%', :search, '%'))
               OR LOWER(d.notes) LIKE LOWER(CONCAT('%', :search, '%')))
          AND d.issueDate BETWEEN :from AND :to
      """)
  Page<VehicleDocument> reportByIssueDate(
      @Param("vehicleId") Long vehicleId,
      @Param("docType") VehicleDocumentType docType,
      @Param("search") String search,
      @Param("from") java.sql.Date from,
      @Param("to") java.sql.Date to,
      Pageable pageable);

  @Query(
      """
        SELECT d FROM VehicleDocument d
        JOIN d.vehicle v
        WHERE (:vehicleId IS NULL OR v.id = :vehicleId)
          AND (:docType IS NULL OR d.documentType = :docType)
          AND (:search IS NULL OR LOWER(v.licensePlate) LIKE LOWER(CONCAT('%', :search, '%'))
               OR LOWER(d.documentNumber) LIKE LOWER(CONCAT('%', :search, '%'))
               OR LOWER(d.notes) LIKE LOWER(CONCAT('%', :search, '%')))
          AND d.expiryDate BETWEEN :from AND :to
      """)
  Page<VehicleDocument> reportByExpiryDate(
      @Param("vehicleId") Long vehicleId,
      @Param("docType") VehicleDocumentType docType,
      @Param("search") String search,
      @Param("from") java.sql.Date from,
      @Param("to") java.sql.Date to,
      Pageable pageable);
}
