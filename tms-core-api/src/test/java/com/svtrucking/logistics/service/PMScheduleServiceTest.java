package com.svtrucking.logistics.service;

import com.svtrucking.logistics.dto.PMScheduleDto;
import com.svtrucking.logistics.enums.PMTriggerType;
import com.svtrucking.logistics.exception.ResourceNotFoundException;
import com.svtrucking.logistics.model.PMSchedule;
import com.svtrucking.logistics.model.User;
import com.svtrucking.logistics.model.Vehicle;
import com.svtrucking.logistics.repository.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDate;
import java.util.Arrays;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class PMScheduleServiceTest {

  @Mock private PMScheduleRepository pmScheduleRepository;
  @Mock private VehicleRepository vehicleRepository;
  @Mock private MaintenanceTaskTypeRepository maintenanceTaskTypeRepository;
  @Mock private UserRepository userRepository;
  @Mock private WorkOrderRepository workOrderRepository;
  @Mock private PMScheduleHistoryRepository pmScheduleHistoryRepository;

  @InjectMocks private PMScheduleService pmScheduleService;

  private PMSchedule pmSchedule;
  private Vehicle vehicle;
  private User user;

  @BeforeEach
  void setUp() {
    vehicle = new Vehicle();
    vehicle.setId(1L);

    user = new User();
    user.setId(1L);
    user.setUsername("admin");

    pmSchedule =
        PMSchedule.builder()
            .id(1L)
            .scheduleName("Oil Change Schedule")
            .description("Regular oil change every 5000 km")
            .vehicle(vehicle)
            .triggerType(PMTriggerType.KILOMETER)
            .triggerInterval(5000)
            .nextDueKm(10000)
            .lastPerformedKm(5000)
            .active(true)
            .isDeleted(false)
            .createdBy(user)
            .build();
  }

  @Test
  void getScheduleById_WhenExists_ShouldReturnDto() {
    // Arrange
    when(pmScheduleRepository.findById(1L)).thenReturn(Optional.of(pmSchedule));

    // Act
    PMScheduleDto result = pmScheduleService.getScheduleById(1L);

    // Assert
    assertNotNull(result);
    assertEquals("Oil Change Schedule", result.getPmName());
    assertEquals(PMTriggerType.KILOMETER, result.getTriggerType());
    verify(pmScheduleRepository, times(1)).findById(1L);
  }

  @Test
  void getScheduleById_WhenNotExists_ShouldThrowException() {
    // Arrange
    when(pmScheduleRepository.findById(999L)).thenReturn(Optional.empty());

    // Act & Assert
    assertThrows(ResourceNotFoundException.class, () -> pmScheduleService.getScheduleById(999L));
  }

  @Test
  void getOverdueSchedules_ShouldCombineDateAndKmOverdue() {
    // Arrange
    PMSchedule dateOverdue =
        PMSchedule.builder()
            .id(2L)
            .scheduleName("Annual Inspection")
            .triggerType(PMTriggerType.DATE)
            .nextDueDate(LocalDate.now().minusDays(10))
            .active(true)
            .isDeleted(false)
            .build();

    when(pmScheduleRepository.findOverdueByDate(any(LocalDate.class)))
        .thenReturn(Arrays.asList(dateOverdue));
    when(pmScheduleRepository.findOverdueByKilometer()).thenReturn(Arrays.asList(pmSchedule));

    // Act
    List<PMScheduleDto> result = pmScheduleService.getOverdueSchedules();

    // Assert
    assertNotNull(result);
    assertEquals(2, result.size());
    verify(pmScheduleRepository, times(1)).findOverdueByDate(any(LocalDate.class));
    verify(pmScheduleRepository, times(1)).findOverdueByKilometer();
  }

  @Test
  void getDueSoonSchedules_ShouldReturnUpcoming() {
    // Arrange
    when(pmScheduleRepository.findDueSoonByDate(any(LocalDate.class), any(LocalDate.class)))
        .thenReturn(Arrays.asList(pmSchedule));

    // Act
    List<PMScheduleDto> result = pmScheduleService.getDueSoonSchedules(7);

    // Assert
    assertNotNull(result);
    assertEquals(1, result.size());
    verify(pmScheduleRepository, times(1))
        .findDueSoonByDate(any(LocalDate.class), any(LocalDate.class));
  }

  @Test
  void createSchedule_ShouldSaveWithCreatedBy() {
    // Arrange
    PMScheduleDto dto =
        PMScheduleDto.builder()
            .pmName("New PM Schedule")
            .description("Test schedule")
            .vehicleId(1L)
            .triggerType(PMTriggerType.KILOMETER)
            .intervalKm(10000)
            .nextDueKm(10000)
            .build();

    when(userRepository.findById(1L)).thenReturn(Optional.of(user));
    when(vehicleRepository.findById(1L)).thenReturn(Optional.of(vehicle));
    when(pmScheduleRepository.save(any(PMSchedule.class))).thenReturn(pmSchedule);

    // Act
    PMScheduleDto result = pmScheduleService.createSchedule(dto, 1L);

    // Assert
    assertNotNull(result);
    verify(userRepository, times(1)).findById(1L);
    verify(vehicleRepository, times(1)).findById(1L);
    verify(pmScheduleRepository, times(1)).save(any(PMSchedule.class));
  }

  @Test
  void updateSchedule_ShouldUpdateFields() {
    // Arrange
    PMScheduleDto dto =
        PMScheduleDto.builder()
            .pmName("Updated PM Name")
            .description("Updated description")
            .triggerType(PMTriggerType.KILOMETER)
            .intervalKm(7500)
            .nextDueKm(15000)
            .active(true)
            .build();

    when(pmScheduleRepository.findById(1L)).thenReturn(Optional.of(pmSchedule));
    when(pmScheduleRepository.save(any(PMSchedule.class)))
        .thenAnswer(invocation -> invocation.getArgument(0));

    // Act
    PMScheduleDto result = pmScheduleService.updateSchedule(1L, dto);

    // Assert
    assertNotNull(result);
    assertEquals("Updated PM Name", pmSchedule.getPmName());
    assertEquals(7500, pmSchedule.getIntervalKm());
    verify(pmScheduleRepository, times(1)).save(pmSchedule);
  }

  @Test
  void deactivateSchedule_ShouldSetActiveToFalse() {
    // Arrange
    when(pmScheduleRepository.findById(1L)).thenReturn(Optional.of(pmSchedule));
    when(pmScheduleRepository.save(any(PMSchedule.class))).thenReturn(pmSchedule);

    // Act
    pmScheduleService.deactivateSchedule(1L);

    // Assert
    assertFalse(pmSchedule.getActive());
    verify(pmScheduleRepository, times(1)).save(pmSchedule);
  }

  @Test
  void deleteSchedule_ShouldSoftDelete() {
    // Arrange
    when(pmScheduleRepository.findById(1L)).thenReturn(Optional.of(pmSchedule));
    when(pmScheduleRepository.save(any(PMSchedule.class))).thenReturn(pmSchedule);

    // Act
    pmScheduleService.deleteSchedule(1L);

    // Assert
    assertTrue(pmSchedule.getIsDeleted());
    verify(pmScheduleRepository, times(1)).save(pmSchedule);
  }
}
