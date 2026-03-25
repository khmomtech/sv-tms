package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.DriverLatestLocation;
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

  @Modifying(flushAutomatically = true, clearAutomatically = true)
  @Transactional
  @Query(
      value =
          """
    INSERT INTO driver_latest_location
        (driver_id, latitude, longitude, speed, heading, dispatch_id, last_seen,
         battery_level, source, location_name, is_online, ws_connected)
    SELECT
        :driverId,
        COALESCE(dl.latitude, 0),
        COALESCE(dl.longitude, 0),
        dl.speed,
        dl.heading,
        dl.dispatch_id,
        UTC_TIMESTAMP(6),
        :battery,
        :source,
        dl.location_name,
        1,
        COALESCE(dl.ws_connected, 0)
    FROM (SELECT 1) AS x
    LEFT JOIN driver_latest_location dl ON dl.driver_id = :driverId
    ON DUPLICATE KEY UPDATE
      driver_latest_location.last_seen     = UTC_TIMESTAMP(6),
      driver_latest_location.is_online     = 1,
      driver_latest_location.battery_level = COALESCE(VALUES(battery_level), driver_latest_location.battery_level),
      driver_latest_location.source        = COALESCE(VALUES(source),        driver_latest_location.source)
  """,
      nativeQuery = true)
  int upsertPresence(
      @Param("driverId") Long driverId,
      @Param("battery") Integer battery,
      @Param("source") String source);

  @Modifying(flushAutomatically = true, clearAutomatically = true)
  @Transactional
  @Query(
      value =
          """
    UPDATE driver_latest_location
    SET last_seen     = UTC_TIMESTAMP(6),
        is_online     = 1,
        battery_level = COALESCE(:battery, battery_level),
        source        = COALESCE(:source,  source)
    WHERE driver_id = :driverId
    """,
      nativeQuery = true)
  int updatePresenceIfExists(
      @Param("driverId") Long driverId,
      @Param("battery") Integer battery,
      @Param("source") String source);

  @Modifying(flushAutomatically = true, clearAutomatically = true)
  @Transactional
  @Query(
      value =
          """
      INSERT INTO driver_latest_location (
          driver_id, latitude, longitude, speed, heading, dispatch_id, last_seen,
          battery_level, source, location_name, is_online,
          accuracy_meters, location_source, net_type, version
      )
      VALUES (
          :driverId, :lat, :lng, :speed, :heading, :dispatchId, UTC_TIMESTAMP(6),
          :batteryLevel, :source, :locationName, :isOnline,
          :accuracyMeters, :locationSource, :netType, :appVersionCode
      )
      ON DUPLICATE KEY UPDATE
        latitude         = COALESCE(VALUES(latitude),         latitude),
        longitude        = COALESCE(VALUES(longitude),        longitude),
        speed            = COALESCE(VALUES(speed),            speed),
        heading          = COALESCE(VALUES(heading),          heading),
        dispatch_id      = COALESCE(VALUES(dispatch_id),      dispatch_id),
        last_seen        = UTC_TIMESTAMP(6),
        battery_level    = COALESCE(VALUES(battery_level),    battery_level),
        source           = COALESCE(VALUES(source),           source),
        location_name    = COALESCE(VALUES(location_name),    location_name),
        is_online        = COALESCE(VALUES(is_online), 1,     is_online),
        accuracy_meters  = COALESCE(VALUES(accuracy_meters),  accuracy_meters),
        location_source  = COALESCE(VALUES(location_source),  location_source),
        net_type         = COALESCE(VALUES(net_type),         net_type),
        version          = COALESCE(VALUES(version),          version)
    """,
      nativeQuery = true)
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
      @Param("appVersionCode") Long appVersionCode);

  @Modifying(flushAutomatically = true, clearAutomatically = true)
  @Transactional
  @Query(
      value =
          """
        INSERT INTO driver_latest_location (
            driver_id, latitude, longitude, speed, heading, dispatch_id, last_seen,
            battery_level, source, location_name, is_online
        )
        VALUES (
            :driverId, :lat, :lng, :speed, :heading, :dispatchId, UTC_TIMESTAMP(6),
            :batteryLevel, :source, :locationName, :isOnline
        )
        ON DUPLICATE KEY UPDATE
          latitude       = COALESCE(VALUES(latitude),       latitude),
          longitude      = COALESCE(VALUES(longitude),      longitude),
          speed          = COALESCE(VALUES(speed),          speed),
          heading        = COALESCE(VALUES(heading),        heading),
          dispatch_id    = COALESCE(VALUES(dispatch_id),    dispatch_id),
          last_seen      = UTC_TIMESTAMP(6),
          battery_level  = COALESCE(VALUES(battery_level),  battery_level),
          source         = COALESCE(VALUES(source),         source),
          location_name  = COALESCE(VALUES(location_name),  location_name),
          is_online      = COALESCE(VALUES(is_online), 1,   is_online)
      """,
      nativeQuery = true)
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
      @Param("isOnline") Boolean isOnline);

  @Modifying(flushAutomatically = true, clearAutomatically = true)
  @Transactional
  @Query(
      value =
          """
    INSERT INTO driver_latest_location
        (driver_id, latitude, longitude, speed, heading, dispatch_id, last_seen,
         battery_level, source, location_name, is_online, ws_connected)
    SELECT
        :driverId,
        COALESCE(dl.latitude, 0),
        COALESCE(dl.longitude, 0),
        dl.speed,
        dl.heading,
        dl.dispatch_id,
        UTC_TIMESTAMP(6),
        dl.battery_level,
        dl.source,
        dl.location_name,
        1,
        1
    FROM (SELECT 1) AS x
    LEFT JOIN driver_latest_location dl ON dl.driver_id = :driverId
    ON DUPLICATE KEY UPDATE
      driver_latest_location.ws_connected = 1,
      driver_latest_location.is_online    = 1,
      driver_latest_location.last_seen    = UTC_TIMESTAMP(6)
  """,
      nativeQuery = true)
  int markWsConnected(@Param("driverId") Long driverId);

  @Modifying(flushAutomatically = true, clearAutomatically = true)
  @Transactional
  @Query(
      value = "UPDATE driver_latest_location SET ws_connected = 0 WHERE driver_id = :driverId",
      nativeQuery = true)
  int markWsDisconnected(@Param("driverId") Long driverId);

  @Transactional(readOnly = true)
  @Query("SELECT l FROM DriverLatestLocation l ORDER BY l.lastSeen DESC")
  List<DriverLatestLocation> findAllLive();

  @Transactional(readOnly = true)
  @Query(
      """
      SELECT l FROM DriverLatestLocation l
      WHERE (:since IS NULL OR l.lastSeen >= :since)
      ORDER BY l.lastSeen DESC
      """)
  List<DriverLatestLocation> findSince(@Param("since") Timestamp since);

  @Transactional(readOnly = true)
  @Query(
      """
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

  @Modifying(flushAutomatically = true, clearAutomatically = true)
  @Transactional
  @Query(
      value =
          """
      UPDATE driver_latest_location
      SET is_online = 0
      WHERE last_seen < :cutoff
        AND (ws_connected = 0 OR ws_connected IS NULL)
        AND is_online = 1
      """,
      nativeQuery = true)
  int markOfflineIfLastSeenBefore(@Param("cutoff") Timestamp cutoff);
}
