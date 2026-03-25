package com.svtrucking.logistics.modules.notification.repository;

import com.svtrucking.logistics.modules.notification.model.DriverNotification;
import jakarta.transaction.Transactional;
import java.time.LocalDateTime;
import java.util.List;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface DriverNotificationRepository extends JpaRepository<DriverNotification, Long> {

  /** Legacy: paginated list, newest first (kept for compatibility). */
  Page<DriverNotification> findByDriverIdOrderByCreatedAtDesc(Long driverId, Pageable pageable);

  /** 🔢 Count unread for badge display. */
  long countByDriverIdAndIsReadFalse(Long driverId);

  /** Bulk mark all as read for a driver. */
  @Transactional
  @Modifying
  @Query(
      """
           UPDATE DriverNotification n
              SET n.isRead = true
            WHERE n.driverId = :driverId
              AND n.isRead = false
           """)
  int markAllAsReadByDriver(@Param("driverId") Long driverId);

  /** 🗑️ Soft delete all notifications for a driver (keep name for service compatibility). */
  @Transactional
  @Modifying
  @Query(
      """
           UPDATE DriverNotification n
              SET n.isDeleted = true,
                  n.deletedAt = CURRENT_TIMESTAMP
            WHERE n.driverId = :driverId
              AND n.isDeleted = false
           """)
  int deleteByDriverId(@Param("driverId") Long driverId);

  /** 🔎 Admin filtering (explicitly excludes soft-deleted). */
  @Query(
      """
           SELECT n FROM DriverNotification n
           WHERE n.isDeleted = false
             AND (:driverId IS NULL OR n.driverId = :driverId)
             AND (:type     IS NULL OR n.type     = :type)
             AND (:fromDate IS NULL OR n.createdAt >= :fromDate)
             AND (:toDate   IS NULL OR n.createdAt <= :toDate)
           ORDER BY n.createdAt DESC, n.id DESC
           """)
  Page<DriverNotification> filterNotifications(
      @Param("driverId") Long driverId,
      @Param("type") String type,
      @Param("fromDate") LocalDateTime fromDate,
      @Param("toDate") LocalDateTime toDate,
      Pageable pageable);

  /** 🧹 Optional: physical purge of already soft-deleted rows before a timestamp. */
  @Transactional
  @Modifying
  @Query("DELETE FROM DriverNotification n WHERE n.isDeleted = true AND n.deletedAt < :before")
  int purgeDeletedBefore(@Param("before") LocalDateTime before);

  // =========================
  //  Methods used by DriverNotificationService
  // =========================

  /** Unread first, then newest (stable tie-breaker by id DESC). */
  @Query(
      """
           SELECT n FROM DriverNotification n
            WHERE n.driverId = :driverId
              AND n.isDeleted = false
           ORDER BY CASE WHEN n.isRead = false THEN 0 ELSE 1 END,
                    n.createdAt DESC,
                    n.id DESC
           """)
  Page<DriverNotification> listForDriverUnreadFirst(
      @Param("driverId") Long driverId, Pageable pageable);

  /** Unread only, newest first. */
  @Query(
      """
           SELECT n FROM DriverNotification n
            WHERE n.driverId = :driverId
              AND n.isDeleted = false
              AND n.isRead = false
           ORDER BY n.createdAt DESC, n.id DESC
           """)
  Page<DriverNotification> listUnreadForDriver(@Param("driverId") Long driverId, Pageable pageable);

  /** New since timestamp, newest first. */
  @Query(
      """
           SELECT n FROM DriverNotification n
            WHERE n.driverId = :driverId
              AND n.isDeleted = false
              AND n.createdAt > :since
           ORDER BY n.createdAt DESC, n.id DESC
           """)
  Page<DriverNotification> listNewSince(
      @Param("driverId") Long driverId, @Param("since") LocalDateTime since, Pageable pageable);

  /** Mark one as read, scoped by driver (driverId may be NULL for legacy). */
  @Transactional
  @Modifying
  @Query(
      """
           UPDATE DriverNotification n
              SET n.isRead = true
            WHERE n.id = :id
              AND (:driverId IS NULL OR n.driverId = :driverId)
              AND n.isRead = false
           """)
  int markAsReadByIdAndDriver(@Param("id") Long id, @Param("driverId") Long driverId);

  // -------------------------
  // 🔥 New for delete endpoints
  // -------------------------

  /** Soft delete only READ notifications for a driver. */
  @Transactional
  @Modifying
  @Query(
      """
           UPDATE DriverNotification n
              SET n.isDeleted = true,
                  n.deletedAt = CURRENT_TIMESTAMP
            WHERE n.driverId = :driverId
              AND n.isDeleted = false
              AND n.isRead = true
           """)
  int deleteReadByDriverId(@Param("driverId") Long driverId);

  /** Bulk soft delete by IDs (ownership + not already deleted). */
  @Transactional
  @Modifying
  @Query(
      """
           UPDATE DriverNotification n
              SET n.isDeleted = true,
                  n.deletedAt = CURRENT_TIMESTAMP
            WHERE n.driverId = :driverId
              AND n.id IN :ids
              AND n.isDeleted = false
           """)
  int deleteByDriverIdAndIdIn(@Param("driverId") Long driverId, @Param("ids") List<Long> ids);

  /** Return IDs that are NOT owned by the given driver (for guard checks). */
  @Query(
      """
           SELECT n.id FROM DriverNotification n
            WHERE n.id IN :ids
              AND (n.driverId IS NULL OR n.driverId <> :driverId)
              AND n.isDeleted = false
           """)
  List<Long> findIdsNotOwnedByDriver(
      @Param("driverId") Long driverId, @Param("ids") List<Long> ids);

  //  use this (filters soft-deleted)
  @Query(
      """
       SELECT n FROM DriverNotification n
        WHERE n.driverId = :driverId
          AND n.isDeleted = false
       ORDER BY n.createdAt DESC, n.id DESC
       """)
  Page<DriverNotification> findNewestAliveByDriverId(
      @Param("driverId") Long driverId, Pageable pageable);
}
