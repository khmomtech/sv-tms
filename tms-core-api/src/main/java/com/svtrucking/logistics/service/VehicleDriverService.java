
package com.svtrucking.logistics.service;

import com.svtrucking.logistics.dto.assignment.AssignmentRequest;
import com.svtrucking.logistics.dto.assignment.AssignmentResponse;
import com.svtrucking.logistics.dto.assignment.DriverWithAssignmentResponse;
import com.svtrucking.logistics.exception.BusinessException;
import com.svtrucking.logistics.exception.ResourceNotFoundException;
import com.svtrucking.logistics.model.Driver;
import com.svtrucking.logistics.model.Vehicle;
import com.svtrucking.logistics.model.VehicleDriver;
import com.svtrucking.logistics.repository.DriverRepository;
import com.svtrucking.logistics.repository.VehicleDriverRepository;
import com.svtrucking.logistics.repository.VehicleRepository;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDateTime;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.stream.Collectors;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.orm.ObjectOptimisticLockingFailureException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Isolation;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Slf4j
public class VehicleDriverService {
    private final VehicleDriverRepository assignmentRepository;
    private final DriverRepository driverRepository;
    private final VehicleRepository vehicleRepository;
    private final JdbcTemplate jdbcTemplate;

    @Value("${app.assignment.enforce-license-class:false}")
    private boolean enforceLicenseClass;

    @Value("${app.assignment.prevent-inactive-drivers:true}")
    private boolean preventInactiveDrivers;

    @Value("${app.assignment.prevent-maintenance-trucks:true}")
    private boolean preventMaintenanceTrucks;

    @Transactional(isolation = Isolation.READ_COMMITTED)
    public AssignmentResponse assignTruckToDriver(AssignmentRequest request, String adminUser) {
        log.info("Assignment request: driverId={}, vehicleId={}, adminUser={}", request.getDriverId(),
                request.getVehicleId(), adminUser);
        // Validate entities exist and are in valid state
        Driver driver = driverRepository.findById(request.getDriverId())
                .orElseThrow(() -> new ResourceNotFoundException("Driver not found: " + request.getDriverId()));
        Vehicle vehicle = vehicleRepository.findById(request.getVehicleId())
                .orElseThrow(() -> new ResourceNotFoundException("Vehicle not found: " + request.getVehicleId()));
        // Business rule validations
        validateDriverStatus(driver, request.getForceReassignment());
        validateTruckStatus(vehicle, request.getForceReassignment());
        validateLicenseCompatibility(driver, vehicle, request.getForceReassignment());
        // Check for duplicate active assignments (idempotency check)
        Optional<VehicleDriver> existing = assignmentRepository.findActiveByDriverId(request.getDriverId());
        if (existing.isPresent() && existing.get().getVehicle().getId().equals(request.getVehicleId())) {
            log.info("Assignment already exists and is active: {}", existing.get().getId());
            return toResponse(existing.get(), driver, vehicle);
        }
        try {
            // Revoke existing assignments (if any) within same transaction
            revokeExistingForDriver(request.getDriverId(), adminUser,
                    "Reassigned to vehicle " + vehicle.getLicensePlate());
            revokeExistingForTruck(request.getVehicleId(), adminUser, "Reassigned to driver " + driver.getName());
            // Create new assignment
            VehicleDriver assignment = new VehicleDriver();
            assignment.setDriver(driver);
            assignment.setVehicle(vehicle);
            assignment.setAssignedBy(adminUser);
            assignment.setReason(request.getReason());
            assignment.setAssignedAt(java.time.LocalDateTime.now());
            assignment.setCreatedAt(java.time.LocalDateTime.now());
            assignment = assignmentRepository.save(assignment);
            assignmentRepository.flush(); // Ensure constraints are checked immediately
            log.info("Successfully assigned vehicle {} ({}) to driver {} ({}) by {}", vehicle.getLicensePlate(),
                    vehicle.getId(), driver.getName(), driver.getId(), adminUser);
            return toResponse(assignment, driver, vehicle);
        } catch (DataIntegrityViolationException e) {
            log.error("Data integrity violation during assignment", e);
            throw new BusinessException("Assignment failed due to data constraint violation. Please retry.");
        } catch (ObjectOptimisticLockingFailureException e) {
            log.error("Concurrent modification detected during assignment", e);
            throw new BusinessException("Assignment was modified by another user. Please refresh and retry.");
        }
    }

    private void validateDriverStatus(Driver driver, Boolean forceReassignment) {
        if (preventInactiveDrivers && !Boolean.TRUE.equals(forceReassignment)) {
            if (driver.getStatus() != null
                    && driver.getStatus() != com.svtrucking.logistics.enums.DriverStatus.ONLINE) {
                throw new BusinessException(
                        "Driver " + driver.getName() + " is not active. Status: " + driver.getStatus());
            }
        }
    }

    private void validateTruckStatus(Vehicle vehicle, Boolean forceReassignment) {
        if (preventMaintenanceTrucks && !Boolean.TRUE.equals(forceReassignment)) {
            if (vehicle.getStatus() != null && ("MAINTENANCE".equalsIgnoreCase(vehicle.getStatus().name())
                    || "DECOMMISSIONED".equalsIgnoreCase(vehicle.getStatus().name()))) {
                throw new BusinessException(
                        "Vehicle " + vehicle.getLicensePlate() + " is not available. Status: " + vehicle.getStatus());
            }
        }
    }

    private void validateLicenseCompatibility(Driver driver, Vehicle vehicle, Boolean forceReassignment) {
        if (enforceLicenseClass && !Boolean.TRUE.equals(forceReassignment)) {
            String driverClass = driver.getLicenseClass();
            String requiredClass = vehicle.getRequiredLicenseClass();
            // Only validate if both fields are populated
            if (driverClass != null && requiredClass != null && !driverClass.trim().isEmpty()
                    && !requiredClass.trim().isEmpty()) {
                if (!driverClass.equalsIgnoreCase(requiredClass)) {
                    throw new BusinessException("Driver license class '" + driverClass
                            + "' does not match vehicle requirement '" + requiredClass + "'");
                }
                log.debug("License class validation passed: driver={}, required={}", driverClass, requiredClass);
            } else {
                log.debug("License class validation skipped - fields not populated (driver: {}, vehicle: {})",
                        driverClass, requiredClass);
            }
        }
    }

    public AssignmentResponse getDriverAssignment(Long driverId) {
        return assignmentRepository.findActiveByDriverId(driverId).map(this::toResponse).orElse(null);
    }

    public AssignmentResponse getTruckAssignment(Long vehicleId) {
        return assignmentRepository.findActiveByVehicleId(vehicleId).map(this::toResponse).orElse(null);
    }

    @Transactional
    public void revokeDriverAssignment(Long driverId, String adminUser, String reason) {
        revokeExistingForDriver(driverId, adminUser, reason);
    }

    private void revokeExistingForDriver(Long driverId, String adminUser, String reason) {
        assignmentRepository.findActiveByDriverId(driverId).ifPresent(existing -> {
            initializeVersion(existing);
            existing.setRevokedAt(LocalDateTime.now());
            existing.setRevokedBy(adminUser);
            existing.setRevokeReason(reason);
            assignmentRepository.save(existing);
            log.info("Revoked assignment for driver {} by {}: {}", driverId, adminUser, reason);
        });
    }

    private void revokeExistingForTruck(Long vehicleId, String adminUser, String reason) {
        assignmentRepository.findActiveByVehicleId(vehicleId).ifPresent(existing -> {
            initializeVersion(existing);
            existing.setRevokedAt(LocalDateTime.now());
            existing.setRevokedBy(adminUser);
            existing.setRevokeReason(reason);
            assignmentRepository.save(existing);
            log.info("Revoked assignment for vehicle {} by {}: {}", vehicleId, adminUser, reason);
        });
    }

    private void initializeVersion(VehicleDriver assignment) {
        // version is a primitive long — always 0L by default, no null check needed
    }

    private AssignmentResponse toResponse(VehicleDriver assignment) {
        Driver driver = assignment.getDriver();
        Vehicle vehicle = assignment.getVehicle();
        return toResponse(assignment, driver, vehicle);
    }

    private AssignmentResponse toResponse(VehicleDriver assignment, Driver driver, Vehicle vehicle) {
        final String driverFullName = driver != null ? driver.getFullName() : "Unknown Driver";
        final String driverFirstName = driver != null ? driver.getFirstName() : null;
        final String driverLastName = driver != null ? driver.getLastName() : null;
        return new AssignmentResponse(
                assignment.getId(),
                driver != null ? driver.getId() : null,
                driverFullName,
                driverFirstName,
                driverLastName,
                driver != null ? driver.getLicenseNumber() : null,
                vehicle != null ? vehicle.getId() : null,
                vehicle != null ? vehicle.getLicensePlate() : "Unknown Vehicle",
                vehicle != null ? vehicle.getModel() : null,
                formatLocalDateTime(assignment.getAssignedAt()),
                assignment.getAssignedBy(),
                assignment.getReason(),
                assignment.isActive(),
                formatLocalDateTime(assignment.getRevokedAt()),
                assignment.getRevokedBy(),
                assignment.getRevokeReason(),
                assignment.getVersion());
    }

    public long countActiveAssignments() {
        return assignmentRepository.findAllActive().size();
    }

    public List<AssignmentResponse> getAssignmentHistory(Long driverId, int limit) {
        // Get last N assignments for a driver (both active and revoked)
        return assignmentRepository.findAll().stream()
                .filter(a -> a.getDriver() != null && a.getDriver().getId().equals(driverId))
                .sorted((a, b) -> b.getAssignedAt().compareTo(a.getAssignedAt()))
                .limit(limit)
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public Map<String, Object> getAssignmentStats() {
        Map<String, Object> stats = new HashMap<>();
        List<VehicleDriver> active = assignmentRepository.findAllActive();
        stats.put("activeCount", active.size());
        stats.put("totalDriversAssigned", active.stream().map(a -> a.getDriver() != null ? a.getDriver().getId() : null)
                .filter(Objects::nonNull).distinct().count());
        stats.put("totalVehiclesAssigned",
                active.stream().map(a -> a.getVehicle() != null ? a.getVehicle().getId() : null)
                        .filter(Objects::nonNull).distinct().count());
        return stats;
    }

    private static final String ASSIGNMENT_BASE_SELECT = "SELECT vd.id, d.id AS driver_id, d.name AS driver_name, d.first_name AS driver_first_name, d.last_name AS driver_last_name, dl.license_number AS driver_license_number, "
            +
            "v.id AS vehicle_id, v.license_plate AS truck_plate, v.model AS truck_model, " +
            "vd.assigned_at, vd.assigned_by, vd.reason, " +
            "CASE WHEN vd.revoked_at IS NULL THEN TRUE ELSE FALSE END AS active, " +
            "vd.revoked_at, vd.revoked_by, vd.revoke_reason, vd.version ";
    private static final String ASSIGNMENT_BASE_FROM = "FROM vehicle_drivers vd " +
            "JOIN drivers d ON vd.driver_id = d.id " +
            "LEFT JOIN (" +
            "  SELECT dd.driver_id, dd.license_number " +
            "  FROM driver_documents dd " +
            "  JOIN (" +
            "    SELECT driver_id, MAX(updated_at) AS max_updated_at " +
            "    FROM driver_documents " +
            "    WHERE category = 'license' " +
            "    GROUP BY driver_id" +
            "  ) latest ON latest.driver_id = dd.driver_id AND latest.max_updated_at = dd.updated_at " +
            "  WHERE dd.category = 'license' " +
            ") dl ON dl.driver_id = d.id " +
            "JOIN vehicles v ON vd.vehicle_id = v.id ";

    @Transactional(readOnly = true)
    public List<AssignmentResponse> getAssignments(Long driverId, Long vehicleId, Boolean active, int limit) {
        int safeLimit = Math.min(Math.max(1, limit), 500);
        StringBuilder sql = new StringBuilder(ASSIGNMENT_BASE_SELECT + ASSIGNMENT_BASE_FROM + "WHERE 1=1");
        List<Object> params = new ArrayList<>();
        if (driverId != null) {
            sql.append(" AND vd.driver_id = ?");
            params.add(driverId);
        }
        if (vehicleId != null) {
            sql.append(" AND vd.vehicle_id = ?");
            params.add(vehicleId);
        }
        if (active != null) {
            if (active) {
                sql.append(" AND vd.revoked_at IS NULL");
            } else {
                sql.append(" AND vd.revoked_at IS NOT NULL");
            }
        }
        sql.append(" ORDER BY vd.assigned_at DESC LIMIT ?");
        params.add(safeLimit);
        return jdbcTemplate.query(
                sql.toString(),
                ps -> {
                    for (int i = 0; i < params.size(); i++) {
                        ps.setObject(i + 1, params.get(i));
                    }
                },
                this::mapAssignment);
    }

    @Transactional(readOnly = true)
    public Page<AssignmentResponse> getVehicleDriverHistory(
            Long vehicleId, int page, int size, String searchTerm, Boolean active) {
        int normalizedPage = Math.max(0, page);
        int normalizedSize = Math.max(1, size);
        StringBuilder whereClause = new StringBuilder("WHERE vd.vehicle_id = ?");
        List<Object> baseParams = new ArrayList<>();
        baseParams.add(vehicleId);
        if (searchTerm != null && !searchTerm.trim().isEmpty()) {
            String term = "%" + searchTerm.trim().toLowerCase() + "%";
            whereClause.append(
                    " AND (LOWER(d.name) LIKE ? OR LOWER(v.license_plate) LIKE ? OR LOWER(dl.license_number) LIKE ?)");
            baseParams.add(term);
            baseParams.add(term);
            baseParams.add(term);
        }
        if (active != null) {
            if (active) {
                whereClause.append(" AND vd.revoked_at IS NULL");
            } else {
                whereClause.append(" AND vd.revoked_at IS NOT NULL");
            }
        }
        long offset = (long) normalizedPage * normalizedSize;
        String selectSql = ASSIGNMENT_BASE_SELECT + ASSIGNMENT_BASE_FROM + whereClause
                + " ORDER BY vd.assigned_at DESC LIMIT ? OFFSET ?";
        String countSql = "SELECT COUNT(*) " + ASSIGNMENT_BASE_FROM + whereClause;
        List<Object> queryParams = new ArrayList<>(baseParams);
        queryParams.add(normalizedSize);
        queryParams.add(offset);

        List<AssignmentResponse> results = jdbcTemplate.query(
                selectSql,
                ps -> {
                    for (int i = 0; i < queryParams.size(); i++) {
                        ps.setObject(i + 1, queryParams.get(i));
                    }
                },
                this::mapAssignment);

        Long total = jdbcTemplate.queryForObject(countSql, baseParams.toArray(), Long.class);
        long totalCount = total != null ? total : 0L;
        return new PageImpl<>(results, PageRequest.of(normalizedPage, normalizedSize), totalCount);
    }

    private static final DateTimeFormatter ISO_DATE_TIME =
            DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'").withZone(ZoneOffset.UTC);

    private AssignmentResponse mapAssignment(ResultSet rs, int rowNum) throws SQLException {
        final String driverFullName = rs.getString("driver_name");
        final String driverFirstName = rs.getString("driver_first_name");
        final String driverLastName = rs.getString("driver_last_name");
        return new AssignmentResponse(
                rs.getLong("id"),
                rs.getLong("driver_id"),
                driverFullName,
                driverFirstName,
                driverLastName,
                rs.getString("driver_license_number"),
                rs.getLong("vehicle_id"),
                rs.getString("truck_plate"),
                rs.getString("truck_model"),
                formatDateTime(rs.getTimestamp("assigned_at")),
                rs.getString("assigned_by"),
                rs.getString("reason"),
                rs.getBoolean("active"),
                formatDateTime(rs.getTimestamp("revoked_at")),
                rs.getString("revoked_by"),
                rs.getString("revoke_reason"),
                rs.getLong("version"));
    }

    private String formatDateTime(java.sql.Timestamp timestamp) {
        if (timestamp == null) return null;
        return ISO_DATE_TIME.format(timestamp.toInstant());
    }

    private String formatLocalDateTime(LocalDateTime value) {
        if (value == null) return null;
        return ISO_DATE_TIME.format(value.atZone(ZoneOffset.UTC));
    }

    @Transactional(readOnly = true)
    public List<DriverWithAssignmentResponse> getAllDriversWithAssignments(int limit) {
        int safeLimit = Math.min(Math.max(1, limit), 500);
        String sql = """
                  SELECT d.id AS driver_id, d.name AS driver_name, dl.license_number,
                         latest_vd.vehicle_id AS assigned_vehicle_id, v.license_plate AS vehicle_plate,
                         latest_vd.active_assignment
                  FROM drivers d
                  LEFT JOIN (
                      SELECT dd.driver_id, dd.license_number
                      FROM driver_documents dd
                      JOIN (
                          SELECT driver_id, MAX(updated_at) AS max_updated_at
                          FROM driver_documents
                          WHERE category = 'license'
                          GROUP BY driver_id
                      ) latest ON latest.driver_id = dd.driver_id AND latest.max_updated_at = dd.updated_at
                      WHERE dd.category = 'license'
                  ) dl ON dl.driver_id = d.id
                  LEFT JOIN (
                      SELECT vd1.driver_id,
                             vd1.vehicle_id,
                             TRUE AS active_assignment
                      FROM vehicle_drivers vd1
                      JOIN (
                          SELECT driver_id, MAX(assigned_at) AS max_assigned_at
                          FROM vehicle_drivers
                          WHERE revoked_at IS NULL
                          GROUP BY driver_id
                      ) latest ON latest.driver_id = vd1.driver_id AND latest.max_assigned_at = vd1.assigned_at
                      WHERE vd1.revoked_at IS NULL
                  ) latest_vd ON latest_vd.driver_id = d.id
                  LEFT JOIN vehicles v ON latest_vd.vehicle_id = v.id
                  ORDER BY d.name
                  LIMIT ?
                """;
        return jdbcTemplate.query(sql, ps -> ps.setInt(1, safeLimit),
                (rs, rowNum) -> new DriverWithAssignmentResponse(
                rs.getLong("driver_id"),
                rs.getString("driver_name"),
                rs.getString("license_number"),
                rs.getObject("assigned_vehicle_id") != null ? rs.getLong("assigned_vehicle_id") : null,
                rs.getString("vehicle_plate"),
                rs.getBoolean("active_assignment")));
    }
}
