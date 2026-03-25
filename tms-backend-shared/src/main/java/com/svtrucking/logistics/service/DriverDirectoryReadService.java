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
public class DriverDirectoryReadService {

  private final NamedParameterJdbcTemplate jdbcTemplate;

  public Map<Long, DriverDirectoryRow> findByIds(Set<Long> driverIds) {
    if (driverIds == null || driverIds.isEmpty()) {
      return Map.of();
    }

    String sql =
        """
        SELECT d.id AS driver_id,
               TRIM(CONCAT(COALESCE(d.first_name, ''), ' ', COALESCE(d.last_name, ''))) AS full_name,
               d.phone AS phone
        FROM drivers d
        WHERE d.id IN (:driverIds)
        """;

    MapSqlParameterSource params = new MapSqlParameterSource("driverIds", driverIds);
    Map<Long, DriverDirectoryRow> result = new HashMap<>();
    jdbcTemplate.query(
        sql,
        params,
        rs -> {
          long driverId = rs.getLong("driver_id");
          result.put(
              driverId,
              new DriverDirectoryRow(
                  driverId,
                  rs.getString("full_name"),
                  rs.getString("phone")));
        });
    return result;
  }

  public record DriverDirectoryRow(Long driverId, String fullName, String phone) {}
}
