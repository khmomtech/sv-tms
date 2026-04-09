package com.svtrucking.logistics.service;

import jakarta.annotation.PostConstruct;
import java.sql.SQLException;
import java.util.Optional;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.jdbc.BadSqlGrammarException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

@Service
public class AuditRecordService {

  private static final Logger LOG = LoggerFactory.getLogger(AuditRecordService.class);

  private final JdbcTemplate jdbc;
  private final boolean auditBootstrapEnabled;

  public AuditRecordService(
      JdbcTemplate jdbc,
      @Value("${app.audit.bootstrap.enabled:false}") boolean auditBootstrapEnabled) {
    this.jdbc = jdbc;
    this.auditBootstrapEnabled = auditBootstrapEnabled;
  }

  @PostConstruct
  public void ensureAuditTablesExist() {
    if (!auditBootstrapEnabled) {
      LOG.info("Audit table bootstrap disabled; tables will be created lazily on first write");
      return;
    }
    try {
      createVehicleAuditTable();
      createDriverAuditTable();
    } catch (Exception ex) {
      // Already logging channel? let default logging handle
      LOG.warn("Unable to ensure audit tables exist: {}", ex.getMessage(), ex);
    }
  }

  private void createVehicleAuditTable() {
    jdbc.execute(
        "CREATE TABLE IF NOT EXISTS vehicle_audit (" +
            "id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, " +
            "vehicle_id BIGINT, " +
            "action VARCHAR(64), " +
            "payload_before JSON, " +
            "payload_after JSON, " +
            "created_by VARCHAR(128), " +
            "created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP" +
        ")"
    );
  }

  private void createDriverAuditTable() {
    jdbc.execute(
        "CREATE TABLE IF NOT EXISTS driver_audit (" +
            "id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, " +
            "driver_id BIGINT, " +
            "action VARCHAR(64), " +
            "payload_before JSON, " +
            "payload_after JSON, " +
            "created_by VARCHAR(128), " +
            "created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP" +
        ")"
    );
  }

  private boolean isMissingTable(BadSqlGrammarException ex, String tableName) {
    SQLException sqlEx = ex.getSQLException();
    if (sqlEx == null) {
      return false;
    }
    String sqlState = sqlEx.getSQLState();
    String message = sqlEx.getMessage();
    return "42S02".equals(sqlState) || (message != null && message.toLowerCase().contains(tableName.toLowerCase()));
  }

  public void recordDriverAudit(Long driverId, String action, String beforeJson, String afterJson, String createdBy) {
    try {
      jdbc.update(
          "INSERT INTO driver_audit(driver_id, action, payload_before, payload_after, created_by) VALUES (?,?,?,?,?)",
          driverId, action, Optional.ofNullable(beforeJson).orElse(null), Optional.ofNullable(afterJson).orElse(null), createdBy);
    } catch (BadSqlGrammarException ex) {
      if (isMissingTable(ex, "driver_audit")) {
        LOG.warn("driver_audit missing, recreating table and retrying insert");
        createDriverAuditTable();
        jdbc.update(
            "INSERT INTO driver_audit(driver_id, action, payload_before, payload_after, created_by) VALUES (?,?,?,?,?)",
            driverId, action, Optional.ofNullable(beforeJson).orElse(null), Optional.ofNullable(afterJson).orElse(null), createdBy);
      } else {
        throw ex;
      }
    }
  }

  public void recordVehicleAudit(Long vehicleId, String action, String beforeJson, String afterJson, String createdBy) {
    try {
      jdbc.update(
          "INSERT INTO vehicle_audit(vehicle_id, action, payload_before, payload_after, created_by) VALUES (?,?,?,?,?)",
          vehicleId, action, Optional.ofNullable(beforeJson).orElse(null), Optional.ofNullable(afterJson).orElse(null), createdBy);
    } catch (BadSqlGrammarException ex) {
      if (isMissingTable(ex, "vehicle_audit")) {
        LOG.warn("vehicle_audit missing, recreating table and retrying insert");
        createVehicleAuditTable();
        jdbc.update(
            "INSERT INTO vehicle_audit(vehicle_id, action, payload_before, payload_after, created_by) VALUES (?,?,?,?,?)",
            vehicleId, action, Optional.ofNullable(beforeJson).orElse(null), Optional.ofNullable(afterJson).orElse(null), createdBy);
      } else {
        throw ex;
      }
    }
  }
}
