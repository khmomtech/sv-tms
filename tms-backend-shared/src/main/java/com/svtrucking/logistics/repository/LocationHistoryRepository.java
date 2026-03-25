package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.LocationHistory;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

@Repository
public interface LocationHistoryRepository extends JpaRepository<LocationHistory, Long> {

  @Query(
      value =
          """
        SELECT lh.driver_id AS driverId,
               d.name       AS name,
               lh.latitude  AS latitude,
               lh.longitude AS longitude,
               lh.`timestamp` AS `timestamp`
        FROM location_history lh
        JOIN drivers d ON lh.driver_id = d.id
        WHERE (lh.driver_id, lh.`timestamp`) IN (
            SELECT driver_id, MAX(`timestamp`)
            FROM location_history
            GROUP BY driver_id
        )
        ORDER BY lh.`timestamp` DESC
        """,
      nativeQuery = true)
  List<Map<String, Object>> findLiveDriverLocations();

  @Query(
      value =
          """
        SELECT x.driver_id    AS driverId,
               d.name         AS name,
               x.latitude     AS latitude,
               x.longitude    AS longitude,
               x.ts           AS `timestamp`
        FROM (
            SELECT lh.driver_id,
                   lh.latitude,
                   lh.longitude,
                   lh.`timestamp` AS ts,
                   ROW_NUMBER() OVER (PARTITION BY lh.driver_id ORDER BY lh.`timestamp` DESC) AS rn
            FROM location_history lh
        ) x
        JOIN drivers d ON x.driver_id = d.id
        WHERE x.rn = 1
        ORDER BY x.ts DESC
        """,
      nativeQuery = true)
  List<Map<String, Object>> findLiveDriverLocationsMySql8();

  @Query(
      value =
          """
        SELECT lh.*
        FROM location_history lh
        INNER JOIN (
            SELECT driver_id, MAX(`timestamp`) AS max_time
            FROM location_history
            GROUP BY driver_id
        ) latest ON lh.driver_id = latest.driver_id AND lh.`timestamp` = latest.max_time
        """,
      nativeQuery = true)
  List<LocationHistory> findLatestLocationPerDriver();

  Optional<LocationHistory> findTopByDriverIdOrderByTimestampDesc(Long driverId);

  boolean existsByDriverIdAndPointId(Long driverId, String pointId);

  List<LocationHistory> findByDriverIdOrderByTimestampDesc(Long driverId);

  Page<LocationHistory> findByDriverIdOrderByTimestampDesc(Long driverId, Pageable pageable);

  Page<LocationHistory> findByDriverIdAndTimestampBetweenOrderByTimestampDesc(
      Long driverId, LocalDateTime start, LocalDateTime end, Pageable pageable);

  List<LocationHistory> findTop100ByDriverIdOrderByTimestampDesc(Long driverId);

  long countByEventTimeBefore(LocalDateTime cutoff);

  @Modifying
  @Transactional
  @Query(
      value =
          """
        DELETE FROM location_history
        WHERE event_time < :cutoff
        ORDER BY event_time
        LIMIT :batchSize
        """,
      nativeQuery = true)
  int deleteOldHistoryBatch(
      @Param("cutoff") LocalDateTime cutoff, @Param("batchSize") int batchSize);
}
