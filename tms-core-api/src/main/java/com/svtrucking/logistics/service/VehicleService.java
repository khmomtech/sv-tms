package com.svtrucking.logistics.service;

import com.svtrucking.logistics.dto.VehicleDto;
import com.svtrucking.logistics.dto.VehicleStatisticsDto;
import com.svtrucking.logistics.enums.TruckSize;
import com.svtrucking.logistics.enums.VehicleStatus;
import com.svtrucking.logistics.enums.VehicleType;
import com.svtrucking.logistics.exception.DuplicateLicensePlateException;
import com.svtrucking.logistics.exception.VehicleNotFoundException;
import com.svtrucking.logistics.model.Vehicle;
import com.svtrucking.logistics.repository.VehicleRepository;
import com.svtrucking.logistics.service.VehicleDocumentService;
import com.svtrucking.logistics.support.audit.AuditedAction;
import com.svtrucking.logistics.validator.VehicleValidator;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Service for vehicle CRUD operations.
 * Refactored to follow Single Responsibility Principle.
 * Statistics delegated to FleetStatisticsService.
 * Validation delegated to VehicleValidator.
 */
@Service
@Slf4j
@RequiredArgsConstructor
public class VehicleService {

  private final VehicleRepository vehicleRepository;
  private final VehicleValidator vehicleValidator;
  private final FleetStatisticsService fleetStatisticsService;
  private final VehicleCacheServiceInterface vehicleCacheService;
  private final VehicleDocumentService vehicleDocumentService;

  // ============================================================================
  // CRUD Operations
  // ============================================================================

  @Cacheable(value = "vehicles", key = "#pageable.pageNumber + '-' + #pageable.pageSize")
  @Transactional(readOnly = true)
  public Page<VehicleDto> getAllVehicles(Pageable pageable) {
    log.debug("Fetching vehicles page: {}, size: {}", pageable.getPageNumber(), pageable.getPageSize());
    return vehicleRepository.findAll(pageable).map(VehicleDto::fromEntity);
  }

  @Cacheable(value = "allVehicles", unless = "#result == null || #result.size() > 1000")
  @Transactional(readOnly = true)
  public List<VehicleDto> getAllVehicles() {
    log.debug("Fetching all vehicles without pagination");
    List<Vehicle> vehicles = vehicleRepository.findAll();
    log.debug("Found {} vehicles in database", vehicles.size());
    return vehicles.stream()
        .map(VehicleDto::fromEntity)
        .collect(Collectors.toList());
  }

  @Transactional(readOnly = true)
  public Optional<Vehicle> getVehicleById(Long id) {
    log.debug("Fetching vehicle by ID: {}", id);
    return vehicleRepository.findById(id);
  }

  /**
   * Fetch vehicle as DTO inside a transaction to ensure lazy collections are initialized
   * before mapping to DTO.
   */
  @Transactional(readOnly = true)
  public Optional<com.svtrucking.logistics.dto.VehicleDto> getVehicleDtoById(Long id) {
    Optional<Vehicle> opt = vehicleRepository.findById(id);
    if (opt.isEmpty()) return Optional.empty();
    Vehicle v = opt.get();
    initializeLazyCollections(v);
    com.svtrucking.logistics.dto.VehicleDto dto = com.svtrucking.logistics.dto.VehicleDto.fromEntity(v);
    dto.setDocuments(vehicleDocumentService.getDocumentsByVehicle(v.getId()));
    return Optional.of(dto);
  }

  @Transactional(readOnly = true)
  public Optional<Vehicle> getVehicleByLicensePlate(String licensePlate) {
    log.debug("Fetching vehicle by license plate: {}", licensePlate);
    return vehicleRepository.findByLicensePlate(licensePlate);
  }

  @Transactional(readOnly = true)
  public Optional<com.svtrucking.logistics.dto.VehicleDto> getVehicleDtoByLicensePlate(String licensePlate) {
    Optional<Vehicle> opt = vehicleRepository.findByLicensePlate(licensePlate);
    if (opt.isEmpty()) return Optional.empty();
    Vehicle v = opt.get();
    initializeLazyCollections(v);
    com.svtrucking.logistics.dto.VehicleDto dto = com.svtrucking.logistics.dto.VehicleDto.fromEntity(v);
    dto.setDocuments(vehicleDocumentService.getDocumentsByVehicle(v.getId()));
    return Optional.of(dto);
  }

  @Transactional(transactionManager = "jpaTransactionManager")
  @AuditedAction("vehicle.create")
  @CacheEvict(value = {"vehicles", "allVehicles", "vehicleStats"}, allEntries = true)
  public com.svtrucking.logistics.dto.VehicleDto addVehicle(com.svtrucking.logistics.model.Vehicle vehicle) {
    log.info("Adding new vehicle with license plate: {}", vehicle.getLicensePlate());
    
    // Check for duplicate license plate
    if (vehicleRepository.findByLicensePlate(vehicle.getLicensePlate()).isPresent()) {
      log.warn("Attempted to add duplicate vehicle: {}", vehicle.getLicensePlate());
      throw new DuplicateLicensePlateException(
          "Vehicle with license plate '" + vehicle.getLicensePlate() + "' already exists!");
    }
    
    // Validate using VehicleValidator
    vehicleValidator.validateVehicle(vehicle);
    vehicleValidator.validateTruckFields(vehicle);
    vehicleValidator.validateMaintenanceSchedule(vehicle);
    
    Vehicle saved = vehicleRepository.save(vehicle);
    log.info("Successfully created vehicle ID: {} - {}", saved.getId(), saved.getLicensePlate());
    // Initialize lazy collections to avoid LazyInitializationException during DTO mapping
    initializeLazyCollections(saved);
    // Clear Redis-backed vehicle cache patterns if available
    try {
      vehicleCacheService.clearVehiclesCache();
    } catch (Exception e) {
      log.debug("Vehicle cache clear failed (non-fatal): {}", e.getMessage());
    }
    return com.svtrucking.logistics.dto.VehicleDto.fromEntity(saved);
  }

  @Transactional(transactionManager = "jpaTransactionManager")
  @AuditedAction("vehicle.update")
  @CacheEvict(value = {"vehicles", "allVehicles", "vehicleStats"}, allEntries = true)
  public com.svtrucking.logistics.dto.VehicleDto updateVehicle(Long id, VehicleDto dto) {
    log.info("Updating vehicle ID: {}", id);
    
    // Fetch existing vehicle or throw custom exception
    Vehicle existing = vehicleRepository
            .findById(id)
            .orElseThrow(() -> {
              log.error("Vehicle not found with ID: {}", id);
              return new VehicleNotFoundException(id);
            });

    // Check for duplicate license plate if changed (null-safe)
    if (dto.getLicensePlate() != null
      && !java.util.Objects.equals(existing.getLicensePlate(), dto.getLicensePlate())
      && vehicleRepository.findByLicensePlate(dto.getLicensePlate()).isPresent()) {
      log.warn("Attempted to update to duplicate license plate: {}", dto.getLicensePlate());
      throw new DuplicateLicensePlateException(
          "License plate '" + dto.getLicensePlate() + "' already exists!");
    }

    // Update fields from DTO
    updateVehicleFromDto(existing, dto);
    
    // Validate updated vehicle
    vehicleValidator.validateVehicle(existing);
    vehicleValidator.validateTruckFields(existing);
    vehicleValidator.validateMaintenanceSchedule(existing);
    
    Vehicle updated = vehicleRepository.save(existing);
    log.info("Successfully updated vehicle ID: {}", id);
    // Ensure lazy collections are initialized before leaving transactional boundary
    initializeLazyCollections(updated);
    // Clear Redis-backed vehicle cache patterns if available
    try {
      vehicleCacheService.clearVehiclesCache();
    } catch (Exception e) {
      log.debug("Vehicle cache clear failed (non-fatal): {}", e.getMessage());
    }
    return com.svtrucking.logistics.dto.VehicleDto.fromEntity(updated);
  }

  @Transactional(transactionManager = "jpaTransactionManager")
  @AuditedAction("vehicle.delete")
  @CacheEvict(value = {"vehicles", "allVehicles", "vehicleStats"}, allEntries = true)
  public void deleteVehicle(Long id) {
    log.info("Deleting vehicle ID: {}", id);
    
    // Check existence or throw custom exception
    if (!vehicleRepository.existsById(id)) {
      log.error("Cannot delete - vehicle not found with ID: {}", id);
      throw new VehicleNotFoundException(id);
    }
    
    vehicleRepository.deleteById(id);
    log.info("Successfully deleted vehicle ID: {}", id);
    try {
      vehicleCacheService.clearVehiclesCache();
    } catch (Exception e) {
      log.debug("Vehicle cache clear failed (non-fatal): {}", e.getMessage());
    }
  }

  @Transactional(readOnly = true)
  public boolean existsByLicensePlate(String licensePlate) {
    return vehicleRepository.existsByLicensePlate(licensePlate);
  }

  // ============================================================================
  // Search and Filter Operations
  // ============================================================================

  /**
   * Advanced search with repository query (PREFERRED METHOD).
   * Uses database-level filtering for performance.
   */
  @Transactional(readOnly = true)
  public Page<VehicleDto> advancedSearch(
      String search,
      VehicleStatus status,
      VehicleType type,
      TruckSize truckSize,
      String zone,
      Boolean assigned,
      Pageable pageable) {

    log.debug("Advanced search - search: {}, status: {}, type: {}, size: {}, zone: {}, assigned: {}",
        search, status, type, truckSize, zone, assigned);

    Page<Vehicle> results = vehicleRepository.searchVehicles(
        search, status, type, truckSize, zone, assigned, pageable);
    
    return results.map(VehicleDto::fromEntity);
  }

  // ============================================================================
  // Fleet Analytics and Statistics
  // (Delegated to FleetStatisticsService)
  // ============================================================================

  /**
   * Generates comprehensive fleet statistics.
   * Delegates to FleetStatisticsService for separation of concerns.
   */
  public VehicleStatisticsDto getFleetStatistics() {
    return fleetStatisticsService.getFleetStatistics();
  }

  // ============================================================================
  // Service Management and Queries
  // ============================================================================

  @Transactional(readOnly = true)
  public List<VehicleDto> getVehiclesRequiringService() {
    return vehicleRepository.findVehiclesRequiringService(LocalDate.now()).stream()
        .map(VehicleDto::fromEntity)
        .collect(Collectors.toList());
  }

  @Transactional(readOnly = true)
  public List<VehicleDto> getVehiclesByStatus(VehicleStatus status) {
    return vehicleRepository.findAllByStatus(status).stream()
        .map(VehicleDto::fromEntity)
        .collect(Collectors.toList());
  }

  @Transactional(readOnly = true)
  public List<VehicleDto> getUnassignedVehicles() {
    return vehicleRepository.findUnassignedVehicles().stream()
        .map(VehicleDto::fromEntity)
        .collect(Collectors.toList());
  }

  @Transactional(readOnly = true)
  public List<VehicleDto> getTrailers() {
    return vehicleRepository.findAllTrailers().stream()
        .map(VehicleDto::fromEntity)
        .collect(Collectors.toList());
  }

  // ============================================================================
  // Private Helper Methods
  // ============================================================================

  /**
   * Updates vehicle entity from DTO.
   * Maps all fields from DTO to existing entity.
   */
  private void updateVehicleFromDto(Vehicle existing, VehicleDto dto) {
    if (dto.getLicensePlate() != null) existing.setLicensePlate(dto.getLicensePlate());
    if (dto.getModel() != null) existing.setModel(dto.getModel());
    if (dto.getManufacturer() != null) existing.setManufacturer(dto.getManufacturer());
    if (dto.getType() != null) existing.setType(dto.getType());
    if (dto.getStatus() != null) existing.setStatus(dto.getStatus());
    if (dto.getMileage() != null) existing.setMileage(dto.getMileage());
    if (dto.getFuelConsumption() != null) existing.setFuelConsumption(dto.getFuelConsumption());
    if (dto.getMaxWeight() != null) existing.setMaxWeight(dto.getMaxWeight());
    if (dto.getMaxVolume() != null) existing.setMaxVolume(dto.getMaxVolume());
    if (dto.getLastInspectionDate() != null) existing.setLastInspectionDate(convertToLocalDate(dto.getLastInspectionDate()));
    if (dto.getLastServiceDate() != null) existing.setLastServiceDate(convertToLocalDate(dto.getLastServiceDate()));
    if (dto.getNextServiceDue() != null) existing.setNextServiceDue(convertToLocalDate(dto.getNextServiceDue()));
    if (dto.getYearMade() != null) existing.setYearMade(dto.getYearMade());
    if (dto.getTruckSize() != null) existing.setTruckSize(dto.getTruckSize());
    if (dto.getQtyPalletsCapacity() != null) existing.setQtyPalletsCapacity(dto.getQtyPalletsCapacity());
    if (dto.getAssignedZone() != null) existing.setAssignedZone(dto.getAssignedZone());
    if (dto.getGpsDeviceId() != null) existing.setGpsDeviceId(dto.getGpsDeviceId());
    if (dto.getRemarks() != null) existing.setRemarks(dto.getRemarks());

    // Handle parent vehicle assignment only when explicitly provided
    if (dto.getParentVehicleId() != null) {
      if (!dto.getParentVehicleId().equals(existing.getId())) {
        Vehicle assigned = vehicleRepository.findById(dto.getParentVehicleId())
            .orElseThrow(() -> new VehicleNotFoundException(dto.getParentVehicleId()));
        existing.setParentVehicle(assigned);
      } else {
        existing.setParentVehicle(null);
      }
    }
  }

  /**
   * Ensure commonly accessed lazy associations are initialized while the session is open.
   * This prevents LazyInitializationException when DTO mapping or JSON serialization
   * occurs after the transaction has committed.
   */
  private void initializeLazyCollections(Vehicle v) {
    if (v == null) return;
    try {
      // assignments (driver assignments history)
      if (v.getAssignments() != null) v.getAssignments().size();
    } catch (Exception ignored) {
    }
    try {
      // routes
      if (v.getRoutes() != null) v.getRoutes().size();
    } catch (Exception ignored) {
    }
    try {
      // parentVehicle reference (parent/trailer)
      if (v.getParentVehicle() != null) v.getParentVehicle().getId();
    } catch (Exception ignored) {
    }
  }

  /**
   * Converts java.util.Date to LocalDate.
   */
  private LocalDate convertToLocalDate(java.util.Date date) {
    return date != null ? new java.sql.Date(date.getTime()).toLocalDate() : null;
  }
}
