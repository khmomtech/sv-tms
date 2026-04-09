package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.DriverDocument;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Repository
public interface DriverDocumentRepository extends JpaRepository<DriverDocument, Long> {

    /**
     * Get all documents for a specific driver
     */
    List<DriverDocument> findByDriverId(Long driverId);

    /**
     * Get documents by driver and category
     */
    List<DriverDocument> findByDriverIdAndCategory(Long driverId, String category);

    @Query("""
            SELECT dd FROM DriverDocument dd
            WHERE dd.driver.id = :driverId
              AND LOWER(dd.category) = 'license'
            ORDER BY dd.updatedAt DESC, dd.createdAt DESC, dd.id DESC
            """)
    List<DriverDocument> findLicenseDocumentsByDriverId(@Param("driverId") Long driverId);

    @Query("""
            SELECT dd FROM DriverDocument dd
            WHERE LOWER(dd.category) = 'license'
              AND LOWER(TRIM(dd.name)) = :normalizedLicenseNumber
            ORDER BY dd.id ASC
            """)
    List<DriverDocument> findLicenseDocumentsByNormalizedName(
            @Param("normalizedLicenseNumber") String normalizedLicenseNumber);

    @Query("""
            SELECT dd FROM DriverDocument dd
            WHERE LOWER(dd.category) = 'license'
              AND dd.driver.id IN :driverIds
            ORDER BY dd.driver.id ASC, dd.updatedAt DESC, dd.createdAt DESC, dd.id DESC
            """)
    List<DriverDocument> findLicenseDocumentsByDriverIds(@Param("driverIds") List<Long> driverIds);

    /**
     * Get documents expiring within a date range
     */
    @Query("SELECT dd FROM DriverDocument dd WHERE dd.driver.id = :driverId AND dd.expiryDate BETWEEN :startDate AND :endDate")
    List<DriverDocument> findExpiringDocuments(@Param("driverId") Long driverId,
            @Param("startDate") LocalDate startDate, @Param("endDate") LocalDate endDate);

    /**
     * Get expired documents
     */
    @Query("SELECT dd FROM DriverDocument dd WHERE dd.driver.id = :driverId AND dd.expiryDate < :today")
    List<DriverDocument> findExpiredDocuments(@Param("driverId") Long driverId, @Param("today") LocalDate today);

    /**
     * Get required documents for a driver
     */
    @Query("SELECT dd FROM DriverDocument dd WHERE dd.driver.id = :driverId AND dd.isRequired = true")
    List<DriverDocument> findRequiredDocuments(@Param("driverId") Long driverId);

    /**
     * Delete all documents for a driver
     */
    void deleteByDriverId(Long driverId);

    /**
     * Check if a document exists by ID and driver ID (security check)
     */
    boolean existsByIdAndDriverId(Long id, Long driverId);

    /**
     * Get a single document by ID and driver ID (security check)
     */
    Optional<DriverDocument> findByIdAndDriverId(Long id, Long driverId);

    // ─── Cross-driver admin queries ────────────────────────────────────────────

    /**
     * All documents of a given category across all drivers (training / compliance
     * admin views).
     */
    @Query("SELECT dd FROM DriverDocument dd WHERE dd.category = :category ORDER BY dd.expiryDate ASC NULLS LAST")
    List<DriverDocument> findAllByCategory(@Param("category") String category);

    /**
     * Paginated, searchable list of documents for a given category across all
     * drivers.
     * search matches driver first/last name, phone, or document name.
     */
    @Query("SELECT dd FROM DriverDocument dd JOIN dd.driver d " +
            "WHERE dd.category = :category " +
            "AND (:search IS NULL OR :search = '' OR " +
            "     LOWER(d.firstName) LIKE LOWER(CONCAT('%', :search, '%')) OR " +
            "     LOWER(d.lastName)  LIKE LOWER(CONCAT('%', :search, '%')) OR " +
            "     LOWER(d.phone)     LIKE LOWER(CONCAT('%', :search, '%')) OR " +
            "     LOWER(dd.name)     LIKE LOWER(CONCAT('%', :search, '%')))")
    Page<DriverDocument> searchByCategory(
            @Param("category") String category,
            @Param("search") String search,
            Pageable pageable);

    /**
     * Documents expiring within a date window for a given category across all
     * drivers.
     */
    @Query("SELECT dd FROM DriverDocument dd WHERE dd.category = :category " +
            "AND dd.expiryDate IS NOT NULL AND dd.expiryDate BETWEEN :startDate AND :endDate " +
            "ORDER BY dd.expiryDate ASC")
    List<DriverDocument> findExpiringByCategory(
            @Param("category") String category,
            @Param("startDate") LocalDate startDate,
            @Param("endDate") LocalDate endDate);

    /**
     * All documents (any category) expiring within a date window across all
     * drivers.
     */
    @Query("SELECT dd FROM DriverDocument dd WHERE dd.expiryDate IS NOT NULL " +
            "AND dd.expiryDate BETWEEN :startDate AND :endDate ORDER BY dd.expiryDate ASC")
    List<DriverDocument> findAllExpiring(
            @Param("startDate") LocalDate startDate,
            @Param("endDate") LocalDate endDate);

    /**
     * All expired documents across all drivers.
     */
    @Query("SELECT dd FROM DriverDocument dd WHERE dd.expiryDate IS NOT NULL " +
            "AND dd.expiryDate < :today ORDER BY dd.expiryDate DESC")
    List<DriverDocument> findAllExpired(@Param("today") LocalDate today);

    /** Count all documents with a given category. */
    long countByCategory(String category);

    /** Count expired documents with a given category. */
    @Query("SELECT COUNT(dd) FROM DriverDocument dd WHERE dd.category = :category AND dd.expiryDate < :today")
    long countExpiredByCategory(@Param("category") String category, @Param("today") LocalDate today);

    /** Count documents with a given category expiring within a window. */
    @Query("SELECT COUNT(dd) FROM DriverDocument dd WHERE dd.category = :category " +
            "AND dd.expiryDate IS NOT NULL AND dd.expiryDate BETWEEN :startDate AND :endDate")
    long countExpiringByCategory(
            @Param("category") String category,
            @Param("startDate") LocalDate startDate,
            @Param("endDate") LocalDate endDate);
}
