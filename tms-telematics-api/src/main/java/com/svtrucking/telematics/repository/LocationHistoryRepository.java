package com.svtrucking.telematics.repository;

import com.svtrucking.telematics.model.LocationHistory;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

/**
 * Telematics-local history repository.
 * Queries that previously JOINed with the 'drivers' table (in main schema) are
 * removed —
 * use DriverSnapshot for driver name/plate lookups instead.
 */
@Repository
public interface LocationHistoryRepository extends JpaRepository<LocationHistory, Long> {

    // ── Latest per driver (no JOIN to drivers table) ────────────────────────

    @Query(value = """
            SELECT lh.*
            FROM location_history lh
            INNER JOIN (
                SELECT driver_id, MAX(timestamp) AS max_time
                FROM location_history
                GROUP BY driver_id
            ) latest ON lh.driver_id = latest.driver_id AND lh.timestamp = latest.max_time
            """, nativeQuery = true)
    List<LocationHistory> findLatestLocationPerDriver();

    // ── Duplicate prevention ─────────────────────────────────────────────────

    Optional<LocationHistory> findTopByDriverIdOrderByTimestampDesc(Long driverId);

    boolean existsByDriverIdAndPointId(Long driverId, String pointId);

    boolean existsByDriverIdAndSessionIdAndSeq(Long driverId, String sessionId, Long seq);

    // ── History lookup ───────────────────────────────────────────────────────

    List<LocationHistory> findByDriverIdOrderByTimestampDesc(Long driverId);

    Page<LocationHistory> findByDriverIdOrderByTimestampDesc(Long driverId, Pageable pageable);

    Page<LocationHistory> findByDriverIdAndTimestampBetweenOrderByTimestampDesc(
            Long driverId, LocalDateTime start, LocalDateTime end, Pageable pageable);

    List<LocationHistory> findTop100ByDriverIdOrderByTimestampDesc(Long driverId);

    // ── Purge ────────────────────────────────────────────────────────────────

    long countByEventTimeBefore(LocalDateTime cutoff);

    @Modifying
    @Transactional
    @Query(value = """
            DELETE FROM location_history
            WHERE event_time < :cutoff
              AND id IN (
                  SELECT id
                  FROM location_history
                  WHERE event_time < :cutoff
                  ORDER BY event_time
                  LIMIT :batchSize
              )
            """, nativeQuery = true)
    int deleteOldHistoryBatch(
            @Param("cutoff") LocalDateTime cutoff,
            @Param("batchSize") int batchSize);
}
