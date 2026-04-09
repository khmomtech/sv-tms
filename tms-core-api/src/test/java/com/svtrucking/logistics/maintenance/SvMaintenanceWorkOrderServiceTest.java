package com.svtrucking.logistics.maintenance;

import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

import com.svtrucking.logistics.dto.WorkOrderDto;
import com.svtrucking.logistics.enums.MaintenanceRequestStatus;
import com.svtrucking.logistics.enums.RepairType;
import com.svtrucking.logistics.enums.WorkOrderType;
import com.svtrucking.logistics.model.MaintenanceRequest;
import com.svtrucking.logistics.model.Vehicle;
import com.svtrucking.logistics.repository.InvoiceRepository;
import com.svtrucking.logistics.repository.MaintenanceRequestRepository;
import com.svtrucking.logistics.repository.MechanicRepository;
import com.svtrucking.logistics.repository.PartnerCompanyRepository;
import com.svtrucking.logistics.repository.PaymentRepository;
import com.svtrucking.logistics.repository.UserRepository;
import com.svtrucking.logistics.repository.VehicleRepository;
import com.svtrucking.logistics.repository.VendorQuotationRepository;
import com.svtrucking.logistics.repository.VendorRepository;
import com.svtrucking.logistics.repository.WorkOrderMechanicRepository;
import com.svtrucking.logistics.repository.WorkOrderRepository;
import com.svtrucking.logistics.service.SvMaintenanceWorkOrderService;
import java.util.Optional;
import org.junit.jupiter.api.Test;

public class SvMaintenanceWorkOrderServiceTest {

  @Test
  void createWorkOrderFromApprovedMr_rejectsWhenMrNotApproved() {
    MaintenanceRequestRepository mrRepo = mock(MaintenanceRequestRepository.class);
    WorkOrderRepository woRepo = mock(WorkOrderRepository.class);
    VehicleRepository vehicleRepo = mock(VehicleRepository.class);
    UserRepository userRepo = mock(UserRepository.class);

    SvMaintenanceWorkOrderService svc =
        new SvMaintenanceWorkOrderService(
            mrRepo,
            woRepo,
            vehicleRepo,
            userRepo,
            mock(MechanicRepository.class),
            mock(WorkOrderMechanicRepository.class),
            mock(PartnerCompanyRepository.class),
            mock(VendorRepository.class),
            mock(VendorQuotationRepository.class),
            mock(InvoiceRepository.class),
            mock(PaymentRepository.class));

    Vehicle v = new Vehicle();
    v.setId(1L);
    MaintenanceRequest mr = new MaintenanceRequest();
    mr.setId(10L);
    mr.setMrNumber("MR-2026-00001");
    mr.setStatus(MaintenanceRequestStatus.SUBMITTED);
    mr.setVehicle(v);

    when(mrRepo.findById(10L)).thenReturn(Optional.of(mr));

    WorkOrderDto dto = WorkOrderDto.builder().type(WorkOrderType.REPAIR).repairType(RepairType.OWN).title("Fix").build();

    assertThatThrownBy(() -> svc.createWorkOrderFromApprovedMr(10L, dto, null))
        .isInstanceOf(IllegalStateException.class)
        .hasMessageContaining("APPROVED");
  }

  @Test
  void createWorkOrderFromApprovedMr_requiresRepairType() {
    MaintenanceRequestRepository mrRepo = mock(MaintenanceRequestRepository.class);
    WorkOrderRepository woRepo = mock(WorkOrderRepository.class);
    VehicleRepository vehicleRepo = mock(VehicleRepository.class);
    UserRepository userRepo = mock(UserRepository.class);

    SvMaintenanceWorkOrderService svc =
        new SvMaintenanceWorkOrderService(
            mrRepo,
            woRepo,
            vehicleRepo,
            userRepo,
            mock(MechanicRepository.class),
            mock(WorkOrderMechanicRepository.class),
            mock(PartnerCompanyRepository.class),
            mock(VendorRepository.class),
            mock(VendorQuotationRepository.class),
            mock(InvoiceRepository.class),
            mock(PaymentRepository.class));

    Vehicle v = new Vehicle();
    v.setId(1L);
    MaintenanceRequest mr = new MaintenanceRequest();
    mr.setId(10L);
    mr.setMrNumber("MR-2026-00001");
    mr.setStatus(MaintenanceRequestStatus.APPROVED);
    mr.setVehicle(v);

    when(mrRepo.findById(10L)).thenReturn(Optional.of(mr));
    when(woRepo.findByMaintenanceRequestId(10L)).thenReturn(Optional.empty());
    when(vehicleRepo.findById(1L)).thenReturn(Optional.of(v));
    when(woRepo.save(any())).thenAnswer(inv -> inv.getArgument(0));

    WorkOrderDto dto = WorkOrderDto.builder().type(WorkOrderType.REPAIR).title("Fix").build();

    assertThatThrownBy(() -> svc.createWorkOrderFromApprovedMr(10L, dto, null))
        .isInstanceOf(IllegalArgumentException.class)
        .hasMessageContaining("repairType");
  }
}

