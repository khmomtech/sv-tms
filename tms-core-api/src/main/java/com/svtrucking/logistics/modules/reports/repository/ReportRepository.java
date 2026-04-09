package com.svtrucking.logistics.modules.reports.repository;

import com.svtrucking.logistics.modules.reports.dto.DispatchDayReportRow;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.stereotype.Repository;

@Repository
public class ReportRepository {

  private final NamedParameterJdbcTemplate jdbc;

  public ReportRepository(NamedParameterJdbcTemplate jdbc) {
    this.jdbc = jdbc;
  }

  public List<DispatchDayReportRow> getDispatchDayReport(
      LocalDate planFrom,
      LocalDate planTo,
      Instant fromTs, // nullable: when null, defaults to plan_from 00:00
      Instant toTs, // nullable: when null, defaults to plan_to + toExtraDays
      Integer toExtraDays // nullable: defaults to 2
      ) {
    final String sql =
        """
      WITH m_bounds AS (
        SELECT
          COALESCE(:from_ts, TIMESTAMP(:plan_from, '00:00:00')) AS start_ts,
          COALESCE(
            :to_ts,
            DATE_ADD(TIMESTAMP(:plan_to, '00:00:00'), INTERVAL :to_extra_days DAY)
          ) AS end_ts
      )
      /* Outer SELECT derives final text from inner aliases */
      SELECT
        t.dispatch_id,
        t.plan_date,
        t.truck_no,
        t.truck_trip,             --  comma was missing before
        t.depot,
        t.number_of_pallets,
        t.truck_type,
        t.factory_departure,
        t.depot_arrival,
        t.planned_depot_arrival,
        t.unloading_complete,
        CASE
          WHEN t.unloading_complete IS NOT NULL THEN 'ទម្លាក់រួច'
          WHEN t.depot_arrival      IS NOT NULL THEN 'ដល់ដេប៉ូ'
          ELSE COALESCE(t.last_loc_dispatch, t.last_loc_driver, '')
        END AS final_destination_text
      FROM (
        SELECT
          d.id            AS dispatch_id,
          d.delivery_date AS plan_date,
          COALESCE(v.license_plate, to_.truck_number) AS truck_no,
          d.truck_trip    AS truck_trip,              --  now projected for outer use
          d.to_location   AS depot,

          /* pallets by order_id (switch to dispatch_items if needed) */
          (SELECT COALESCE(SUM(oi.pallet_type), 0)
             FROM order_items oi
            WHERE oi.order_id = d.transport_order_id) AS number_of_pallets,

          v.`type`        AS truck_type,

          /* 🔹 first IN_TRANSIT within window */
          (SELECT h.updated_at
             FROM dispatch_status_history h
             JOIN m_bounds b
               ON h.updated_at >= b.start_ts
              AND h.updated_at  < b.end_ts
            WHERE h.dispatch_id = d.id
              AND h.status = 'IN_TRANSIT'
            ORDER BY h.updated_at ASC
            LIMIT 1) AS factory_departure,

          /* 🔹 first ARRIVED_UNLOADING within window */
          (SELECT h.updated_at
             FROM dispatch_status_history h
             JOIN m_bounds b
               ON h.updated_at >= b.start_ts
              AND h.updated_at  < b.end_ts
            WHERE h.dispatch_id = d.id
              AND h.status = 'ARRIVED_UNLOADING'
            ORDER BY h.updated_at ASC
            LIMIT 1) AS depot_arrival,

          /* 🔹 planned ETA only if in window */
          (SELECT CASE
                    WHEN d.estimated_arrival IS NOT NULL
                     AND d.estimated_arrival BETWEEN b.start_ts AND b.end_ts
                    THEN d.estimated_arrival
                    ELSE NULL
                  END
             FROM m_bounds b) AS planned_depot_arrival,

          /* 🔹 first UNLOADED/DELIVERED within window */
          (SELECT h.updated_at
             FROM dispatch_status_history h
             JOIN m_bounds b
               ON h.updated_at >= b.start_ts
              AND h.updated_at  < b.end_ts
            WHERE h.dispatch_id = d.id
              AND h.status IN ('UNLOADED','DELIVERED')
            ORDER BY h.updated_at ASC
            LIMIT 1) AS unloading_complete,

          /* 📍 latest location up to cutoff (no lower bound; only < end_ts) */
          (SELECT lh.location_name
             FROM location_history lh
             JOIN m_bounds b ON lh.event_time < b.end_ts
            WHERE lh.dispatch_id = d.id
            ORDER BY lh.event_time DESC
            LIMIT 1) AS last_loc_dispatch,

          /* 📍 driver-level fallback (latest up to cutoff) */
          (SELECT lh.location_name
             FROM location_history lh
             JOIN m_bounds b ON lh.event_time < b.end_ts
            WHERE lh.driver_id = d.driver_id
            ORDER BY lh.event_time DESC
            LIMIT 1) AS last_loc_driver

        FROM dispatches d
        LEFT JOIN transport_orders to_ ON to_.id = d.transport_order_id
        LEFT JOIN vehicles v           ON v.id  = d.vehicle_id
        WHERE d.delivery_date >= :plan_from
          AND d.delivery_date <  DATE_ADD(:plan_to, INTERVAL 1 DAY)
      ) t
      ORDER BY t.plan_date, t.dispatch_id
      """;

    MapSqlParameterSource params =
        new MapSqlParameterSource()
            .addValue("plan_from", planFrom)
            .addValue("plan_to", planTo)
            .addValue("from_ts", fromTs == null ? null : Timestamp.from(fromTs))
            .addValue("to_ts", toTs == null ? null : Timestamp.from(toTs))
            .addValue("to_extra_days", toExtraDays == null ? 2 : toExtraDays);

    return jdbc.query(
        sql,
        params,
        (rs, i) ->
            new DispatchDayReportRow(
                rs.getLong("dispatch_id"),
                rs.getObject("plan_date", LocalDate.class),
                rs.getString("truck_no"),
                rs.getString("truck_trip"),
                rs.getString("depot"),
                rs.getBigDecimal("number_of_pallets"),
                rs.getString("truck_type"),
                ts(rs, "factory_departure"),
                ts(rs, "depot_arrival"),
                ts(rs, "planned_depot_arrival"),
                ts(rs, "unloading_complete"),
                rs.getString("final_destination_text")));
  }

  private static Instant ts(ResultSet rs, String col) throws SQLException {
    Timestamp t = rs.getTimestamp(col);
    return t == null ? null : t.toInstant();
  }
}
