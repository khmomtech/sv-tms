package com.svtrucking.logistics.service;

import com.svtrucking.logistics.dto.VehicleFuelLogDto;
import com.svtrucking.logistics.exception.ResourceNotFoundException;
import com.svtrucking.logistics.model.User;
import com.svtrucking.logistics.model.Vehicle;
import com.svtrucking.logistics.model.VehicleFuelLog;
import com.svtrucking.logistics.repository.UserRepository;
import com.svtrucking.logistics.repository.VehicleFuelLogRepository;
import com.svtrucking.logistics.repository.VehicleRepository;
import java.math.BigDecimal;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class VehicleFuelLogService {

  private final VehicleFuelLogRepository fuelLogRepository;
  private final VehicleRepository vehicleRepository;
  private final UserRepository userRepository;

  @Transactional(readOnly = true)
  public Page<VehicleFuelLogDto> list(Long vehicleId, String search, Pageable pageable) {
    return fuelLogRepository
        .searchByVehicle(vehicleId, search, pageable)
        .map(VehicleFuelLogDto::fromEntity);
  }

  @Transactional
  public VehicleFuelLogDto create(VehicleFuelLogDto dto, Long createdById) {
    Vehicle vehicle =
        vehicleRepository
            .findById(dto.getVehicleId())
            .orElseThrow(() -> new ResourceNotFoundException("Vehicle not found"));

    User createdBy =
        createdById != null
            ? userRepository
                .findById(createdById)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"))
            : null;

    VehicleFuelLog log =
        VehicleFuelLog.builder()
            .vehicle(vehicle)
            .filledAt(dto.getFilledAt())
            .odometerKm(dto.getOdometerKm())
            .liters(dto.getLiters())
            .amount(dto.getAmount())
            .station(dto.getStation())
            .notes(dto.getNotes())
            .createdBy(createdBy)
            .build();

    VehicleFuelLog saved = fuelLogRepository.save(log);
    updateVehicleMileageIfHigher(vehicle, saved.getOdometerKm());
    return VehicleFuelLogDto.fromEntity(saved);
  }

  @Transactional
  public VehicleFuelLogDto update(Long id, VehicleFuelLogDto dto) {
    VehicleFuelLog log =
        fuelLogRepository
            .findById(id)
            .orElseThrow(() -> new ResourceNotFoundException("Fuel log not found"));

    log.setFilledAt(dto.getFilledAt());
    log.setOdometerKm(dto.getOdometerKm());
    log.setLiters(dto.getLiters());
    log.setAmount(dto.getAmount());
    log.setStation(dto.getStation());
    log.setNotes(dto.getNotes());

    if (dto.getVehicleId() != null && !dto.getVehicleId().equals(log.getVehicle().getId())) {
      Vehicle vehicle =
          vehicleRepository
              .findById(dto.getVehicleId())
              .orElseThrow(() -> new ResourceNotFoundException("Vehicle not found"));
      log.setVehicle(vehicle);
    }

    VehicleFuelLog saved = fuelLogRepository.save(log);
    updateVehicleMileageIfHigher(saved.getVehicle(), saved.getOdometerKm());
    return VehicleFuelLogDto.fromEntity(saved);
  }

  @Transactional
  public void delete(Long id) {
    VehicleFuelLog log =
        fuelLogRepository
            .findById(id)
            .orElseThrow(() -> new ResourceNotFoundException("Fuel log not found"));
    fuelLogRepository.delete(log);
  }

  private void updateVehicleMileageIfHigher(Vehicle vehicle, BigDecimal odometerKm) {
    if (vehicle == null || odometerKm == null) return;
    if (vehicle.getMileage() == null || vehicle.getMileage().compareTo(odometerKm) < 0) {
      vehicle.setMileage(odometerKm);
      vehicleRepository.save(vehicle);
    }
  }
}
