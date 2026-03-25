package com.svtrucking.telematics.service;

import java.sql.Connection;
import java.sql.DatabaseMetaData;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

@Service
@Slf4j
public class PostgresLocationHistoryPartitionService {

    private static final DateTimeFormatter PARTITION_SUFFIX = DateTimeFormatter.ofPattern("yyyyMM");

    private final JdbcTemplate jdbcTemplate;

    @Value("${location.history.partitioning.enabled:true}")
    private boolean partitioningEnabled;

    @Value("${location.history.postgres.partition-maintenance.enabled:true}")
    private boolean maintenanceEnabled;

    @Value("${location.history.partitioning.months-ahead:2}")
    private int monthsAhead;

    @Value("${location.history.partitioning.retain-months:3}")
    private int retainMonths;

    public PostgresLocationHistoryPartitionService(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @Scheduled(
            fixedDelayString = "${location.history.postgres.partition-maintenance.interval-ms:3600000}",
            initialDelayString = "${location.history.postgres.partition-maintenance.interval-ms:3600000}")
    public void maintainPartitions() {
        if (!partitioningEnabled || !maintenanceEnabled || !isPostgres()) {
            return;
        }

        LocalDate firstOfCurrentMonth = LocalDate.now().withDayOfMonth(1);
        for (int i = 0; i <= Math.max(0, monthsAhead); i++) {
            ensureMonthlyPartition(firstOfCurrentMonth.plusMonths(i));
        }

        dropExpiredPartitions(firstOfCurrentMonth.minusMonths(Math.max(0, retainMonths)));
    }

    void ensureMonthlyPartition(LocalDate monthStart) {
        LocalDate nextMonth = monthStart.plusMonths(1);
        String partitionName = "location_history_" + monthStart.format(PARTITION_SUFFIX);
        String sql = String.format(
                """
                CREATE TABLE IF NOT EXISTS %s
                PARTITION OF location_history
                FOR VALUES FROM ('%s 00:00:00') TO ('%s 00:00:00')
                """,
                partitionName,
                monthStart,
                nextMonth);
        jdbcTemplate.execute(sql);
    }

    void dropExpiredPartitions(LocalDate keepFromMonth) {
        jdbcTemplate.query(
                """
                SELECT tablename
                FROM pg_tables
                WHERE schemaname = current_schema()
                  AND tablename LIKE 'location_history_%'
                  AND tablename <> 'location_history_default'
                """,
                rs -> {
                    String tableName = rs.getString(1);
                    String suffix = tableName.substring("location_history_".length());
                    if (suffix.length() != 6) {
                        return;
                    }
                    LocalDate month = LocalDate.parse(suffix + "01", DateTimeFormatter.BASIC_ISO_DATE);
                    if (month.isBefore(keepFromMonth)) {
                        jdbcTemplate.execute("DROP TABLE IF EXISTS " + tableName);
                        log.info("Dropped expired telematics partition {}", tableName);
                    }
                });
    }

    private boolean isPostgres() {
        try (Connection connection = jdbcTemplate.getDataSource().getConnection()) {
            DatabaseMetaData metaData = connection.getMetaData();
            return metaData.getDatabaseProductName().toLowerCase().contains("postgres");
        } catch (SQLException e) {
            log.warn("Unable to inspect telematics DB type for partition maintenance: {}", e.getMessage());
            return false;
        }
    }
}
