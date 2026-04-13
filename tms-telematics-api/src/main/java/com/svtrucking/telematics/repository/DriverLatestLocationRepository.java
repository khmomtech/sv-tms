package com.svtrucking.telematics.repository;

import com.svtrucking.telematics.model.DriverLatestLocation;
import java.sql.Timestamp;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

@Repository
public interface DriverLatestLocationRepository extends JpaRepository<DriverLatestLocation, Long> {

    // ── Upserts / Presence Writes ────────────────────────────────────────────

    @Modifying(flushAutomatically = true, clearAutomatically = true)
    @Transactional
    @Query(value = """
            INSERT INTO driver_latest_location
                (driver_id, latitude, longitude, speed, heading, dispatch_id, last_seen, last_received_at,
                 battery_level, source, location_name, is_online, ws_connected)
            VALUES (
                :driverId,
                COALESCE((SELECT dl.latitude FROM driver_latest_location dl WHERE dl.driver_id = :driverId), 0),
                COALESCE((SELECT dl.longitude FROM driver_latest_location dl WHERE dl.driver_id = :driverId), 0),
                (SELECT dl.speed FROM driver_latest_location dl WHERE dl.driver_id = :driverId),
                (SELECT dl.heading FROM driver_latest_location dl WHERE dl.driver_id = :driverId),
                (SELECT dl.dispatch_id FROM driver_latest_location dl WHERE dl.driver_id = :driverId),
                CURRENT_TIMESTAMP,
                CURRENT_TIMESTAMP,
                :battery,
                :source,
                (SELECT dl.location_name FROM driver_latest_location dl WHERE dl.driver_id = :driverId),
                TRUE,
                COALESCE((SELECT dl.ws_connected FROM driver_latest_location dl WHERE dl.driver_id = :driverId), FALSE)
            )
            ON CONFLICT (driver_id) DO UPDATE
            SET last_seen = CURRENT_TIMESTAMP,
                last_received_at = CURRENT_TIMESTAMP,
                is_online = TRUE,
                battery_level = COALESCE(EXCLUDED.battery_level, driver_latest_location.battery_level),
                source = COALESCE(EXCLUDED.source, driver_latest_location.source)
            """, nativeQuery = true)
    int upsertPresence(
            @Param("driverId") Long driverId,
            @Param("battery") Integer battery,
            @Param("source") String source);

    @Modifying(flushAutomatically = true, clearAutomatically = true)
    @Transactional
    @Query(value = """
            UPDATE driver_latest_location
            SET last_seen     = CURRENT_TIMESTAMP,
                last_received_at = CURRENT_TIMESTAMP,
                is_online     = TRUE,
                battery_level = COALESCE(:battery, battery_level),
                source        = COALESCE(:source,  source)
            WHERE driver_id = :driverId
            """, nativeQuery = true)
    int updatePresenceIfExists(
            @Param("driverId") Long driverId,
            @Param("battery") Integer battery,
            @Param("source") String source);

    @Modifying(flushAutomatically = true, clearAutomatically = true)
    @Transactional
    @Query(value = """
            INSERT INTO driver_latest_location (
                driver_id, latitude, longitude, speed, heading, dispatch_id, last_seen, last_received_at,
                battery_level, source, location_name, is_online,
                accuracy_meters, location_source, net_type, version, last_event_time
            )
            VALUES (
                :driverId, :lat, :lng, :speed, :heading, :dispatchId, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP,
                :batteryLevel, :source, :locationName, :isOnline,
                :accuracyMeters, :locationSource, :netType, :appVersionCode, :eventTime
            )
            ON CONFLICT (driver_id) DO UPDATE
            SET latitude = CASE
                    WHEN driver_latest_location.last_event_time IS NULL
                      OR EXCLUDED.last_event_time IS NULL
                      OR EXCLUDED.last_event_time >= driver_latest_location.last_event_time
                    THEN COALESCE(EXCLUDED.latitude, driver_latest_location.latitude)
                    ELSE driver_latest_location.latitude
                END,
                longitude = CASE
                    WHEN driver_latest_location.last_event_time IS NULL
                      OR EXCLUDED.last_event_time IS NULL
                      OR EXCLUDED.last_event_time >= driver_latest_location.last_event_time
                    THEN COALESCE(EXCLUDED.longitude, driver_latest_location.longitude)
                    ELSE driver_latest_location.longitude
                END,
                speed = CASE
                    WHEN driver_latest_location.last_event_time IS NULL
                      OR EXCLUDED.last_event_time IS NULL
                      OR EXCLUDED.last_event_time >= driver_latest_location.last_event_time
                    THEN COALESCE(EXCLUDED.speed, driver_latest_location.speed)
                    ELSE driver_latest_location.speed
                END,
                heading = CASE
                    WHEN driver_latest_location.last_event_time IS NULL
                      OR EXCLUDED.last_event_time IS NULL
                      OR EXCLUDED.last_event_time >= driver_latest_location.last_event_time
                    THEN COALESCE(EXCLUDED.heading, driver_latest_location.heading)
                    ELSE driver_latest_location.heading
                END,
                dispatch_id = CASE
                    WHEN driver_latest_location.last_event_time IS NULL
                      OR EXCLUDED.last_event_time IS NULL
                      OR EXCLUDED.last_event_time >= driver_latest_location.last_event_time
                    THEN COALESCE(EXCLUDED.dispatch_id, driver_latest_location.dispatch_id)
                    ELSE driver_latest_location.dispatch_id
                END,
                last_seen = CURRENT_TIMESTAMP,
                last_received_at = CURRENT_TIMESTAMP,
                battery_level = COALESCE(EXCLUDED.battery_level, driver_latest_location.battery_level),
                source = COALESCE(EXCLUDED.source, driver_latest_location.source),
                location_name = CASE
                    WHEN driver_latest_location.last_event_time IS NULL
                      OR EXCLUDED.last_event_time IS NULL
                      OR EXCLUDED.last_event_time >= driver_latest_location.last_event_time
                    THEN COALESCE(EXCLUDED.location_name, driver_latest_location.location_name)
                    ELSE driver_latest_location.location_name
                END,
                is_online = COALESCE(EXCLUDED.is_online, driver_latest_location.is_online, TRUE),
                accuracy_meters = CASE
                    WHEN driver_latest_location.last_event_time IS NULL
                      OR EXCLUDED.last_event_time IS NULL
                      OR EXCLUDED.last_event_time >= driver_latest_location.last_event_time
                    THEN COALESCE(EXCLUDED.accuracy_meters, driver_latest_location.accuracy_meters)
                    ELSE driver_latest_location.accuracy_meters
                END,
                location_source = CASE
                    WHEN driver_latest_location.last_event_time IS NULL
                      OR EXCLUDED.last_event_time IS NULL
                      OR EXCLUDED.last_event_time >= driver_latest_location.last_event_time
                    THEN COALESCE(EXCLUDED.location_source, driver_latest_location.location_source)
                    ELSE driver_latest_location.location_source
                END,
                net_type = CASE
                    WHEN driver_latest_location.last_event_time IS NULL
                      OR EXCLUDED.last_event_time IS NULL
                      OR EXCLUDED.last_event_time >= driver_latest_location.last_event_time
                    THEN COALESCE(EXCLUDED.net_type, driver_latest_location.net_type)
                    ELSE driver_latest_location.net_type
                END,
                version = CASE
                    WHEN driver_latest_location.last_event_time IS NULL
                      OR EXCLUDED.last_event_time IS NULL
                      OR EXCLUDED.last_event_time >= driver_latest_location.last_event_time
                    THEN COALESCE(EXCLUDED.version, driver_latest_location.version)
                    ELSE driver_latest_location.version
                END,
                last_event_time = CASE
                    WHEN driver_latest_location.last_event_time IS NULL THEN EXCLUDED.last_event_time
                    WHEN EXCLUDED.last_event_time IS NULL THEN driver_latest_location.last_event_time
                    ELSE GREATEST(EXCLUDED.last_event_time, driver_latest_location.last_event_time)
                END
            """, nativeQuery = true)
    int upsertLatest(
            @Param("driverId") Long driverId,
            @Param("lat") Double lat,
            @Param("lng") Double lng,
            @Param("speed") Double speed,
            @Param("heading") Double heading,
            @Param("dispatchId") Long dispatchId,
            @Param("batteryLevel") Integer batteryLevel,
            @Param("source") String source,
            @Param("locationName") String locationName,
            @Param("isOnline") Boolean isOnline,
            @Param("accuracyMeters") Double accuracyMeters,
            @Param("locationSource") String locationSource,
            @Param("netType") String netType,
            @Param("appVersionCode") Long appVersionCode,
            @Param("eventTime") Timestamp eventTime);

    // ── WebSocket Presence Flags ─────────────────────────────────────────────

    @Modifying(flushAutomatically = true, clearAutomatically = true)
    @Transactional
    @Query(value = """
            INSERT INTO driver_latest_location
                (driver_id, latitude, longitude, speed, heading, dispatch_id, last_seen, last_received_at,
                 battery_level, source, location_name, is_online, ws_connected)
            VALUES (
                :driverId,
                COALESCE((SELECT dl.latitude FROM driver_latest_location dl WHERE dl.driver_id = :driverId), 0),
                COALESCE((SELECT dl.longitude FROM driver_latest_location dl WHERE dl.driver_id = :driverId), 0),
                (SELECT dl.speed FROM driver_latest_location dl WHERE dl.driver_id = :driverId),
                (SELECT dl.heading FROM driver_latest_location dl WHERE dl.driver_id = :driverId),
                (SELECT dl.dispatch_id FROM driver_latest_location dl WHERE dl.driver_id = :driverId),
                CURRENT_TIMESTAMP,
                CURRENT_TIMESTAMP,
                (SELECT dl.battery_level FROM driver_latest_location dl WHERE dl.driver_id = :driverId),
                (SELECT dl.source FROM driver_latest_location dl WHERE dl.driver_id = :driverId),
                (SELECT dl.location_name FROM driver_latest_location dl WHERE dl.driver_id = :driverId),
                TRUE,
                TRUE
            )
            ON CONFLICT (driver_id) DO UPDATE
            SET ws_connected = TRUE,
                is_online = TRUE,
                last_seen = CURRENT_TIMESTAMP,
                last_received_at = CURRENT_TIMESTAMP
            """, nativeQuery = true)
    int markWsConnected(@Param("driverId") Long driverId);

    @Modifying(flushAutomatically = true, clearAutomatically = true)
    @Transactional
    @Query(value = "UPDATE driver_latest_location SET ws_connected = 0 WHERE driver_id = :driverId", nativeQuery = true)
    int markWsDisconnected(@Param("driverId") Long driverId);

    // ── Queries ──────────────────────────────────────────────────────────────

    @Transactional(readOnly = true)
    @Query("SELECT l FROM DriverLatestLocation l ORDER BY l.lastSeen DESC")
    List<DriverLatestLocation> findAllLive();

    @Transactional(readOnly = true)
    @Query("""
            SELECT l FROM DriverLatestLocation l
            WHERE (:since IS NULL OR l.lastSeen >= :since)
            ORDER BY l.lastSeen DESC
            """)
    List<DriverLatestLocation> findSince(@Param("since") Timestamp since);

    @Transactional(readOnly = true)
    @Query("""
            SELECT l FROM DriverLatestLocation l
            WHERE (:since IS NULL OR l.lastSeen >= :since)
              AND (:south IS NULL OR l.latitude  >= :south)
              AND (:north IS NULL OR l.latitude  <= :north)
              AND (:west  IS NULL OR l.longitude >= :west)
              AND (:east  IS NULL OR l.longitude <= :east)
            ORDER BY l.lastSeen DESC
            """)
    List<DriverLatestLocation> findSinceWithinBbox(
            @Param("since") Timestamp since,
            @Param("south") Double south,
            @Param("west") Double west,
            @Param("north") Double north,
            @Param("east") Double east);

    @Modifying
    @Transactional
    @Query(value = """
            UPDATE driver_latest_location
            SET is_online = FALSE
            WHERE COALESCE(last_received_at, last_seen) < :cutoff
              AND COALESCE(ws_connected, FALSE) = FALSE
            """, nativeQuery = true)
    int markOfflineIfLastSeenBefore(@Param("cutoff") Timestamp cutoff);
}
