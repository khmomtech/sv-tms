package com.svtrucking.logistics.service;

import com.svtrucking.logistics.dto.*;
import com.svtrucking.logistics.dto.CaseTaskRequest;
import com.svtrucking.logistics.enums.*;
import com.svtrucking.logistics.model.*;
import com.svtrucking.logistics.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Calendar;
import java.util.List;
import java.util.NoSuchElementException;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional
@Slf4j
public class CaseService {

  private final CaseRepository caseRepository;
  private final DriverIssueRepository incidentRepository;
  private final CaseIncidentRepository caseIncidentRepository;
  private final CaseTimelineRepository caseTimelineRepository;
  private final DriverRepository driverRepository;
  private final VehicleRepository vehicleRepository;
  private final UserRepository userRepository;
  private final CaseTaskRepository caseTaskRepository;

  /**
   * Generate unique case code in format: CASE-YYYY-NNNN
   */
  private String generateCaseCode() {
    int year = Calendar.getInstance().get(Calendar.YEAR);
    String prefix = "CASE-" + year + "-";
    
    // Find the latest case code for this year
    Case latestCase = caseRepository
        .findFirstByCodeStartingWithOrderByCodeDesc(prefix)
        .orElse(null);
    
    int nextNumber = 1;
    if (latestCase != null && latestCase.getCode() != null) {
      String lastCode = latestCase.getCode();
      String numberPart = lastCode.substring(prefix.length());
      try {
        nextNumber = Integer.parseInt(numberPart) + 1;
      } catch (NumberFormatException e) {
        log.warn("Failed to parse case number from code: {}", lastCode);
      }
    }
    
    return prefix + String.format("%04d", nextNumber);
  }

  /**
   * Create a new case
   */
  public CaseDto createCase(CaseDto dto, Long currentUserId) {
    // Validate required fields
    if (dto.getCategory() == null) {
      throw new IllegalArgumentException("Category is required");
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

    User assignedTo = null;
    if (dto.getAssignedToUserId() != null) {
      assignedTo = userRepository.findById(dto.getAssignedToUserId())
          .orElseThrow(() -> new NoSuchElementException("User not found: " + dto.getAssignedToUserId()));
    }

    User createdBy = null;
    if (currentUserId != null) {
      createdBy = userRepository.findById(currentUserId).orElse(null);
    }

    Case caseEntity = Case.builder()
        .code(generateCaseCode())
        .title(dto.getTitle())
        .description(dto.getDescription())
        .category(dto.getCategory())
        .severity(dto.getSeverity() != null ? dto.getSeverity() : IssueSeverity.MEDIUM)
        .status(CaseStatus.OPEN)
        .assignedToUser(assignedTo)
        .assignedTeam(dto.getAssignedTeam())
        .driver(driver)
        .vehicle(vehicle)
        .slaTargetAt(dto.getSlaTargetAt())
        .createdByUser(createdBy)
        .isDeleted(false)
        .build();

    caseEntity = caseRepository.save(caseEntity);
    
    // Add timeline entry for case creation
    addTimelineEntry(caseEntity.getId(), TimelineEntryType.CREATED, 
        "Case created: " + caseEntity.getTitle(), currentUserId);
    
    log.info("Created case: {} ({})", caseEntity.getCode(), caseEntity.getId());
    
    return mapToDto(caseEntity, false);
  }

  /**
   * Get case by ID
   */
  @Transactional(readOnly = true)
  public CaseDto getCaseById(Long id, boolean includeRelatedData) {
    Case caseEntity = caseRepository.findById(id)
        .orElseThrow(() -> new NoSuchElementException("Case not found: " + id));
    return mapToDto(caseEntity, includeRelatedData);
  }

  /**
   * Get case by code
   */
  @Transactional(readOnly = true)
  public CaseDto getCaseByCode(String code, boolean includeRelatedData) {
    Case caseEntity = caseRepository.findByCode(code)
        .orElseThrow(() -> new NoSuchElementException("Case not found: " + code));
    return mapToDto(caseEntity, includeRelatedData);
  }

  /**
   * List cases with filtering
   */
  @Transactional(readOnly = true)
  public Page<CaseDto> listCases(
      CaseStatus status,
      CaseCategory category,
      IssueSeverity severity,
      Long assignedToUserId,
      Long driverId,
      Long vehicleId,
      LocalDateTime createdAfter,
      LocalDateTime createdBefore,
      Pageable pageable) {
    
    Page<Case> cases = caseRepository.filterCases(
        status, category, severity, assignedToUserId, driverId, vehicleId,
        createdAfter, createdBefore, pageable);
    
    return cases.map(c -> mapToDto(c, false));
  }

  /**
   * Search cases by text
   */
  @Transactional(readOnly = true)
  public Page<CaseDto> searchCases(String searchTerm, Pageable pageable) {
    Page<Case> cases = caseRepository.searchCases(searchTerm, pageable);
    return cases.map(c -> mapToDto(c, false));
  }

  /**
   * Update case
   */
  public CaseDto updateCase(Long id, CaseDto dto, Long currentUserId) {
    Case caseEntity = caseRepository.findById(id)
        .orElseThrow(() -> new NoSuchElementException("Case not found: " + id));

    boolean statusChanged = false;
    CaseStatus oldStatus = caseEntity.getStatus();

    if (dto.getTitle() != null) {
      caseEntity.setTitle(dto.getTitle());
    }
    if (dto.getDescription() != null) {
      caseEntity.setDescription(dto.getDescription());
    }
    if (dto.getCategory() != null) {
      caseEntity.setCategory(dto.getCategory());
    }
    if (dto.getSeverity() != null) {
      caseEntity.setSeverity(dto.getSeverity());
    }
    if (dto.getStatus() != null && dto.getStatus() != oldStatus) {
      caseEntity.setStatus(dto.getStatus());
      statusChanged = true;
    }
    if (dto.getAssignedTeam() != null) {
      caseEntity.setAssignedTeam(dto.getAssignedTeam());
    }
    if (dto.getSlaTargetAt() != null) {
      caseEntity.setSlaTargetAt(dto.getSlaTargetAt());
    }

    // Update assigned user if changed
    if (dto.getAssignedToUserId() != null) {
      User newAssignee = userRepository.findById(dto.getAssignedToUserId())
          .orElseThrow(() -> new NoSuchElementException("User not found: " + dto.getAssignedToUserId()));
      
      if (caseEntity.getAssignedToUser() == null || 
          !caseEntity.getAssignedToUser().getId().equals(newAssignee.getId())) {
        caseEntity.setAssignedToUser(newAssignee);
        addTimelineEntry(id, TimelineEntryType.ASSIGNED, 
            "Case assigned to " + newAssignee.getUsername(), currentUserId);
      }
    }

    caseEntity = caseRepository.save(caseEntity);

    // Add timeline entry for status change
    if (statusChanged) {
      addTimelineEntry(id, TimelineEntryType.STATUS_CHANGE, 
          "Status changed from " + oldStatus + " to " + dto.getStatus(), currentUserId);
      
      // If closing, set closed timestamp
      if (dto.getStatus() == CaseStatus.CLOSED) {
        caseEntity.setClosedAt(LocalDateTime.now());
        caseRepository.save(caseEntity);
      }
    }

    log.info("Updated case: {}", caseEntity.getCode());
    
    return mapToDto(caseEntity, false);
  }

  /**
   * Link incident to case (escalate)
   */
  public CaseDto linkIncidentToCase(Long caseId, Long incidentId, String notes, Long currentUserId) {
    Case caseEntity = caseRepository.findById(caseId)
        .orElseThrow(() -> new NoSuchElementException("Case not found: " + caseId));
    
    DriverIssue incident = incidentRepository.findById(incidentId)
        .orElseThrow(() -> new NoSuchElementException("Incident not found: " + incidentId));

    // Check if already linked
    if (caseIncidentRepository.existsByCaseEntityIdAndIncidentId(caseId, incidentId)) {
      throw new IllegalStateException("Incident is already linked to this case");
    }

    User linkedBy = null;
    if (currentUserId != null) {
      linkedBy = userRepository.findById(currentUserId).orElse(null);
    }

    // Create link
    CaseIncident caseIncident = CaseIncident.builder()
        .caseEntity(caseEntity)
        .incident(incident)
        .linkedByUser(linkedBy)
        .notes(notes)
        .build();
    
    caseIncidentRepository.save(caseIncident);

    // Update incident status
    incident.setIncidentStatus(IncidentStatus.LINKED_TO_CASE);
    incidentRepository.save(incident);

    // Add timeline entry
    addTimelineEntry(caseId, TimelineEntryType.INCIDENT_LINKED, 
        "Incident " + incident.getCode() + " linked to case", currentUserId);
    
    log.info("Linked incident {} to case {}", incident.getCode(), caseEntity.getCode());
    
    return mapToDto(caseEntity, true);
  }

  /**
   * Close case
   */
  public CaseDto closeCase(Long id, Long currentUserId) {
    Case caseEntity = caseRepository.findById(id)
        .orElseThrow(() -> new NoSuchElementException("Case not found: " + id));

    if (caseEntity.getStatus() == CaseStatus.CLOSED) {
      throw new IllegalStateException("Case is already closed");
    }

    caseEntity.setStatus(CaseStatus.CLOSED);
    caseEntity.setClosedAt(LocalDateTime.now());
    caseEntity = caseRepository.save(caseEntity);

    addTimelineEntry(id, TimelineEntryType.STATUS_CHANGE, 
        "Case closed", currentUserId);
    
    log.info("Closed case: {}", caseEntity.getCode());
    
    return mapToDto(caseEntity, false);
  }

  /**
   * Delete case (soft delete)
   */
  public void deleteCase(Long id) {
    Case caseEntity = caseRepository.findById(id)
        .orElseThrow(() -> new NoSuchElementException("Case not found: " + id));

    caseEntity.setIsDeleted(true);
    caseRepository.save(caseEntity);
    log.info("Deleted case: {}", caseEntity.getCode());
  }

  /**
   * Add timeline entry
   */
  private void addTimelineEntry(Long caseId, TimelineEntryType type, String message, Long userId) {
    Case caseEntity = caseRepository.findById(caseId)
        .orElseThrow(() -> new NoSuchElementException("Case not found: " + caseId));

    User user = null;
    if (userId != null) {
      user = userRepository.findById(userId).orElse(null);
    }

    CaseTimeline entry = CaseTimeline.builder()
        .caseEntity(caseEntity)
        .entryType(type)
        .message(message)
        .createdByUser(user)
        .build();
    
    caseTimelineRepository.save(entry);
  }

  /**
   * Get case statistics
   */
  @Transactional(readOnly = true)
  public java.util.Map<String, Long> getCaseStatistics() {
    return java.util.Map.of(
        "open", caseRepository.countByStatusAndIsDeletedFalse(CaseStatus.OPEN),
        "investigation", caseRepository.countByStatusAndIsDeletedFalse(CaseStatus.INVESTIGATION),
        "pending_approval", caseRepository.countByStatusAndIsDeletedFalse(CaseStatus.PENDING_APPROVAL),
        "closed", caseRepository.countByStatusAndIsDeletedFalse(CaseStatus.CLOSED),
        "total", caseRepository.count()
    );
  }

  /**
   * Get overdue cases
   */
  @Transactional(readOnly = true)
  public List<CaseDto> getOverdueCases() {
    List<Case> overdueCases = caseRepository.findOverdueCases(LocalDateTime.now());
    return overdueCases.stream()
        .map(c -> mapToDto(c, false))
        .collect(Collectors.toList());
  }

  /**
   * Unlink incident from case
   */
  @Transactional
  public void unlinkIncidentFromCase(Long caseId, Long incidentId) {
    Case caseEntity = caseRepository.findById(caseId)
        .orElseThrow(() -> new IllegalArgumentException("Case not found"));

    DriverIssue incident = incidentRepository.findById(incidentId)
        .orElseThrow(() -> new IllegalArgumentException("Incident not found"));

    // Remove link
    caseIncidentRepository.deleteByCaseEntityIdAndIncidentId(caseId, incidentId);

    // Update incident status back to VALIDATED
    incident.setIncidentStatus(IncidentStatus.VALIDATED);
    incidentRepository.save(incident);

    // Add timeline entry
    addTimelineEntry(caseId, TimelineEntryType.INCIDENT_REMOVED,
        "Incident " + incident.getCode() + " unlinked from case", null);
  }

  /**
   * Map entity to DTO
   */
  private CaseDto mapToDto(Case caseEntity, boolean includeRelatedData) {
    CaseDto dto = CaseDto.builder()
        .id(caseEntity.getId())
        .code(caseEntity.getCode())
        .title(caseEntity.getTitle())
        .description(caseEntity.getDescription())
        .category(caseEntity.getCategory())
        .severity(caseEntity.getSeverity())
        .status(caseEntity.getStatus())
        .assignedToUserId(caseEntity.getAssignedToUser() != null ? caseEntity.getAssignedToUser().getId() : null)
        .assignedToUsername(caseEntity.getAssignedToUser() != null ? caseEntity.getAssignedToUser().getUsername() : null)
        .assignedTeam(caseEntity.getAssignedTeam())
        .driverId(caseEntity.getDriver() != null ? caseEntity.getDriver().getId() : null)
        .driverName(caseEntity.getDriver() != null ? 
            caseEntity.getDriver().getFirstName() + " " + caseEntity.getDriver().getLastName() : null)
        .vehicleId(caseEntity.getVehicle() != null ? caseEntity.getVehicle().getId() : null)
        .vehiclePlate(caseEntity.getVehicle() != null ? caseEntity.getVehicle().getLicensePlate() : null)
        .slaTargetAt(caseEntity.getSlaTargetAt())
        .createdAt(caseEntity.getCreatedAt())
        .createdByUserId(caseEntity.getCreatedByUser() != null ? caseEntity.getCreatedByUser().getId() : null)
        .createdByUsername(caseEntity.getCreatedByUser() != null ? caseEntity.getCreatedByUser().getUsername() : null)
        .updatedAt(caseEntity.getUpdatedAt())
        .closedAt(caseEntity.getClosedAt())
        .incidentCount((int) caseIncidentRepository.countByCaseId(caseEntity.getId()))
        .taskCount((int) caseTaskRepository.countByCaseId(caseEntity.getId()))
        .build();

    if (includeRelatedData) {
      // Include related incidents, tasks, attachments, timeline
      List<CaseIncident> caseIncidents = caseIncidentRepository.findByCaseEntityId(caseEntity.getId());
      dto.setIncidents(caseIncidents.stream()
          .map(ci -> mapIncidentToDto(ci.getIncident()))
          .collect(Collectors.toList()));
      List<CaseTask> caseTasks = caseTaskRepository.findByCaseEntityIdOrderByCreatedAtDesc(caseEntity.getId());
      dto.setTasks(caseTasks.stream().map(this::mapTaskToDto).toList());
    }

    return dto;
  }

  // ---------------------------------------------------------------------------
  // Case task helpers
  // ---------------------------------------------------------------------------
  @Transactional(readOnly = true)
  public List<CaseTaskDto> getCaseTasks(Long caseId) {
    Case caseEntity = caseRepository.findById(caseId)
        .orElseThrow(() -> new NoSuchElementException("Case not found: " + caseId));
    return caseTaskRepository.findByCaseEntityIdOrderByCreatedAtDesc(caseEntity.getId())
        .stream()
        .map(this::mapTaskToDto)
        .toList();
  }

  public CaseTaskDto createCaseTask(Long caseId, CaseTaskRequest request, Long currentUserId) {
    Case caseEntity = caseRepository.findById(caseId)
        .orElseThrow(() -> new NoSuchElementException("Case not found: " + caseId));

    User owner = null;
    if (request.ownerUserId() != null) {
      owner = userRepository.findById(request.ownerUserId())
          .orElseThrow(() -> new NoSuchElementException("User not found: " + request.ownerUserId()));
    }

    User createdBy = currentUserId != null ? userRepository.findById(currentUserId).orElse(null) : null;

    CaseTask task = CaseTask.builder()
        .caseEntity(caseEntity)
        .title(request.title())
        .description(request.description())
        .status(request.status() != null ? request.status() : CaseTaskStatus.TODO)
        .ownerUser(owner)
        .dueAt(request.dueAt())
        .createdByUser(createdBy)
        .build();

    if (task.getStatus() == CaseTaskStatus.DONE) {
      task.markCompleted(createdBy);
    }

    task = caseTaskRepository.save(task);

    addTimelineEntry(
        caseId,
        TimelineEntryType.TASK_ADDED,
        "Task added: " + task.getTitle(),
        currentUserId);

    return mapTaskToDto(task);
  }

  public CaseTaskDto updateCaseTask(
      Long caseId, Long taskId, CaseTaskRequest request, Long currentUserId) {
    CaseTask task = caseTaskRepository.findById(taskId)
        .orElseThrow(() -> new NoSuchElementException("Case task not found: " + taskId));

    if (!task.getCaseEntity().getId().equals(caseId)) {
      throw new IllegalArgumentException("Task does not belong to this case");
    }

    if (request.title() != null) task.setTitle(request.title());
    if (request.description() != null) task.setDescription(request.description());
    if (request.dueAt() != null) task.setDueAt(request.dueAt());
    if (request.ownerUserId() != null) {
      User owner = userRepository.findById(request.ownerUserId())
          .orElseThrow(() -> new NoSuchElementException("User not found: " + request.ownerUserId()));
      task.setOwnerUser(owner);
    }
    if (request.status() != null) {
      task.setStatus(request.status());
      if (request.status() == CaseTaskStatus.DONE) {
        User completedBy = currentUserId != null ? userRepository.findById(currentUserId).orElse(null) : null;
        task.markCompleted(completedBy);
      }
    }

    task = caseTaskRepository.save(task);

    addTimelineEntry(
        caseId,
        TimelineEntryType.NOTE,
        "Task updated: " + task.getTitle(),
        currentUserId);

    return mapTaskToDto(task);
  }

  public void deleteCaseTask(Long caseId, Long taskId) {
    CaseTask task = caseTaskRepository.findById(taskId)
        .orElseThrow(() -> new NoSuchElementException("Case task not found: " + taskId));
    if (!task.getCaseEntity().getId().equals(caseId)) {
      throw new IllegalArgumentException("Task does not belong to this case");
    }
    caseTaskRepository.delete(task);
  }

  private CaseTaskDto mapTaskToDto(CaseTask task) {
    LocalDateTime now = LocalDateTime.now();
    boolean overdue = task.getDueAt() != null
        && task.getStatus() != CaseTaskStatus.DONE
        && task.getDueAt().isBefore(now);

    return CaseTaskDto.builder()
        .id(task.getId())
        .caseId(task.getCaseEntity().getId())
        .caseCode(task.getCaseEntity().getCode())
        .title(task.getTitle())
        .description(task.getDescription())
        .status(task.getStatus())
        .ownerUserId(task.getOwnerUser() != null ? task.getOwnerUser().getId() : null)
        .ownerUsername(task.getOwnerUser() != null ? task.getOwnerUser().getUsername() : null)
        .dueAt(task.getDueAt())
        .createdAt(task.getCreatedAt())
        .createdByUserId(task.getCreatedByUser() != null ? task.getCreatedByUser().getId() : null)
        .createdByUsername(task.getCreatedByUser() != null ? task.getCreatedByUser().getUsername() : null)
        .completedAt(task.getCompletedAt())
        .completedByUserId(task.getCompletedByUser() != null ? task.getCompletedByUser().getId() : null)
        .completedByUsername(task.getCompletedByUser() != null ? task.getCompletedByUser().getUsername() : null)
        .isOverdue(overdue)
        .build();
  }

  /**
   * Quick incident mapping for case context
   */
  private IncidentDto mapIncidentToDto(DriverIssue incident) {
    return IncidentDto.builder()
        .id(incident.getId())
        .code(incident.getCode())
        .title(incident.getTitle())
        .incidentGroup(incident.getIncidentGroup())
        .incidentType(incident.getIncidentType())
        .severity(incident.getSeverity())
        .incidentStatus(incident.getIncidentStatus())
        .reportedAt(incident.getReportedAt())
        .build();
  }
}
