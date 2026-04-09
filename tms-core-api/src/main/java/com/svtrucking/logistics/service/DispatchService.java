package com.svtrucking.logistics.service;

import com.svtrucking.logistics.dto.DispatchDto;
import com.svtrucking.logistics.dto.DispatchStatusHistoryDto;
import com.svtrucking.logistics.dto.CustomerAddressDto;
import com.svtrucking.logistics.dto.OrderItemDto;
import com.svtrucking.logistics.dto.response.DispatchActionMetadata;
import com.svtrucking.logistics.enums.DispatchStatus;
import com.svtrucking.logistics.enums.DispatchApprovalStatus;
import com.svtrucking.logistics.enums.DispatchStatusChangeSource;
import com.svtrucking.logistics.enums.LoadingQueueStatus;
import com.svtrucking.logistics.enums.OrderStatus;
import com.svtrucking.logistics.enums.PreEntrySafetyStatus;
import com.svtrucking.logistics.exception.InvalidDispatchDataException;
import com.svtrucking.logistics.exception.ResourceNotFoundException;
import com.svtrucking.logistics.config.FeatureToggleConfig;
import com.svtrucking.logistics.enums.WarehouseCode;
import com.svtrucking.logistics.model.*;
import com.svtrucking.logistics.repository.*;
import com.svtrucking.logistics.security.AuthenticatedUserUtil;
import com.svtrucking.logistics.security.AuthorizationService;
import com.svtrucking.logistics.security.PermissionNames;
import com.svtrucking.logistics.validator.DispatchValidator;
import jakarta.persistence.criteria.JoinType;
import java.io.InputStream;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.YearMonth;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.Iterator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.function.Function;
import java.util.stream.Collectors;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.hibernate.Hibernate;
import org.hibernate.HibernateException;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.ss.usermodel.WorkbookFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.dao.InvalidDataAccessApiUsageException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.orm.jpa.JpaSystemException;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import com.svtrucking.logistics.enums.SafetyCheckStatus;
import com.svtrucking.logistics.dto.response.DispatchStatusUpdateResponse;
import com.svtrucking.logistics.workflow.DispatchStateMachine;
import com.svtrucking.logistics.metrics.DispatchMetricsService;
import java.util.Set;

@Slf4j
@Service
@RequiredArgsConstructor
public class DispatchService {
    @Autowired
    private DispatchRepository dispatchRepository;
    @Autowired
    private DriverRepository driverRepository;
    @Autowired
    private UserRepository userRepository;
    @Autowired
    private TransportOrderRepository transportOrderRepository;
    @Autowired
    private VehicleRepository vehicleRepository;
    @Autowired
    private DispatchValidator dispatchValidator;
    @Autowired
    private DispatchStatusHistoryRepository dispatchStatusHistoryRepository;
    @Autowired
    private UnloadProofRepository unloadProofRepository;
    @Autowired
    private DispatchItemRepository dispatchItemRepository;
    @Autowired
    private OrderItemRepository orderItemRepository;
    @Autowired
    private ItemRepository itemRepository;
    @Autowired
    private CustomerAddressRepository orderAddressRepository;
    @Autowired
    private CustomerRepository customerRepository;
    @Autowired
    private LoadProofRepository loadProofRepository;
    @Autowired
    private FileStorageService fileStorageService;
    @Autowired
    private SafetyCheckService safetyCheckService;
    @Autowired
    private DispatchStateMachine dispatchStateMachine;
    @Autowired
    private AuthenticatedUserUtil authUtil;
    @Autowired
    private LoadingQueueRepository loadingQueueRepository;
    @Autowired
    private FeatureToggleConfig featureToggleConfig;
    @Autowired
    private VehicleDriverRepository vehicleDriverRepository;
    @Autowired
    private DispatchWorkflowPolicyService dispatchWorkflowPolicyService;
    @Autowired
    private DispatchProofPolicyService dispatchProofPolicyService;
    @Autowired
    private DispatchFlowTemplateRepository dispatchFlowTemplateRepository;
    @Autowired
    private AuthorizationService authorizationService;
    @Autowired(required = false)
    private DispatchMetricsService dispatchMetricsService;
    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Value("${dispatch.autoAssignOnChangeTruck:false}")
    private boolean autoAssignOnChangeTruck;

    private String normalizeVehiclePlate(String raw) {
        if (raw == null) {
            return null;
        }
        String normalized = raw.replaceAll("[^A-Za-z0-9]", "").toLowerCase();
        return normalized.isEmpty() ? null : normalized;
    }

    private String normalizeLoadingType(String loadingTypeCode) {
        if (loadingTypeCode == null || loadingTypeCode.isBlank()) {
            return DispatchWorkflowPolicyService.DEFAULT_TEMPLATE_CODE;
        }
        return loadingTypeCode.trim().toUpperCase();
    }

    private String validateRequestedLoadingType(String loadingTypeCode) {
        String normalized = normalizeLoadingType(loadingTypeCode);
        if (!dispatchFlowTemplateRepository.existsByCodeIgnoreCaseAndActiveTrue(normalized)) {
            throw new InvalidDispatchDataException(
                    "loadingTypeCode",
                    "Unknown or inactive dispatch workflow template: " + normalized);
        }
        return normalized;
    }

    private Long resolveWorkflowVersionId(String loadingTypeCode) {
        Dispatch probe = new Dispatch();
        probe.setLoadingTypeCode(normalizeLoadingType(loadingTypeCode));
        return dispatchWorkflowPolicyService.resolveWorkflowVersionIdForDispatch(probe);
    }

    private Map<String, VehicleDriver> buildActiveVehicleDriverByPlateMap() {
        List<VehicleDriver> activeAssignments = vehicleDriverRepository
                .findAllActiveWithVehicleAndDriverOrderByAssignedAtDesc();
        Map<String, VehicleDriver> byPlate = new LinkedHashMap<>();
        for (VehicleDriver assignment : activeAssignments) {
            if (assignment.getVehicle() == null || assignment.getVehicle().getLicensePlate() == null) {
                continue;
            }
            String plateKey = normalizeVehiclePlate(assignment.getVehicle().getLicensePlate());
            if (plateKey == null) {
                continue;
            }
            byPlate.putIfAbsent(plateKey, assignment);
        }
        return byPlate;
    }

    private int logDuplicateActiveAssignmentWarnings(Map<String, VehicleDriver> selectedByPlate) {
        List<VehicleDriver> activeAssignments = vehicleDriverRepository
                .findAllActiveWithVehicleAndDriverOrderByAssignedAtDesc();
        Map<String, List<VehicleDriver>> groupedByPlate = new LinkedHashMap<>();
        for (VehicleDriver assignment : activeAssignments) {
            if (assignment.getVehicle() == null || assignment.getVehicle().getLicensePlate() == null) {
                continue;
            }
            String plateKey = normalizeVehiclePlate(assignment.getVehicle().getLicensePlate());
            if (plateKey == null) {
                continue;
            }
            groupedByPlate.computeIfAbsent(plateKey, ignored -> new ArrayList<>()).add(assignment);
        }

        int warnings = 0;
        for (Map.Entry<String, List<VehicleDriver>> entry : groupedByPlate.entrySet()) {
            List<VehicleDriver> assignments = entry.getValue();
            if (assignments.size() <= 1) {
                continue;
            }
            VehicleDriver selected = selectedByPlate.get(entry.getKey());
            if (selected == null) {
                continue;
            }
            List<String> ignored = assignments.stream()
                    .filter(a -> !Objects.equals(a.getId(), selected.getId()))
                    .map(a -> "assignmentId=" + a.getId() + ",driverId="
                            + (a.getDriver() != null ? a.getDriver().getId() : null))
                    .toList();
            log.warn(
                    "Multiple active vehicle assignments found for normalizedPlate={}; selected assignmentId={}, driverId={}, ignored=[{}]",
                    entry.getKey(),
                    selected.getId(),
                    selected.getDriver() != null ? selected.getDriver().getId() : null,
                    String.join("; ", ignored));
            warnings++;
        }
        return warnings;
    }

    @Transactional(transactionManager = "jpaTransactionManager")
    public DispatchDto changeDriver(Long dispatchId, Long newDriverId) {
        return changeDriver(dispatchId, newDriverId, false);
    }

    /**
     * Change driver with optional bypass for assignment validation.
     * If {@code bypassAssignmentCheck} is true or the caller is an admin, the
     * vehicle-driver
     * relationship check is skipped.
     */
    @Transactional(transactionManager = "jpaTransactionManager")
    public DispatchDto changeDriver(Long dispatchId, Long newDriverId, boolean bypassAssignmentCheck) {
        log.debug("Changing driver: dispatchId={}, newDriverId={}, bypass={}", dispatchId, newDriverId,
                bypassAssignmentCheck);

        Dispatch dispatch = dispatchRepository
                .findById(dispatchId)
                .orElseThrow(
                        () -> {
                            log.error("Dispatch not found: id={}", dispatchId);
                            return new ResourceNotFoundException("Dispatch not found");
                        });
        Driver driver = driverRepository
                .findById(newDriverId)
                .orElseThrow(
                        () -> {
                            log.error("Driver not found: id={}", newDriverId);
                            return new ResourceNotFoundException("Driver not found");
                        });

        // Only set the main driver for the dispatch; vehicle_drivers is not used for
        // dispatch assignment logic
        dispatch.setDriver(driver);
        dispatch.setUpdatedDate(LocalDateTime.now());

        Driver previousDriver = null;
        // capture previous driver before save for audit
        if (dispatch.getDriver() != null && !dispatch.getDriver().getId().equals(driver.getId())) {
            previousDriver = dispatch.getDriver();
        } else if (dispatch.getDriver() != null && dispatch.getDriver().getId().equals(driver.getId())) {
            previousDriver = null; // no change
        }

        Dispatch updated = dispatchRepository.save(dispatch);

        log.info("Changed driver: dispatchId={}, newDriverId={}, driverName={}", dispatchId, newDriverId,
                driver.getName());

        // If validation was bypassed (admin or explicit), create an audit/history entry
        if (bypassAssignmentCheck || isCallerAdmin()) {
            String prev = previousDriver != null ? (previousDriver.getId() + ":" + previousDriver.getName()) : "<none>";
            String remark = "Admin override: changed driver from " + prev + " to " + newDriverId + ":"
                    + driver.getName();
            saveStatusHistory(updated, updated.getStatus(), remark);
        }

        return DispatchDto.fromEntityWithDetails(updated);
    }

    @Transactional(transactionManager = "jpaTransactionManager")
    public DispatchDto createDispatch(DispatchDto dispatchDto) {
        if (dispatchDto.getDriverId() == null) {
            throw new InvalidDispatchDataException("driverId", "Driver is required");
        }

        String currentUsername = SecurityContextHolder.getContext().getAuthentication().getName();
        User currentUser = userRepository
                .findByUsername(currentUsername)
                .orElseThrow(
                        () -> {
                            log.error("User not found: {}", currentUsername);
                            return new ResourceNotFoundException("User not found: " + currentUsername);
                        });

        TransportOrder transportOrder = transportOrderRepository
                .findById(dispatchDto.getTransportOrderId())
                .orElseThrow(
                        () -> {
                            log.error(
                                    "Transport Order not found: id={}", dispatchDto.getTransportOrderId());
                            return new ResourceNotFoundException("Transport Order not found");
                        });
        Vehicle vehicle = vehicleRepository
                .findById(dispatchDto.getVehicleId())
                .orElseThrow(
                        () -> {
                            log.error("Vehicle not found: id={}", dispatchDto.getVehicleId());
                            return new ResourceNotFoundException("Vehicle not found");
                        });
        Driver driver = driverRepository
                .findById(dispatchDto.getDriverId())
                .orElseThrow(
                        () -> {
                            log.error("Driver not found: id={}", dispatchDto.getDriverId());
                            return new ResourceNotFoundException("Driver not found");
                        });

        // Planning/arranging dispatch should not be blocked by safety approval.
        // Safety is enforced later at operational transitions (e.g.
        // loading/in-transit).
        var eligibility = safetyCheckService.checkEligibility(driver.getId(), vehicle.getId(), null);
        if (!eligibility.isEligible()) {
            log.info(
                    "Dispatch plan created without approved safety yet: driverId={}, vehicleId={}, status={}, message={}",
                    driver.getId(),
                    vehicle.getId(),
                    eligibility.getStatus(),
                    eligibility.getMessage());
        }

        Dispatch dispatch = Dispatch.builder()
                .routeCode(
                        (dispatchDto.getManualRouteCode() != null
                                && !dispatchDto.getManualRouteCode().isBlank())
                                        ? dispatchDto.getManualRouteCode().trim()
                                        : generateRouteCode())
                .startTime(LocalDateTime.now())
                .estimatedArrival(
                        dispatchDto.getEstimatedArrival() != null
                                ? dispatchDto.getEstimatedArrival()
                                : LocalDateTime.now().plusHours(2))
                .status(DispatchStatus.PENDING)
                .loadingTypeCode(validateRequestedLoadingType(dispatchDto.getLoadingTypeCode()))
                .createdBy(currentUser)
                .transportOrder(transportOrder)
                .vehicle(vehicle)
                .driver(driver)
                .build();
        dispatch.setWorkflowVersionId(resolveWorkflowVersionId(dispatch.getLoadingTypeCode()));

        // Validate before saving
        // dispatchValidator.validateForCreate(dispatch);

        Dispatch savedDispatch = dispatchRepository.save(dispatch);
        log.info(
                "Created dispatch: id={}, routeCode={}, status={}",
                savedDispatch.getId(),
                savedDispatch.getRouteCode(),
                savedDispatch.getStatus());

        saveStatusHistory(savedDispatch, DispatchStatus.PENDING, "Initial creation");
        syncTransportOrderStatus(savedDispatch);
        return DispatchDto.fromEntityWithDetails(savedDispatch);
    }

    @Transactional(transactionManager = "jpaTransactionManager")
    public DispatchDto planTrip(
            Long orderId,
            String tripType,
            Long vehicleId,
            String scheduleTimeStr,
            String estimatedDropStr,
            String manualRouteCode) {

        TransportOrder transportOrder = transportOrderRepository
                .findById(orderId)
                .orElseThrow(() -> new ResourceNotFoundException("Transport order not found"));

        Vehicle vehicle = vehicleRepository
                .findById(vehicleId)
                .orElseThrow(() -> new ResourceNotFoundException("Vehicle not found"));

        String currentUsername = SecurityContextHolder.getContext().getAuthentication().getName();
        User currentUser = userRepository
                .findByUsername(currentUsername)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        LocalDateTime scheduleTime = LocalDateTime.parse(scheduleTimeStr);
        LocalDateTime estimatedDrop = LocalDateTime.parse(estimatedDropStr);

        String finalRouteCode = (manualRouteCode != null && !manualRouteCode.isEmpty())
                ? manualRouteCode
                : "T-" + System.currentTimeMillis();

        Dispatch dispatch = Dispatch.builder()
                .routeCode(finalRouteCode)
                .startTime(scheduleTime)
                .estimatedArrival(estimatedDrop)
                .status(DispatchStatus.PENDING)
                .loadingTypeCode(DispatchWorkflowPolicyService.DEFAULT_TEMPLATE_CODE)
                .tripType(tripType)
                .createdBy(currentUser)
                .transportOrder(transportOrder)
                .vehicle(vehicle)
                .build();
        dispatch.setWorkflowVersionId(resolveWorkflowVersionId(dispatch.getLoadingTypeCode()));

        Dispatch saved = dispatchRepository.save(dispatch);
        saveStatusHistory(saved, DispatchStatus.PENDING, "Trip PENDING");
        syncTransportOrderStatus(saved);
        return DispatchDto.fromEntityWithDetails(saved);
    }

    private String generateRouteCode() {
        YearMonth now = YearMonth.now();
        String prefix = "T-" + now.getYear() + "-" + "%02d".formatted(now.getMonthValue());
        String lastCode = dispatchRepository.findLastRouteCodeStartingWith(prefix).orElse(null);
        int next = 1;
        if (lastCode != null && lastCode.matches(prefix + "-\\d{6}")) {
            next = Integer.parseInt(lastCode.substring(lastCode.lastIndexOf("-") + 1)) + 1;
        }
        return prefix + "-" + "%06d".formatted(next);
    }

    // -------------------- CRUD + STATUS --------------------

    @Transactional(transactionManager = "jpaTransactionManager")
    public DispatchDto assignDispatch(Long dispatchId, Long driverId, Long vehicleId) {
        log.debug("Assigning dispatch: id={}, driverId={}, vehicleId={}", dispatchId, driverId, vehicleId);

        Dispatch dispatch = dispatchRepository
                .findById(dispatchId)
                .orElseThrow(
                        () -> {
                            log.error("Dispatch not found: id={}", dispatchId);
                            return new ResourceNotFoundException("Dispatch not found");
                        });
        ensureVersionInitialized(dispatch);
        Vehicle vehicle = vehicleRepository
                .findById(vehicleId)
                .orElseThrow(
                        () -> {
                            log.error("Vehicle not found: id={}", vehicleId);
                            return new ResourceNotFoundException("Vehicle not found");
                        });
        Driver driver = driverRepository
                .findById(driverId)
                .orElseThrow(
                        () -> {
                            log.error("Driver not found: id={}", driverId);
                            return new ResourceNotFoundException("Driver not found");
                        });

        // Validate driver and vehicle assignment
        dispatchValidator.validateDriverAssignment(driverId, dispatchId);
        dispatchValidator.validateVehicleAssignment(vehicleId, dispatchId);

        // No assignment check: vehicle_drivers is only for main driver of vehicle, not
        // for dispatch

        dispatch.setVehicle(vehicle);
        dispatch.setDriver(driver);
        dispatch.setStatus(DispatchStatus.ASSIGNED);
        dispatch.setPreEntrySafetyRequired(requiresPreEntrySafetyForDispatch(dispatch));
        dispatch.setPreEntrySafetyStatus(PreEntrySafetyStatus.NOT_STARTED);
        dispatch.setUpdatedDate(LocalDateTime.now());

        Dispatch updated = dispatchRepository.save(dispatch);
        log.info(
                "Assigned dispatch: id={}, driverId={}, vehicleId={}, status={}",
                dispatchId,
                driverId,
                vehicleId,
                updated.getStatus());

        saveStatusHistory(updated, DispatchStatus.ASSIGNED, "Assigned to vehicle and driver");
        syncTransportOrderStatus(updated);
        return DispatchDto.fromEntityWithDetails(updated);
    }

    private boolean requiresPreEntrySafetyForDispatch(Dispatch dispatch) {
        if (dispatch == null || featureToggleConfig == null) {
            return false;
        }

        final String warehouseCode = resolveDispatchWarehouseCode(dispatch);
        if (warehouseCode == null) {
            return false;
        }

        Set<String> requiredWarehouses = featureToggleConfig.getPreEntrySafetyRequiredWarehouses();
        if (requiredWarehouses == null || requiredWarehouses.isEmpty()) {
            return false;
        }

        final String normalizedWarehouse = normalizeWarehouseCode(warehouseCode);
        return requiredWarehouses.stream()
                .filter(Objects::nonNull)
                .map(this::normalizeWarehouseCode)
                .anyMatch(normalizedWarehouse::equals);
    }

    private String resolveDispatchWarehouseCode(Dispatch dispatch) {
        if (dispatch.getItems() != null) {
            for (DispatchItem dispatchItem : dispatch.getItems()) {
                if (dispatchItem == null || dispatchItem.getOrderItem() == null) {
                    continue;
                }
                String code = dispatchItem.getOrderItem().getWarehouse();
                if (code != null && !code.isBlank()) {
                    return code;
                }
            }
        }

        if (dispatch.getTransportOrder() != null && dispatch.getTransportOrder().getItems() != null) {
            for (OrderItem orderItem : dispatch.getTransportOrder().getItems()) {
                if (orderItem == null) {
                    continue;
                }
                String code = orderItem.getWarehouse();
                if (code != null && !code.isBlank()) {
                    return code;
                }
            }
        }

        return null;
    }

    private String normalizeWarehouseCode(String rawCode) {
        WarehouseCode code = WarehouseCode.from(rawCode);
        if (code != null) {
            return code.name();
        }
        return rawCode == null ? "" : rawCode.trim().toUpperCase();
    }

    @Transactional(transactionManager = "jpaTransactionManager")
    public DispatchDto updateDispatch(Long dispatchId, DispatchDto dispatchDetails) {
        Dispatch dispatch = dispatchRepository
                .findById(dispatchId)
                .orElseThrow(() -> new ResourceNotFoundException("Dispatch not found"));

        if (dispatchDetails.getStatus() != null
                && dispatchDetails.getStatus() != dispatch.getStatus()) {
            dispatch.setStatus(dispatchDetails.getStatus());
            dispatch.setUpdatedDate(LocalDateTime.now());
            Dispatch updated = persistDispatch(dispatch);
            saveStatusHistory(updated, dispatchDetails.getStatus(), "Status updated via API",
                    DispatchStatusChangeSource.NORMAL, null);
            syncTransportOrderStatus(updated);
            return buildDispatchPayloadSafely(updated);
        }
        if (dispatchDetails.getLoadingTypeCode() != null) {
            dispatch.setLoadingTypeCode(validateRequestedLoadingType(dispatchDetails.getLoadingTypeCode()));
            dispatch.setWorkflowVersionId(resolveWorkflowVersionId(dispatch.getLoadingTypeCode()));
            dispatch.setUpdatedDate(LocalDateTime.now());
            Dispatch updated = persistDispatch(dispatch);
            return DispatchDto.fromEntityWithDetails(updated);
        }
        return buildDispatchPayloadSafely(dispatch);
    }

    public DispatchDto updateDispatchStatus(Long dispatchId, DispatchStatus status) {
        log.debug("Updating dispatch status: id={}, newStatus={}", dispatchId, status);

        Dispatch dispatch = dispatchRepository
                .findById(dispatchId)
                .orElseThrow(
                        () -> {
                            log.error("Dispatch not found: id={}", dispatchId);
                            return new ResourceNotFoundException("Dispatch not found");
                        });

        if (status != null && status != dispatch.getStatus()) {
            validateDriverActionPrerequisites(dispatch, status);
            DispatchWorkflowPolicyService.TransitionCheck transitionCheck = dispatchWorkflowPolicyService
                    .evaluateTransition(dispatch, status);
            if (!transitionCheck.allowed()) {
                throw new InvalidDispatchDataException("status", transitionCheck.blockedReason());
            }

            DispatchStatus previousStatus = dispatch.getStatus();
            dispatch.setStatus(status);
            dispatch.setUpdatedDate(LocalDateTime.now());
            Dispatch updated;
            try {
                updated = persistDispatch(dispatch);
                saveStatusHistory(updated, status, "Manual status update",
                        DispatchStatusChangeSource.NORMAL, null);
                syncTransportOrderStatus(updated);
            } catch (InvalidDataAccessApiUsageException ex) {
                if (!isMissingTransaction(ex)) {
                    throw ex;
                }
                updated = persistDispatchStatusViaJdbc(
                        dispatch,
                        previousStatus,
                        status,
                        null,
                        "Manual status update",
                        DispatchStatusChangeSource.NORMAL,
                        null);
            }

            log.info(
                    "Updated dispatch status: id={}, oldStatus={}, newStatus={}",
                    dispatchId,
                    previousStatus,
                    status);
            return buildDispatchPayloadSafely(updated);
        }

        log.debug("No status change for dispatch: id={}, status={}", dispatchId, dispatch.getStatus());
        return buildDispatchPayloadSafely(dispatch);
    }

    public DispatchDto updateDispatchStatus(Long dispatchId, DispatchStatus status, String reason) {
        return updateDispatchStatus(dispatchId, status, reason, false);
    }

    public DispatchDto updateDispatchStatus(Long dispatchId, DispatchStatus status, String reason,
            boolean forceOverride) {
        log.debug("Updating dispatch status: id={}, newStatus={}, reason={}", dispatchId, status, reason);

        Dispatch dispatch = dispatchRepository
                .findById(dispatchId)
                .orElseThrow(
                        () -> {
                            log.error("Dispatch not found: id={}", dispatchId);
                            return new ResourceNotFoundException("Dispatch not found");
                        });

        if (status != null && status != dispatch.getStatus()) {
            if (forceOverride) {
                if (!authorizationService.hasPermission(PermissionNames.DISPATCH_STATUS_OVERRIDE)) {
                    throw new SecurityException("Override permission required for manual status override");
                }
                if (reason == null || reason.isBlank()) {
                    throw new InvalidDispatchDataException("reason", "Override reason is required");
                }
            } else {
                validateDriverActionPrerequisites(dispatch, status);
                DispatchWorkflowPolicyService.TransitionCheck transitionCheck = dispatchWorkflowPolicyService
                        .evaluateTransition(dispatch, status);
                if (!transitionCheck.allowed()) {
                    throw new InvalidDispatchDataException("status", transitionCheck.blockedReason());
                }
            }

            DispatchStatus previousStatus = dispatch.getStatus();
            dispatch.setStatus(status);
            dispatch.setUpdatedDate(LocalDateTime.now());
            String normalizedReason = (reason != null && !reason.isBlank())
                    ? reason.trim()
                    : (forceOverride
                            ? "Manual override status update"
                            : "Manual status update");
            Dispatch updated;
            try {
                updated = persistDispatch(dispatch);
                saveStatusHistory(
                        updated,
                        status,
                        normalizedReason,
                        forceOverride ? DispatchStatusChangeSource.OVERRIDE : DispatchStatusChangeSource.NORMAL,
                        forceOverride ? normalizedReason : null);
                syncTransportOrderStatus(updated);
            } catch (InvalidDataAccessApiUsageException ex) {
                if (!isMissingTransaction(ex)) {
                    throw ex;
                }
                updated = persistDispatchStatusViaJdbc(
                        dispatch,
                        previousStatus,
                        status,
                        dispatch.getCancelReason(),
                        normalizedReason,
                        forceOverride ? DispatchStatusChangeSource.OVERRIDE : DispatchStatusChangeSource.NORMAL,
                        forceOverride ? normalizedReason : null);
            }

            log.info(
                    "Updated dispatch status: id={}, oldStatus={}, newStatus={}, reason={}",
                    dispatchId,
                    previousStatus,
                    status,
                    reason);

            if (dispatchMetricsService != null) {
                dispatchMetricsService.recordTransition(previousStatus, status);
            }
            return buildDispatchPayloadSafely(updated);
        }

        log.debug("No status change for dispatch: id={}, status={}", dispatchId, dispatch.getStatus());
        return DispatchDto.fromEntityWithDetails(dispatch);
    }

    public DispatchStatusUpdateResponse updateDispatchStatusWithResponse(
            Long dispatchId,
            DispatchStatus status,
            String reason,
            Map<String, Object> metadata) {
        log.debug("Updating dispatch status with response: id={}, newStatus={}, reason={}",
                dispatchId, status, reason);

        Dispatch dispatch = dispatchRepository
                .findById(dispatchId)
                .orElseThrow(
                        () -> {
                            log.error("Dispatch not found: id={}", dispatchId);
                            return new ResourceNotFoundException("Dispatch not found");
                        });
        validateDriverOwnershipForMutation(dispatch, dispatchId);

        DispatchStatus previousStatus = dispatch.getStatus();

        if (status != null && status != dispatch.getStatus()) {
            validateDriverActionPrerequisites(dispatch, status);
            DispatchWorkflowPolicyService.TransitionCheck transitionCheck = dispatchWorkflowPolicyService
                    .evaluateTransition(dispatch, status);
            if (!transitionCheck.allowed()) {
                throw new InvalidDispatchDataException("status", transitionCheck.blockedReason());
            }

            dispatch.setStatus(status);
            dispatch.setUpdatedDate(LocalDateTime.now());
            Dispatch updated;
            try {
                updated = persistDispatch(dispatch);
                saveStatusHistory(
                        updated,
                        status,
                        reason != null ? reason : "Manual status update",
                        DispatchStatusChangeSource.NORMAL,
                        null);
                syncTransportOrderStatus(updated);
            } catch (InvalidDataAccessApiUsageException ex) {
                if (!isMissingTransaction(ex)) {
                    throw ex;
                }
                updated = persistDispatchStatusViaJdbc(
                        dispatch,
                        previousStatus,
                        status,
                        dispatch.getCancelReason(),
                        reason != null ? reason : "Manual status update",
                        DispatchStatusChangeSource.NORMAL,
                        null);
            }

            log.info(
                    "Updated dispatch status: id={}, oldStatus={}, newStatus={}, reason={}",
                    dispatchId,
                    previousStatus,
                    status,
                    reason);

            Dispatch responseDispatch = reloadDispatchForMutationResponse(updated.getId(), updated);

            // Build response with available next states from a fully reloaded dispatch.
            Set<DispatchStatus> nextStates = dispatchWorkflowPolicyService.getNextStatuses(responseDispatch);
            var actionMetadataList = enrichActionMetadataForDispatch(
                    responseDispatch,
                    dispatchWorkflowPolicyService.getAvailableActions(responseDispatch));
            var resolution = dispatchWorkflowPolicyService.resolveVersionedTemplate(responseDispatch);
            var template = resolution.template();

            return DispatchStatusUpdateResponse.builder()
                    .dispatchId(responseDispatch.getId())
                    .previousStatus(previousStatus)
                    .currentStatus(status)
                    .availableNextStates(new ArrayList<>(nextStates))
                    .availableActions(actionMetadataList)
                    .isTerminal(dispatchStateMachine.isTerminal(status))
                    .updatedAt(responseDispatch.getUpdatedDate())
                    .reason(reason)
                    .dispatch(buildDispatchPayloadSafely(responseDispatch))
                    .canPerformActions(true)
                    .loadingTypeCode(responseDispatch.getLoadingTypeCode())
                    .loadingTypeName(template != null ? template.getName() : null)
                    .workflowVersionId(responseDispatch.getWorkflowVersionId())
                    .resolvedWorkflowVersionId(resolution.workflowVersionId())
                    .build();
        }

        // No status change - still return current response with available actions
        Set<DispatchStatus> nextStates = dispatchWorkflowPolicyService.getNextStatuses(dispatch);
        var actionMetadataList = enrichActionMetadataForDispatch(
                dispatch,
                dispatchWorkflowPolicyService.getAvailableActions(dispatch));
        var resolution = dispatchWorkflowPolicyService.resolveVersionedTemplate(dispatch);
        var template = resolution.template();

        return DispatchStatusUpdateResponse.builder()
                .dispatchId(dispatch.getId())
                .previousStatus(previousStatus)
                .currentStatus(previousStatus)
                .availableNextStates(new ArrayList<>(nextStates))
                .availableActions(actionMetadataList)
                .isTerminal(dispatchStateMachine.isTerminal(previousStatus))
                .updatedAt(dispatch.getUpdatedDate())
                .reason(reason)
                .dispatch(buildDispatchPayloadSafely(dispatch))
                .canPerformActions(true)
                .loadingTypeCode(dispatch.getLoadingTypeCode())
                .loadingTypeName(template != null ? template.getName() : null)
                .workflowVersionId(dispatch.getWorkflowVersionId())
                .resolvedWorkflowVersionId(resolution.workflowVersionId())
                .build();
    }

    /**
     * Get available actions for a dispatch without changing status.
     * Used by mobile UI to dynamically display action buttons.
     * Returns response with available next states for the current dispatch status.
     * 
     * Enhanced in Phase 4 to include rich action metadata.
     * 
     * @param dispatchId Dispatch ID
     * @return Response with current status and available actions with metadata
     * @since Phase 2, enhanced Phase 4 - March 3, 2026
     */
    @Transactional(readOnly = true)
    public DispatchStatusUpdateResponse getAvailableActionsForDispatch(Long dispatchId) {
        log.debug("Fetching available actions for dispatch: id={}", dispatchId);

        Dispatch dispatch = dispatchRepository
                .findByIdWithActionDetails(dispatchId)
                .orElseThrow(
                        () -> {
                            log.error("Dispatch not found: id={}", dispatchId);
                            return new ResourceNotFoundException("Dispatch not found");
                        });

        DispatchStatus currentStatus = dispatch.getStatus();

        // Get next states (for backward compatibility)
        Set<DispatchStatus> nextStates = dispatchWorkflowPolicyService.getNextStatuses(dispatch);

        // Get rich action metadata (NEW in Phase 4)
        var actionMetadataList = enrichActionMetadataForDispatch(
                dispatch,
                dispatchWorkflowPolicyService.getAvailableActions(dispatch));

        // Check if current authenticated user can perform actions on this dispatch
        boolean canPerformActions = true;
        String restrictionMessage = null;

        try {
            // Get authenticated driver ID from JWT
            Long authenticatedDriverId = authUtil.getCurrentDriverId();

            // Check if dispatch is assigned to this driver
            Driver assignedDriver = dispatch.getDriver();
            if (assignedDriver != null && !assignedDriver.getId().equals(authenticatedDriverId)) {
                canPerformActions = false;
                restrictionMessage = "This dispatch is assigned to a different driver";
                log.warn("Driver {} attempted to access dispatch {} assigned to driver {}",
                        authenticatedDriverId, dispatchId, assignedDriver.getId());
            }
        } catch (Exception e) {
            log.warn("Could not verify driver authorization for dispatch {}: {}", dispatchId, e.getMessage());
            canPerformActions = false;
            restrictionMessage = "Authentication required";
        }

        var resolution = dispatchWorkflowPolicyService.resolveVersionedTemplate(dispatch);
        var template = resolution.template();
        return DispatchStatusUpdateResponse.builder()
                .dispatchId(dispatch.getId())
                .previousStatus(currentStatus)
                .currentStatus(currentStatus)
                .availableNextStates(new ArrayList<>(nextStates)) // Deprecated but kept for compatibility
                .availableActions(actionMetadataList) // NEW: Rich action metadata
                .isTerminal(nextStates.isEmpty())
                .updatedAt(dispatch.getUpdatedDate())
                .dispatch(buildDispatchPayloadSafely(dispatch))
                .canPerformActions(canPerformActions)
                .actionRestrictionMessage(restrictionMessage)
                .loadingTypeCode(dispatch.getLoadingTypeCode())
                .loadingTypeName(template != null ? template.getName() : null)
                .workflowVersionId(dispatch.getWorkflowVersionId())
                .resolvedWorkflowVersionId(resolution.workflowVersionId())
                .build();
    }

    /**
     * Get available actions for admin/operations screens without driver ownership
     * restrictions.
     */
    @Transactional(readOnly = true)
    public DispatchStatusUpdateResponse getAvailableActionsForDispatchAdmin(Long dispatchId) {
        log.debug("Fetching available actions (admin) for dispatch: id={}", dispatchId);

        Dispatch dispatch = dispatchRepository
                .findByIdWithActionDetails(dispatchId)
                .orElseThrow(
                        () -> {
                            log.error("Dispatch not found: id={}", dispatchId);
                            return new ResourceNotFoundException("Dispatch not found");
                        });

        DispatchStatus currentStatus = dispatch.getStatus();
        Set<DispatchStatus> nextStates = dispatchWorkflowPolicyService.getNextStatuses(dispatch);
        var actionMetadataList = enrichActionMetadataForDispatch(
                dispatch,
                dispatchWorkflowPolicyService.getAvailableActions(dispatch));
        var resolution = dispatchWorkflowPolicyService.resolveVersionedTemplate(dispatch);
        var template = resolution.template();

        return DispatchStatusUpdateResponse.builder()
                .dispatchId(dispatch.getId())
                .previousStatus(currentStatus)
                .currentStatus(currentStatus)
                .availableNextStates(new ArrayList<>(nextStates))
                .availableActions(actionMetadataList)
                .isTerminal(nextStates.isEmpty())
                .updatedAt(dispatch.getUpdatedDate())
                .dispatch(buildDispatchPayloadSafely(dispatch))
                .canPerformActions(true)
                .loadingTypeCode(dispatch.getLoadingTypeCode())
                .loadingTypeName(template != null ? template.getName() : null)
                .workflowVersionId(dispatch.getWorkflowVersionId())
                .resolvedWorkflowVersionId(resolution.workflowVersionId())
                .build();
    }

    private DispatchDto buildDispatchPayloadSafely(Dispatch dispatch) {
        if (dispatch == null) {
            return null;
        }
        try {
            return DispatchDto.fromEntity(dispatch);
        } catch (EntityNotFoundException | HibernateException | IllegalStateException ex) {
            log.warn("Failed to map dispatch payload for id={}. Falling back to base payload. cause={}",
                    dispatch.getId(), ex.getMessage());
            return DispatchDto.fromEntity(dispatch);
        } catch (RuntimeException ex) {
            log.error("Unexpected dispatch payload mapping failure for id={}. Returning base payload.",
                    dispatch.getId(), ex);
            return DispatchDto.fromEntity(dispatch);
        }
    }

    private List<DispatchActionMetadata> enrichActionMetadataForDispatch(
            Dispatch dispatch,
            List<DispatchActionMetadata> baseActions) {
        if (dispatch == null || baseActions == null || baseActions.isEmpty()) {
            return baseActions;
        }

        for (DispatchActionMetadata action : baseActions) {
            try {
                final DispatchStatus targetStatus = action.getTargetStatus();
                if (featureToggleConfig.isDispatchWorkflowEmergencyBypass()) {
                    action.setDriverInitiated(true);
                    action.setAllowedForCurrentUser(true);
                    action.setRequiresAdminApproval(false);
                    action.setRequiresInput(false);
                    action.setRequiredInput("NONE");
                    action.setInputRouteHint(null);
                    action.setBlockedCode(null);
                    action.setBlockedReason(null);
                    continue;
                }
                final ActionBlockInfo blockInfo = getActionBlockInfo(dispatch, targetStatus);
                final String blockMessage = blockInfo.message();
                if (action.getRequiredInput() == null || action.getRequiredInput().isBlank()) {
                    action.setRequiredInput(blockInfo.requiredInput());
                }
                if (action.getInputRouteHint() == null || action.getInputRouteHint().isBlank()) {
                    action.setInputRouteHint(blockInfo.inputRouteHint());
                }
                if (action.getBlockedCode() == null || action.getBlockedCode().isBlank()) {
                    action.setBlockedCode(blockInfo.code());
                }
                if (blockMessage != null && !blockMessage.isBlank()) {
                    action.setDriverInitiated(false);
                    action.setValidationMessage(blockMessage);
                    action.setAllowedForCurrentUser(false);
                    if (action.getBlockedReason() == null || action.getBlockedReason().isBlank()) {
                        action.setBlockedReason(blockMessage);
                    }
                }

                // LOADED should be completed via Proof of Loading (POL) submission endpoint.
                // Keep it driver-initiated so app can open input flow instead of patching
                // status.
                if (targetStatus == DispatchStatus.LOADED) {
                    action.setRequiresInput(true);
                    if (action.getRequiredInput() == null || action.getRequiredInput().isBlank()) {
                        action.setRequiredInput("POL");
                    }
                    if (action.getInputRouteHint() == null || action.getInputRouteHint().isBlank()) {
                        action.setInputRouteHint("LOAD_PROOF");
                    }
                }

                if (targetStatus == DispatchStatus.APPROVED) {
                    action.setRequiresAdminApproval(true);
                    if (action.getValidationMessage() == null || action.getValidationMessage().isBlank()) {
                        action.setValidationMessage("Waiting admin approval.");
                    }
                    action.setAllowedForCurrentUser(false);
                    if (action.getBlockedReason() == null || action.getBlockedReason().isBlank()) {
                        action.setBlockedReason("Waiting admin approval.");
                    }
                    action.setBlockedCode("ADMIN_APPROVAL_REQUIRED");
                }
            } catch (RuntimeException ex) {
                log.warn("Action metadata enrichment failed for dispatch id={}, targetStatus={}, cause={}",
                        dispatch != null ? dispatch.getId() : null,
                        action != null ? action.getTargetStatus() : null,
                        ex.getMessage());
                if (action != null) {
                    action.setDriverInitiated(false);
                    if (action.getValidationMessage() == null || action.getValidationMessage().isBlank()) {
                        action.setValidationMessage("Action temporarily unavailable.");
                    }
                }
            }
        }
        return baseActions;
    }

    private void validateDriverActionPrerequisites(Dispatch dispatch, DispatchStatus targetStatus) {
        final ActionBlockInfo blockInfo = getActionBlockInfo(dispatch, targetStatus);
        final String blockMessage = blockInfo.message();
        if (blockMessage != null && !blockMessage.isBlank()) {
            throw new InvalidDispatchDataException(
                    "status",
                    blockMessage,
                    blockInfo.code(),
                    blockInfo.requiredInput(),
                    blockInfo.nextAllowedAction());
        }
    }

    private String getActionBlockMessage(Dispatch dispatch, DispatchStatus targetStatus) {
        return getActionBlockInfo(dispatch, targetStatus).message();
    }

    private ActionBlockInfo getActionBlockInfo(Dispatch dispatch, DispatchStatus targetStatus) {
        if (dispatch == null || targetStatus == null) {
            return ActionBlockInfo.none();
        }

        if (featureToggleConfig.isDispatchWorkflowEmergencyBypass()) {
            log.warn(
                    "Emergency workflow bypass active: suppressing action block dispatchId={}, currentStatus={}, targetStatus={}",
                    dispatch.getId(),
                    dispatch.getStatus(),
                    targetStatus);
            return ActionBlockInfo.none();
        }

        if (targetStatus == DispatchStatus.APPROVED) {
            return new ActionBlockInfo(
                    "Waiting admin approval.",
                    "ADMIN_APPROVAL_REQUIRED",
                    "NONE",
                    null,
                    null);
        }

        if (targetStatus == DispatchStatus.IN_QUEUE) {
            if (dispatch.getStatus() != DispatchStatus.SAFETY_PASSED) {
                return new ActionBlockInfo(
                        "Safety check must pass before entering queue.",
                        "SAFETY_REQUIRED",
                        "NONE",
                        null,
                        null);
            }

            return ActionBlockInfo.none();
        }

        if (targetStatus == DispatchStatus.LOADING) {
            if (dispatch.getStatus() != DispatchStatus.IN_QUEUE) {
                return new ActionBlockInfo(
                        "Truck must be in queue before loading.",
                        "QUEUE_REQUIRED",
                        "NONE",
                        null,
                        null);
            }

            if (dispatch.getPreEntrySafetyRequired() != null
                    && dispatch.getPreEntrySafetyRequired()
                    && dispatch.getPreEntrySafetyStatus() != PreEntrySafetyStatus.PASSED) {
                return new ActionBlockInfo(
                        "Waiting pre-entry safety approval.",
                        "PRE_ENTRY_SAFETY_REQUIRED",
                        "NONE",
                        null,
                        null);
            }

            final LoadingQueueStatus queueStatus = loadingQueueRepository.findByDispatchId(dispatch.getId())
                    .map(LoadingQueue::getStatus)
                    .orElse(null);

            if (queueStatus == null || queueStatus == LoadingQueueStatus.WAITING) {
                return new ActionBlockInfo(
                        "Waiting warehouse call to loading bay.",
                        "WAREHOUSE_CALL_REQUIRED",
                        "NONE",
                        null,
                        null);
            }
        }

        if (targetStatus == DispatchStatus.LOADED) {
            var proofDecision = dispatchProofPolicyService.evaluateTransitionProofRequirement(dispatch, targetStatus);
            if (!proofDecision.allowed()) {
                String requiredInput = proofDecision.proofPolicy() != null
                        ? proofDecision.proofPolicy().getRequiredInputType()
                        : "POL";
                return new ActionBlockInfo(
                        proofDecision.blockedReason(),
                        proofDecision.blockedCode(),
                        requiredInput,
                        "POL".equalsIgnoreCase(requiredInput) ? "LOAD_PROOF" : null,
                        "LOAD_PROOF");
            }
            return ActionBlockInfo.none();
        }

        if (targetStatus == DispatchStatus.IN_TRANSIT && dispatch.getStatus() == DispatchStatus.LOADED) {
            var proofDecision = dispatchProofPolicyService.evaluateTransitionProofRequirement(dispatch, targetStatus);
            if (!proofDecision.allowed()) {
                return new ActionBlockInfo(
                        proofDecision.blockedReason(),
                        proofDecision.blockedCode(),
                        "POL",
                        "LOAD_PROOF",
                        "LOAD_PROOF");
            }
        }

        if (targetStatus == DispatchStatus.UNLOADED
                || targetStatus == DispatchStatus.DELIVERED
                || targetStatus == DispatchStatus.COMPLETED) {
            var proofDecision = dispatchProofPolicyService.evaluateTransitionProofRequirement(dispatch, targetStatus);
            if (!proofDecision.allowed()) {
                String requiredInput = proofDecision.proofPolicy() != null
                        ? proofDecision.proofPolicy().getRequiredInputType()
                        : "POD";
                return new ActionBlockInfo(
                        proofDecision.blockedReason(),
                        proofDecision.blockedCode(),
                        requiredInput,
                        "POD".equalsIgnoreCase(requiredInput) ? "UNLOAD_PROOF" : null,
                        "UNLOAD_PROOF");
            }
        }

        if (targetStatus == DispatchStatus.COMPLETED
                && dispatch.getApprovalStatus() != null
                && dispatch.getApprovalStatus() == DispatchApprovalStatus.PENDING_APPROVAL) {
            return new ActionBlockInfo(
                    "Waiting admin closure approval.",
                    "ADMIN_CLOSURE_APPROVAL_REQUIRED",
                    "NONE",
                    null,
                    null);
        }

        return ActionBlockInfo.none();
    }

    private record ActionBlockInfo(
            String message,
            String code,
            String requiredInput,
            String inputRouteHint,
            String nextAllowedAction) {
        private static ActionBlockInfo none() {
            return new ActionBlockInfo(null, null, "NONE", null, null);
        }
    }

    @Transactional(transactionManager = "jpaTransactionManager")
    public DispatchDto updateDispatchSafetyStatus(Long dispatchId, SafetyCheckStatus safetyStatus) {
        log.debug("Updating dispatch safety status: id={}, newSafety={}", dispatchId, safetyStatus);

        Dispatch dispatch = dispatchRepository
                .findById(dispatchId)
                .orElseThrow(
                        () -> {
                            log.error("Dispatch not found: id={}", dispatchId);
                            return new ResourceNotFoundException("Dispatch not found");
                        });

        if (safetyStatus != null && safetyStatus != dispatch.getSafetyStatus()) {
            dispatch.setSafetyStatus(safetyStatus);
            dispatch.setUpdatedDate(LocalDateTime.now());
            Dispatch updated = dispatchRepository.save(dispatch);

            // Audit history using legacy SAFETY_* markers for compatibility
            DispatchStatus historyStatus = safetyStatus == SafetyCheckStatus.PASSED ? DispatchStatus.SAFETY_PASSED
                    : DispatchStatus.SAFETY_FAILED;
            saveStatusHistory(updated, historyStatus, "Manual safety status update");

            return DispatchDto.fromEntityWithDetails(updated);
        }

        return DispatchDto.fromEntityWithDetails(dispatch);
    }

    @Transactional(transactionManager = "jpaTransactionManager")
    public void deleteDispatch(Long dispatchId) {
        log.debug("Deleting dispatch: id={}", dispatchId);
        dispatchStatusHistoryRepository.deleteByDispatchId(dispatchId);
        Dispatch dispatch = dispatchRepository
                .findById(dispatchId)
                .orElseThrow(
                        () -> {
                            log.error("Dispatch not found for deletion: id={}", dispatchId);
                            return new ResourceNotFoundException("Dispatch not found");
                        });

        dispatchRepository.delete(dispatch);
        log.warn("Deleted dispatch: id={}, routeCode={}", dispatchId, dispatch.getRouteCode());
    }

    @Transactional(transactionManager = "jpaTransactionManager")
    public void deleteDispatches(Collection<Long> dispatchIds) {
        if (dispatchIds == null || dispatchIds.isEmpty()) {
            log.warn("Bulk delete called with empty id list");
            return;
        }

        log.debug("Bulk deleting dispatches: ids={}", dispatchIds);
        dispatchStatusHistoryRepository.deleteByDispatchIdIn(dispatchIds);
        dispatchRepository.deleteAllByIdInBatch(dispatchIds);
        log.warn("Bulk deleted dispatches: ids={}", dispatchIds);
    }

    // -------------------- Reopen --------------------

    /**
     * Reopen a completed/delivered/closed dispatch for investigation.
     * Transitions: DELIVERED | CLOSED | COMPLETED → PENDING_INVESTIGATION.
     * Records an OVERRIDE history entry with admin-supplied reason.
     *
     * @param dispatchId Dispatch to reopen
     * @param reason     Mandatory reason (e.g. damage claim, customer complaint)
     * @return Updated dispatch DTO
     */
    @Transactional(transactionManager = "jpaTransactionManager")
    public DispatchDto reopenDispatch(Long dispatchId, String reason) {
        log.info("Reopening dispatch: dispatchId={}, reason={}", dispatchId, reason);

        Dispatch dispatch = dispatchRepository.findById(dispatchId)
                .orElseThrow(() -> new ResourceNotFoundException("Dispatch not found: " + dispatchId));

        Set<DispatchStatus> REOPENABLE = java.util.EnumSet.of(
                DispatchStatus.DELIVERED,
                DispatchStatus.CLOSED,
                DispatchStatus.COMPLETED);

        if (!REOPENABLE.contains(dispatch.getStatus())) {
            throw new InvalidDispatchDataException("status",
                    "Dispatch can only be reopened from DELIVERED, CLOSED, or COMPLETED. Current: "
                            + dispatch.getStatus());
        }

        dispatch.setStatus(DispatchStatus.PENDING_INVESTIGATION);
        dispatch.setUpdatedDate(LocalDateTime.now());
        Dispatch saved = dispatchRepository.save(dispatch);

        saveStatusHistory(
                saved,
                DispatchStatus.PENDING_INVESTIGATION,
                "Admin reopen: " + reason,
                DispatchStatusChangeSource.OVERRIDE,
                reason);

        syncTransportOrderStatus(saved);
        log.info("Dispatch reopened for investigation: dispatchId={}", dispatchId);
        return DispatchDto.fromEntityWithDetails(saved);
    }

    // -------------------- Breakdown --------------------

    /**
     * Record a vehicle breakdown reported by the driver mid-transit.
     * Validates that the calling driver owns the dispatch and it is IN_TRANSIT.
     * Transitions: IN_TRANSIT → IN_TRANSIT_BREAKDOWN.
     *
     * @param dispatchId  Dispatch to mark as broken down
     * @param location    Human-readable location description
     * @param description Details of the breakdown
     * @param lat         GPS latitude (optional)
     * @param lng         GPS longitude (optional)
     * @return Updated dispatch DTO
     */
    @Transactional(transactionManager = "jpaTransactionManager")
    public DispatchDto reportBreakdown(
            Long dispatchId,
            String location,
            String description,
            Double lat,
            Double lng) {
        log.info("Driver reporting breakdown: dispatchId={}, location={}", dispatchId, location);

        Dispatch dispatch = dispatchRepository.findById(dispatchId)
                .orElseThrow(() -> new ResourceNotFoundException("Dispatch not found: " + dispatchId));

        validateDriverOwnershipForMutation(dispatch, dispatchId);

        if (dispatch.getStatus() != DispatchStatus.IN_TRANSIT) {
            throw new InvalidDispatchDataException("status",
                    "Breakdown can only be reported when IN_TRANSIT. Current: " + dispatch.getStatus());
        }

        dispatch.setStatus(DispatchStatus.IN_TRANSIT_BREAKDOWN);
        dispatch.setUpdatedDate(LocalDateTime.now());
        Dispatch saved = dispatchRepository.save(dispatch);

        String remark = "Breakdown at " + location + ": " + description
                + (lat != null && lng != null ? " [" + lat + "," + lng + "]" : "");
        saveStatusHistory(saved, DispatchStatus.IN_TRANSIT_BREAKDOWN, remark);
        syncTransportOrderStatus(saved);

        log.warn("IN_TRANSIT_BREAKDOWN recorded: dispatchId={}, location={}", dispatchId, location);
        return DispatchDto.fromEntityWithDetails(saved);
    }

    // -------------------- Driver / Truck Change --------------------

    @Transactional(transactionManager = "jpaTransactionManager")
    public ChangeTruckResult changeTruck(Long dispatchId, Long newVehicleId) {
        log.debug("Changing truck: dispatchId={}, newVehicleId={}", dispatchId, newVehicleId);

        Dispatch dispatch = dispatchRepository
                .findById(dispatchId)
                .orElseThrow(
                        () -> {
                            log.error("Dispatch not found: id={}", dispatchId);
                            return new ResourceNotFoundException("Dispatch not found");
                        });
        ensureVersionInitialized(dispatch);
        Vehicle vehicle = vehicleRepository
                .findById(newVehicleId)
                .orElseThrow(
                        () -> {
                            log.error("Vehicle not found: id={}", newVehicleId);
                            return new ResourceNotFoundException("Vehicle not found");
                        });

        // Validate vehicle assignment — for changeTruck we prefer to record a warning
        // rather than abort the operation if validation fails (driver may be
        // unassigned).
        java.util.List<String> warnings = new java.util.ArrayList<>();
        try {
            dispatchValidator.validateVehicleAssignment(newVehicleId, dispatchId);
        } catch (InvalidDispatchDataException ex) {
            log.warn(
                    "Vehicle assignment validation failed for dispatch {} -> vehicle {}: {}. Proceeding and recording warning.",
                    dispatchId, newVehicleId, ex.getMessage());
            warnings.add(ex.getMessage());
        }

        dispatch.setVehicle(vehicle);
        dispatch.setUpdatedDate(LocalDateTime.now());
        // Preserve previous vehicle for history/audit
        Vehicle previousVehicle = dispatch.getVehicle();

        // No assignment check: vehicle_drivers is only for main driver of vehicle, not
        // for dispatch

        dispatch.setVehicle(vehicle);
        dispatch.setUpdatedDate(LocalDateTime.now());
        Dispatch updated = persistDispatch(dispatch);

        // Record change in dispatch history only
        String remark = previousVehicle != null
                ? String.format("Vehicle changed from %s (id=%d) to %s (id=%d)",
                        previousVehicle.getLicensePlate(), previousVehicle.getId(),
                        vehicle.getLicensePlate(), vehicle.getId())
                : String.format("Vehicle set to %s (id=%d)", vehicle.getLicensePlate(), vehicle.getId());
        saveStatusHistory(updated, DispatchStatus.ASSIGNED, remark);

        log.info("Changed vehicle: dispatchId={}, newVehicleId={}, licensePlate={}", dispatchId, newVehicleId,
                vehicle.getLicensePlate());
        // No auto-assignment: vehicle_drivers is only for main driver of vehicle

        return new ChangeTruckResult(DispatchDto.fromEntityWithDetails(updated), true, warnings);
    }

    // -------------------- Other Operations --------------------

    @Transactional(readOnly = true)
    public DispatchDto getDispatchById(Long id) {
        log.debug("Fetching dispatch: id={}", id);
        Dispatch dispatch = dispatchRepository
                .findById(id)
                .orElseThrow(
                        () -> {
                            log.error("Dispatch not found: id={}", id);
                            return new ResourceNotFoundException("Dispatch not found");
                        });
        log.info("Found dispatch: id={}, routeCode={}", id, dispatch.getRouteCode());
        return DispatchDto.fromEntityWithDetails(dispatch);
    }

    @Transactional(readOnly = true)
    public Page<DispatchDto> getAllDispatches(Pageable pageable) {
        log.debug("Fetching all dispatches: page={}, size={}", pageable.getPageNumber(), pageable.getPageSize());
        Pageable sortedPageable = pageable.getSort().isSorted()
                ? pageable
                : PageRequest.of(pageable.getPageNumber(), pageable.getPageSize(),
                        Sort.by(Sort.Direction.DESC, "startTime"));
        Page<Dispatch> page = dispatchRepository.findAll(sortedPageable);
        Page<DispatchDto> result = mapDispatchPage(page, DispatchDto::fromEntity);
        log.info("Retrieved {} dispatches (page {}/{})", result.getNumberOfElements(), result.getNumber(),
                result.getTotalPages());
        return result;
    }

    @Transactional(readOnly = true)
    public Page<DispatchDto> getAllDispatchesWithDetails(Pageable pageable) {
        log.debug("Fetching all dispatches with details: page={}, size={}", pageable.getPageNumber(),
                pageable.getPageSize());
        Pageable sortedPageable = pageable.getSort().isSorted()
                ? pageable
                : PageRequest.of(pageable.getPageNumber(), pageable.getPageSize(),
                        Sort.by(Sort.Direction.DESC, "startTime"));
        try {
            Page<Dispatch> detailsPage = dispatchRepository.findAllWithDetails(sortedPageable);
            Page<DispatchDto> result = mapDispatchPage(detailsPage, DispatchDto::fromEntityWithDetails);
            log.info("Retrieved {} dispatches with details (page {}/{})", result.getNumberOfElements(),
                    result.getNumber(),
                    result.getTotalPages());
            return result;
        } catch (JpaSystemException ex) {
            log.warn("Falling back to basic dispatch mapping due JPA detail fetch issue: {}", ex.getMessage());
            Page<Dispatch> fallbackPage = dispatchRepository.findAll(sortedPageable);
            Page<DispatchDto> fallback = mapDispatchPage(fallbackPage, DispatchDto::fromEntity);
            log.info("Retrieved {} dispatches via fallback mapping (page {}/{})",
                    fallback.getNumberOfElements(), fallback.getNumber(), fallback.getTotalPages());
            return fallback;
        }
    }

    @Transactional(readOnly = true)
    public Page<DispatchDto> filterDispatches(
            Long driverId,
            Long vehicleId,
            DispatchStatus status,
            LocalDateTime start,
            LocalDateTime end,
            Pageable pageable) {

        log.debug(
                "Filtering dispatches: driverId={}, vehicleId={}, status={}, start={}, end={}",
                driverId,
                vehicleId,
                status,
                start,
                end);

        Page<Dispatch> page = dispatchRepository.filterDispatches(driverId, vehicleId, status, start, end, pageable);
        Page<DispatchDto> result = mapDispatchPage(page, DispatchDto::fromEntityWithDetails);

        log.info("Filtered dispatches: found {} results", result.getTotalElements());
        return result;
    }

    @Transactional(readOnly = true)
    public Page<DispatchDto> getDispatchesByDriverIdWithDateRange(
            Long driverId, LocalDate startDate, LocalDate endDate, Pageable pageable) {
        log.debug(
                "Fetching dispatches by driver and date range: driverId={}, startDate={}, endDate={}",
                driverId,
                startDate,
                endDate);

        LocalDateTime from = startDate != null
                ? startDate.atStartOfDay()
                : LocalDate.now().withDayOfMonth(1).atStartOfDay();
        LocalDateTime to = endDate != null
                ? endDate.atTime(LocalTime.MAX)
                : LocalDate.now().withDayOfMonth(LocalDate.now().lengthOfMonth()).atTime(LocalTime.MAX);

        Page<Dispatch> rangePage = dispatchRepository.findByDriverIdAndStartTimeBetween(driverId, from, to, pageable);
        Page<DispatchDto> result = mapDispatchPage(rangePage, DispatchDto::fromEntityWithDetails);

        log.info(
                "Retrieved {} dispatches for driver {} between {} and {}",
                result.getTotalElements(),
                driverId,
                from,
                to);
        return result;
    }

    @Transactional(readOnly = true)
    public Page<DispatchDto> getDispatchesByDriverId(Long driverId, Pageable pageable) {
        log.debug("Fetching dispatches by driver: driverId={}", driverId);
        Page<Dispatch> driverPage = dispatchRepository.findByDriverId(driverId, pageable);
        Page<DispatchDto> result = mapDispatchPage(driverPage, DispatchDto::fromEntityWithDetails);
        log.info("Retrieved {} dispatches for driver: id={}", result.getTotalElements(), driverId);
        return result;
    }

    @Transactional(transactionManager = "jpaTransactionManager")
    public void markAsUnloaded(
            Long dispatchId,
            String remarks,
            String address,
            Double latitude,
            Double longitude,
            List<MultipartFile> images,
            MultipartFile signature) {
        Dispatch dispatch = dispatchRepository
                .findById(dispatchId)
                .orElseThrow(() -> new RuntimeException("Dispatch not found"));

        UnloadProof unloadProof = unloadProofRepository
                .findFirstByDispatchIdOrderBySubmittedAtDescIdDesc(dispatchId)
                .orElseGet(UnloadProof::new);
        unloadProof.setDispatch(dispatch);
        unloadProof.setRemarks(remarks);
        unloadProof.setAddress(address);
        unloadProof.setLatitude(latitude);
        unloadProof.setLongitude(longitude);
        unloadProof.setSubmittedAt(LocalDateTime.now());

        if (images != null && !images.isEmpty()) {
            List<String> imagePaths = new ArrayList<>();
            for (MultipartFile file : images) {
                imagePaths.add(fileStorageService.storeFile(file));
            }
            unloadProof.setProofImagePaths(imagePaths);
        }

        if (signature != null && !signature.isEmpty()) {
            unloadProof.setSignaturePath(fileStorageService.storeFile(signature));
        }

        unloadProofRepository.save(unloadProof);
        dispatch.setStatus(DispatchStatus.UNLOADED);
        dispatch.setUpdatedDate(LocalDateTime.now());
        dispatchRepository.save(dispatch);

        saveStatusHistory(dispatch, DispatchStatus.UNLOADED, "Unloaded at destination");
        syncTransportOrderStatus(dispatch);
    }

    // -------------------- Driver Response --------------------

    @Transactional(transactionManager = "jpaTransactionManager")
    public DispatchDto acceptDispatch(Long dispatchId) {
        log.debug("Driver accepting dispatch: id={}", dispatchId);

        Dispatch dispatch = dispatchRepository
                .findById(dispatchId)
                .orElseThrow(
                        () -> {
                            log.error("Dispatch not found: id={}", dispatchId);
                            return new ResourceNotFoundException("Dispatch not found");
                        });
        validateDriverOwnershipForMutation(dispatch, dispatchId);
        ensureVersionInitialized(dispatch);

        if (dispatch.getStatus() != DispatchStatus.ASSIGNED) {
            log.error(
                    "Invalid status for acceptance: dispatchId={}, currentStatus={}",
                    dispatchId,
                    dispatch.getStatus());
            throw new InvalidDispatchDataException(
                    "status", "Only ASSIGNED dispatches can be accepted. Current status: " + dispatch.getStatus());
        }

        DispatchStatus previousStatus = dispatch.getStatus();
        dispatch.setStatus(DispatchStatus.DRIVER_CONFIRMED);
        dispatch.setUpdatedDate(LocalDateTime.now());
        Dispatch updated;
        try {
            updated = persistDispatch(dispatch);
            saveStatusHistory(updated, DispatchStatus.DRIVER_CONFIRMED, "Driver accepted dispatch");
            syncTransportOrderStatus(updated);
        } catch (InvalidDataAccessApiUsageException ex) {
            if (!isMissingTransaction(ex)) {
                throw ex;
            }
            updated = persistDispatchStatusViaJdbc(
                    dispatch,
                    previousStatus,
                    DispatchStatus.DRIVER_CONFIRMED,
                    null,
                    "Driver accepted dispatch",
                    DispatchStatusChangeSource.NORMAL,
                    null);
        }

        log.info(
                "Driver accepted dispatch: id={}, driverId={}, status={}",
                dispatchId,
                dispatch.getDriver() != null ? dispatch.getDriver().getId() : null,
                updated.getStatus());

        return buildDispatchPayloadSafely(updated);
    }

    @Transactional(transactionManager = "jpaTransactionManager")
    public DispatchDto rejectDispatch(Long dispatchId, String reason) {
        log.debug("Driver rejecting dispatch: id={}, reason={}", dispatchId, reason);

        Dispatch dispatch = dispatchRepository
                .findById(dispatchId)
                .orElseThrow(
                        () -> {
                            log.error("Dispatch not found: id={}", dispatchId);
                            return new ResourceNotFoundException("Dispatch not found");
                        });
        validateDriverOwnershipForMutation(dispatch, dispatchId);
        ensureVersionInitialized(dispatch);

        if (dispatch.getStatus() != DispatchStatus.ASSIGNED) {
            log.error(
                    "Invalid status for rejection: dispatchId={}, currentStatus={}",
                    dispatchId,
                    dispatch.getStatus());
            throw new InvalidDispatchDataException(
                    "status", "Only ASSIGNED dispatches can be rejected. Current status: " + dispatch.getStatus());
        }

        // Validate cancellation
        dispatchValidator.validateForCancellation(dispatch, reason);

        DispatchStatus previousStatus = dispatch.getStatus();
        dispatch.setStatus(DispatchStatus.CANCELLED);
        dispatch.setCancelReason(reason);
        dispatch.setUpdatedDate(LocalDateTime.now());
        Dispatch updated;
        try {
            updated = persistDispatch(dispatch);
            saveStatusHistory(updated, DispatchStatus.CANCELLED, "Driver rejected dispatch: " + reason);
            syncTransportOrderStatus(updated);
        } catch (InvalidDataAccessApiUsageException ex) {
            if (!isMissingTransaction(ex)) {
                throw ex;
            }
            updated = persistDispatchStatusViaJdbc(
                    dispatch,
                    previousStatus,
                    DispatchStatus.CANCELLED,
                    reason,
                    "Driver rejected dispatch: " + reason,
                    DispatchStatusChangeSource.NORMAL,
                    null);
        }

        log.warn(
                "Driver rejected dispatch: id={}, driverId={}, reason={}",
                dispatchId,
                dispatch.getDriver() != null ? dispatch.getDriver().getId() : null,
                reason);

        return buildDispatchPayloadSafely(updated);
    }

    private void validateDriverOwnershipForMutation(Dispatch dispatch, Long dispatchId) {
        try {
            Long authenticatedDriverId = authUtil.getCurrentDriverId();
            Driver assignedDriver = dispatch.getDriver();
            if (assignedDriver != null && !assignedDriver.getId().equals(authenticatedDriverId)) {
                log.warn("Driver {} attempted to mutate dispatch {} assigned to driver {}",
                        authenticatedDriverId, dispatchId, assignedDriver.getId());
                throw new SecurityException("This dispatch is assigned to a different driver");
            }
        } catch (SecurityException e) {
            throw e;
        } catch (Exception e) {
            log.warn("Could not verify driver authorization for dispatch {}: {}", dispatchId, e.getMessage());
            throw new SecurityException("Authentication required");
        }
    }

    @Transactional(readOnly = true)
    public List<DispatchStatusHistoryDto> getStatusHistory(Long dispatchId) {
        log.debug("Fetching status history: dispatchId={}", dispatchId);
        List<DispatchStatusHistoryDto> history = dispatchStatusHistoryRepository
                .findByDispatchIdOrderByUpdatedAtAsc(dispatchId).stream()
                .map(DispatchStatusHistoryDto::fromEntity)
                .toList();
        log.info("Retrieved {} status history entries for dispatch: id={}", history.size(), dispatchId);
        return history;
    }

    private void saveStatusHistory(Dispatch dispatch, DispatchStatus status, String remarks) {
        saveStatusHistory(dispatch, status, remarks, DispatchStatusChangeSource.NORMAL, null);
    }

    private Dispatch persistDispatch(Dispatch dispatch) {
        Dispatch saved = dispatchRepository.saveAndFlush(dispatch);
        return reloadDispatchForMutationResponse(saved.getId(), saved);
    }

    private boolean isMissingTransaction(Throwable throwable) {
        Throwable cursor = throwable;
        while (cursor != null) {
            String message = cursor.getMessage();
            if (message != null && message.contains("no transaction is in progress")) {
                return true;
            }
            cursor = cursor.getCause();
        }
        return false;
    }

    private Dispatch persistDispatchStatusViaJdbc(
            Dispatch dispatch,
            DispatchStatus previousStatus,
            DispatchStatus newStatus,
            String cancelReason,
            String remarks,
            DispatchStatusChangeSource source,
            String overrideReason) {
        LocalDateTime now = LocalDateTime.now();
        int updatedRows = jdbcTemplate.update(
                """
                        UPDATE dispatches
                           SET status = ?,
                               updated_date = ?,
                               cancel_reason = ?,
                               version = COALESCE(version, 0) + 1
                         WHERE id = ?
                           AND status = ?
                        """,
                newStatus.name(),
                java.sql.Timestamp.valueOf(now),
                cancelReason,
                dispatch.getId(),
                previousStatus.name());
        if (updatedRows == 0) {
            throw new InvalidDispatchDataException(
                    "status",
                    "Dispatch status changed concurrently. Please refresh and try again.");
        }

        if (dispatch.getTransportOrder() != null) {
            OrderStatus currentOrderStatus = dispatch.getTransportOrder().getStatus();
            OrderStatus mappedStatus = mapDispatchStatusToOrderStatus(newStatus, currentOrderStatus);
            if (mappedStatus != null) {
                jdbcTemplate.update(
                        """
                                UPDATE transport_orders
                                   SET status = ?,
                                       version = COALESCE(version, 0) + 1
                                 WHERE id = ?
                                """,
                        mappedStatus.name(),
                        dispatch.getTransportOrder().getId());
            }
        }

        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String updatedBy = authentication != null ? authentication.getName() : "system";
        Long actorUserId = 0L;
        String actorRolesSnapshot = "SYSTEM";
        try {
            User currentUser = authUtil.getCurrentUser();
            actorUserId = currentUser.getId();
            actorRolesSnapshot = currentUser.getRoles() == null ? ""
                    : currentUser.getRoles().stream()
                            .filter(Objects::nonNull)
                            .map(Role::getName)
                            .filter(Objects::nonNull)
                            .map(Enum::name)
                            .sorted()
                            .collect(Collectors.joining(","));
        } catch (Exception ignored) {
            // Fallback to system audit values when no authenticated user is available.
        }

        jdbcTemplate.update(
                """
                        INSERT INTO dispatch_status_history
                            (dispatch_id, status, updated_by, actor_user_id, actor_roles_snapshot, source, override_reason, remarks, updated_at)
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                        """,
                dispatch.getId(),
                newStatus.name(),
                updatedBy,
                actorUserId,
                actorRolesSnapshot,
                (source != null ? source : DispatchStatusChangeSource.NORMAL).name(),
                overrideReason,
                remarks,
                java.sql.Timestamp.valueOf(now));

        return reloadDispatchForMutationResponse(dispatch.getId(), null);
    }

    private Dispatch reloadDispatchForMutationResponse(Long dispatchId, Dispatch fallback) {
        return dispatchRepository.findByIdWithActionDetails(dispatchId)
                .orElseGet(() -> dispatchRepository.findById(dispatchId).orElse(fallback));
    }

    private void saveStatusHistory(
            Dispatch dispatch,
            DispatchStatus status,
            String remarks,
            DispatchStatusChangeSource source,
            String overrideReason) {
        DispatchStatusHistory history = new DispatchStatusHistory();
        history.setDispatch(dispatch);
        history.setStatus(status);
        history.setRemarks(remarks);
        history.setUpdatedAt(LocalDateTime.now());
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        history.setUpdatedBy(authentication != null ? authentication.getName() : "system");
        history.setSource(source != null ? source : DispatchStatusChangeSource.NORMAL);
        history.setOverrideReason(overrideReason);
        try {
            User currentUser = authUtil.getCurrentUser();
            history.setActorUserId(currentUser.getId());
            String rolesSnapshot = currentUser.getRoles() == null ? ""
                    : currentUser.getRoles().stream()
                            .filter(Objects::nonNull)
                            .map(Role::getName)
                            .filter(Objects::nonNull)
                            .map(Enum::name)
                            .sorted()
                            .collect(Collectors.joining(","));
            history.setActorRolesSnapshot(rolesSnapshot);
        } catch (Exception ex) {
            // System/async context (scheduler, event handler) — use sentinel values
            // so audit rows are never stored with null actor fields.
            history.setActorUserId(0L);
            history.setActorRolesSnapshot("SYSTEM");
            log.debug("System context for status history actor: {}", ex.getMessage());
        }
        dispatchStatusHistoryRepository.save(history);
    }

    public DispatchDto assignDriverOnly(Long dispatchId, Long driverId) {
        Dispatch dispatch = dispatchRepository
                .findById(dispatchId)
                .orElseThrow(() -> new ResourceNotFoundException("Dispatch not found"));

        dispatch.setDriver(
                driverRepository
                        .findById(driverId)
                        .orElseThrow(() -> new ResourceNotFoundException("Driver not found")));

        boolean statusChanged = false;
        if (dispatch.getStatus() == DispatchStatus.PENDING) {
            dispatch.setStatus(DispatchStatus.ASSIGNED);
            statusChanged = true;
        }

        dispatch.setUpdatedDate(LocalDateTime.now());
        Dispatch updated = dispatchRepository.save(dispatch);

        if (statusChanged) {
            saveStatusHistory(updated, DispatchStatus.ASSIGNED, "Driver assigned");
            syncTransportOrderStatus(updated);
        }
        return DispatchDto.fromEntity(updated);
    }

    public DispatchDto assignNotifyDriverOnly(Long dispatchId) {
        Dispatch dispatch = dispatchRepository
                .findById(dispatchId)
                .orElseThrow(() -> new ResourceNotFoundException("Dispatch not found"));

        if (dispatch.getStatus() == DispatchStatus.PENDING) {
            dispatch.setStatus(DispatchStatus.ASSIGNED);
            dispatch.setUpdatedDate(LocalDateTime.now());
            Dispatch updated = dispatchRepository.save(dispatch);
            saveStatusHistory(updated, DispatchStatus.ASSIGNED, "Assigned (notify only)");
            syncTransportOrderStatus(updated);
            return DispatchDto.fromEntity(updated);
        }

        dispatch.setUpdatedDate(LocalDateTime.now());
        return DispatchDto.fromEntity(dispatchRepository.save(dispatch));
    }

    public DispatchDto assignTruckOnly(Long dispatchId, Long vehicleId) {
        Dispatch dispatch = dispatchRepository
                .findById(dispatchId)
                .orElseThrow(() -> new ResourceNotFoundException("Dispatch not found"));

        dispatch.setVehicle(
                vehicleRepository
                        .findById(vehicleId)
                        .orElseThrow(() -> new ResourceNotFoundException("Vehicle not found")));

        boolean statusChanged = false;
        if (dispatch.getStatus() == DispatchStatus.PENDING) {
            dispatch.setStatus(DispatchStatus.ASSIGNED);
            statusChanged = true;
        }

        dispatch.setUpdatedDate(LocalDateTime.now());
        // `version` is a primitive long (defaults to 0L); no null-check required.
        Dispatch updated = dispatchRepository.save(dispatch);

        if (statusChanged) {
            saveStatusHistory(updated, DispatchStatus.ASSIGNED, "Truck assigned");
            syncTransportOrderStatus(updated);
        }
        return DispatchDto.fromEntity(updated);
    }

    // -------------------- Import --------------------

    @Transactional(transactionManager = "jpaTransactionManager")
    public Map<String, Object> importBulkDispatchesFromExcel(
            MultipartFile file, boolean previewOnly) {
        Map<String, Object> result = new HashMap<>();
        List<Map<String, Object>> previewList = new ArrayList<>();
        List<String> errors = new ArrayList<>();
        int successCount = 0;
        int autoAssignedCount = 0;
        int unassignedCount = 0;

        Map<String, Dispatch> dispatchMap = new HashMap<>();
        Map<String, List<DispatchItem>> itemMap = new HashMap<>();
        Map<String, Vehicle> vehicleByNormalizedPlate = vehicleRepository.findAll().stream()
                .filter(v -> v.getLicensePlate() != null)
                .collect(Collectors.toMap(
                        v -> normalizeVehiclePlate(v.getLicensePlate()),
                        Function.identity(),
                        (first, second) -> first));
        Map<String, VehicleDriver> activeVehicleDriverByPlate = buildActiveVehicleDriverByPlateMap();

        User currentUser = userRepository
                .findByUsername("admin")
                .orElseThrow(() -> new RuntimeException("Admin user not found"));

        try (InputStream inputStream = file.getInputStream();
                Workbook workbook = WorkbookFactory.create(inputStream)) {

            Sheet sheet = workbook.getSheetAt(0);
            Iterator<Row> rowIterator = sheet.iterator();

            if (!rowIterator.hasNext()) {
                throw new IllegalArgumentException("Excel file is empty.");
            }

            Row headerRow = rowIterator.next();
            List<String> expectedHeaders = List.of(
                    "DeliveryDate",
                    "CustomerCode",
                    "TrackingNo",
                    "TruckNumber",
                    "TruckTripCount",
                    "FromDestination",
                    "ToDestination",
                    "Item",
                    "Qty",
                    "UoM",
                    "UoMPallet",
                    "LoadingPlace",
                    "Status");

            for (int i = 0; i < expectedHeaders.size(); i++) {
                String cellValue = getStringCellValue(headerRow.getCell(i));
                if (!expectedHeaders.get(i).equalsIgnoreCase(cellValue)) {
                    throw new IllegalArgumentException(
                            "Invalid header format at column "
                                    + (i + 1)
                                    + ". Expected: "
                                    + expectedHeaders.get(i)
                                    + " but found: "
                                    + cellValue);
                }
            }

            int rowNum = 1;
            while (rowIterator.hasNext()) {
                rowNum++;
                Row row = rowIterator.next();

                try {
                    String deliveryDateStr = getStringCellValue(row.getCell(0));
                    String customerCode = getStringCellValue(row.getCell(1));
                    String truckTripCount = getStringCellValue(row.getCell(2));
                    String truckNumber = getStringCellValue(row.getCell(3));
                    String truckTrip = getStringCellValue(row.getCell(4));
                    String fromDest = getStringCellValue(row.getCell(5));
                    String toDest = getStringCellValue(row.getCell(6));
                    String itemName = getStringCellValue(row.getCell(7));
                    Integer qty = getIntegerCellValue(row.getCell(8));
                    String uom = getStringCellValue(row.getCell(9));
                    Integer palletQty = getIntegerCellValue(row.getCell(10));
                    String loadingPlace = getStringCellValue(row.getCell(11));
                    String status = getStringCellValue(row.getCell(12));

                    if (truckTripCount == null || truckTripCount.isEmpty()) {
                        throw new IllegalArgumentException("Missing tracking number at row " + rowNum);
                    }

                    if (previewOnly) {
                        Map<String, Object> preview = new HashMap<>();
                        preview.put("truckTripCount", truckTripCount);
                        preview.put("truckNumber", truckNumber);
                        preview.put("deliveryDate", deliveryDateStr);
                        preview.put("customerCode", customerCode);
                        preview.put("status", status);
                        preview.put("item", itemName);
                        preview.put("qty", qty);
                        previewList.add(preview);
                        continue;
                    }

                    Dispatch dispatch = dispatchMap.get(truckTripCount);
                    if (dispatch == null) {
                        dispatch = new Dispatch();
                        dispatch.setTrackingNo(truckTripCount);
                        dispatch.setTruckTrip(truckTrip);
                        dispatch.setFromLocation(fromDest);
                        dispatch.setToLocation(toDest);
                        dispatch.setDeliveryDate(
                                LocalDate.parse(deliveryDateStr, DateTimeFormatter.ofPattern("yyyy-MM-dd")));
                        dispatch.setStatus(DispatchStatus.PENDING);
                        dispatch.setLoadingTypeCode(DispatchWorkflowPolicyService.DEFAULT_TEMPLATE_CODE);
                        dispatch.setWorkflowVersionId(resolveWorkflowVersionId(dispatch.getLoadingTypeCode()));
                        dispatch.setCreatedDate(LocalDateTime.now());
                        dispatch.setStartTime(LocalDateTime.now());

                        String normalizedTruckNumber = normalizeVehiclePlate(truckNumber);
                        Vehicle vehicle = normalizedTruckNumber != null
                                ? vehicleByNormalizedPlate.get(normalizedTruckNumber)
                                : null;
                        if (vehicle == null) {
                            throw new IllegalArgumentException("Vehicle not found: " + truckNumber);
                        }
                        dispatch.setVehicle(vehicle);
                        VehicleDriver activeAssignment = activeVehicleDriverByPlate.get(normalizedTruckNumber);
                        if (activeAssignment != null && activeAssignment.getDriver() != null) {
                            dispatch.setDriver(activeAssignment.getDriver());
                            dispatch.setStatus(DispatchStatus.ASSIGNED);
                            autoAssignedCount++;
                        } else {
                            unassignedCount++;
                        }

                        Customer customer = customerRepository
                                .findByCustomerCode(customerCode)
                                .orElseThrow(
                                        () -> new IllegalArgumentException("Customer not found: " + customerCode));
                        dispatch.setCustomer(customer);
                        dispatch.setCreatedBy(currentUser);

                        // Attach dummy transport order for now
                        CustomerAddress pickup = resolveFallbackImportAddress(2L, "Import Pickup");
                        CustomerAddress drop = resolveFallbackImportAddress(34L, "Import Drop");
                        TransportOrder to = TransportOrder.builder()
                                .orderReference("TO-" + truckTripCount)
                                .customer(customer)
                                .orderDate(dispatch.getDeliveryDate())
                                .deliveryDate(dispatch.getDeliveryDate())
                                .pickupAddress(pickup)
                                .dropAddress(drop)
                                .status(OrderStatus.PENDING)
                                .createdBy(currentUser)
                                .build();

                        to = transportOrderRepository.save(to);
                        dispatch.setTransportOrder(to);

                        dispatchMap.put(truckTripCount, dispatch);
                        itemMap.put(truckTripCount, new ArrayList<>());
                    }

                    DispatchItem item = new DispatchItem();
                    item.setItemName(itemName);
                    item.setQuantity(qty != null ? qty.doubleValue() : 0);
                    item.setUnitOfMeasurement(uom);
                    item.setPalletQty(palletQty);
                    item.setLoadingPlace(loadingPlace);
                    item.setDispatch(dispatch);
                    OrderItem linkedOrderItem = new OrderItem();
                    linkedOrderItem.setItem(resolveImportFallbackItem(itemName));
                    linkedOrderItem.setQuantity(qty != null ? qty.doubleValue() : 0);
                    linkedOrderItem.setUnitOfMeasurement((uom != null && !uom.isBlank()) ? uom : "PCS");
                    linkedOrderItem.setPalletType(palletQty != null ? palletQty.doubleValue() : 0);
                    linkedOrderItem.setFromDestination(fromDest);
                    linkedOrderItem.setToDestination(toDest);
                    linkedOrderItem.setWarehouse(loadingPlace);
                    linkedOrderItem.setTransportOrder(dispatch.getTransportOrder());
                    linkedOrderItem = orderItemRepository.save(linkedOrderItem);
                    item.setOrderItem(linkedOrderItem);

                    itemMap.get(truckTripCount).add(item);

                } catch (Exception e) {
                    errors.add("Row " + rowNum + ": " + e.getMessage());
                }
            }

            if (!previewOnly) {
                for (String truckTripCount : dispatchMap.keySet()) {
                    Dispatch dispatch = dispatchMap.get(truckTripCount);
                    List<DispatchItem> items = itemMap.get(truckTripCount);
                    dispatch.setItems(items);
                    dispatchRepository.save(dispatch);
                    successCount++;
                }
            }

            result.put("success", errors.isEmpty());
            result.put(
                    "message",
                    errors.isEmpty() ? " Dispatches imported successfully" : "Some rows failed to import");
            result.put("successCount", successCount);
            result.put("errors", errors);
            if (previewOnly) {
                result.put("previews", previewList);
            } else {
                int duplicateAssignmentWarnings = logDuplicateActiveAssignmentWarnings(activeVehicleDriverByPlate);
                log.info(
                        "Bulk dispatch import summary: rowsProcessed={}, dispatchesCreated={}, autoAssigned={}, unassigned={}, duplicateActivePlateWarnings={}",
                        Math.max(rowNum - 1, 0),
                        successCount,
                        autoAssignedCount,
                        unassignedCount,
                        duplicateAssignmentWarnings);
            }

        } catch (Exception e) {
            throw new RuntimeException("Failed to import dispatches: " + e.getMessage(), e);
        }

        return result;
    }

    private CustomerAddress resolveFallbackImportAddress(Long preferredId, String fallbackName) {
        return orderAddressRepository.findById(preferredId)
                .orElseGet(() -> orderAddressRepository.findAll(Sort.by(Sort.Direction.ASC, "id"))
                        .stream()
                        .findFirst()
                        .orElseGet(() -> {
                            CustomerAddress address = new CustomerAddress();
                            address.setName(fallbackName);
                            return orderAddressRepository.save(address);
                        }));
    }

    private Item resolveImportFallbackItem(String itemName) {
        final String fallbackCode = "_IMPORT_BULK_ITEM";
        return itemRepository.findByItemCode(fallbackCode).orElseGet(() -> {
            Item item = new Item();
            item.setItemCode(fallbackCode);
            item.setItemName((itemName != null && !itemName.isBlank()) ? itemName : "Import Bulk Item");
            item.setQuantity(1);
            item.setUnit("PCS");
            item.setStatus(1);
            return itemRepository.save(item);
        });
    }

    private String getStringCellValue(org.apache.poi.ss.usermodel.Cell cell) {
        if (cell == null)
            return null;
        cell.setCellType(org.apache.poi.ss.usermodel.CellType.STRING);
        return cell.getStringCellValue().trim();
    }

    private Integer getIntegerCellValue(org.apache.poi.ss.usermodel.Cell cell) {
        if (cell == null)
            return null;
        if (cell.getCellType() == org.apache.poi.ss.usermodel.CellType.NUMERIC) {
            return (int) cell.getNumericCellValue();
        } else {
            String val = cell.getStringCellValue().trim();
            return val.isEmpty() ? null : Integer.parseInt(val);
        }
    }

    private OrderItem convertToOrderItem(OrderItemDto dto) {
        OrderItem orderItem = new OrderItem();

        // Resolve Item by id or code and assign relation
        Item resolvedItem = null;
        if (dto.getItemId() != null) {
            resolvedItem = itemRepository
                    .findById(dto.getItemId())
                    .orElseThrow(
                            () -> new ResourceNotFoundException("Item not found: id=" + dto.getItemId()));
        } else if (dto.getItemCode() != null && !dto.getItemCode().isBlank()) {
            resolvedItem = itemRepository
                    .findByItemCode(dto.getItemCode())
                    .orElseThrow(
                            () -> new ResourceNotFoundException("Item not found: code=" + dto.getItemCode()));
        }
        if (resolvedItem != null) {
            orderItem.setItem(resolvedItem);
        }

        // Quantities and attributes
        orderItem.setQuantity(dto.getQuantity());
        if ((dto.getUnitOfMeasurement() == null || dto.getUnitOfMeasurement().isBlank())
                && resolvedItem != null) {
            orderItem.setUnitOfMeasurement(resolvedItem.getUnit());
        } else {
            orderItem.setUnitOfMeasurement(dto.getUnitOfMeasurement());
        }
        orderItem.setPalletType(dto.getPalletType());
        orderItem.setDimensions(dto.getDimensions());
        orderItem.setWeight(dto.getWeight());
        orderItem.setFromDestination(dto.getFromDestination());
        orderItem.setToDestination(dto.getToDestination());
        orderItem.setWarehouse(dto.getWarehouse());
        orderItem.setDepartment(dto.getDepartment());

        if (dto.getPickupAddress() != null) {
            orderItem.setPickupAddress(findOrCreateOrderAddress(dto.getPickupAddress(), null));
        }
        if (dto.getDropAddress() != null) {
            orderItem.setDropAddress(findOrCreateOrderAddress(dto.getDropAddress(), null));
        }
        return orderItem;
    }

    private CustomerAddress findOrCreateOrderAddress(CustomerAddressDto dto, TransportOrder order) {
        if (dto.getId() != null) {
            return orderAddressRepository
                    .findById(dto.getId())
                    .orElseThrow(
                            () -> new ResourceNotFoundException(
                                    "Customer Address with ID " + dto.getId() + " not found"));
        }
        CustomerAddress newAddress = convertToCustomerAddress(dto);
        return orderAddressRepository.save(newAddress);
    }

    private CustomerAddress convertToCustomerAddress(CustomerAddressDto dto) {
        CustomerAddress orderAddress = new CustomerAddress();
        orderAddress.setName(dto.getName());
        orderAddress.setAddress(dto.getAddress());
        orderAddress.setCity(dto.getCity());
        orderAddress.setCountry(dto.getCountry());
        orderAddress.setContactName(dto.getContactName());
        orderAddress.setContactPhone(dto.getContactPhone());
        orderAddress.setLongitude(dto.getLongitude());
        orderAddress.setLatitude(dto.getLatitude());
        orderAddress.setType("DROP");
        return orderAddress;
    }

    private User getAuthenticatedUser() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null
                || !authentication.isAuthenticated()
                || "anonymousUser".equals(authentication.getPrincipal())) {
            throw new UsernameNotFoundException("User is not authenticated!");
        }
        return userRepository
                .findByUsername(authentication.getName())
                .orElseThrow(() -> new UsernameNotFoundException("User not found"));
    }

    private Customer findCustomerById(Long customerId) {
        return customerRepository
                .findById(customerId)
                .orElseThrow(() -> new ResourceNotFoundException("Customer not found"));
    }

    /** Sync TransportOrder status based on current dispatch status. */
    private void syncTransportOrderStatus(Dispatch dispatch) {
        if (dispatch == null || dispatch.getTransportOrder() == null)
            return;

        TransportOrder order = dispatch.getTransportOrder();
        // version is a primitive int — always initialized, no null check needed
        OrderStatus currentOrderStatus = order.getStatus();
        OrderStatus mappedStatus = mapDispatchStatusToOrderStatus(dispatch.getStatus(), currentOrderStatus);
        if (mappedStatus != null && mappedStatus != currentOrderStatus) {
            order.setStatus(mappedStatus);
            try {
                transportOrderRepository.save(order);
            } catch (org.springframework.orm.ObjectOptimisticLockingFailureException ex) {
                log.warn(
                        "Optimistic lock conflict syncing TransportOrder status: orderId={}, dispatchStatus={} — concurrent update in progress",
                        order.getId(), dispatch.getStatus());
            }
        }
    }

    /**
     * No-op: version is a primitive long, always 0L by default — never null.
     */
    private void ensureVersionInitialized(Dispatch dispatch) {
        // primitive long cannot be null — nothing to do
    }

    private boolean isCallerAdmin() {
        var auth = org.springframework.security.core.context.SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !auth.isAuthenticated())
            return false;
        return auth.getAuthorities().stream()
                .map(a -> a.getAuthority() == null ? "" : a.getAuthority())
                .anyMatch(
                        s -> s.equalsIgnoreCase("ROLE_ADMIN") || s.equalsIgnoreCase("ADMIN")
                                || s.toUpperCase().contains("ADMIN"));
    }

    /**
     * Map DispatchStatus to OrderStatus according to business rules. Matches
     * DispatchStatus: PENDING,
     * ASSIGNED, DRIVER_CONFIRMED, ARRIVED_LOADING, LOADING, LOADED, IN_TRANSIT,
     * ARRIVED_UNLOADING,
     * UNLOADING, UNLOADED, DELIVERED, CANCELLED
     */
    private OrderStatus mapDispatchStatusToOrderStatus(
            DispatchStatus status, OrderStatus currentOrderStatus) {
        if (status == null)
            return currentOrderStatus;

        switch (status) {
            case PENDING:
                return OrderStatus.PENDING;
            case SCHEDULED:
                return OrderStatus.PENDING;
            case ASSIGNED:
                return OrderStatus.ASSIGNED;
            case DRIVER_CONFIRMED:
                return OrderStatus.DRIVER_CONFIRMED;
            case ARRIVED_LOADING:
                return OrderStatus.ARRIVED_LOADING;
            case LOADING:
                return OrderStatus.LOADING;
            case LOADED:
                return OrderStatus.LOADED;
            case SAFETY_PASSED:
                // Safety checks do not directly change transport order status.
                return null;
            case SAFETY_FAILED:
                // Safety failures should not alter transport order lifecycle here.
                return null;
            case IN_QUEUE:
                return OrderStatus.ARRIVED_LOADING;
            case IN_TRANSIT:
                return OrderStatus.IN_TRANSIT;
            case ARRIVED_UNLOADING:
                return OrderStatus.ARRIVED_UNLOADING;
            case UNLOADING:
                return OrderStatus.UNLOADING;
            case UNLOADED:
                return OrderStatus.UNLOADED;
            case DELIVERED:
                return OrderStatus.DELIVERED;
            case CANCELLED:
                return OrderStatus.CANCELLED;
            case AT_HUB:
            case HUB_LOADING:
            case IN_TRANSIT_BREAKDOWN:
            case PENDING_INVESTIGATION:
                return OrderStatus.IN_TRANSIT;
            case APPROVED:
                return OrderStatus.APPROVED;
            case REJECTED:
                return OrderStatus.REJECTED;
            case FINANCIAL_LOCKED:
                return OrderStatus.DELIVERED;
            case PLANNED:
                return OrderStatus.PENDING;
            case COMPLETED:
            case CLOSED:
                return OrderStatus.COMPLETED;
            default:
                return currentOrderStatus;
        }
    }

    private Page<DispatchDto> mapDispatchPage(
            Page<Dispatch> page, Function<Dispatch, DispatchDto> mapper) {
        List<Dispatch> dispatches = page.getContent();
        initializeLoadProofs(dispatches);
        initializeUnloadProofs(dispatches);
        List<DispatchDto> dtos = dispatches.stream().map(mapper).collect(Collectors.toList());
        return new PageImpl<>(dtos, page.getPageable(), page.getTotalElements());
    }

    private void initializeLoadProofs(Collection<Dispatch> dispatches) {
        if (dispatches == null || dispatches.isEmpty()) {
            return;
        }
        for (Dispatch dispatch : dispatches) {
            if (dispatch == null) {
                continue;
            }
            LoadProof proof = dispatch.getLoadProof();
            if (proof != null) {
                List<String> paths = proof.getProofImagePaths();
                if (paths != null) {
                    Hibernate.initialize(paths);
                    List<String> existing = paths.stream()
                            .filter(fileStorageService::existsPublicPath)
                            .collect(Collectors.toCollection(ArrayList::new));
                    if (existing.size() != paths.size()) {
                        log.warn(
                                "Dispatch {} has missing POL file references: total={}, existing={}",
                                dispatch.getId(),
                                paths.size(),
                                existing.size());
                    }
                    proof.setProofImagePaths(existing);
                }
                if (proof.getSignaturePath() != null
                        && !fileStorageService.existsPublicPath(proof.getSignaturePath())) {
                    log.warn("Dispatch {} has missing POL signature path: {}", dispatch.getId(), proof.getSignaturePath());
                    proof.setSignaturePath(null);
                }
            }
        }
    }

    private void initializeUnloadProofs(Collection<Dispatch> dispatches) {
        if (dispatches == null || dispatches.isEmpty()) {
            return;
        }
        for (Dispatch dispatch : dispatches) {
            if (dispatch == null) {
                continue;
            }
            try {
                UnloadProof proof = dispatch.getUnloadProof();
                if (proof != null) {
                    List<String> paths = proof.getProofImagePaths();
                    if (paths != null) {
                        Hibernate.initialize(paths);
                        List<String> existing = paths.stream()
                                .filter(fileStorageService::existsPublicPath)
                                .collect(Collectors.toCollection(ArrayList::new));
                        if (existing.size() != paths.size()) {
                            log.warn(
                                    "Dispatch {} has missing POD file references: total={}, existing={}",
                                    dispatch.getId(),
                                    paths.size(),
                                    existing.size());
                        }
                        proof.setProofImagePaths(existing);
                    }
                    if (proof.getSignaturePath() != null
                            && !fileStorageService.existsPublicPath(proof.getSignaturePath())) {
                        log.warn("Dispatch {} has missing POD signature path: {}", dispatch.getId(),
                                proof.getSignaturePath());
                        proof.setSignaturePath(null);
                    }
                }
            } catch (RuntimeException ex) {
                log.warn(
                        "Unload proof relation failed for dispatch {}. Falling back to canonical proof row. cause={}",
                        dispatch.getId(),
                        ex.getMessage());
                unloadProofRepository
                        .findFirstByDispatchIdOrderBySubmittedAtDescIdDesc(dispatch.getId())
                        .ifPresent(dispatch::setUnloadProof);
            }
        }
    }

    @Transactional(readOnly = true)
    public Page<DispatchDto> getDispatchesByDriverWithStatuses(
            Long driverId, List<DispatchStatus> statuses, Pageable pageable) {
        Pageable effective = ensureDefaultSort(pageable);
        Page<Dispatch> page;
        if (statuses == null || statuses.isEmpty()) {
            page = dispatchRepository.findByDriverId(driverId, effective);
        } else {
            page = dispatchRepository.findByDriverIdAndStatusIn(driverId, statuses, effective);
        }
        return mapDispatchPage(page, DispatchDto::fromEntityWithDetails);
    }

    private Pageable ensureDefaultSort(Pageable pageable) {
        if (pageable == null || !pageable.isPaged()) {
            return PageRequest.of(0, 20, Sort.by("startTime").descending());
        }
        if (pageable.getSort().isUnsorted()) {
            return PageRequest.of(
                    pageable.getPageNumber(), pageable.getPageSize(), Sort.by("startTime").descending());
        }
        return pageable;
    }

    @Transactional(readOnly = true)
    public Page<DispatchDto> filterDispatches(
            Long driverId,
            Long vehicleId,
            DispatchStatus status,
            String driverName,
            String routeCode,
            String q,
            String customerName,
            String destinationTo,
            String truckPlate,
            String tripNo,
            LocalDateTime start,
            LocalDateTime end,
            Pageable pageable) {

        Specification<Dispatch> spec = Specification.where(null);

        if (driverId != null) {
            spec = spec.and(
                    (root, cq, cb) -> cb.equal(root.join("driver", JoinType.LEFT).get("id"), driverId));
        }
        if (vehicleId != null) {
            spec = spec.and(
                    (root, cq, cb) -> cb.equal(root.join("vehicle", JoinType.LEFT).get("id"), vehicleId));
        }
        if (status != null) {
            spec = spec.and((root, cq, cb) -> cb.equal(root.get("status"), status));
        }
        if (driverName != null && !driverName.isBlank()) {
            String like = "%" + driverName.trim().toLowerCase() + "%";
            spec = spec.and(
                    (root, cq, cb) -> cb.like(cb.lower(root.join("driver", JoinType.LEFT).get("name")), like));
            // If Driver entity uses a different field, adjust here (e.g.,
            // firstName/lastName)
        }
        if (routeCode != null && !routeCode.isBlank()) {
            String like = "%" + routeCode.trim().toLowerCase() + "%";
            spec = spec.and((root, cq, cb) -> cb.like(cb.lower(root.get("routeCode")), like));
        }
        if (customerName != null && !customerName.isBlank()) {
            String like = "%" + customerName.trim().toLowerCase() + "%";
            spec = spec.and(
                    (root, cq, cb) -> cb.like(cb.lower(root.join("customer", JoinType.LEFT).get("name")), like));
        }
        if (destinationTo != null && !destinationTo.isBlank()) {
            String like = "%" + destinationTo.trim().toLowerCase() + "%";
            // Try transportOrder.dropAddress.name first; fall back to dispatch.toLocation
            // if needed
            spec = spec.and(
                    (root, cq, cb) -> cb.or(
                            cb.like(
                                    cb.lower(
                                            root.join("transportOrder", JoinType.LEFT)
                                                    .join("dropAddress", JoinType.LEFT)
                                                    .get("name")),
                                    like),
                            cb.like(cb.lower(root.get("toLocation")), like)));
        }
        if (truckPlate != null && !truckPlate.isBlank()) {
            String like = "%" + truckPlate.trim().toLowerCase() + "%";
            spec = spec.and(
                    (root, cq, cb) -> cb.like(cb.lower(root.join("vehicle", JoinType.LEFT).get("licensePlate")), like));
        }
        if (tripNo != null && !tripNo.isBlank()) {
            String like = "%" + tripNo.trim().toLowerCase() + "%";
            spec = spec.and(
                    (root, cq, cb) -> cb.like(
                            cb.lower(root.join("transportOrder", JoinType.LEFT).get("tripNo")), like));
        }

        if (start != null) {
            spec = spec.and((root, cq, cb) -> cb.greaterThanOrEqualTo(root.get("startTime"), start));
        }
        if (end != null) {
            spec = spec.and((root, cq, cb) -> cb.lessThanOrEqualTo(root.get("startTime"), end));
        }

        // Free-text 'q' across several useful fields
        if (q != null && !q.isBlank()) {
            String like = "%" + q.trim().toLowerCase() + "%";
            spec = spec.and(
                    (root, cq, cb) -> cb.or(
                            cb.like(cb.lower(root.get("routeCode")), like),
                            cb.like(cb.lower(root.join("driver", JoinType.LEFT).get("name")), like),
                            cb.like(
                                    cb.lower(root.join("vehicle", JoinType.LEFT).get("licensePlate")), like),
                            cb.like(
                                    cb.lower(root.join("transportOrder", JoinType.LEFT).get("tripNo")), like),
                            cb.like(cb.lower(root.join("customer", JoinType.LEFT).get("name")), like),
                            cb.like(cb.lower(root.get("toLocation")), like)));
        }

        Page<Dispatch> page = dispatchRepository.findAll(spec, pageable);
        return mapDispatchPage(page, DispatchDto::fromEntityWithDetails);
    }
}
