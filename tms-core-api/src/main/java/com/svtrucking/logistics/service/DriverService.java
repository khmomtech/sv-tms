package com.svtrucking.logistics.service;

import com.svtrucking.logistics.domain.driver.DriverDomainService;
import com.svtrucking.logistics.dto.DriverDto;
import com.svtrucking.logistics.dto.HeartbeatDto;
import com.svtrucking.logistics.dto.LocationHistoryDto;
import com.svtrucking.logistics.model.LocationHistory;
import com.svtrucking.logistics.dto.requests.DriverCreateRequest;
import com.svtrucking.logistics.dto.requests.DriverUpdateRequest;
import com.svtrucking.logistics.enums.DispatchStatus;
import com.svtrucking.logistics.enums.DriverStatus;
import com.svtrucking.logistics.enums.VehicleType;
import com.svtrucking.logistics.exception.DriverFileUploadException;
import com.svtrucking.logistics.exception.DriverNotFoundException;
import com.svtrucking.logistics.exception.InvalidDriverDataException;
import com.svtrucking.logistics.model.Dispatch;
import com.svtrucking.logistics.model.Driver;
import com.svtrucking.logistics.model.DriverDocument;
import com.svtrucking.logistics.model.Employee;
import com.svtrucking.logistics.model.Vehicle;
import com.svtrucking.logistics.repository.DispatchRepository;
import com.svtrucking.logistics.repository.DriverDocumentRepository;
import com.svtrucking.logistics.repository.DriverRepository;
import com.svtrucking.logistics.repository.EmployeeRepository;
import com.svtrucking.logistics.repository.LocationHistoryRepository;
import com.svtrucking.logistics.repository.VehicleRepository;
import com.svtrucking.logistics.validator.DriverValidator;
import com.svtrucking.logistics.utils.AssetUrlHelper;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import com.svtrucking.logistics.support.audit.AuditedAction;
import org.springframework.web.multipart.MultipartFile;
import lombok.extern.slf4j.Slf4j;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Service
public class DriverService {

  private static final Logger LOG = LoggerFactory.getLogger(DriverService.class);

  private final DispatchRepository dispatchRepository;
  private final DriverRepository driverRepository;
  private final DriverDocumentRepository driverDocumentRepository;
  private final EmployeeRepository employeeRepository;
  private final VehicleRepository vehicleRepository;
  private final LocationHistoryRepository locationHistoryRepository;
  private final DriverDomainService driverDomainService;
  private final DriverValidator driverValidator;
  private final TelematicsProxyService telematicsProxy;
  @Autowired(required = false)
  private DriverLocationMongoService mongoService;

  public DriverService(
      DriverRepository driverRepository,
      DriverDocumentRepository driverDocumentRepository,
      EmployeeRepository employeeRepository,
      VehicleRepository vehicleRepository,
      DispatchRepository dispatchRepository,
      LocationHistoryRepository locationHistoryRepository,
      DriverDomainService driverDomainService,
      DriverValidator driverValidator,
      TelematicsProxyService telematicsProxy) {
    this.driverRepository = driverRepository;
    this.driverDocumentRepository = driverDocumentRepository;
    this.employeeRepository = employeeRepository;
    this.vehicleRepository = vehicleRepository;
    this.dispatchRepository = dispatchRepository;
    this.locationHistoryRepository = locationHistoryRepository;
    this.driverDomainService = driverDomainService;
    this.driverValidator = driverValidator;
    this.telematicsProxy = telematicsProxy;
  }

  // -------------------- Config (old style with @Value) --------------------

  @Value("${file.upload.base-dir:/opt/sv-tms/uploads/}")
  private String uploadBaseDir; // absolute FS folder, e.g. /opt/sv-tms/uploads/

  @Value("${file.upload.dir.profiles:profiles/}")
  private String profilesDir; // logical subfolder, e.g. profiles/

  @Value("${location.history.read.require-mongo:true}")
  private boolean requireMongoForHistoryReads;

  private static final Set<String> ALLOWED_EXT = Set.of(".jpg", ".jpeg", ".png", ".webp");

  // -------------------- CRUD --------------------

  @Transactional
  @AuditedAction("driver.create")
  public Driver addDriver(Driver driver) {
    LOG.info("Creating new driver: {}", driver.getName());

    if (driver.getId() != null) {
      throw new InvalidDriverDataException("id", "must not be provided for new driver");
    }

    // Validate driver data
    driverValidator.validateDriver(driver);

    Optional.ofNullable(driver.getEmployee())
        .map(Employee::getId)
        .flatMap(employeeRepository::findById)
        .ifPresent(driver::setEmployee);

    // Partner validation now handled via partnerCompanyEntity FK relationship

    // Assign vehicle using new VehicleDriver assignment logic if needed
    // (Assignment logic should be handled via VehicleDriver, not direct field)

    Driver saved = driverRepository.save(driver);
    syncDriverSnapshotAsync(saved);
    LOG.info("Driver created successfully with ID: {}", saved.getId());
    return saved;
  }

  @Transactional(readOnly = true)
  public Page<DriverDto> getAllDrivers(Pageable pageable) {
    LOG.debug("Fetching drivers page: {}, size: {}", pageable.getPageNumber(), pageable.getPageSize());
    return convertToDtoPage(driverRepository.findAll(pageable), false, false);
  }

  @Transactional(readOnly = true)
  public Page<DriverDto> getAllListDrivers(Pageable pageable) {
    LOG.debug("Fetching all list drivers page: {}, size: {}", pageable.getPageNumber(), pageable.getPageSize());
    return convertToDtoPage(driverRepository.findAll(pageable), false, false);
  }

  private Page<DriverDto> convertToDtoPage(
      Page<Driver> driverPage, boolean includeLocationHistory, boolean onlyLatestLocation) {
    List<Driver> drivers = driverPage.getContent();
    hydrateLicenseNumbers(drivers);
    List<DriverDto> driverDtos = drivers.stream()
        .map(driver -> DriverDto.fromEntity(driver, includeLocationHistory, onlyLatestLocation))
        .collect(Collectors.toList());
    return new PageImpl<>(driverDtos, driverPage.getPageable(), driverPage.getTotalElements());
  }

  public List<DriverDto> getAllDrivers() {
    List<Driver> drivers = driverRepository.findAll();
    hydrateLicenseNumbers(drivers);
    return drivers.stream()
        .map(driver -> DriverDto.fromEntity(driver, false, false))
        .collect(Collectors.toList());
  }

  @Transactional(readOnly = true)
  public Driver getDriverById(Long id) {
    LOG.debug("Fetching driver by ID: {}", id);
    Driver driver = driverRepository
        .findById(id)
        .orElseThrow(() -> new DriverNotFoundException(id));
    hydrateLicenseNumber(driver);
    return driver;
  }

  @Transactional
  @AuditedAction("driver.update")
  public Driver updateDriver(Long id, Driver updatedDriver) {
    Driver driver = getDriverById(id);

    driver.setName(updatedDriver.getName());
    driver.setPhone(updatedDriver.getPhone());
    driver.setLicenseNumber(updatedDriver.getLicenseNumber());
    driver.setRating(updatedDriver.getRating());
    driver.setIsActive(updatedDriver.getIsActive());

    Optional.ofNullable(updatedDriver.getEmployee())
        .map(Employee::getId)
        .flatMap(employeeRepository::findById)
        .ifPresent(driver::setEmployee);

    driver.setPartner(updatedDriver.isPartner());
    // Partner company now managed via partnerCompanyEntity relationship

    // Assign vehicle using new VehicleDriver assignment logic if needed
    // (Assignment logic should be handled via VehicleDriver, not direct field)

    Driver saved = driverRepository.save(driver);
    syncDriverSnapshotAsync(saved);
    return saved;
  }

  @Transactional
  @AuditedAction("driver.update")
  public Driver updateDriverFromRequest(Long id, DriverUpdateRequest req) {
    Driver driver = getDriverById(id);
    driverValidator.validateDriverUpdate(driver, req);
    driverDomainService.applyUpdate(driver, req);
    Driver saved = driverRepository.save(driver);
    syncLicenseDocument(saved, req.getLicenseNumber());
    hydrateLicenseNumber(saved);
    syncDriverSnapshotAsync(saved);
    return saved;
  }

  @AuditedAction("driver.delete")
  public void deleteDriver(Long id) {
    driverRepository.deleteById(id);
  }

  private void syncDriverSnapshotAsync(Driver driver) {
    if (driver == null) {
      return;
    }
    try {
      Vehicle vehicle =
          driver.getTempAssignedVehicle() != null
              ? driver.getTempAssignedVehicle()
              : driver.getAssignedVehicle();
      telematicsProxy.syncDriverAsync(
          driver.getId(),
          driver.getName(),
          driver.getPhone(),
          vehicle != null ? vehicle.getLicensePlate() : null);
    } catch (Exception e) {
      LOG.debug("Driver telematics sync skipped for driver {}: {}", driver.getId(), e.getMessage());
    }
  }

  // -------------------- Location & device --------------------

  /**
   * Update heartbeat info for a driver (lastSeenAt, network, battery, gps, app
   * version).
   */
  @Transactional
  @AuditedAction("driver.heartbeat")
  public void updateHeartbeat(Long driverId, HeartbeatDto dto) {
    Driver driver = getDriverById(driverId);
    driver.setLastSeenAt(LocalDateTime.now());
    driver.setNetType(dto.getNetType());
    driver.setBattery(dto.getBattery());
    driver.setGpsOn(dto.getGpsOn());
    driver.setAppVersion(dto.getAppVersion());
    driverRepository.save(driver);
  }

  @Transactional
  @AuditedAction("driver.location.update")
  public void updateDriverLocation(Long driverId, double latitude, double longitude) {
    // Note: Location updates now handled via DriverLatestLocation table
    // This method is deprecated - use DriverLocationService instead
    // Keeping for backward compatibility but implementation removed
    LOG.warn("updateDriverLocation called for driver {} - this method is deprecated, use DriverLocationService",
        driverId);
  }

  public List<LocationHistoryDto> getDriverLocationHistory(Long driverId) {
    if (mongoService != null) {
      return mongoService.findByDriver(driverId);
    }
    if (requireMongoForHistoryReads) {
      throw new IllegalStateException("Location history store unavailable (MongoDB not configured)");
    }
    return locationHistoryRepository.findByDriverIdOrderByTimestampDesc(driverId).stream()
        .map(LocationHistoryDto::fromEntity)
        .collect(Collectors.toList());
  }

  @Transactional
  @AuditedAction("driver.device.update")
  public void updateDeviceToken(Long driverId, String deviceToken) {
    Driver driver = getDriverById(driverId);
    driver.setDeviceToken(deviceToken);
    driverRepository.save(driver);
  }

  public String getDeviceToken(Long driverId) {
    return getDriverById(driverId).getDeviceToken();
  }

  public List<String> getAllDeviceTokens() {
    return driverRepository.findAll().stream()
        .map(Driver::getDeviceToken)
        .filter(token -> token != null && !token.isEmpty())
        .collect(Collectors.toList());
  }

  // -------------------- Queries --------------------

  public DriverDto getDriverByUserId(Long userId) {
    return driverRepository
        .findByUserId(userId)
        .map(
            driver -> {
              hydrateLicenseNumber(driver);
              return DriverDto.fromEntity(driver, true, true);
            })
        .orElseThrow(() -> new RuntimeException("No driver found for this user."));
  }

  public List<DriverDto> searchDrivers(String query) {
    List<Driver> drivers = driverRepository.searchDriversWithFilters(
            Optional.ofNullable(query).orElse("").trim(),
            null,
            null,
            null,
            null);
    hydrateLicenseNumbers(drivers);
    return drivers.stream()
        .map(driver -> DriverDto.fromEntity(driver, true, true))
        .collect(Collectors.toList());
  }

  @Transactional(readOnly = true)
  public Page<DriverDto> advancedSearchDrivers(
      int page,
      int size,
      String query,
      Boolean isActive,
      Integer minRating,
      Integer maxRating,
      String zone,
      VehicleType vehicleType,
      DriverStatus status,
      Boolean isPartner) {
    LOG.debug("Advanced search drivers - query: {}, status: {}, zone: {}", query, status, zone);
    Pageable pageable = PageRequest.of(page, size);

    Double minRatingDouble = minRating != null ? minRating.doubleValue() : null;
    Double maxRatingDouble = maxRating != null ? maxRating.doubleValue() : null;

    Page<Driver> result = driverRepository.advancedSearch(
        query,
        isActive,
        minRatingDouble,
        maxRatingDouble,
        zone,
        vehicleType,
        status,
        isPartner,
        pageable);

    List<Driver> drivers = result.getContent();
    hydrateLicenseNumbers(drivers);
    List<DriverDto> dtoList = drivers.stream()
        .map(driver -> DriverDto.fromEntity(driver, false, true))
        .toList();
    return new PageImpl<>(dtoList, result.getPageable(), result.getTotalElements());
  }

  // -------------------- Dispatch helpers --------------------

  /**
   * Active = any status where the trip is ongoing. Includes the new LOADING /
   * UNLOADING stages.
   */
  @Transactional(readOnly = true)
  public Dispatch getCurrentActiveDispatch(Long driverId) {
    LOG.debug("Fetching active dispatch for driver ID: {}", driverId);
    List<DispatchStatus> activeStatuses = List.of(
        DispatchStatus.ASSIGNED,
        DispatchStatus.DRIVER_CONFIRMED,
        DispatchStatus.IN_QUEUE,
        DispatchStatus.ARRIVED_LOADING,
        DispatchStatus.LOADING,
        DispatchStatus.LOADED,
        DispatchStatus.IN_TRANSIT,
        DispatchStatus.ARRIVED_UNLOADING,
        DispatchStatus.UNLOADING);
    return dispatchRepository
        .findTopByDriverIdAndStatusInOrderByUpdatedDateDesc(driverId, activeStatuses)
        .orElse(null);
  }

  // -------------------- File upload (configurable, safe, old style)
  // --------------------

  @Transactional
  @AuditedAction("driver.profile.upload")
  public String saveProfilePicture(Long driverId, MultipartFile file) {
    LOG.info("Uploading profile picture for driver ID: {}", driverId);

    Driver driver = getDriverById(driverId);

    // Validate file
    driverValidator.validateProfilePicture(file);

    try {
      // 1) Resolve base + profiles dir
      Path base = Path.of(ensureTrailingSlash(uploadBaseDir)).toAbsolutePath().normalize();
      Path profilesPath = base.resolve(ensureTrailingSlash(profilesDir)).normalize();
      Files.createDirectories(profilesPath);

      // 2) Determine and validate extension
      String original = Optional.ofNullable(file.getOriginalFilename()).orElse("").trim();
      String ext = ".jpg";
      int dot = original.lastIndexOf('.');
      if (dot >= 0 && dot < original.length() - 1) {
        ext = original.substring(dot).toLowerCase();
      }
      if (!ALLOWED_EXT.contains(ext)) {
        throw new InvalidDriverDataException("profilePicture", "Unsupported image type. Allowed: " + ALLOWED_EXT);
      }

      // 3) New filename
      String newFileName = "driver_" + driverId + "_" + System.currentTimeMillis() + ext;

      // 4) Destination (path traversal safe)
      Path destination = profilesPath.resolve(newFileName).normalize();
      if (!destination.startsWith(base)) {
        throw new DriverFileUploadException("profile picture", new SecurityException("Invalid upload path"));
      }

      // 5) Write file
      Files.copy(file.getInputStream(), destination, StandardCopyOption.REPLACE_EXISTING);

      // 6) Optional: delete previous file if it was under our uploads base
      safeDeleteIfUnderBase(base, driver.getProfilePicture());

      // 7) Public URL served by /uploads/** → base dir
      String publicUrl = "/uploads/" + ensureTrailingSlash(profilesDir) + newFileName;

      // 8) Persist
      driver.setProfilePicture(publicUrl);
      driverRepository.save(driver);

      LOG.info("Profile picture uploaded successfully for driver ID: {}", driverId);
      return AssetUrlHelper.toAbsoluteUrl(publicUrl);
    } catch (IOException e) {
      LOG.error("Failed to save profile picture for driver ID {}: {}", driverId, e.getMessage(), e);
      throw new DriverFileUploadException("profile picture", e);
    }
  }

  public Driver createDriverFromRequest(DriverCreateRequest request) {
    driverValidator.validateDriverCreation(request);
    Driver driver = driverDomainService.buildNewDriver(request);
    Driver saved = driverRepository.save(driver);
    syncLicenseDocument(saved, request.getLicenseNumber());
    hydrateLicenseNumber(saved);
    return saved;
  }

  public Page<LocationHistoryDto> getDriverLocationHistoryPaginated(
      Long driverId, int page, int size) {
    if (mongoService != null) {
      List<LocationHistoryDto> docs = mongoService.findByDriver(driverId, page, size);
      return new PageImpl<>(docs, PageRequest.of(page, size), docs.size());
    }
    if (requireMongoForHistoryReads) {
      throw new IllegalStateException("Location history store unavailable (MongoDB not configured)");
    }
    Page<LocationHistory> history = locationHistoryRepository.findByDriverIdOrderByTimestampDesc(
        driverId, PageRequest.of(page, size));
    return history.map(LocationHistoryDto::fromEntity);
  }

  // -------------------- Helpers --------------------

  private static String ensureTrailingSlash(String p) {
    if (p == null || p.isBlank())
      return "";
    return p.endsWith("/") ? p : p + "/";
  }

  private void safeDeleteIfUnderBase(Path base, String publicUrl) {
    try {
      if (publicUrl == null || publicUrl.isBlank())
        return;
      // Expect URLs like /uploads/profiles/filename
      if (!publicUrl.startsWith("/uploads/"))
        return;

      String relative = publicUrl.substring("/uploads/".length());
      Path candidate = base.resolve(relative).normalize();
      if (!candidate.startsWith(base))
        return; // safety
      Files.deleteIfExists(candidate);
    } catch (Exception ignored) {
      // best effort cleanup
    }
  }

  // integration search with filters (non-breaking, new overload)

  public List<DriverDto> searchDrivers(
      String keyword,
      VehicleType truckType,
      DriverStatus status,
      String zone,
      String licensePlate,
      boolean includeLocationHistory) {

    List<Driver> drivers = driverRepository.searchDriversWithFilters(
        Optional.ofNullable(keyword).orElse("").trim(),
        Optional.ofNullable(licensePlate).orElse("").trim(),
        truckType,
        status,
        zone);
    hydrateLicenseNumbers(drivers);

    return drivers.stream()
        .map(d -> includeLocationHistory
            ? DriverDto.fromEntityWithLatestLocation(d)
            : DriverDto.fromEntityWithoutLocationHistory(d))
        .toList();
  }

  // integration getById with optional location history (non-breaking overload)
  public DriverDto getDriverById(Long id, boolean includeLocationHistory) {
    Driver driver = driverRepository
        .findByIdWithVehicles(id)
        .orElseThrow(() -> new RuntimeException("Driver not found with id=" + id));
    hydrateLicenseNumber(driver);

    return includeLocationHistory
        ? DriverDto.fromEntityWithLatestLocation(driver)
        : DriverDto.fromEntityWithoutLocationHistory(driver);
  }

  private void syncLicenseDocument(Driver driver, String requestedLicenseNumber) {
    String normalizedLicenseNumber = normalizeLicenseNumber(requestedLicenseNumber);
    if (normalizedLicenseNumber == null) {
      return;
    }

    validateLicenseDocumentUniqueness(normalizedLicenseNumber, driver.getId());

    DriverDocument document = driverDocumentRepository.findLicenseDocumentsByDriverId(driver.getId()).stream()
        .findFirst()
        .orElseGet(() -> {
          DriverDocument fresh = new DriverDocument();
          fresh.setDriver(driver);
          fresh.setCategory("license");
          fresh.setIsRequired(Boolean.TRUE);
          return fresh;
        });

    document.setDriver(driver);
    document.setCategory("license");
    document.setName(normalizedLicenseNumber);
    if (document.getIsRequired() == null) {
      document.setIsRequired(Boolean.TRUE);
    }
    driverDocumentRepository.save(document);
    driver.setLicenseNumber(normalizedLicenseNumber);
  }

  private void validateLicenseDocumentUniqueness(String normalizedLicenseNumber, Long currentDriverId) {
    String lookupValue = normalizedLicenseNumber.toLowerCase();
    Optional<DriverDocument> duplicate = driverDocumentRepository
        .findLicenseDocumentsByNormalizedName(lookupValue)
        .stream()
        .filter(doc -> doc.getDriver() != null && doc.getDriver().getId() != null)
        .filter(doc -> !doc.getDriver().getId().equals(currentDriverId))
        .findFirst();

    if (duplicate.isPresent()) {
      throw new InvalidDriverDataException("licenseNumber", "is already in use");
    }
  }

  private void hydrateLicenseNumber(Driver driver) {
    if (driver == null || driver.getId() == null) {
      return;
    }
    driver.setLicenseNumber(
        driverDocumentRepository.findLicenseDocumentsByDriverId(driver.getId()).stream()
            .map(DriverDocument::getName)
            .map(this::normalizeLicenseNumber)
            .filter(value -> value != null && !value.isBlank())
            .findFirst()
            .orElse(null));
  }

  private void hydrateLicenseNumbers(List<Driver> drivers) {
    if (drivers == null || drivers.isEmpty()) {
      return;
    }

    List<Long> driverIds = drivers.stream()
        .map(Driver::getId)
        .filter(id -> id != null)
        .distinct()
        .toList();
    if (driverIds.isEmpty()) {
      return;
    }

    Map<Long, String> licenseByDriverId = new LinkedHashMap<>();
    for (DriverDocument document : driverDocumentRepository.findLicenseDocumentsByDriverIds(driverIds)) {
      Long driverId = document.getDriver() != null ? document.getDriver().getId() : null;
      String normalized = normalizeLicenseNumber(document.getName());
      if (driverId != null && normalized != null && !licenseByDriverId.containsKey(driverId)) {
        licenseByDriverId.put(driverId, normalized);
      }
    }

    for (Driver driver : drivers) {
      driver.setLicenseNumber(licenseByDriverId.get(driver.getId()));
    }
  }

  private String normalizeLicenseNumber(String licenseNumber) {
    if (licenseNumber == null) {
      return null;
    }
    String normalized = licenseNumber.trim().toUpperCase();
    return normalized.isBlank() ? null : normalized;
  }
}
