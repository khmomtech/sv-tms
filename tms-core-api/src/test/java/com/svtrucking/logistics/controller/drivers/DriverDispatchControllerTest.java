package com.svtrucking.logistics.controller.drivers;

import com.svtrucking.logistics.dto.DispatchDto;
import com.svtrucking.logistics.enums.DispatchStatus;
import com.svtrucking.logistics.modules.notification.service.DriverNotificationService;
import com.svtrucking.logistics.security.AuthenticatedUserUtil;
import com.svtrucking.logistics.service.DispatchService;
import com.svtrucking.logistics.service.LoadProofService;
import com.svtrucking.logistics.service.UnloadProofService;
import java.util.List;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.mockito.Mockito;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class DriverDispatchControllerTest {

  private DriverDispatchController controller;
  private DispatchService dispatchService;
  private AuthenticatedUserUtil authUtil;

  @BeforeEach
  void setup() {
    dispatchService = Mockito.mock(DispatchService.class);
    LoadProofService loadProofService = Mockito.mock(LoadProofService.class);
    UnloadProofService unloadProofService = Mockito.mock(UnloadProofService.class);
    DriverNotificationService notificationService = Mockito.mock(DriverNotificationService.class);
    authUtil = Mockito.mock(AuthenticatedUserUtil.class);

    controller = new DriverDispatchController(
        dispatchService,
        loadProofService,
        unloadProofService,
        notificationService,
        authUtil);
  }

  @Test
  void getMyPendingDispatches_usesExpectedStatuses() {
    when(authUtil.getCurrentDriverId()).thenReturn(7L);
    when(dispatchService.getDispatchesByDriverWithStatuses(eq(7L), any(), any()))
        .thenReturn(new PageImpl<>(List.of(sampleDispatch(1L, DispatchStatus.ASSIGNED))));

    controller.getMyPendingDispatches(PageRequest.of(0, 100));

    ArgumentCaptor<List<DispatchStatus>> statusesCaptor = ArgumentCaptor.forClass(List.class);
    verify(dispatchService).getDispatchesByDriverWithStatuses(eq(7L), statusesCaptor.capture(), any());
    assertEquals(
        List.of(
            DispatchStatus.PLANNED,
            DispatchStatus.PENDING,
            DispatchStatus.SCHEDULED,
            DispatchStatus.ASSIGNED),
        statusesCaptor.getValue());
  }

  @Test
  void getMyInProgressDispatches_usesExpectedStatuses() {
    when(authUtil.getCurrentDriverId()).thenReturn(7L);
    when(dispatchService.getDispatchesByDriverWithStatuses(eq(7L), any(), any()))
        .thenReturn(Page.empty());

    controller.getMyInProgressDispatches(PageRequest.of(0, 100));

    ArgumentCaptor<List<DispatchStatus>> statusesCaptor = ArgumentCaptor.forClass(List.class);
    verify(dispatchService).getDispatchesByDriverWithStatuses(eq(7L), statusesCaptor.capture(), any());
    assertEquals(
        List.of(
            DispatchStatus.DRIVER_CONFIRMED,
            DispatchStatus.APPROVED,
            DispatchStatus.ARRIVED_LOADING,
            DispatchStatus.IN_QUEUE,
            DispatchStatus.LOADING,
            DispatchStatus.LOADED,
            DispatchStatus.AT_HUB,
            DispatchStatus.HUB_LOADING,
            DispatchStatus.IN_TRANSIT,
            DispatchStatus.ARRIVED_UNLOADING,
            DispatchStatus.UNLOADING,
            DispatchStatus.UNLOADED,
            DispatchStatus.SAFETY_PASSED),
        statusesCaptor.getValue());
  }

  @Test
  void getMyCompletedDispatches_usesExpectedStatuses() {
    when(authUtil.getCurrentDriverId()).thenReturn(7L);
    when(dispatchService.getDispatchesByDriverWithStatuses(eq(7L), any(), any()))
        .thenReturn(Page.empty());

    controller.getMyCompletedDispatches(PageRequest.of(0, 100));

    ArgumentCaptor<List<DispatchStatus>> statusesCaptor = ArgumentCaptor.forClass(List.class);
    verify(dispatchService).getDispatchesByDriverWithStatuses(eq(7L), statusesCaptor.capture(), any());
    assertEquals(
        List.of(
            DispatchStatus.DELIVERED,
            DispatchStatus.FINANCIAL_LOCKED,
            DispatchStatus.CLOSED,
            DispatchStatus.COMPLETED,
            DispatchStatus.CANCELLED,
            DispatchStatus.REJECTED,
            DispatchStatus.SAFETY_FAILED),
        statusesCaptor.getValue());
  }

  private DispatchDto sampleDispatch(Long id, DispatchStatus status) {
    DispatchDto dto = new DispatchDto();
    dto.setId(id);
    dto.setStatus(status);
    return dto;
  }
}

