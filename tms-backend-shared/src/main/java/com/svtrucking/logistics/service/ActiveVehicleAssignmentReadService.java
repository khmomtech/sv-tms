package com.svtrucking.logistics.service;

import java.util.HashMap;
import java.util.Map;
import java.util.Set;
import lombok.RequiredArgsConstructor;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class ActiveVehicleAssignmentReadService {

  private final NamedParameterJdbcTemplate jdbcTemplate;

  public Map<Long, ActiveVehicleAssignmentRow> findActiveByDriverIds(Set<Long> driverIds) {
    if (driverIds == null || driverIds.isEmpty()) {
      return Map.of();
    }

    String sql =
        """
        SELECT vd.driver_id AS driver_id,
               vd.id AS assignment_id,
               v.license_plate AS vehicle_plate
        FROM vehicle_drivers vd
        JOIN vehicles v ON v.id = vd.vehicle_id
        WHERE vd.revoked_at IS NULL
          AND vd.driver_id IN (:driverIds)
        ORDER BY vd.assigned_at DESC, vd.id DESC
        """;

    MapSqlParameterSource params = new MapSqlParameterSource("driverIds", driverIds);
    Map<Long, ActiveVehicleAssignmentRow> result = new HashMap<>();
    jdbcTemplate.query(
        sql,
        params,
        rs -> {
          long driverId = rs.getLong("driver_id");
          result.putIfAbsent(
              driverId,
              new ActiveVehicleAssignmentRow(
                  driverId,
                  rs.getLong("assignment_id"),
                  rs.getString("vehicle_plate")));
        });
    return result;
  }

  public record ActiveVehicleAssignmentRow(Long driverId, Long assignmentId, String vehiclePlate) {}
}
