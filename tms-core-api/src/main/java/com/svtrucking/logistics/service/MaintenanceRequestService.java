package com.svtrucking.logistics.service;

import com.svtrucking.logistics.dto.MaintenanceRequestDto;
import com.svtrucking.logistics.enums.MaintenanceRequestStatus;
import com.svtrucking.logistics.exception.ResourceNotFoundException;
import com.svtrucking.logistics.model.MaintenanceRequest;
import com.svtrucking.logistics.model.User;
import com.svtrucking.logistics.model.Vehicle;
import com.svtrucking.logistics.repository.MaintenanceRequestRepository;
import com.svtrucking.logistics.repository.UserRepository;
import com.svtrucking.logistics.repository.VehicleRepository;
import java.time.LocalDateTime;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Slf4j
public class MaintenanceRequestService {

  private final MaintenanceRequestRepository maintenanceRequestRepository;
  private final VehicleRepository vehicleRepository;
  private final UserRepository userRepository;
  private final com.svtrucking.logistics.repository.FailureCodeRepository failureCodeRepository;
  private final com.svtrucking.logistics.repository.WorkOrderRepository workOrderRepository;

  private synchronized String generateMrNumber() {
    int year = LocalDateTime.now().getYear();
    // Simple monotonic-ish id: MR-YYYY-<epochSecondsLast5>
    // If you need strict sequencing, add a repository query like WorkOrderService does.
    long suffix = (System.currentTimeMillis() / 1000) % 100000;
    return String.format("MR-%d-%05d", year, suffix);
  }

  @Transactional(readOnly = true)
  public Page<MaintenanceRequestDto> search(
      String search,
      MaintenanceRequestStatus status,
      Long vehicleId,
      Long failureCodeId,
      Pageable pageable) {
    String q = (search == null || search.isBlank()) ? null : search.trim();
    Page<MaintenanceRequest> page =
        maintenanceRequestRepository.search(q, status, vehicleId, failureCodeId, pageable);
    java.util.List<Long> mrIds =
        page.getContent().stream().map(MaintenanceRequest::getId).toList();
    java.util.Map<Long, com.svtrucking.logistics.model.WorkOrder> woByMrId =
        mrIds.isEmpty()
            ? java.util.Collections.emptyMap()
            : workOrderRepository.findByMaintenanceRequestIdIn(mrIds).stream()
                .filter(wo -> wo.getMaintenanceRequest() != null)
                .collect(
                    java.util.stream.Collectors.toMap(
                        wo -> wo.getMaintenanceRequest().getId(), wo -> wo));

    return page.map(
        mr -> {
          MaintenanceRequestDto dto = MaintenanceRequestDto.fromEntity(mr);
          com.svtrucking.logistics.model.WorkOrder wo = woByMrId.get(mr.getId());
          if (wo != null) {
            dto.setWorkOrderId(wo.getId());
            dto.setWorkOrderNumber(wo.getWoNumber());
            dto.setWorkOrderStatus(wo.getStatus());
          }
          return dto;
        });
  }

  @Transactional(readOnly = true)
  public MaintenanceRequestDto getById(Long id) {
    MaintenanceRequest mr =
        maintenanceRequestRepository
            .findById(id)
            .orElseThrow(() -> new ResourceNotFoundException("Maintenance request not found: " + id));
    MaintenanceRequestDto dto = MaintenanceRequestDto.fromEntity(mr);
    workOrderRepository
        .findByMaintenanceRequestId(id)
        .ifPresent(
            wo -> {
              dto.setWorkOrderId(wo.getId());
              dto.setWorkOrderNumber(wo.getWoNumber());
              dto.setWorkOrderStatus(wo.getStatus());
            });
    return dto;
  }

  @Transactional
  public MaintenanceRequestDto create(MaintenanceRequestDto dto, Long userId) {
    Vehicle vehicle =
        vehicleRepository
            .findById(dto.getVehicleId())
            .orElseThrow(() -> new ResourceNotFoundException("Vehicle not found: " + dto.getVehicleId()));
    User createdBy = userId != null ? userRepository.findById(userId).orElse(null) : null;
    com.svtrucking.logistics.model.FailureCode failureCode =
        dto.getFailureCodeId() != null
            ? failureCodeRepository
                .findById(dto.getFailureCodeId())
                .orElseThrow(
                    () ->
                        new ResourceNotFoundException(
                            "Failure code not found: " + dto.getFailureCodeId()))
            : null;

    MaintenanceRequest mr =
        MaintenanceRequest.builder()
            .mrNumber(generateMrNumber())
            .vehicle(vehicle)
            .title(dto.getTitle())
            .description(dto.getDescription())
            .priority(dto.getPriority() != null ? dto.getPriority() : com.svtrucking.logistics.enums.Priority.NORMAL)
            .status(MaintenanceRequestStatus.SUBMITTED)
            .requestType(
                dto.getRequestType() != null
                    ? dto.getRequestType()
                    : com.svtrucking.logistics.enums.MaintenanceRequestType.REPAIR)
            .createdBy(createdBy)
            .requestedAt(LocalDateTime.now())
            .failureCode(failureCode)
            .isDeleted(false)
            .build();

    MaintenanceRequest saved = maintenanceRequestRepository.save(mr);
    return MaintenanceRequestDto.fromEntity(saved);
  }

  @Transactional
  public MaintenanceRequestDto update(Long id, MaintenanceRequestDto dto) {
    MaintenanceRequest mr =
        maintenanceRequestRepository
            .findById(id)
            .orElseThrow(() -> new ResourceNotFoundException("Maintenance request not found: " + id));

    if (mr.getStatus() == MaintenanceRequestStatus.APPROVED) {
      throw new IllegalStateException("Cannot update an approved maintenance request.");
    }

    if (dto.getTitle() != null) mr.setTitle(dto.getTitle());
    mr.setDescription(dto.getDescription());
    if (dto.getPriority() != null) mr.setPriority(dto.getPriority());
    if (dto.getRequestType() != null) mr.setRequestType(dto.getRequestType());
    if (dto.getFailureCodeId() != null) {
      com.svtrucking.logistics.model.FailureCode failureCode =
          failureCodeRepository
              .findById(dto.getFailureCodeId())
              .orElseThrow(
                  () ->
                      new ResourceNotFoundException(
                          "Failure code not found: " + dto.getFailureCodeId()));
      mr.setFailureCode(failureCode);
    }
    mr.setUpdatedAt(LocalDateTime.now());

    return MaintenanceRequestDto.fromEntity(maintenanceRequestRepository.save(mr));
  }

  @Transactional
  public MaintenanceRequestDto approve(Long id, Long userId, String remarks) {
    MaintenanceRequest mr =
        maintenanceRequestRepository
            .findById(id)
            .orElseThrow(() -> new ResourceNotFoundException("Maintenance request not found: " + id));

    if (mr.getStatus() != MaintenanceRequestStatus.SUBMITTED && mr.getStatus() != MaintenanceRequestStatus.DRAFT) {
      throw new IllegalStateException("Only SUBMITTED/DRAFT maintenance requests can be approved.");
    }

    User approver = userId != null ? userRepository.findById(userId).orElse(null) : null;
    mr.setStatus(MaintenanceRequestStatus.APPROVED);
    mr.setApprovedAt(LocalDateTime.now());
    mr.setApprovedBy(approver);
    mr.setApprovalRemarks(remarks);
    mr.setRejectionReason(null);
    mr.setRejectedAt(null);
    mr.setRejectedBy(null);
    return MaintenanceRequestDto.fromEntity(maintenanceRequestRepository.save(mr));
  }

  @Transactional
  public MaintenanceRequestDto reject(Long id, Long userId, String reason) {
    MaintenanceRequest mr =
        maintenanceRequestRepository
            .findById(id)
            .orElseThrow(() -> new ResourceNotFoundException("Maintenance request not found: " + id));

    if (mr.getStatus() != MaintenanceRequestStatus.SUBMITTED && mr.getStatus() != MaintenanceRequestStatus.DRAFT) {
      throw new IllegalStateException("Only SUBMITTED/DRAFT maintenance requests can be rejected.");
    }

    User rejector = userId != null ? userRepository.findById(userId).orElse(null) : null;
    mr.setStatus(MaintenanceRequestStatus.REJECTED);
    mr.setRejectedAt(LocalDateTime.now());
    mr.setRejectedBy(rejector);
    mr.setRejectionReason(reason);
    return MaintenanceRequestDto.fromEntity(maintenanceRequestRepository.save(mr));
  }

  @Transactional
  public void delete(Long id) {
    MaintenanceRequest mr =
        maintenanceRequestRepository
            .findById(id)
            .orElseThrow(() -> new ResourceNotFoundException("Maintenance request not found: " + id));
    mr.setIsDeleted(true);
    maintenanceRequestRepository.save(mr);
  }
}
