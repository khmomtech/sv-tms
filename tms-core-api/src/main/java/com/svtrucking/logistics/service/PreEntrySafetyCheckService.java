package com.svtrucking.logistics.service;

import com.svtrucking.logistics.config.FeatureToggleConfig;
import com.svtrucking.logistics.dto.PreEntrySafetyCheckDto;
import com.svtrucking.logistics.dto.LoadingSessionStartRequest;
import com.svtrucking.logistics.dto.request.PreEntrySafetyCheckSubmitRequest;
import com.svtrucking.logistics.dto.request.SafetyConditionalOverrideRequest;
import com.svtrucking.logistics.enums.DispatchStatus;
import com.svtrucking.logistics.enums.LoadingQueueStatus;
import com.svtrucking.logistics.enums.PreEntrySafetyStatus;
import com.svtrucking.logistics.enums.WarehouseCode;
import com.svtrucking.logistics.exception.InvalidDispatchDataException;
import com.svtrucking.logistics.exception.ResourceNotFoundException;
import com.svtrucking.logistics.model.Dispatch;
import com.svtrucking.logistics.model.DispatchStatusHistory;
import com.svtrucking.logistics.model.Driver;
import com.svtrucking.logistics.model.LoadingQueue;
import com.svtrucking.logistics.model.PreEntrySafetyCheck;
import com.svtrucking.logistics.model.PreEntrySafetyItem;
import com.svtrucking.logistics.model.PreEntrySafetyItem.SafetyCategory;
import com.svtrucking.logistics.model.PreEntrySafetyItem.SafetyItemStatus;
import com.svtrucking.logistics.model.User;
import com.svtrucking.logistics.model.Vehicle;
import com.svtrucking.logistics.repository.DispatchRepository;
import com.svtrucking.logistics.repository.DispatchStatusHistoryRepository;
import com.svtrucking.logistics.repository.DriverRepository;
import com.svtrucking.logistics.repository.LoadingQueueRepository;
import com.svtrucking.logistics.repository.PreEntrySafetyCheckRepository;
import com.svtrucking.logistics.repository.PreEntryCheckMasterItemRepository;
import com.svtrucking.logistics.repository.PreEntrySafetyItemRepository;
import com.svtrucking.logistics.repository.VehicleRepository;
import com.svtrucking.logistics.security.AuthenticatedUserUtil;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.stream.IntStream;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Service for Pre-Entry Safety Check workflow (Phase 3).
 * Handles gate-level safety inspections before warehouse arrival.
 * Enables conditional overrides for FAILED checks by supervisors.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class PreEntrySafetyCheckService {
    private static final String AUTO_CALL_REMARKS = "Auto-called after pre-entry PASS";
    private static final String AUTO_TRANSITION_NOTE = "Pre-entry safety PASSED -> auto transition to LOADING (KHB).";
    private static final String QUEUE_REQUIRED_TRANSITION_MESSAGE =
            "Queue entry required before pre-entry PASS can transition to loading.";
    private static final long MAX_UPLOAD_SIZE_BYTES = 5L * 1024 * 1024; // 5MB
    private static final Set<String> ALLOWED_IMAGE_TYPES = Set.of("image/jpeg", "image/jpg", "image/png", "image/webp");

    private final PreEntrySafetyCheckRepository safetyCheckRepository;
    private final PreEntryCheckMasterItemRepository preEntryCheckMasterItemRepository;
    private final PreEntrySafetyItemRepository safetyItemRepository;
    private final DispatchRepository dispatchRepository;
    private final VehicleRepository vehicleRepository;
    private final DriverRepository driverRepository;
    private final LoadingQueueRepository loadingQueueRepository;
    private final LoadingWorkflowService loadingWorkflowService;
    private final DispatchStatusHistoryRepository dispatchStatusHistoryRepository;
    private final FileStorageService fileStorageService;
    private final AuthenticatedUserUtil authenticatedUserUtil;
    private final FeatureToggleConfig featureToggleConfig;

    /**
     * Submit a new pre-entry safety check.
     * Called by field checkers at warehouse gate before vehicle enters.
     * 
     * @param request Pre-entry safety check request containing dispatch, vehicle,
     *                driver IDs and safety item details
     * @return Created safety check DTO
     * @throws ResourceNotFoundException    if dispatch/vehicle/driver not found
     * @throws InvalidDispatchDataException if safety check already exists
     */
    @Transactional
    public PreEntrySafetyCheckDto submitSafetyCheck(PreEntrySafetyCheckSubmitRequest request) {
        log.info("Submitting pre-entry safety check: dispatchId={}", request.getDispatchId());

        // Validate feature toggle
        if (!featureToggleConfig.isSafetyCheckBlockingEnabled()) {
            log.warn("Safety check blocking is disabled. Check will be recorded but not enforced.");
        }

        // Validate entities exist
        Dispatch dispatch = dispatchRepository.findById(request.getDispatchId())
                .orElseThrow(() -> new ResourceNotFoundException("Dispatch not found: " + request.getDispatchId()));

        Vehicle vehicle = vehicleRepository.findById(request.getVehicleId())
                .orElseThrow(() -> new ResourceNotFoundException("Vehicle not found: " + request.getVehicleId()));

        Driver driver = driverRepository.findById(request.getDriverId())
                .orElseThrow(() -> new ResourceNotFoundException("Driver not found: " + request.getDriverId()));

        // Check if safety check already exists
        safetyCheckRepository.findByDispatchId(request.getDispatchId()).ifPresent(existing -> {
            throw new InvalidDispatchDataException("dispatchId",
                    "Safety check already exists for dispatch: " + request.getDispatchId());
        });

        User currentUser = authenticatedUserUtil.getCurrentUser();

        // Create safety check
        PreEntrySafetyCheck safetyCheck = PreEntrySafetyCheck.builder()
                .dispatch(dispatch)
                .vehicle(vehicle)
                .driver(driver)
                .warehouseCode(request.getWarehouseCode())
                .status(PreEntrySafetyStatus.NOT_STARTED) // Will be determined after items
                .checkDate(LocalDate.now())
                .remarks(request.getRemarks())
                .checkedBy(currentUser)
                .checkedAt(LocalDateTime.now())
                .checkerSignaturePath(request.getCheckerSignatureUrl())
                .inspectionPhotos(request.getInspectionPhotoUrls())
                .build();

        PreEntrySafetyCheck savedCheck = safetyCheckRepository.save(safetyCheck);

        List<PreEntrySafetyItem> items = mapAndValidateItems(request, savedCheck);
        safetyItemRepository.saveAll(items);

        // Determine overall status based on items
        PreEntrySafetyStatus overallStatus = determineOverallStatus(items);
        savedCheck.setStatus(overallStatus);
        PreEntrySafetyCheck updatedCheck = safetyCheckRepository.save(savedCheck);

        // Update dispatch pre-entry safety status
        dispatch.setPreEntrySafetyStatus(overallStatus);
        dispatchRepository.save(dispatch);

        boolean autoTransitionApplied = false;
        String transitionMessage = null;
        if (overallStatus == PreEntrySafetyStatus.PASSED) {
            AutoTransitionResult transitionResult = autoTransitionToLoadingIfEligible(dispatch, request.getWarehouseCode());
            autoTransitionApplied = transitionResult.applied();
            transitionMessage = transitionResult.message();
        }

        Dispatch dispatchAfterCheck = dispatchRepository.findById(dispatch.getId()).orElse(dispatch);
        PreEntrySafetyCheckDto responseDto = PreEntrySafetyCheckDto.from(updatedCheck);
        responseDto.setDispatchStatusAfterCheck(dispatchAfterCheck.getStatus() != null ? dispatchAfterCheck.getStatus().name() : null);
        responseDto.setAutoTransitionApplied(autoTransitionApplied);
        responseDto.setTransitionMessage(transitionMessage);

        log.info("Created pre-entry safety check: id={}, dispatchId={}, status={}, itemCount={}",
                updatedCheck.getId(), request.getDispatchId(), overallStatus, items.size());

        // Log warning if FAILED and blocking is enabled
        if (overallStatus == PreEntrySafetyStatus.FAILED && featureToggleConfig.isSafetyCheckBlockingEnabled()) {
            log.warn("FAILED safety check submitted. Dispatch will be blocked from queue entry: dispatchId={}",
                    request.getDispatchId());
        }

        return responseDto;
    }

    private AutoTransitionResult autoTransitionToLoadingIfEligible(Dispatch dispatch, String requestedWarehouseCode) {
        if (dispatch.getStatus() != DispatchStatus.IN_QUEUE) {
            return new AutoTransitionResult(false,
                    String.format("Pre-entry PASSED. Dispatch remains %s; auto-transition requires IN_QUEUE.",
                            dispatch.getStatus()));
        }

        LoadingQueue queue = loadingQueueRepository.findByDispatchId(dispatch.getId())
                .orElseThrow(() -> new IllegalStateException(QUEUE_REQUIRED_TRANSITION_MESSAGE));

        String effectiveWarehouseCode = requestedWarehouseCode;
        if ((effectiveWarehouseCode == null || effectiveWarehouseCode.isBlank()) && queue.getWarehouseCode() != null) {
            effectiveWarehouseCode = queue.getWarehouseCode().name();
        }

        if (!isAutoTransitionWarehouse(effectiveWarehouseCode)) {
            return new AutoTransitionResult(false,
                    "Pre-entry PASSED. Auto-transition to LOADING is not enabled for this warehouse.");
        }

        if (queue.getStatus() == LoadingQueueStatus.WAITING) {
            loadingWorkflowService.callToBay(queue.getId(), queue.getBay(), AUTO_CALL_REMARKS);
        } else if (queue.getStatus() != LoadingQueueStatus.CALLED && queue.getStatus() != LoadingQueueStatus.LOADING) {
            throw new IllegalStateException("Cannot auto transition to loading from queue status: " + queue.getStatus());
        }

        LoadingSessionStartRequest startRequest = new LoadingSessionStartRequest();
        startRequest.setDispatchId(dispatch.getId());
        startRequest.setQueueId(queue.getId());
        startRequest.setWarehouseCode(resolveWarehouseCode(effectiveWarehouseCode, queue));
        startRequest.setBay(queue.getBay());
        startRequest.setRemarks(AUTO_TRANSITION_NOTE);
        loadingWorkflowService.startLoading(startRequest);
        appendAutoTransitionHistory(dispatch);

        return new AutoTransitionResult(true, "Pre-entry passed, moved to LOADING.");
    }

    private WarehouseCode resolveWarehouseCode(String warehouseCode, LoadingQueue queue) {
        WarehouseCode resolvedFromRequest = WarehouseCode.from(warehouseCode);
        if (resolvedFromRequest != null) {
            return resolvedFromRequest;
        }
        return queue.getWarehouseCode();
    }

    private boolean isAutoTransitionWarehouse(String warehouseCode) {
        if (warehouseCode == null || warehouseCode.isBlank()) {
            return false;
        }
        String normalized = normalizeWarehouseCode(warehouseCode);
        Set<String> configured = featureToggleConfig.getPreEntrySafetyRequiredWarehouses();
        if (configured == null || configured.isEmpty()) {
            return "KHB".equals(normalized);
        }
        return configured.stream()
                .filter(code -> code != null && !code.isBlank())
                .map(this::normalizeWarehouseCode)
                .anyMatch(normalized::equals);
    }

    private String normalizeWarehouseCode(String warehouseCode) {
        WarehouseCode parsed = WarehouseCode.from(warehouseCode);
        if (parsed != null) {
            return parsed.name();
        }
        return warehouseCode.trim().toUpperCase();
    }

    private void appendAutoTransitionHistory(Dispatch dispatch) {
        DispatchStatusHistory history = new DispatchStatusHistory();
        history.setDispatch(dispatch);
        history.setStatus(DispatchStatus.LOADING);
        history.setRemarks(AUTO_TRANSITION_NOTE);
        history.setUpdatedAt(LocalDateTime.now());
        history.setUpdatedBy(resolveCurrentUsername());
        dispatchStatusHistoryRepository.save(history);
    }

    private String resolveCurrentUsername() {
        try {
            User user = authenticatedUserUtil.getCurrentUser();
            return user != null && user.getUsername() != null ? user.getUsername() : "system";
        } catch (Exception ex) {
            return "system";
        }
    }

    private record AutoTransitionResult(boolean applied, String message) {
    }

    /**
     * Determine overall safety check status based on individual item statuses.
     * Priority: FAILED > CONDITIONAL > PASSED
     * 
     * @param items List of safety check items
     * @return Overall safety status
     */
    private PreEntrySafetyStatus determineOverallStatus(List<PreEntrySafetyItem> items) {
        if (items.stream().anyMatch(i -> i.getStatus() == SafetyItemStatus.FAILED)) {
            return PreEntrySafetyStatus.FAILED;
        }
        if (items.stream().anyMatch(i -> i.getStatus() == SafetyItemStatus.CONDITIONAL)) {
            return PreEntrySafetyStatus.CONDITIONAL;
        }
        return PreEntrySafetyStatus.PASSED;
    }

    /**
     * Approve conditional override for a FAILED or CONDITIONAL safety check.
     * Allows dispatch to proceed despite minor safety issues.
     * Only authorized supervisors (ADMIN/SUPERADMIN) can perform this action.
     * 
     * @param request SafetyConditionalOverrideRequest containing safety check ID
     *                and override details
     * @return Updated safety check DTO
     * @throws ResourceNotFoundException    if safety check not found
     * @throws InvalidDispatchDataException if override not allowed
     */
    @Transactional
    public PreEntrySafetyCheckDto approveConditionalOverride(SafetyConditionalOverrideRequest request) {
        log.info("Approving conditional override for safety check: id={}", request.getSafetyCheckId());

        PreEntrySafetyCheck safetyCheck = safetyCheckRepository.findById(request.getSafetyCheckId())
                .orElseThrow(
                        () -> new ResourceNotFoundException("Safety check not found: " + request.getSafetyCheckId()));

        // Validate current status
        if (safetyCheck.getStatus() != PreEntrySafetyStatus.FAILED
                && safetyCheck.getStatus() != PreEntrySafetyStatus.CONDITIONAL) {
            throw new InvalidDispatchDataException("status",
                    "Only FAILED or CONDITIONAL safety checks can be overridden. Current status: "
                            + safetyCheck.getStatus());
        }

        // Validate override remarks required
        if (request.getRemarks() == null || request.getRemarks().trim().isEmpty()) {
            throw new InvalidDispatchDataException("remarks",
                    "Override justification is required when approving conditional override");
        }

        User currentUser = authenticatedUserUtil.getCurrentUser();

        // Update override fields
        safetyCheck.setOverrideApprovedBy(currentUser);
        safetyCheck.setOverrideApprovedAt(LocalDateTime.now());
        safetyCheck.setOverrideRemarks(request.getRemarks());
        safetyCheck.setStatus(PreEntrySafetyStatus.PASSED); // Override to PASSED

        PreEntrySafetyCheck saved = safetyCheckRepository.save(safetyCheck);

        // Update dispatch pre-entry safety status to PASSED
        Dispatch dispatch = saved.getDispatch();
        dispatch.setPreEntrySafetyStatus(PreEntrySafetyStatus.PASSED);
        dispatchRepository.save(dispatch);

        log.info("Conditional override approved: safetyCheckId={}, approvedBy={}", request.getSafetyCheckId(),
                currentUser.getUsername());

        return PreEntrySafetyCheckDto.from(saved);
    }

    /**
     * Get safety check by dispatch ID.
     * Returns the pre-entry safety check for a specific dispatch.
     * 
     * @param dispatchId Dispatch ID
     * @return Safety check DTO
     * @throws ResourceNotFoundException if safety check not found
     */
    @Transactional(readOnly = true)
    public PreEntrySafetyCheckDto getByDispatchId(Long dispatchId) {
        log.debug("Fetching safety check for dispatch: {}", dispatchId);

        PreEntrySafetyCheck safetyCheck = safetyCheckRepository.findByDispatchId(dispatchId)
                .orElseThrow(() -> new ResourceNotFoundException("Safety check not found for dispatch: " + dispatchId));

        return PreEntrySafetyCheckDto.from(safetyCheck);
    }

    /**
     * Get list of pending conditional overrides.
     * Returns all CONDITIONAL safety checks awaiting supervisor approval.
     * 
     * @return List of safety check DTOs awaiting override
     */
    @Transactional(readOnly = true)
    public List<PreEntrySafetyCheckDto> getPendingConditionalOverrides() {
        log.debug("Fetching pending conditional overrides");

        List<PreEntrySafetyCheck> pending = safetyCheckRepository.findPendingConditionalOverrides();

        return pending.stream()
                .map(PreEntrySafetyCheckDto::from)
                .collect(Collectors.toList());
    }

    /**
     * Get all safety checks for a vehicle on a specific date.
     * Useful for tracking vehicle safety history and identifying patterns.
     * 
     * @param vehicleId Vehicle ID
     * @param checkDate Check date
     * @return List of safety check DTOs
     */
    @Transactional(readOnly = true)
    public List<PreEntrySafetyCheckDto> getByVehicleAndDate(Long vehicleId, LocalDate checkDate) {
        log.debug("Fetching safety checks for vehicle: vehicleId={}, date={}", vehicleId, checkDate);

        // Validate vehicle exists
        vehicleRepository.findById(vehicleId)
                .orElseThrow(() -> new ResourceNotFoundException("Vehicle not found: " + vehicleId));

        // Find safety checks by vehicle and date
        return safetyCheckRepository.findAll().stream()
                .filter(sc -> sc.getVehicle().getId().equals(vehicleId))
                .filter(sc -> sc.getCheckDate().equals(checkDate))
                .map(PreEntrySafetyCheckDto::from)
                .collect(Collectors.toList());
    }

    /**
     * Get all FAILED safety checks for a vehicle on a specific date.
     * Identifies vehicles with recurring safety issues.
     * 
     * @param vehicleId Vehicle ID
     * @param checkDate Check date
     * @return List of failed safety check DTOs
     */
    @Transactional(readOnly = true)
    public List<PreEntrySafetyCheckDto> getFailedChecksByVehicleAndDate(Long vehicleId, LocalDate checkDate) {
        log.debug("Fetching failed safety checks for vehicle: vehicleId={}, date={}", vehicleId, checkDate);

        List<PreEntrySafetyCheck> failed = safetyCheckRepository.findFailedChecksByVehicleAndDate(vehicleId, checkDate);

        return failed.stream()
                .map(PreEntrySafetyCheckDto::from)
                .collect(Collectors.toList());
    }

    /**
     * Get safety check by primary key.
     *
     * @param checkId safety check id
     * @return safety check dto
     */
    @Transactional(readOnly = true)
    public PreEntrySafetyCheckDto getById(Long checkId) {
        PreEntrySafetyCheck safetyCheck = safetyCheckRepository.findById(checkId)
                .orElseThrow(() -> new ResourceNotFoundException("Safety check not found: " + checkId));
        return PreEntrySafetyCheckDto.from(safetyCheck);
    }

    /**
     * List safety checks with optional filters.
     *
     * @param status optional pre-entry status
     * @param warehouseCode optional warehouse code
     * @param fromDate optional start date
     * @param toDate optional end date
     * @return filtered safety checks
     */
    @Transactional(readOnly = true)
    public List<PreEntrySafetyCheckDto> listSafetyChecks(
            PreEntrySafetyStatus status,
            String warehouseCode,
            LocalDate fromDate,
            LocalDate toDate,
            List<Long> dispatchIds) {
        String normalizedWarehouse = warehouseCode == null ? null : warehouseCode.trim();
        if (normalizedWarehouse != null && normalizedWarehouse.isBlank()) {
            normalizedWarehouse = null;
        }
        List<PreEntrySafetyCheck> checks;
        if (dispatchIds != null && !dispatchIds.isEmpty()) {
            List<Long> normalizedDispatchIds = dispatchIds.stream()
                    .filter(id -> id != null && id > 0)
                    .distinct()
                    .collect(Collectors.toList());
            if (normalizedDispatchIds.isEmpty()) {
                return List.of();
            }
            checks = safetyCheckRepository.findForListByDispatchIds(
                    status,
                    normalizedWarehouse,
                    fromDate,
                    toDate,
                    normalizedDispatchIds);
        } else {
            checks = safetyCheckRepository.findForList(status, normalizedWarehouse, fromDate, toDate);
        }

        return checks.stream()
                .map(PreEntrySafetyCheckDto::fromSummary)
                .collect(Collectors.toList());
    }

    /**
     * Replace an existing safety check and its items.
     *
     * @param checkId safety check id
     * @param request full check payload
     * @return updated safety check dto
     */
    @Transactional
    public PreEntrySafetyCheckDto updateSafetyCheck(Long checkId, PreEntrySafetyCheckSubmitRequest request) {
        PreEntrySafetyCheck safetyCheck = safetyCheckRepository.findById(checkId)
                .orElseThrow(() -> new ResourceNotFoundException("Safety check not found: " + checkId));

        if (!safetyCheck.getDispatch().getId().equals(request.getDispatchId())) {
            throw new InvalidDispatchDataException("dispatchId",
                    "Dispatch mismatch for safety check update. Expected dispatchId=" + safetyCheck.getDispatch().getId());
        }

        Vehicle vehicle = vehicleRepository.findById(request.getVehicleId())
                .orElseThrow(() -> new ResourceNotFoundException("Vehicle not found: " + request.getVehicleId()));
        Driver driver = driverRepository.findById(request.getDriverId())
                .orElseThrow(() -> new ResourceNotFoundException("Driver not found: " + request.getDriverId()));
        User currentUser = authenticatedUserUtil.getCurrentUser();

        safetyCheck.setVehicle(vehicle);
        safetyCheck.setDriver(driver);
        safetyCheck.setWarehouseCode(request.getWarehouseCode());
        safetyCheck.setRemarks(request.getRemarks());
        safetyCheck.setCheckedBy(currentUser);
        safetyCheck.setCheckedAt(LocalDateTime.now());
        safetyCheck.setCheckerSignaturePath(request.getCheckerSignatureUrl());
        safetyCheck.setInspectionPhotos(request.getInspectionPhotoUrls());

        safetyItemRepository.deleteBySafetyCheckId(checkId);
        List<PreEntrySafetyItem> items = mapAndValidateItems(request, safetyCheck);
        safetyItemRepository.saveAll(items);

        PreEntrySafetyStatus overallStatus = determineOverallStatus(items);
        safetyCheck.setStatus(overallStatus);
        safetyCheck.setItems(items);
        PreEntrySafetyCheck saved = safetyCheckRepository.save(safetyCheck);

        Dispatch dispatch = saved.getDispatch();
        dispatch.setPreEntrySafetyStatus(overallStatus);
        dispatchRepository.save(dispatch);

        return PreEntrySafetyCheckDto.from(saved);
    }

    /**
     * Delete an existing safety check and reset dispatch pre-entry status.
     *
     * @param checkId safety check id
     */
    @Transactional
    public void deleteSafetyCheck(Long checkId) {
        PreEntrySafetyCheck safetyCheck = safetyCheckRepository.findById(checkId)
                .orElseThrow(() -> new ResourceNotFoundException("Safety check not found: " + checkId));

        Dispatch dispatch = safetyCheck.getDispatch();
        if (dispatch.getStatus() != DispatchStatus.ARRIVED_LOADING && dispatch.getStatus() != DispatchStatus.IN_QUEUE) {
            throw new InvalidDispatchDataException("status",
                    "Delete is only allowed while dispatch is ARRIVED_LOADING or IN_QUEUE. Current status: "
                            + dispatch.getStatus());
        }

        safetyItemRepository.deleteBySafetyCheckId(checkId);
        safetyCheckRepository.delete(safetyCheck);

        dispatch.setPreEntrySafetyStatus(PreEntrySafetyStatus.NOT_STARTED);
        dispatchRepository.save(dispatch);
    }

    public String uploadInspectionPhoto(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new InvalidDispatchDataException("file", "Image file is required.");
        }

        String contentType = String.valueOf(file.getContentType()).toLowerCase();
        if (!ALLOWED_IMAGE_TYPES.contains(contentType)) {
            log.warn("Rejected pre-entry photo upload due to mime type: {}", contentType);
            throw new InvalidDispatchDataException("file",
                    "Unsupported image type. Allowed: JPEG, PNG, WEBP.");
        }

        if (file.getSize() > MAX_UPLOAD_SIZE_BYTES) {
            log.warn("Rejected pre-entry photo upload due to size: {} bytes", file.getSize());
            throw new InvalidDispatchDataException("file", "Image exceeds max size (5MB).");
        }

        String storedUrl = fileStorageService.storeFileInSubfolder(file, "pre-entry-safety");
        log.info("Pre-entry inspection photo uploaded successfully: name={}, url={}", file.getOriginalFilename(), storedUrl);
        return storedUrl;
    }

    private List<PreEntrySafetyItem> mapAndValidateItems(
            PreEntrySafetyCheckSubmitRequest request,
            PreEntrySafetyCheck safetyCheck) {
        if (request.getItems() == null || request.getItems().isEmpty()) {
            throw new InvalidDispatchDataException("items", "Full pre-entry checklist is required.");
        }

        List<PreEntrySafetyItem> items = IntStream.range(0, request.getItems().size())
                .mapToObj(index -> {
                    PreEntrySafetyCheckSubmitRequest.SafetyItemSubmit itemDto = request.getItems().get(index);
                    try {
                        String normalizedName = normalizeItemName(itemDto.getItemName());
                        SafetyItemStatus normalizedStatus = parseItemStatus(itemDto.getStatus());
                        String normalizedRemarks = normalizeText(itemDto.getRemarks());
                        if ((normalizedStatus == SafetyItemStatus.FAILED || normalizedStatus == SafetyItemStatus.CONDITIONAL)
                                && (normalizedRemarks == null || normalizedRemarks.isBlank())) {
                            throw new InvalidDispatchDataException("items[" + index + "].remarks",
                                    "Remarks are required for FAILED or CONDITIONAL items.");
                        }
                        return PreEntrySafetyItem.builder()
                                .safetyCheck(safetyCheck)
                                .category(parseCategory(itemDto.getCategory()))
                                .itemName(normalizedName)
                                .status(normalizedStatus)
                                .remarks(normalizedRemarks)
                                .photoPath(normalizeText(itemDto.getPhotoUrl()))
                                .build();
                    } catch (InvalidDispatchDataException ex) {
                        String field = ex.getField();
                        if (field != null && field.startsWith("items[")) {
                            throw ex;
                        }
                        String mappedField = switch (field) {
                            case "category" -> "items[" + index + "].category";
                            case "itemName" -> "items[" + index + "].itemName";
                            case "status" -> "items[" + index + "].status";
                            case "remarks" -> "items[" + index + "].remarks";
                            case "photoUrl" -> "items[" + index + "].photoUrl";
                            default -> "items[" + index + "]";
                        };
                        String reason = ex.getReason() != null ? ex.getReason() : ex.getMessage();
                        throw new InvalidDispatchDataException(mappedField, reason);
                    }
                })
                .collect(Collectors.toList());

        Set<SafetyCategory> requiredCategories = resolveRequiredCategoriesFromMaster();
        Set<SafetyCategory> presentCategories = items.stream()
                .map(PreEntrySafetyItem::getCategory)
                .collect(Collectors.toSet());

        List<String> missingCategories = requiredCategories.stream()
                .filter(required -> !presentCategories.contains(required))
                .map(Enum::name)
                .sorted()
                .collect(Collectors.toList());

        if (!missingCategories.isEmpty()) {
            throw new InvalidDispatchDataException("items",
                    "Missing required checklist categories: " + String.join(", ", missingCategories));
        }

        return items;
    }

    private Set<SafetyCategory> resolveRequiredCategoriesFromMaster() {
        Set<SafetyCategory> mapped = preEntryCheckMasterItemRepository.findActiveCategoryCodesWithActiveItems()
                .stream()
                .map(this::parseCategoryOrNull)
                .filter(java.util.Objects::nonNull)
                .collect(Collectors.toSet());

        if (mapped.isEmpty()) {
            throw new InvalidDispatchDataException(
                    "items",
                    "No active pre-entry master items configured.");
        }
        return mapped;
    }

    private String normalizeItemName(String itemName) {
        String normalized = itemName == null ? "" : itemName.trim();
        if (normalized.isEmpty()) {
            throw new InvalidDispatchDataException("itemName", "Safety item name is required.");
        }
        return normalized;
    }

    private String normalizeText(String value) {
        if (value == null) {
            return null;
        }
        String normalized = value.trim();
        return normalized.isEmpty() ? null : normalized;
    }

    private SafetyCategory parseCategory(String rawCategory) {
        if (rawCategory == null || rawCategory.isBlank()) {
            throw new InvalidDispatchDataException("category", "Safety item category is required.");
        }

        String value = rawCategory.trim().toUpperCase().replace('-', '_').replace(' ', '_');
        return switch (value) {
            case "TIRES" -> SafetyCategory.TIRES;
            case "LIGHTS" -> SafetyCategory.LIGHTS;
            case "LOAD", "LOAD_SECURING", "LOAD_&_SECURING" -> SafetyCategory.LOAD;
            case "DOCUMENTS" -> SafetyCategory.DOCUMENTS;
            case "WEIGHT" -> SafetyCategory.WEIGHT;
            case "BRAKES" -> SafetyCategory.BRAKES;
            case "WINDSHIELD" -> SafetyCategory.WINDSHIELD;
            default -> throw new InvalidDispatchDataException("category",
                    "Invalid safety item category: " + rawCategory);
        };
    }

    private SafetyCategory parseCategoryOrNull(String rawCategory) {
        try {
            return parseCategory(rawCategory);
        } catch (InvalidDispatchDataException ignored) {
            return null;
        }
    }

    private SafetyItemStatus parseItemStatus(String rawStatus) {
        if (rawStatus == null || rawStatus.isBlank()) {
            throw new InvalidDispatchDataException("status", "Safety item status is required.");
        }

        String value = rawStatus.trim().toUpperCase().replace('-', '_').replace(' ', '_');
        return switch (value) {
            case "OK", "PASS", "PASSED" -> SafetyItemStatus.OK;
            case "FAILED", "FAIL" -> SafetyItemStatus.FAILED;
            case "CONDITIONAL" -> SafetyItemStatus.CONDITIONAL;
            default -> throw new InvalidDispatchDataException("status", "Invalid safety item status: " + rawStatus);
        };
    }
}
