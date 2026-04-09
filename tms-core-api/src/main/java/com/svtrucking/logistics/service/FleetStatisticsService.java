package com.svtrucking.logistics.service;

import com.svtrucking.logistics.dto.VehicleStatisticsDto;
import com.svtrucking.logistics.model.Vehicle;
import com.svtrucking.logistics.enums.VehicleStatus;
import com.svtrucking.logistics.enums.VehicleType;
import com.svtrucking.logistics.repository.VehicleRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * Service for fleet analytics and statistics.
 * Extracted from VehicleService to follow Single Responsibility Principle.
 */
@Service
@Slf4j
@RequiredArgsConstructor
public class FleetStatisticsService {

    private final VehicleRepository vehicleRepository;

    /**
     * Generates comprehensive fleet statistics.
     * Cached for performance.
     *
     * @return Fleet statistics DTO
     */
    @Cacheable(value = "vehicleStats")
    @Transactional(readOnly = true)
    public VehicleStatisticsDto getFleetStatistics() {
        log.info("Generating fleet statistics");

        List<Vehicle> allVehicles = vehicleRepository.findAll();
        long total = allVehicles.size();

        // Status counts
        Map<String, Long> byStatus = vehicleRepository.countByStatus().stream()
            .collect(Collectors.toMap(
                arr -> ((VehicleStatus) arr[0]).name(),
                arr -> (Long) arr[1]
            ));

        // Type counts
        Map<String, Long> byType = vehicleRepository.countByType().stream()
            .collect(Collectors.toMap(
                arr -> ((VehicleType) arr[0]).name(),
                arr -> (Long) arr[1]
            ));

        // Calculate various statistics
        long available = byStatus.getOrDefault(VehicleStatus.AVAILABLE.name(), 0L);
        long inUse = byStatus.getOrDefault(VehicleStatus.IN_USE.name(), 0L);
        long maintenance = byStatus.getOrDefault(VehicleStatus.MAINTENANCE.name(), 0L);
        long outOfService = byStatus.getOrDefault(VehicleStatus.OUT_OF_SERVICE.name(), 0L);

        List<Vehicle> unassigned = vehicleRepository.findUnassignedVehicles();
        long assigned = total - unassigned.size();

        long withGPS = vehicleRepository.findByGpsDeviceIdIsNotNull().size();
        long requiresService = vehicleRepository.findVehiclesRequiringService(LocalDate.now()).size();

        List<Vehicle> trailers = vehicleRepository.findAllTrailers();

        // Calculate averages
        BigDecimal avgMileage = calculateAverageMileage(allVehicles, total);
        double avgAge = calculateAverageAge(allVehicles);

        return VehicleStatisticsDto.builder()
            .totalVehicles(total)
            .availableVehicles(available)
            .inUseVehicles(inUse)
            .maintenanceVehicles(maintenance)
            .outOfServiceVehicles(outOfService)
            .assignedVehicles(assigned)
            .unassignedVehicles((long) unassigned.size())
            .assignmentRate(total > 0 ? (assigned * 100.0 / total) : 0.0)
            .vehiclesRequiringService(requiresService)
            .vehiclesByStatus(byStatus)
            .vehiclesByType(byType)
            .averageMileage(avgMileage)
            .averageVehicleAge((int) Math.round(avgAge))
            .vehiclesWithGPS(withGPS)
            .vehiclesWithoutGPS(total - withGPS)
            .totalTrailers((long) trailers.size())
            .build();
    }

    /**
     * Gets vehicles requiring service based on service due date.
     *
     * @return List of vehicles requiring service
     */
    @Transactional(readOnly = true)
    public long getVehiclesRequiringServiceCount() {
        return vehicleRepository.findVehiclesRequiringService(LocalDate.now()).size();
    }

    /**
     * Gets count of vehicles by status.
     *
     * @param status Vehicle status
     * @return Count of vehicles with given status
     */
    @Transactional(readOnly = true)
    public long getVehicleCountByStatus(VehicleStatus status) {
        return vehicleRepository.findAllByStatus(status).size();
    }

    /**
     * Gets count of vehicles by type.
     *
     * @param type Vehicle type
     * @return Count of vehicles with given type
     */
    @Transactional(readOnly = true)
    public long getVehicleCountByType(VehicleType type) {
        return vehicleRepository.findAll().stream()
            .filter(v -> v.getType() == type)
            .count();
    }

    /**
     * Gets count of unassigned vehicles.
     *
     * @return Count of unassigned vehicles
     */
    @Transactional(readOnly = true)
    public long getUnassignedVehiclesCount() {
        return vehicleRepository.findUnassignedVehicles().size();
    }

    /**
     * Gets count of vehicles with GPS devices.
     *
     * @return Count of vehicles with GPS
     */
    @Transactional(readOnly = true)
    public long getVehiclesWithGPSCount() {
        return vehicleRepository.findByGpsDeviceIdIsNotNull().size();
    }

    /**
     * Gets count of trailer vehicles.
     *
     * @return Count of trailers
     */
    @Transactional(readOnly = true)
    public long getTrailerCount() {
        return vehicleRepository.findAllTrailers().size();
    }

    /**
     * Calculates average mileage across all vehicles.
     *
     * @param vehicles List of all vehicles
     * @param total Total count of vehicles
     * @return Average mileage
     */
    private BigDecimal calculateAverageMileage(List<Vehicle> vehicles, long total) {
        if (total == 0) {
            return BigDecimal.ZERO;
        }

        return vehicles.stream()
            .filter(v -> v.getMileage() != null)
            .map(Vehicle::getMileage)
            .reduce(BigDecimal.ZERO, BigDecimal::add)
            .divide(BigDecimal.valueOf(total), 2, java.math.RoundingMode.HALF_UP);
    }

    /**
     * Calculates average age of vehicles in fleet.
     *
     * @param vehicles List of all vehicles
     * @return Average age in years
     */
    private double calculateAverageAge(List<Vehicle> vehicles) {
        int currentYear = LocalDate.now().getYear();

        return vehicles.stream()
            .filter(v -> v.getYearMade() != null)
            .mapToInt(v -> currentYear - v.getYearMade())
            .average()
            .orElse(0.0);
    }
}
