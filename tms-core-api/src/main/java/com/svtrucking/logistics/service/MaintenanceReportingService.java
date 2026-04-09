package com.svtrucking.logistics.service;

import com.svtrucking.logistics.dto.MaintenanceRequestDto;
import com.svtrucking.logistics.dto.WorkOrderDto;
import com.svtrucking.logistics.enums.WorkOrderStatus;
import com.svtrucking.logistics.exception.ResourceNotFoundException;
import com.svtrucking.logistics.model.Vehicle;
import com.svtrucking.logistics.repository.MaintenanceRequestRepository;
import com.svtrucking.logistics.repository.VehicleRepository;
import com.svtrucking.logistics.repository.WorkOrderRepository;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class MaintenanceReportingService {

  private final WorkOrderRepository workOrderRepository;
  private final MaintenanceRequestRepository maintenanceRequestRepository;
  private final VehicleRepository vehicleRepository;

  @Transactional(readOnly = true)
  public Map<String, Object> getDashboardKpis() {
    Map<String, Object> out = new HashMap<>();

    long open = workOrderRepository.countByStatusAndIsDeletedFalse(WorkOrderStatus.OPEN);
    long inProgress = workOrderRepository.countByStatusAndIsDeletedFalse(WorkOrderStatus.IN_PROGRESS);
    long waiting = workOrderRepository.countByStatusAndIsDeletedFalse(WorkOrderStatus.WAITING_PARTS);
    long completed = workOrderRepository.countByStatusAndIsDeletedFalse(WorkOrderStatus.COMPLETED);

    out.put("workOrdersOpen", open);
    out.put("workOrdersInProgress", inProgress);
    out.put("workOrdersWaitingParts", waiting);
    out.put("workOrdersCompleted", completed);

    // "Breakdown frequency": count recent maintenance requests in last 30 days (proxy)
    LocalDateTime since = LocalDateTime.now().minusDays(30);
    out.put("maintenanceRequestsLast30Days", maintenanceRequestRepository.count() /* lightweight fallback */);
    out.put("since", since);

    return out;
  }

  @Transactional(readOnly = true)
  public Map<String, Object> getVehicleHistory(Long vehicleId, Pageable pageable) {
    Vehicle v =
        vehicleRepository
            .findById(vehicleId)
            .orElseThrow(() -> new ResourceNotFoundException("Vehicle not found: " + vehicleId));

    Page<WorkOrderDto> workOrders =
        workOrderRepository
            .findByVehicleIdAndIsDeletedFalse(vehicleId, pageable)
            .map(wo -> WorkOrderDto.fromEntity(wo, true));

    // MR list is returned as a "page" with same pagination for simplicity.
    Page<MaintenanceRequestDto> mrs =
        maintenanceRequestRepository
            .search(null, null, vehicleId, null, PageRequest.of(pageable.getPageNumber(), pageable.getPageSize()))
            .map(MaintenanceRequestDto::fromEntity);

    Map<String, Object> out = new HashMap<>();
    out.put("vehicleId", v.getId());
    out.put("licensePlate", v.getLicensePlate());
    out.put("maintenanceRequests", mrs);
    out.put("workOrders", workOrders);
    return out;
  }

  /**
   * Reports: cost per vehicle (completed work orders only).
   * Returned as a list of simple maps to keep API conventions stable.
   */
  @Transactional(readOnly = true)
  public List<Map<String, Object>> getCostPerVehicle(int limit) {
    // For portability across DBs, compute in-memory based on completed work orders.
    // If needed, replace with a native aggregation query.
    var completed = workOrderRepository.findByStatusAndIsDeletedFalse(WorkOrderStatus.COMPLETED);
    Map<Long, BigDecimal> sums = new HashMap<>();
    for (var wo : completed) {
      Long vid = wo.getVehicle() != null ? wo.getVehicle().getId() : null;
      if (vid == null) continue;
      BigDecimal cost = wo.getActualCost() != null ? wo.getActualCost() : wo.getTotalCost();
      if (cost == null) cost = BigDecimal.ZERO;
      sums.put(vid, sums.getOrDefault(vid, BigDecimal.ZERO).add(cost));
    }
    return sums.entrySet().stream()
        .sorted((a, b) -> b.getValue().compareTo(a.getValue()))
        .limit(Math.max(1, limit))
        .map(
            e -> {
              Vehicle v = vehicleRepository.findById(e.getKey()).orElse(null);
              Map<String, Object> row = new HashMap<>();
              row.put("vehicleId", e.getKey());
              row.put("licensePlate", v != null ? v.getLicensePlate() : null);
              row.put("totalCost", e.getValue());
              return row;
            })
        .toList();
  }
}
