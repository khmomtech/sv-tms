package com.svtrucking.logistics.service;

import com.svtrucking.logistics.dto.VehicleDto;
import com.svtrucking.logistics.enums.VehicleStatus;
import com.svtrucking.logistics.enums.VehicleType;
import com.svtrucking.logistics.model.Vehicle;
import com.svtrucking.logistics.repository.VehicleRepository;
import jakarta.persistence.EntityNotFoundException;
import java.util.List;
import java.util.stream.Collectors;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Service for trailer-specific operations.
 * Trailers are vehicles with type=TRAILER and may have a parent vehicle (truck)
 * assigned.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class TrailerService {

  private final VehicleRepository vehicleRepository;

  /**
   * Get all trailers with pagination
   */
  public Page<VehicleDto> getAllTrailers(Pageable pageable) {
    log.debug("Fetching trailers with pagination: page={}, size={}",
        pageable.getPageNumber(), pageable.getPageSize());

    return vehicleRepository.searchVehicles(null, null, VehicleType.TRAILER, null, null, null, pageable)
        .map(VehicleDto::fromEntity);
  }

  /**
   * Get all trailers without pagination
   */
  public List<VehicleDto> getAllTrailers() {
    log.debug("Fetching all trailers without pagination");
    return vehicleRepository.findAllTrailers().stream()
        .map(VehicleDto::fromEntity)
        .collect(Collectors.toList());
  }

  /**
   * Get available trailers (not assigned to any truck)
   */
  public List<VehicleDto> getAvailableTrailers() {
    log.debug("Fetching available trailers");
    return vehicleRepository.findAll().stream()
        .filter(v -> v.getType() == VehicleType.TRAILER)
        .filter(v -> v.getStatus() == VehicleStatus.AVAILABLE)
        .filter(v -> v.getParentVehicle() == null)
        .map(VehicleDto::fromEntity)
        .collect(Collectors.toList());
  }

  /**
   * Get trailers assigned to a specific truck
   */
  public List<VehicleDto> getTrailersByTruck(Long vehicleId) {
    log.debug("Fetching trailers assigned to truck ID: {}", vehicleId);

    // Verify truck exists
    vehicleRepository.findById(vehicleId)
        .orElseThrow(() -> new EntityNotFoundException("Truck not found with ID: " + vehicleId));

    return vehicleRepository.findAll().stream()
        .filter(v -> v.getType() == VehicleType.TRAILER)
        .filter(v -> v.getParentVehicle() != null && v.getParentVehicle().getId().equals(vehicleId))
        .map(VehicleDto::fromEntity)
        .collect(Collectors.toList());
  }

  /**
   * Assign trailer to a truck
   */
  @Transactional
  public VehicleDto assignTrailerToTruck(Long trailerId, Long vehicleId) {
    log.info("Assigning trailer {} to truck {}", trailerId, vehicleId);

    Vehicle trailer = vehicleRepository.findById(trailerId)
        .orElseThrow(() -> new EntityNotFoundException("Trailer not found with ID: " + trailerId));

    if (trailer.getType() != VehicleType.TRAILER) {
      throw new IllegalArgumentException("Vehicle is not a trailer: " + trailerId);
    }

    Vehicle truck = vehicleRepository.findById(vehicleId)
        .orElseThrow(() -> new EntityNotFoundException("Truck not found with ID: " + vehicleId));

    if (truck.getType() == VehicleType.TRAILER) {
      throw new IllegalArgumentException("Cannot assign trailer to another trailer");
    }

    trailer.setParentVehicle(truck);
    trailer.setStatus(VehicleStatus.IN_USE);

    Vehicle saved = vehicleRepository.save(trailer);
    log.info("Successfully assigned trailer {} to truck {}", trailerId, vehicleId);

    return VehicleDto.fromEntity(saved);
  }

  /**
   * Unassign trailer from its current truck
   */
  @Transactional
  public VehicleDto unassignTrailer(Long trailerId) {
    log.info("Unassigning trailer {}", trailerId);

    Vehicle trailer = vehicleRepository.findById(trailerId)
        .orElseThrow(() -> new EntityNotFoundException("Trailer not found with ID: " + trailerId));

    if (trailer.getType() != VehicleType.TRAILER) {
      throw new IllegalArgumentException("Vehicle is not a trailer: " + trailerId);
    }

    trailer.setParentVehicle(null);
    trailer.setStatus(VehicleStatus.AVAILABLE);

    Vehicle saved = vehicleRepository.save(trailer);
    log.info("Successfully unassigned trailer {}", trailerId);

    return VehicleDto.fromEntity(saved);
  }

  /**
   * Search trailers with filters
   */
  public Page<VehicleDto> searchTrailers(
      String search,
      VehicleStatus status,
      String zone,
      Boolean assigned,
      Pageable pageable) {

    log.debug("Searching trailers with filters - search: {}, status: {}, zone: {}, assigned: {}",
        search, status, zone, assigned);

    Page<Vehicle> trailers = vehicleRepository.searchVehicles(
        search, status, VehicleType.TRAILER, null, zone, null, pageable);

    if (assigned != null) {
      List<Vehicle> filtered = trailers.getContent().stream()
          .filter(v -> assigned ? v.getParentVehicle() != null : v.getParentVehicle() == null)
          .collect(Collectors.toList());

      return new org.springframework.data.domain.PageImpl<>(
          filtered.stream().map(VehicleDto::fromEntity).collect(Collectors.toList()),
          pageable,
          filtered.size());
    }

    return trailers.map(VehicleDto::fromEntity);
  }
}
