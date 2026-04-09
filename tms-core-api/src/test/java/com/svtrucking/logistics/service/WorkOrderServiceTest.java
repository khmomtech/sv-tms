package com.svtrucking.logistics.service;

import com.svtrucking.logistics.dto.WorkOrderDto;
import com.svtrucking.logistics.enums.MaintenanceRequestStatus;
import com.svtrucking.logistics.enums.Priority;
import com.svtrucking.logistics.enums.WorkOrderStatus;
import com.svtrucking.logistics.enums.WorkOrderType;
import com.svtrucking.logistics.exception.ResourceNotFoundException;
import com.svtrucking.logistics.model.MaintenanceRequest;
import com.svtrucking.logistics.model.User;
import com.svtrucking.logistics.model.Vehicle;
import com.svtrucking.logistics.model.WorkOrder;
import com.svtrucking.logistics.repository.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;

import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class WorkOrderServiceTest {

  @Mock private WorkOrderRepository workOrderRepository;
  @Mock private VehicleRepository vehicleRepository;
  @Mock private UserRepository userRepository;
  @Mock private DriverIssueRepository driverIssueRepository;
  @Mock private PMScheduleRepository pmScheduleRepository;
  @Mock private WorkOrderTaskRepository workOrderTaskRepository;
  @Mock private WorkOrderPartRepository workOrderPartRepository;
  @Mock private PartsMasterRepository partsMasterRepository;
  @Mock private MaintenanceRequestRepository maintenanceRequestRepository;
  @Mock private VendorQuotationRepository vendorQuotationRepository;
  @Mock private InvoiceRepository invoiceRepository;

  @InjectMocks private WorkOrderService workOrderService;

  private WorkOrder workOrder;
  private Vehicle vehicle;
  private User technician;

  @BeforeEach
  void setUp() {
    vehicle = new Vehicle();
    vehicle.setId(1L);

    technician = new User();
    technician.setId(2L);
    technician.setUsername("tech1");

    workOrder =
        WorkOrder.builder()
            .id(1L)
            .woNumber("WO-2025-00001")
            .vehicle(vehicle)
            .type(WorkOrderType.PREVENTIVE)
            .priority(Priority.NORMAL)
            .status(WorkOrderStatus.OPEN)
            .title("Oil Change")
            .description("Regular maintenance")
            .scheduledDate(LocalDateTime.now())
            .isDeleted(false)
            .build();

    lenient().when(vendorQuotationRepository.findByWorkOrderId(anyLong())).thenReturn(Optional.empty());
    lenient().when(invoiceRepository.findByWorkOrderId(anyLong())).thenReturn(Optional.empty());
  }

  @Test
  void getAllWorkOrders_ShouldReturnPageOfWorkOrders() {
    // Arrange
    Pageable pageable = PageRequest.of(0, 10);
    Page<WorkOrder> page = new PageImpl<>(Arrays.asList(workOrder));
    when(workOrderRepository.findByIsDeletedFalse(pageable)).thenReturn(page);

    // Act
    Page<WorkOrderDto> result = workOrderService.getAllWorkOrders(pageable);

    // Assert
    assertNotNull(result);
    assertEquals(1, result.getTotalElements());
    assertEquals("WO-2025-00001", result.getContent().get(0).getWoNumber());
    verify(workOrderRepository, times(1)).findByIsDeletedFalse(pageable);
  }

  @Test
  void getWorkOrderById_WhenExists_ShouldReturnDto() {
    // Arrange
    when(workOrderRepository.findById(1L)).thenReturn(Optional.of(workOrder));

    // Act
    WorkOrderDto result = workOrderService.getWorkOrderById(1L);

    // Assert
    assertNotNull(result);
    assertEquals("WO-2025-00001", result.getWoNumber());
    assertEquals("Oil Change", result.getTitle());
    verify(workOrderRepository, times(1)).findById(1L);
  }

  @Test
  void getWorkOrderById_WhenNotExists_ShouldThrowException() {
    // Arrange
    when(workOrderRepository.findById(999L)).thenReturn(Optional.empty());

    // Act & Assert
    assertThrows(ResourceNotFoundException.class, () -> workOrderService.getWorkOrderById(999L));
    verify(workOrderRepository, times(1)).findById(999L);
  }

  @Test
  void createWorkOrder_ShouldGenerateWoNumberAndSave() {
    // Arrange
    WorkOrderDto dto =
        WorkOrderDto.builder()
            .vehicleId(1L)
            .type(WorkOrderType.REPAIR)
            .priority(Priority.HIGH)
            .title("Engine Repair")
            .description("Fix engine issue")
            .maintenanceRequestId(10L)
            .build();

    MaintenanceRequest approvedRequest = new MaintenanceRequest();
    approvedRequest.setId(10L);
    approvedRequest.setStatus(MaintenanceRequestStatus.APPROVED);

    when(vehicleRepository.findById(1L)).thenReturn(Optional.of(vehicle));
    when(maintenanceRequestRepository.findById(10L)).thenReturn(Optional.of(approvedRequest));
    when(workOrderRepository.save(any(WorkOrder.class))).thenReturn(workOrder);
    when(workOrderRepository.findMaxWoNumberForYear(anyString())).thenReturn(0);

    // Act
    WorkOrderDto result = workOrderService.createWorkOrder(dto, 1L);

    // Assert
    assertNotNull(result);
    verify(vehicleRepository, times(1)).findById(1L);
    verify(workOrderRepository, times(1)).save(any(WorkOrder.class));
  }

  @Test
  void updateStatus_ShouldUpdateWorkOrderStatus() {
    // Arrange
    when(workOrderRepository.findById(1L)).thenReturn(Optional.of(workOrder));
    when(workOrderRepository.save(any(WorkOrder.class))).thenReturn(workOrder);

    // Act
    WorkOrderDto result = workOrderService.updateStatus(1L, WorkOrderStatus.IN_PROGRESS, 2L);

    // Assert
    assertNotNull(result);
    verify(workOrderRepository, times(1)).findById(1L);
    verify(workOrderRepository, times(1)).save(any(WorkOrder.class));
  }

  @Test
  void updateStatus_ToCompleted_ShouldSetCompletedAt() {
    // Arrange
    when(workOrderRepository.findById(1L)).thenReturn(Optional.of(workOrder));
    when(workOrderRepository.save(any(WorkOrder.class)))
        .thenAnswer(invocation -> invocation.getArgument(0));

    // Act
    workOrderService.updateStatus(1L, WorkOrderStatus.COMPLETED, 2L);

    // Assert
    assertNotNull(workOrder.getCompletedAt());
    verify(workOrderRepository, times(1)).save(workOrder);
  }

  @Test
  void getUrgentWorkOrders_ShouldReturnUrgentOnly() {
    // Arrange
    WorkOrder urgentWo =
        WorkOrder.builder()
            .id(2L)
            .priority(Priority.URGENT)
            .status(WorkOrderStatus.OPEN)
            .vehicle(vehicle)
            .type(WorkOrderType.EMERGENCY)
            .title("Urgent Repair")
            .isDeleted(false)
            .build();

    when(workOrderRepository.findUrgentWorkOrders()).thenReturn(Arrays.asList(urgentWo));

    // Act
    List<WorkOrderDto> result = workOrderService.getUrgentWorkOrders();

    // Assert
    assertNotNull(result);
    assertEquals(1, result.size());
    verify(workOrderRepository, times(1)).findUrgentWorkOrders();
  }

  @Test
  void deleteWorkOrder_ShouldSoftDelete() {
    // Arrange
    when(workOrderRepository.findById(1L)).thenReturn(Optional.of(workOrder));
    when(workOrderRepository.save(any(WorkOrder.class))).thenReturn(workOrder);

    // Act
    workOrderService.deleteWorkOrder(1L);

    // Assert
    assertTrue(workOrder.getIsDeleted());
    verify(workOrderRepository, times(1)).save(workOrder);
  }

  @Test
  void approveWorkOrder_ShouldSetApprovalFields() {
    // Arrange
    when(workOrderRepository.findById(1L)).thenReturn(Optional.of(workOrder));
    when(userRepository.findById(2L)).thenReturn(Optional.of(technician));
    when(workOrderRepository.save(any(WorkOrder.class)))
        .thenAnswer(invocation -> invocation.getArgument(0));

    // Act
    WorkOrderDto result = workOrderService.approveWorkOrder(1L, 2L);

    // Assert
    assertNotNull(result);
    assertTrue(workOrder.getApproved());
    assertNotNull(workOrder.getApprovedAt());
    assertEquals(technician, workOrder.getApprovedBy());
  }

  @Test
  void countByStatus_ShouldReturnCount() {
    // Arrange
    when(workOrderRepository.countByStatusAndIsDeletedFalse(WorkOrderStatus.OPEN)).thenReturn(5L);

    // Act
    Long count = workOrderService.countByStatus(WorkOrderStatus.OPEN);

    // Assert
    assertEquals(5L, count);
    verify(workOrderRepository, times(1)).countByStatusAndIsDeletedFalse(WorkOrderStatus.OPEN);
  }
}
