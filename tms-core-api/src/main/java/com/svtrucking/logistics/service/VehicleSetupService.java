package com.svtrucking.logistics.service;

import com.svtrucking.logistics.dto.VehicleDto;
import com.svtrucking.logistics.dto.VehicleDocumentDto;
import com.svtrucking.logistics.dto.VehicleDocumentRequest;
import com.svtrucking.logistics.dto.VehicleSetupRequest;
import com.svtrucking.logistics.dto.MaintenancePolicyRequest;
import com.svtrucking.logistics.dto.PMScheduleDto;
import com.svtrucking.logistics.dto.PMScheduleRequest;
import com.svtrucking.logistics.enums.VehicleStatus;
import com.svtrucking.logistics.enums.VehicleDocumentType;
import com.svtrucking.logistics.model.Vehicle;
import com.svtrucking.logistics.exception.VehicleNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.Set;

/**
 * Service for complete Vehicle Master Setup workflow.
 * Orchestrates the end-to-end process: Create → Validate → Activate → Ready for Operation
 */
@Service
@Slf4j
@RequiredArgsConstructor
public class VehicleSetupService {

    private final VehicleService vehicleService;
    private final DocumentAdminService documentAdminService;
    private final VehicleDocumentService vehicleDocumentService;
    private final PMScheduleService pmScheduleService;

    /**
     * Complete vehicle master setup workflow
     */
    @Transactional
    public VehicleDto setupVehicle(VehicleSetupRequest request) {
        log.info("Starting vehicle master setup for license plate: {}", request.getLicensePlate());

        // Step 1: Create vehicle with basic information
        VehicleDto vehicle = createVehicle(request);

        // Step 2: Add required documents
        addRequiredDocuments(vehicle.getId(), request.getDocuments());

        // Step 3: Validate setup completeness (documents present and not expired)
        validateSetupComplete(vehicle.getId());

        // Step 4: Assign GPS device if provided
        if (request.getGpsDeviceId() != null) {
            assignGpsDevice(vehicle.getId(), request.getGpsDeviceId());
        }

        // Step 5: Setup maintenance policy
        setupMaintenancePolicy(vehicle.getId(), request.getMaintenancePolicy());

        // Step 6: Activate vehicle (set to AVAILABLE status)
        VehicleDto activatedVehicle = activateVehicle(vehicle.getId());

        log.info("Vehicle master setup completed for ID: {} - {}", activatedVehicle.getId(),
                activatedVehicle.getLicensePlate());

        return activatedVehicle;
    }

    /**
     * Create vehicle with basic information
     */
    private VehicleDto createVehicle(VehicleSetupRequest request) {
        log.debug("Creating vehicle with license plate: {}", request.getLicensePlate());

        Vehicle vehicle = Vehicle.builder()
                .licensePlate(request.getLicensePlate())
                .vin(request.getVin())
                .model(request.getModel())
                .manufacturer(request.getManufacturer())
                .yearMade(request.getYearMade())
                .type(request.getType())
                .ownership(request.getOwnership())
                .truckSize(request.getTruckSize())
                .maxWeight(request.getMaxWeight())
                .maxVolume(request.getMaxVolume())
                .fuelConsumption(request.getFuelConsumption())
                .mileage(request.getMileage())
                .qtyPalletsCapacity(request.getQtyPalletsCapacity())
                .assignedZone(request.getAssignedZone())
                .requiredLicenseClass(request.getRequiredLicenseClass())
                .remarks(request.getRemarks())
                .status(VehicleStatus.AVAILABLE) // Start as AVAILABLE, will be activated later
                .build();

        // Validate the vehicle data
        // Validation is handled by Bean Validation annotations on the entity

        return vehicleService.addVehicle(vehicle);
    }

    /**
     * Add required documents to vehicle
     */
    private void addRequiredDocuments(Long vehicleId, List<VehicleDocumentRequest> documents) {
        if (documents == null || documents.isEmpty()) {
            log.warn("No documents provided for vehicle setup: {}", vehicleId);
            return;
        }

        log.debug("Adding {} documents to vehicle: {}", documents.size(), vehicleId);

        for (VehicleDocumentRequest doc : documents) {
            // Set the vehicle ID in the request
            VehicleDocumentRequest docWithVehicleId = VehicleDocumentRequest.builder()
                    .vehicleId(vehicleId)
                    .documentType(doc.getDocumentType())
                    .documentNumber(doc.getDocumentNumber())
                    .notes(doc.getNotes())
                    .issueDate(doc.getIssueDate())
                    .expiryDate(doc.getExpiryDate())
                    .documentUrl(doc.getDocumentUrl())
                    .build();

            documentAdminService.createDocument(docWithVehicleId, "SYSTEM");
        }
    }

    /**
     * Assign GPS device to vehicle
     */
    private void assignGpsDevice(Long vehicleId, String gpsDeviceId) {
        log.debug("Assigning GPS device {} to vehicle: {}", gpsDeviceId, vehicleId);

        Vehicle vehicle = vehicleService.getVehicleById(vehicleId)
                .orElseThrow(() -> new VehicleNotFoundException(vehicleId));

        vehicle.setGpsDeviceId(gpsDeviceId);
        vehicleService.updateVehicle(vehicleId, VehicleDto.fromEntity(vehicle));
    }

    /**
     * Setup maintenance policy for vehicle
     */
    private void setupMaintenancePolicy(Long vehicleId, MaintenancePolicyRequest policy) {
        if (policy == null) {
            log.debug("No maintenance policy provided for vehicle: {}", vehicleId);
            return;
        }

        log.debug("Setting up maintenance policy for vehicle: {}", vehicleId);

        // Create PM schedules based on policy
        for (PMScheduleRequest schedule : policy.getSchedules()) {
            PMScheduleDto pmSchedule = PMScheduleDto.builder()
                    .pmName(schedule.getScheduleName())
                    .description(schedule.getDescription())
                    .vehicleId(vehicleId)
                    .triggerType(schedule.getTriggerType())
                    .intervalKm(schedule.getTriggerInterval())
                    .intervalDays(schedule.getReminderBeforeDays())
                    .maintenanceTaskTypeId(schedule.getTaskTypeId())
                    .active(true)
                    .build();

            pmScheduleService.createSchedule(pmSchedule, 1L); // System user ID
        }
    }

    /**
     * Validate that vehicle setup is complete
     */
    private void validateSetupComplete(Long vehicleId) {
        log.debug("Validating setup completeness for vehicle: {}", vehicleId);

        // Check required documents are present
        List<VehicleDocumentDto> documents = vehicleDocumentService.getDocumentsByVehicle(vehicleId);
        Set<VehicleDocumentType> documentTypes = documents.stream()
                .map(doc -> VehicleDocumentType.valueOf(doc.getDocumentType()))
                .collect(java.util.stream.Collectors.toSet());

        // Required documents: REGISTRATION, INSURANCE, INSPECTION
        Set<VehicleDocumentType> requiredTypes = Set.of(
                VehicleDocumentType.REGISTRATION,
                VehicleDocumentType.INSURANCE,
                VehicleDocumentType.INSPECTION
        );

        if (!documentTypes.containsAll(requiredTypes)) {
            throw new IllegalStateException("Missing required documents. Required: " + requiredTypes +
                    ", Found: " + documentTypes);
        }

        // Check documents are not expired
        LocalDate now = LocalDate.now();
        boolean hasExpiredDocs = documents.stream()
                .anyMatch(doc -> {
                    if (doc.getExpiryDate() == null) {
                        return false;
                    }
                    java.time.LocalDate expiryDate;
                    if (doc.getExpiryDate() instanceof java.sql.Date sqlDate) {
                        expiryDate = sqlDate.toLocalDate();
                    } else {
                        expiryDate = doc.getExpiryDate()
                                .toInstant()
                                .atZone(java.time.ZoneId.systemDefault())
                                .toLocalDate();
                    }
                    return expiryDate.isBefore(now);
                });

        if (hasExpiredDocs) {
            throw new IllegalStateException("Some documents are expired. Please update expired documents.");
        }

        log.debug("Vehicle setup validation passed for vehicle: {}", vehicleId);
    }

    /**
     * Activate vehicle by setting status to ACTIVE
     */
    private VehicleDto activateVehicle(Long vehicleId) {
        log.debug("Activating vehicle: {}", vehicleId);

        Vehicle vehicle = vehicleService.getVehicleById(vehicleId)
                .orElseThrow(() -> new VehicleNotFoundException(vehicleId));

        vehicle.setStatus(VehicleStatus.AVAILABLE);
        return vehicleService.updateVehicle(vehicleId, VehicleDto.fromEntity(vehicle));
    }

    /**
     * Check if vehicle is ready for operation
     */
    public boolean isVehicleReadyForOperation(Long vehicleId) {
        try {
            Vehicle vehicle = vehicleService.getVehicleById(vehicleId)
                    .orElseThrow(() -> new VehicleNotFoundException(vehicleId));

            return vehicle.getStatus() == VehicleStatus.AVAILABLE;
        } catch (Exception e) {
            log.error("Error checking if vehicle is ready for operation: {}", vehicleId, e);
            return false;
        }
    }
}
