package com.svtrucking.logistics.service;

import com.svtrucking.logistics.dto.IncidentDto;
import com.svtrucking.logistics.dto.IncidentStatisticsDto;
import com.svtrucking.logistics.enums.*;
import com.svtrucking.logistics.model.*;
import com.svtrucking.logistics.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional
@Slf4j
public class IncidentService {

  private final DriverIssueRepository incidentRepository;
  private final DriverRepository driverRepository;
  private final VehicleRepository vehicleRepository;
  private final DispatchRepository dispatchRepository;
  private final UserRepository userRepository;
  private final CaseIncidentRepository caseIncidentRepository;

  @Value("${app.upload.dir:uploads/incidents}")
  private String uploadDir;

  /**
   * Generate unique incident code in format: INC-YYYY-NNNN
   */
  private String generateIncidentCode() {
    int year = Calendar.getInstance().get(Calendar.YEAR);
    String prefix = "INC-" + year + "-";

    // Find the latest incident code for this year
    DriverIssue latestIncident = incidentRepository
        .findFirstByCodeStartingWithOrderByCodeDesc(prefix)
        .orElse(null);

    int nextNumber = 1;
    if (latestIncident != null && latestIncident.getCode() != null) {
      String lastCode = latestIncident.getCode();
      String numberPart = lastCode.substring(prefix.length());
      try {
        nextNumber = Integer.parseInt(numberPart) + 1;
      } catch (NumberFormatException e) {
        log.warn("Failed to parse incident number from code: {}", lastCode);
      }
    }

    return prefix + String.format("%04d", nextNumber);
  }

  /**
   * Create a new incident
   */
  public IncidentDto createIncident(IncidentDto dto, Long currentUserId) {
    // Validate required fields
    if (dto.getIncidentGroup() == null) {
      throw new IllegalArgumentException("Incident group is required");
    }
    if (dto.getIncidentType() == null) {
      throw new IllegalArgumentException("Incident type is required");
    }

    Driver driver = null;
    if (dto.getDriverId() != null) {
      driver = driverRepository.findById(dto.getDriverId())
          .orElseThrow(() -> new NoSuchElementException("Driver not found: " + dto.getDriverId()));
    }

    Vehicle vehicle = null;
    if (dto.getVehicleId() != null) {
      vehicle = vehicleRepository.findById(dto.getVehicleId())
          .orElseThrow(() -> new NoSuchElementException("Vehicle not found: " + dto.getVehicleId()));
    }

    Dispatch dispatch = null;
    if (dto.getTripId() != null) {
      dispatch = dispatchRepository.findById(dto.getTripId())
          .orElseThrow(() -> new NoSuchElementException("Trip/Dispatch not found: " + dto.getTripId()));
    }

    User reportedBy = null;
    if (currentUserId != null) {
      reportedBy = userRepository.findById(currentUserId).orElse(null);
    }

    DriverIssue incident = DriverIssue.builder()
        .code(generateIncidentCode())
        .incidentGroup(dto.getIncidentGroup())
        .incidentType(dto.getIncidentType())
        .title(dto.getTitle())
        .description(dto.getDescription())
        .severity(dto.getSeverity() != null ? dto.getSeverity() : IssueSeverity.MEDIUM)
        .incidentStatus(IncidentStatus.NEW)
        .source(dto.getSource() != null ? dto.getSource() : IncidentSource.SYSTEM)
        .driver(driver)
        .vehicle(vehicle)
        .dispatch(dispatch)
        .reportedByUser(reportedBy)
        .locationAddress(dto.getLocationText())
        .latitude(dto.getLocationLat())
        .longitude(dto.getLocationLng())
        .slaDueAt(dto.getSlaDueAt())
        .reportedAt(LocalDateTime.now())
        .isDeleted(false)
        .build();

    incident = incidentRepository.save(incident);
    log.info("Created incident: {} ({})", incident.getCode(), incident.getId());

    return mapToDto(incident);
  }

  /**
   * Get incident by ID
   */
  @Transactional(readOnly = true)
  public IncidentDto getIncidentById(Long id) {
    DriverIssue incident = incidentRepository.findById(id)
        .orElseThrow(() -> new NoSuchElementException("Incident not found: " + id));
    return mapToDto(incident);
  }

  /**
   * Get incident by code
   */
  @Transactional(readOnly = true)
  public IncidentDto getIncidentByCode(String code) {
    DriverIssue incident = incidentRepository.findByCode(code)
        .orElseThrow(() -> new NoSuchElementException("Incident not found: " + code));
    return mapToDto(incident);
  }

  /**
   * List incidents with filtering
   */
  @Transactional(readOnly = true)
  public Page<IncidentDto> listIncidents(
      IncidentStatus incidentStatus,
      IncidentGroup incidentGroup,
      IssueSeverity severity,
      Long driverId,
      Long vehicleId,
      LocalDateTime reportedAfter,
      LocalDateTime reportedBefore,
      Pageable pageable) {

    Page<DriverIssue> incidents = incidentRepository.filterIncidentsByNew(
        incidentStatus, incidentGroup, severity, driverId, vehicleId,
        reportedAfter, reportedBefore, pageable);

    return incidents.map(this::mapToDto);
  }

  /**
   * Update incident
   */
  public IncidentDto updateIncident(Long id, IncidentDto dto) {
    DriverIssue incident = incidentRepository.findById(id)
        .orElseThrow(() -> new NoSuchElementException("Incident not found: " + id));

    if (dto.getTitle() != null) {
      incident.setTitle(dto.getTitle());
    }
    if (dto.getDescription() != null) {
      incident.setDescription(dto.getDescription());
    }
    if (dto.getSeverity() != null) {
      incident.setSeverity(dto.getSeverity());
    }
    if (dto.getIncidentGroup() != null) {
      incident.setIncidentGroup(dto.getIncidentGroup());
    }
    if (dto.getIncidentType() != null) {
      incident.setIncidentType(dto.getIncidentType());
    }
    if (dto.getLocationText() != null) {
      incident.setLocationAddress(dto.getLocationText());
    }
    if (dto.getLocationLat() != null) {
      incident.setLatitude(dto.getLocationLat());
    }
    if (dto.getLocationLng() != null) {
      incident.setLongitude(dto.getLocationLng());
    }

    incident = incidentRepository.save(incident);
    log.info("Updated incident: {}", incident.getCode());

    return mapToDto(incident);
  }

  /**
   * Update incident fields (title/description) with driver ownership check.
   */
  public IncidentDto updateIncidentOwnedByDriver(
      Long id, Long driverId, String title, String description) {
    DriverIssue incident = incidentRepository
        .findById(id)
        .orElseThrow(() -> new NoSuchElementException("Incident not found: " + id));
    if (incident.getDriver() == null
        || incident.getDriver().getId() == null
        || !incident.getDriver().getId().equals(driverId)) {
      throw new SecurityException("Incident does not belong to the current driver");
    }
    incident.setTitle(title);
    incident.setDescription(description);
    incident = incidentRepository.save(incident);
    return mapToDto(incident);
  }

  /**
   * Validate an incident (change status to VALIDATED)
   */
  public IncidentDto validateIncident(Long id) {
    DriverIssue incident = incidentRepository.findById(id)
        .orElseThrow(() -> new NoSuchElementException("Incident not found: " + id));

    if (incident.getIncidentStatus() == IncidentStatus.LINKED_TO_CASE) {
      throw new IllegalStateException("Cannot validate incident that is already linked to a case");
    }

    incident.setIncidentStatus(IncidentStatus.VALIDATED);
    incident = incidentRepository.save(incident);
    log.info("Validated incident: {}", incident.getCode());

    return mapToDto(incident);
  }

  /**
   * Close an incident (without escalating to case)
   */
  public IncidentDto closeIncident(Long id, String resolutionNotes) {
    DriverIssue incident = incidentRepository.findById(id)
        .orElseThrow(() -> new NoSuchElementException("Incident not found: " + id));

    if (incident.getIncidentStatus() == IncidentStatus.LINKED_TO_CASE) {
      throw new IllegalStateException("Cannot close incident that is linked to a case. Close the case instead.");
    }

    incident.setIncidentStatus(IncidentStatus.CLOSED);
    incident.setResolutionNotes(resolutionNotes);
    incident.setResolvedAt(LocalDateTime.now());
    incident = incidentRepository.save(incident);
    log.info("Closed incident: {}", incident.getCode());

    return mapToDto(incident);
  }

  /**
   * Update incident status with driver ownership check (used by driver_app).
   */
  public IncidentDto updateIncidentStatusOwnedByDriver(
      Long id, Long driverId, IncidentStatus status) {
    DriverIssue incident = incidentRepository
        .findById(id)
        .orElseThrow(() -> new NoSuchElementException("Incident not found: " + id));
    if (incident.getDriver() == null
        || incident.getDriver().getId() == null
        || !incident.getDriver().getId().equals(driverId)) {
      throw new SecurityException("Incident does not belong to the current driver");
    }

    incident.setIncidentStatus(status);
    if (status == IncidentStatus.CLOSED) {
      incident.setResolvedAt(LocalDateTime.now());
    }
    incident = incidentRepository.save(incident);
    return mapToDto(incident);
  }

  /**
   * Delete incident with driver ownership check.
   */
  public void deleteIncidentOwnedByDriver(Long id, Long driverId) {
    DriverIssue incident = incidentRepository
        .findById(id)
        .orElseThrow(() -> new NoSuchElementException("Incident not found: " + id));
    if (incident.getDriver() == null
        || incident.getDriver().getId() == null
        || !incident.getDriver().getId().equals(driverId)) {
      throw new SecurityException("Incident does not belong to the current driver");
    }
    incidentRepository.delete(incident);
  }

  /**
   * Check if incident is linked to any case
   */
  @Transactional(readOnly = true)
  public boolean isLinkedToCase(Long incidentId) {
    return caseIncidentRepository.countByIncidentId(incidentId) > 0;
  }

  /**
   * Delete incident (soft delete)
   */
  public void deleteIncident(Long id) {
    DriverIssue incident = incidentRepository.findById(id)
        .orElseThrow(() -> new NoSuchElementException("Incident not found: " + id));

    // Check if linked to case
    if (isLinkedToCase(id)) {
      throw new IllegalStateException("Cannot delete incident that is linked to a case");
    }

    incident.setIsDeleted(true);
    incidentRepository.save(incident);
    log.info("Deleted incident: {}", incident.getCode());
  }

  /**
   * Map entity to DTO
   */
  private IncidentDto mapToDto(DriverIssue incident) {
    // Calculate photo count
    int photoCount = 0;
    if (incident.getPhotos() != null) {
      photoCount = incident.getPhotos().size();
    } else if (incident.getImages() != null) {
      photoCount = incident.getImages().size();
    }

    IncidentDto dto = IncidentDto.builder()
        .id(incident.getId())
        .code(incident.getCode())
        .incidentGroup(incident.getIncidentGroup())
        .incidentType(incident.getIncidentType())
        .title(incident.getTitle())
        .description(incident.getDescription())
        .severity(incident.getSeverity())
        .incidentStatus(incident.getIncidentStatus())
        .source(incident.getSource())
        .driverId(incident.getDriver() != null ? incident.getDriver().getId() : null)
        .driverName(incident.getDriver() != null
            ? incident.getDriver().getFirstName() + " " + incident.getDriver().getLastName()
            : null)
        .vehicleId(incident.getVehicle() != null ? incident.getVehicle().getId() : null)
        .vehiclePlate(incident.getVehicle() != null ? incident.getVehicle().getLicensePlate() : null)
        .tripId(incident.getDispatch() != null ? incident.getDispatch().getId() : null)
        .tripReference(
            incident.getDispatch() != null
                ? (incident.getDispatch().getRouteCode() != null ? incident.getDispatch().getRouteCode()
                    : incident.getDispatch().getTrackingNo())
                : null)
        .locationText(incident.getLocationAddress())
        .locationLat(incident.getLatitude())
        .locationLng(incident.getLongitude())
        .reportedByUserId(incident.getReportedByUser() != null ? incident.getReportedByUser().getId() : null)
        .reportedByUsername(incident.getReportedByUser() != null ? incident.getReportedByUser().getUsername() : null)
        .reportedAt(incident.getReportedAt())
        .slaDueAt(incident.getSlaDueAt())
        .assignedToId(incident.getAssignedTo() != null ? incident.getAssignedTo().getId() : null)
        .assignedToName(incident.getAssignedTo() != null ? incident.getAssignedTo().getUsername() : null)
        .photoUrls(
            incident.getImages() != null ? new java.util.ArrayList<>(incident.getImages()) : null)
        .photos(incident.getPhotos() != null ? incident.getPhotos().stream()
            .map(photo -> com.svtrucking.logistics.dto.DriverIssuePhotoDto.fromEntity(photo))
            .collect(Collectors.toList()) : null)
        .photoCount(photoCount)
        .resolutionNotes(incident.getResolutionNotes())
        .resolvedAt(incident.getResolvedAt())
        .createdAt(incident.getCreatedAt())
        .updatedAt(incident.getUpdatedAt())
        .linkedToCase(isLinkedToCase(incident.getId()))
        .build();

    // Get case info if linked
    if (dto.getLinkedToCase() != null && dto.getLinkedToCase()) {
      caseIncidentRepository.findByIncidentId(incident.getId())
          .stream()
          .findFirst()
          .ifPresent(caseIncident -> {
            dto.setCaseId(caseIncident.getCaseEntity().getId());
            dto.setCaseCode(caseIncident.getCaseEntity().getCode());
          });
    }

    return dto;
  }

  /**
   * Calculate incident statistics
   */
  @Transactional(readOnly = true)
  public IncidentStatisticsDto calculateStatistics(
      IncidentStatus incidentStatus,
      IncidentGroup incidentGroup,
      IssueSeverity severity,
      Long driverId,
      Long vehicleId,
      LocalDateTime reportedAfter,
      LocalDateTime reportedBefore) {

    // Get all incidents matching filters
    Page<DriverIssue> allIncidents = incidentRepository.filterIncidentsByNew(
        incidentStatus, incidentGroup, severity, driverId, vehicleId,
        reportedAfter, reportedBefore, Pageable.unpaged());

    List<DriverIssue> incidents = allIncidents.getContent();

    // Calculate by status
    Map<String, Long> byStatus = new HashMap<>();
    for (IncidentStatus status : IncidentStatus.values()) {
      long count = incidents.stream()
          .filter(i -> i.getIncidentStatus() == status)
          .count();
      byStatus.put(status.name(), count);
    }

    // Calculate by group
    Map<String, Long> byGroup = new HashMap<>();
    for (IncidentGroup group : IncidentGroup.values()) {
      long count = incidents.stream()
          .filter(i -> i.getIncidentGroup() == group)
          .count();
      byGroup.put(group.name(), count);
    }

    // Calculate by severity
    Map<String, Long> bySeverity = new HashMap<>();
    for (IssueSeverity sev : IssueSeverity.values()) {
      long count = incidents.stream()
          .filter(i -> i.getSeverity() == sev)
          .count();
      bySeverity.put(sev.name(), count);
    }

    // Calculate SLA metrics
    LocalDateTime now = LocalDateTime.now();
    long slaBreached = incidents.stream()
        .filter(i -> i.getSlaDueAt() != null && i.getSlaDueAt().isBefore(now) &&
            i.getIncidentStatus() != IncidentStatus.CLOSED &&
            i.getIncidentStatus() != IncidentStatus.LINKED_TO_CASE)
        .count();

    long withinSla = incidents.stream()
        .filter(i -> i.getSlaDueAt() == null || i.getSlaDueAt().isAfter(now) ||
            i.getIncidentStatus() == IncidentStatus.CLOSED ||
            i.getIncidentStatus() == IncidentStatus.LINKED_TO_CASE)
        .count();

    return IncidentStatisticsDto.builder()
        .total((long) incidents.size())
        .byStatus(byStatus)
        .byGroup(byGroup)
        .bySeverity(bySeverity)
        .slaBreached(slaBreached)
        .withinSla(withinSla)
        .build();
  }

  /**
   * Upload photos to incident
   */
  public IncidentDto uploadPhotos(Long incidentId, List<MultipartFile> files) {
    DriverIssue incident = incidentRepository.findById(incidentId)
        .orElseThrow(() -> new NoSuchElementException("Incident not found: " + incidentId));

    if (files == null || files.isEmpty()) {
      throw new IllegalArgumentException("No files provided");
    }

    // Create upload directory if it doesn't exist
    Path uploadPath = Paths.get(uploadDir);
    try {
      Files.createDirectories(uploadPath);
    } catch (IOException e) {
      throw new RuntimeException("Failed to create upload directory", e);
    }

    // Process each file
    List<DriverIssuePhoto> photos = new ArrayList<>();
    for (MultipartFile file : files) {
      if (file.isEmpty()) {
        continue;
      }

      try {
        // Generate unique filename
        String originalFilename = file.getOriginalFilename();
        String extension = "";
        if (originalFilename != null && originalFilename.contains(".")) {
          extension = originalFilename.substring(originalFilename.lastIndexOf("."));
        }
        String filename = "incident_" + incidentId + "_" +
            System.currentTimeMillis() + "_" +
            UUID.randomUUID().toString().substring(0, 8) +
            extension;

        // Save file
        Path filePath = uploadPath.resolve(filename);
        Files.copy(file.getInputStream(), filePath, StandardCopyOption.REPLACE_EXISTING);

        // Create photo entity
        DriverIssuePhoto photo = new DriverIssuePhoto();
        photo.setDriverIssue(incident);
        photo.setPhotoUrl("/uploads/incidents/" + filename);
        photo.setUploadedAt(LocalDateTime.now());
        photos.add(photo);

        log.info("Uploaded photo for incident {}: {}", incidentId, filename);
      } catch (IOException e) {
        log.error("Failed to upload file for incident {}", incidentId, e);
        throw new RuntimeException("Failed to upload file: " + file.getOriginalFilename(), e);
      }
    }

    // Add photos to incident
    incident.getPhotos().addAll(photos);
    incident = incidentRepository.save(incident);

    log.info("Uploaded {} photos to incident {}", photos.size(), incident.getCode());
    return mapToDto(incident);
  }

  /**
   * Returns a paginated list of incidents linked to dispatches belonging to the
   * given customer. Read-only — used by the customer mobile app incident list.
   * Default: page 0, size 50, ordered by reportedAt DESC.
   */
  @Transactional(readOnly = true)
  public Page<IncidentDto> getIncidentsByCustomerId(Long customerId, Pageable pageable) {
    return incidentRepository.findByDispatchCustomerId(customerId, pageable)
        .map(this::mapToDto);
  }
}
