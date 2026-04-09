package com.svtrucking.logistics.service;

import com.svtrucking.logistics.dto.*;
import com.svtrucking.logistics.enums.*;
import com.svtrucking.logistics.exception.VehicleNotFoundException;
import com.svtrucking.logistics.model.Vehicle;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Date;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * Test suite for Vehicle Master Setup workflow
 */
@ExtendWith(MockitoExtension.class)
class VehicleSetupServiceTest {

    @Mock
    private VehicleService vehicleService;

    @Mock
    private DocumentAdminService documentAdminService;

    @Mock
    private VehicleDocumentService vehicleDocumentService;

    @Mock
    private PMScheduleService pmScheduleService;

    @InjectMocks
    private VehicleSetupService vehicleSetupService;

    private VehicleSetupRequest setupRequest;
    private VehicleDto expectedVehicle;

    @BeforeEach
    void setUp() {
        setupRequest = createSampleSetupRequest();
        expectedVehicle = createSampleVehicleDto();
    }

    @Test
    void setupVehicle_CompleteFlow_ShouldSucceed() {
        // Arrange
        VehicleDto activatedVehicle = createSampleVehicleDto();
        activatedVehicle.setStatus(VehicleStatus.AVAILABLE);
        
        when(vehicleService.addVehicle(any(Vehicle.class))).thenReturn(expectedVehicle);
        when(vehicleService.getVehicleById(1L)).thenReturn(Optional.of(createSampleVehicle()));
        when(vehicleDocumentService.getDocumentsByVehicle(anyLong())).thenReturn(createSampleDocuments());
        when(pmScheduleService.createSchedule(any(PMScheduleDto.class), anyLong())).thenReturn(createSamplePMSchedule());
        when(vehicleService.updateVehicle(eq(1L), any(VehicleDto.class))).thenReturn(activatedVehicle);

        // Act
        VehicleDto result = vehicleSetupService.setupVehicle(setupRequest);

        // Assert
        assertThat(result).isNotNull();
        assertThat(result.getLicensePlate()).isEqualTo("ABC-123");
        assertThat(result.getStatus()).isEqualTo(VehicleStatus.AVAILABLE);

        verify(vehicleService).addVehicle(any(Vehicle.class));
        verify(documentAdminService, times(3)).createDocument(any(VehicleDocumentRequest.class), eq("SYSTEM"));
        verify(pmScheduleService, times(2)).createSchedule(any(PMScheduleDto.class), eq(1L));
        verify(vehicleService, times(2)).updateVehicle(eq(1L), any(VehicleDto.class)); // GPS assignment + Activation
    }

    @Test
    void setupVehicle_MissingRequiredDocuments_ShouldFail() {
        // Arrange
        when(vehicleService.addVehicle(any(Vehicle.class))).thenReturn(expectedVehicle);
        when(vehicleDocumentService.getDocumentsByVehicle(anyLong())).thenReturn(List.of()); // No documents

        // Act & Assert
        assertThatThrownBy(() -> vehicleSetupService.setupVehicle(setupRequest))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("Missing required documents");

        verify(vehicleService).addVehicle(any(Vehicle.class));
        verify(vehicleService, never()).updateVehicle(anyLong(), any(VehicleDto.class)); // Should not activate
    }

    @Test
    void setupVehicle_ExpiredDocuments_ShouldFail() {
        // Arrange
        when(vehicleService.addVehicle(any(Vehicle.class))).thenReturn(expectedVehicle);
        when(vehicleDocumentService.getDocumentsByVehicle(anyLong()))
                .thenReturn(createExpiredDocuments());

        // Act & Assert
        assertThatThrownBy(() -> vehicleSetupService.setupVehicle(setupRequest))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("Some documents are expired");

        verify(vehicleService).addVehicle(any(Vehicle.class));
        verify(vehicleService, never()).updateVehicle(anyLong(), any(VehicleDto.class)); // Should not activate
    }

    @Test
    void isVehicleReadyForOperation_ActiveVehicle_ShouldReturnTrue() {
        // Arrange
        Vehicle activeVehicle = createSampleVehicle();
        activeVehicle.setStatus(VehicleStatus.AVAILABLE);
        when(vehicleService.getVehicleById(1L)).thenReturn(Optional.of(activeVehicle));

        // Act
        boolean result = vehicleSetupService.isVehicleReadyForOperation(1L);

        // Assert
        assertThat(result).isTrue();
    }

    @Test
    void isVehicleReadyForOperation_InactiveVehicle_ShouldReturnFalse() {
        // Arrange
        Vehicle inactiveVehicle = createSampleVehicle();
        inactiveVehicle.setStatus(VehicleStatus.MAINTENANCE);
        when(vehicleService.getVehicleById(1L)).thenReturn(Optional.of(inactiveVehicle));

        // Act
        boolean result = vehicleSetupService.isVehicleReadyForOperation(1L);

        // Assert
        assertThat(result).isFalse();
    }

    @Test
    void isVehicleReadyForOperation_NonExistentVehicle_ShouldReturnFalse() {
        // Arrange
        when(vehicleService.getVehicleById(999L)).thenReturn(Optional.empty());

        // Act
        boolean result = vehicleSetupService.isVehicleReadyForOperation(999L);

        // Assert
        assertThat(result).isFalse();
    }

    @Test
    void setupVehicle_WithGpsDevice_ShouldAssignGps() {
        // Arrange
        setupRequest.setGpsDeviceId("GPS-001");
        VehicleDto activatedVehicle = createSampleVehicleDto();
        activatedVehicle.setStatus(VehicleStatus.AVAILABLE);
        
        when(vehicleService.addVehicle(any(Vehicle.class))).thenReturn(expectedVehicle);
        when(vehicleService.getVehicleById(1L)).thenReturn(Optional.of(createSampleVehicle()));
        when(vehicleDocumentService.getDocumentsByVehicle(anyLong())).thenReturn(createSampleDocuments());
        when(vehicleService.updateVehicle(eq(1L), any(VehicleDto.class))).thenReturn(activatedVehicle);

        // Act
        VehicleDto result = vehicleSetupService.setupVehicle(setupRequest);

        // Assert
        assertThat(result.getStatus()).isEqualTo(VehicleStatus.AVAILABLE);
        verify(vehicleService, times(2)).updateVehicle(eq(1L), any(VehicleDto.class)); // GPS + Activation
    }

    @Test
    void setupVehicle_WithoutMaintenancePolicy_ShouldSkipPmSetup() {
        // Arrange
        setupRequest.setMaintenancePolicy(null);
        VehicleDto activatedVehicle = createSampleVehicleDto();
        activatedVehicle.setStatus(VehicleStatus.AVAILABLE);
        
        when(vehicleService.addVehicle(any(Vehicle.class))).thenReturn(expectedVehicle);
        when(vehicleService.getVehicleById(1L)).thenReturn(Optional.of(createSampleVehicle()));
        when(vehicleDocumentService.getDocumentsByVehicle(anyLong())).thenReturn(createSampleDocuments());
        when(vehicleService.updateVehicle(eq(1L), any(VehicleDto.class))).thenReturn(activatedVehicle);

        // Act
        VehicleDto result = vehicleSetupService.setupVehicle(setupRequest);

        // Assert
        assertThat(result.getStatus()).isEqualTo(VehicleStatus.AVAILABLE);
        verify(pmScheduleService, never()).createSchedule(any(PMScheduleDto.class), anyLong());
    }

    private VehicleSetupRequest createSampleSetupRequest() {
        return VehicleSetupRequest.builder()
                .licensePlate("ABC-123")
                .vin("1HGCM82633A123456")
                .model("F-150")
                .manufacturer("Ford")
                .yearMade(2020)
                .type(VehicleType.TRUCK)
                .ownership(VehicleOwnership.OWNED)
                .truckSize(TruckSize.MEDIUM_TRUCK)
                .maxWeight(BigDecimal.valueOf(5000))
                .maxVolume(BigDecimal.valueOf(100))
                .fuelConsumption(BigDecimal.valueOf(12.5))
                .mileage(BigDecimal.valueOf(50000))
                .qtyPalletsCapacity(20)
                .assignedZone("Zone A")
                .requiredLicenseClass("C")
                .gpsDeviceId("GPS-001")
                .remarks("Test vehicle")
                .documents(createSampleDocumentRequests())
                .maintenancePolicy(createSampleMaintenancePolicy())
                .build();
    }

    private VehicleDto createSampleVehicleDto() {
        return VehicleDto.builder()
                .id(1L)
                .licensePlate("ABC-123")
                .vin("1HGCM82633A123456")
                .model("F-150")
                .manufacturer("Ford")
                .yearMade(2020)
                .type(VehicleType.TRUCK)
                .ownership(VehicleOwnership.OWNED)
                .status(VehicleStatus.AVAILABLE)
                .build();
    }

    private Vehicle createSampleVehicle() {
        return Vehicle.builder()
                .id(1L)
                .licensePlate("ABC-123")
                .status(VehicleStatus.AVAILABLE)
                .build();
    }

    private List<VehicleDocumentRequest> createSampleDocumentRequests() {
        return List.of(
                VehicleDocumentRequest.builder()
                        .documentType("REGISTRATION")
                        .documentNumber("REG-001")
                        .expiryDate(LocalDate.now().plusYears(1))
                        .build(),
                VehicleDocumentRequest.builder()
                        .documentType("INSURANCE")
                        .documentNumber("INS-001")
                        .expiryDate(LocalDate.now().plusMonths(6))
                        .build(),
                VehicleDocumentRequest.builder()
                        .documentType("INSPECTION")
                        .documentNumber("INSP-001")
                        .expiryDate(LocalDate.now().plusMonths(12))
                        .build()
        );
    }

    private List<VehicleDocumentDto> createSampleDocuments() {
        return List.of(
                VehicleDocumentDto.builder()
                        .documentType("REGISTRATION")
                        .expiryDate(Date.from(LocalDate.now().plusYears(1).atStartOfDay().toInstant(java.time.ZoneOffset.UTC)))
                        .build(),
                VehicleDocumentDto.builder()
                        .documentType("INSURANCE")
                        .expiryDate(Date.from(LocalDate.now().plusMonths(6).atStartOfDay().toInstant(java.time.ZoneOffset.UTC)))
                        .build(),
                VehicleDocumentDto.builder()
                        .documentType("INSPECTION")
                        .expiryDate(Date.from(LocalDate.now().plusMonths(12).atStartOfDay().toInstant(java.time.ZoneOffset.UTC)))
                        .build()
        );
    }

    private List<VehicleDocumentDto> createExpiredDocuments() {
        return List.of(
                VehicleDocumentDto.builder()
                        .documentType("REGISTRATION")
                        .expiryDate(Date.from(LocalDate.now().minusDays(1).atStartOfDay().toInstant(java.time.ZoneOffset.UTC)))
                        .build(),
                VehicleDocumentDto.builder()
                        .documentType("INSURANCE")
                        .expiryDate(Date.from(LocalDate.now().plusDays(30).atStartOfDay().toInstant(java.time.ZoneOffset.UTC)))
                        .build(),
                VehicleDocumentDto.builder()
                        .documentType("INSPECTION")
                        .expiryDate(Date.from(LocalDate.now().plusDays(30).atStartOfDay().toInstant(java.time.ZoneOffset.UTC)))
                        .build()
        );
    }

    private MaintenancePolicyRequest createSampleMaintenancePolicy() {
        return MaintenancePolicyRequest.builder()
                .schedules(List.of(
                        PMScheduleRequest.builder()
                                .scheduleName("Oil Change")
                                .description("Regular oil change")
                                .triggerType(PMTriggerType.KILOMETER)
                                .triggerInterval(5000)
                                .reminderBeforeKm(500)
                                .taskTypeId(1L)
                                .build(),
                        PMScheduleRequest.builder()
                                .scheduleName("Tire Rotation")
                                .description("Tire maintenance")
                                .triggerType(PMTriggerType.DATE)
                                .triggerInterval(180)
                                .reminderBeforeDays(30)
                                .taskTypeId(2L)
                                .build()
                ))
                .build();
    }

    private PMScheduleDto createSamplePMSchedule() {
        return PMScheduleDto.builder()
                .id(1L)
                .pmName("Test Schedule")
                .active(true)
                .build();
    }
}
