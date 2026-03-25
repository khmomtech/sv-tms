package com.svtrucking.logistics.service;

import com.svtrucking.logistics.dto.DriverIssueDto;
import com.svtrucking.logistics.enums.IssueStatus;
import com.svtrucking.logistics.enums.IssueSeverity;
import com.svtrucking.logistics.exception.ResourceNotFoundException;
import com.svtrucking.logistics.model.Driver;
import com.svtrucking.logistics.model.DriverIssue;
import com.svtrucking.logistics.model.User;
import com.svtrucking.logistics.model.Vehicle;
import com.svtrucking.logistics.repository.DriverIssueRepository;
import com.svtrucking.logistics.repository.DriverRepository;
import com.svtrucking.logistics.repository.UserRepository;
import com.svtrucking.logistics.repository.VehicleRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Service
@RequiredArgsConstructor
@Slf4j
public class DriverIssueServiceEnhanced {

  private static final Logger LOG = LoggerFactory.getLogger(DriverIssueServiceEnhanced.class);

  private final DriverIssueRepository driverIssueRepository;
  private final DriverRepository driverRepository;
  private final VehicleRepository vehicleRepository;
  private final UserRepository userRepository;

  @Transactional(readOnly = true)
  public Page<DriverIssueDto> getAllIssues(Pageable pageable) {
    return driverIssueRepository.findByIsDeletedFalse(pageable).map(DriverIssueDto::fromEntity);
  }

  @Transactional(readOnly = true)
  public Page<DriverIssueDto> getIssuesByDriver(Long driverId, Pageable pageable) {
    return driverIssueRepository
        .findByDriverIdAndIsDeletedFalse(driverId, pageable)
        .map(DriverIssueDto::fromEntity);
  }

  @Transactional(readOnly = true)
  public Page<DriverIssueDto> getIssuesByStatus(IssueStatus status, Pageable pageable) {
    return driverIssueRepository
        .findByStatusAndIsDeletedFalse(status, pageable)
        .map(DriverIssueDto::fromEntity);
  }

  @Transactional(readOnly = true)
  public Page<DriverIssueDto> filterIssues(
      IssueStatus status,
      IssueSeverity severity,
      Long driverId,
      Long vehicleId,
      LocalDateTime reportedAfter,
      LocalDateTime reportedBefore,
      Pageable pageable) {
    return driverIssueRepository
        .filterIssues(status, severity, driverId, vehicleId, reportedAfter, reportedBefore, pageable)
        .map(DriverIssueDto::fromEntity);
  }

  @Transactional(readOnly = true)
  public List<DriverIssueDto> getUrgentIssues() {
    return driverIssueRepository.findUrgentIssues().stream()
        .map(DriverIssueDto::fromEntity)
        .collect(Collectors.toList());
  }

  @Transactional(readOnly = true)
  public DriverIssueDto getIssueById(Long id) {
    DriverIssue issue = driverIssueRepository
        .findById(id)
        .orElseThrow(() -> new ResourceNotFoundException("Driver issue not found with id: " + id));
    return DriverIssueDto.fromEntity(issue);
  }

  public DriverIssueDto createIssue(DriverIssueDto dto, Long driverId) {
    log.info("Creating driver issue: {}", dto.getTitle());

    Driver driver = driverRepository
        .findById(driverId)
        .orElseThrow(() -> new ResourceNotFoundException("Driver not found with id: " + driverId));

    Vehicle vehicle = vehicleRepository
        .findById(dto.getVehicleId())
        .orElseThrow(
            () -> new ResourceNotFoundException("Vehicle not found with id: " + dto.getVehicleId()));

    DriverIssue issue = DriverIssue.builder()
        .driver(driver)
        .vehicle(vehicle)
        .title(dto.getTitle())
        .description(dto.getDescription())
        .severity(dto.getSeverity())
        .status(IssueStatus.OPEN)
        .locationAddress(dto.getLocation())
        .currentKm(dto.getCurrentKm())
        .reportedAt(LocalDateTime.now())
        .isDeleted(false)
        .build();

    DriverIssue saved = driverIssueRepository.save(issue);
    log.info("Created driver issue with ID: {}", saved.getId());

    return DriverIssueDto.fromEntity(saved);
  }

  @Transactional
  public DriverIssueDto updateIssueStatus(Long issueId, IssueStatus status, Long userId) {
    log.info("Updating issue {} status to {}", issueId, status);

    DriverIssue issue = driverIssueRepository
        .findById(issueId)
        .orElseThrow(() -> new ResourceNotFoundException("Driver issue not found with id: " + issueId));

    issue.setStatus(status);

    if (status == IssueStatus.RESOLVED || status == IssueStatus.CLOSED) {
      issue.setResolvedAt(LocalDateTime.now());
    }

    DriverIssue updated = driverIssueRepository.save(issue);
    return DriverIssueDto.fromEntity(updated);
  }

  @Transactional
  public DriverIssueDto assignIssue(Long issueId, Long technicianId) {
    log.info("Assigning issue {} to technician {}", issueId, technicianId);

    DriverIssue issue = driverIssueRepository
        .findById(issueId)
        .orElseThrow(() -> new ResourceNotFoundException("Driver issue not found with id: " + issueId));

    User technician = userRepository
        .findById(technicianId)
        .orElseThrow(
            () -> new ResourceNotFoundException("Technician not found with id: " + technicianId));

    issue.setAssignedTo(technician);
    issue.setStatus(IssueStatus.IN_PROGRESS);

    DriverIssue updated = driverIssueRepository.save(issue);
    return DriverIssueDto.fromEntity(updated);
  }

  @Transactional
  public void deleteIssue(Long id) {
    log.info("Soft deleting driver issue: {}", id);

    DriverIssue issue = driverIssueRepository
        .findById(id)
        .orElseThrow(() -> new ResourceNotFoundException("Driver issue not found with id: " + id));

    issue.setIsDeleted(true);
    driverIssueRepository.save(issue);
  }

  @Transactional(readOnly = true)
  public Long countByStatus(IssueStatus status) {
    return driverIssueRepository.countByStatusAndIsDeletedFalse(status);
  }
}
