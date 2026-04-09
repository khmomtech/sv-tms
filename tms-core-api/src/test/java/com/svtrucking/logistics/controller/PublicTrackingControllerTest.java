package com.svtrucking.logistics.controller;

import com.svtrucking.logistics.enums.DispatchStatus;
import com.svtrucking.logistics.enums.OrderStatus;
import com.svtrucking.logistics.model.*;
import com.svtrucking.logistics.repository.DispatchRepository;
import com.svtrucking.logistics.repository.DispatchStatusHistoryRepository;
import com.svtrucking.logistics.repository.TransportOrderRepository;
import com.svtrucking.logistics.service.TelematicsProxyService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

import static org.hamcrest.Matchers.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultHandlers.print;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * Unit tests for PublicTrackingController
 * Tests public tracking API endpoints without authentication
 */
class PublicTrackingControllerTest {

  private MockMvc mockMvc;

  @MockBean
  private TransportOrderRepository transportOrderRepository;

  @MockBean
  private DispatchRepository dispatchRepository;

  @MockBean
  private DispatchStatusHistoryRepository dispatchStatusHistoryRepository;

  @MockBean
  private TelematicsProxyService telematicsProxyService;

  private PublicTrackingController controller;

  private TransportOrder mockOrder;
  private Customer mockCustomer;
  private Dispatch mockDispatch;
  private Driver mockDriver;
  private Vehicle mockVehicle;

  @BeforeEach
  void setUp() {
    transportOrderRepository = org.mockito.Mockito.mock(TransportOrderRepository.class);
    dispatchRepository = org.mockito.Mockito.mock(DispatchRepository.class);
    dispatchStatusHistoryRepository = org.mockito.Mockito.mock(DispatchStatusHistoryRepository.class);
    telematicsProxyService = org.mockito.Mockito.mock(TelematicsProxyService.class);

    controller = new PublicTrackingController(
        transportOrderRepository,
        dispatchRepository,
        dispatchStatusHistoryRepository,
        telematicsProxyService
    );
    when(telematicsProxyService.isForwardingEnabled()).thenReturn(false);

    mockMvc = MockMvcBuilders.standaloneSetup(controller).build();

    setupMockData();
        // Default repository behavior: return mockOrder for common lookup methods
        org.mockito.Mockito.when(transportOrderRepository.findWithCustomerByOrderReferenceIgnoreCase(org.mockito.ArgumentMatchers.anyString()))
                .thenAnswer(inv -> {
                    String ref = inv.getArgument(0, String.class);
                    if ("INVALID-REF".equalsIgnoreCase(ref)) return java.util.Optional.empty();
                    return java.util.Optional.of(mockOrder);
                });
        org.mockito.Mockito.when(transportOrderRepository.findByOrderReferenceIgnoreCase(org.mockito.ArgumentMatchers.anyString()))
                .thenAnswer(inv -> {
                    String ref = inv.getArgument(0, String.class);
                    if ("INVALID-REF".equalsIgnoreCase(ref)) return java.util.Optional.empty();
                    return java.util.Optional.of(mockOrder);
                });
  }

  private void setupMockData() {
    // Mock Customer
    mockCustomer = new Customer();
    mockCustomer.setId(1L);
    mockCustomer.setName("ABC Corporation");

    // Mock Vehicle
    mockVehicle = new Vehicle();
    mockVehicle.setId(1L);
    mockVehicle.setLicensePlate("PP-1234");

    // Mock Driver
    mockDriver = new Driver();
    mockDriver.setId(1L);
    mockDriver.setName("John Doe");
    mockDriver.setPhone("+855123456789");

    // Mock TransportOrder
    mockOrder = TransportOrder.builder()
        .id(1L)
        .orderReference("BK-2026-00125")
        .customer(mockCustomer)
        .status(OrderStatus.IN_TRANSIT)
        .shipmentType("Standard")
        .orderDate(LocalDate.of(2026, 1, 1))
        .deliveryDate(LocalDate.of(2026, 1, 10))
        .billTo("ABC Corporation")
        .build();

    // Mock Dispatch
    mockDispatch = Dispatch.builder()
        .id(1L)
        .transportOrder(mockOrder)
        .routeCode("RT-001")
        .trackingNo("TRK-2026-001")
        .status(DispatchStatus.IN_TRANSIT)
        .fromLocation("Phnom Penh")
        .toLocation("Siem Reap")
        .driver(mockDriver)
        .vehicle(mockVehicle)
        .startTime(LocalDateTime.of(2026, 1, 5, 8, 0))
        .estimatedArrival(LocalDateTime.of(2026, 1, 10, 18, 0))
        .createdDate(LocalDateTime.of(2026, 1, 5, 7, 0))
        .updatedDate(LocalDateTime.of(2026, 1, 9, 10, 30))
        .build();
  }

  @Test
  @DisplayName("GET /api/public/tracking/{orderReference} - Success")
  void trackShipment_withValidReference_returnsOk() throws Exception {
    when(transportOrderRepository.findByOrderReferenceIgnoreCase("BK-2026-00125"))
        .thenReturn(Optional.of(mockOrder));
    when(dispatchRepository.findByTransportOrderOrderByCreatedDateDesc(any(TransportOrder.class)))
        .thenReturn(List.of(mockDispatch));

    mockMvc.perform(get("/api/public/tracking/BK-2026-00125")
            .contentType(MediaType.APPLICATION_JSON))
        .andDo(print())
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.success").value(true))
        .andExpect(jsonPath("$.message").value("Tracking information retrieved"))
        .andExpect(jsonPath("$.data.orderReference").value("BK-2026-00125"))
        .andExpect(jsonPath("$.data.orderStatus").value("IN_TRANSIT"))
        .andExpect(jsonPath("$.data.customerName").value("ABC Corporation"))
        .andExpect(jsonPath("$.data.dispatch.routeCode").value("RT-001"))
        .andExpect(jsonPath("$.data.dispatch.driver.name").value("John Doe"))
        .andExpect(jsonPath("$.data.dispatch.driver.vehicleNumber").value("PP-1234"));
  }

  @Test
  @DisplayName("GET /api/public/tracking/{orderReference} - Order Not Found")
  void trackShipment_withInvalidReference_returns404() throws Exception {
    when(transportOrderRepository.findByOrderReferenceIgnoreCase("INVALID-REF"))
        .thenReturn(Optional.empty());

    mockMvc.perform(get("/api/public/tracking/INVALID-REF")
            .contentType(MediaType.APPLICATION_JSON))
        .andDo(print())
        .andExpect(status().isNotFound());
  }

  @Test
  @DisplayName("GET /api/public/tracking/{orderReference} - Case Insensitive")
  void trackShipment_withLowercaseReference_returnsOk() throws Exception {
    when(transportOrderRepository.findByOrderReferenceIgnoreCase("bk-2026-00125"))
        .thenReturn(Optional.of(mockOrder));
    when(dispatchRepository.findByTransportOrderOrderByCreatedDateDesc(any(TransportOrder.class)))
        .thenReturn(List.of(mockDispatch));

    mockMvc.perform(get("/api/public/tracking/bk-2026-00125")
            .contentType(MediaType.APPLICATION_JSON))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.data.orderReference").value("BK-2026-00125"));
  }

  @Test
  @DisplayName("GET /api/public/tracking/{orderReference} - No Dispatch Assigned")
  void trackShipment_withNoDispatch_returnsOrderOnly() throws Exception {
    when(transportOrderRepository.findByOrderReferenceIgnoreCase("BK-2026-00125"))
        .thenReturn(Optional.of(mockOrder));
    when(dispatchRepository.findByTransportOrderOrderByCreatedDateDesc(any(TransportOrder.class)))
        .thenReturn(List.of());

    mockMvc.perform(get("/api/public/tracking/BK-2026-00125")
            .contentType(MediaType.APPLICATION_JSON))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.data.orderReference").value("BK-2026-00125"))
        .andExpect(jsonPath("$.data.dispatch").doesNotExist());
  }

  @Test
  @DisplayName("GET /api/public/tracking/{orderReference}/location - Success")
  void getCurrentLocation_withValidReference_returnsOk() throws Exception {
    when(transportOrderRepository.findByOrderReferenceIgnoreCase("BK-2026-00125"))
        .thenReturn(Optional.of(mockOrder));
    when(dispatchRepository.findByTransportOrderOrderByCreatedDateDesc(any(TransportOrder.class)))
        .thenReturn(List.of(mockDispatch));

    mockMvc.perform(get("/api/public/tracking/BK-2026-00125/location")
            .contentType(MediaType.APPLICATION_JSON))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.data.orderReference").value("BK-2026-00125"))
        .andExpect(jsonPath("$.data.hasActiveDispatch").value(true))
        .andExpect(jsonPath("$.data.driverAssigned").value(true))
        .andExpect(jsonPath("$.data.currentStatus").value("IN_TRANSIT"));
  }

  @Test
  @DisplayName("GET /api/public/tracking/{orderReference}/location - No Dispatch")
  void getCurrentLocation_withNoDispatch_returnsNoDriver() throws Exception {
    when(transportOrderRepository.findByOrderReferenceIgnoreCase("BK-2026-00125"))
        .thenReturn(Optional.of(mockOrder));
    when(dispatchRepository.findByTransportOrderOrderByCreatedDateDesc(any(TransportOrder.class)))
        .thenReturn(List.of());

    mockMvc.perform(get("/api/public/tracking/BK-2026-00125/location")
            .contentType(MediaType.APPLICATION_JSON))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.data.hasActiveDispatch").value(false))
        .andExpect(jsonPath("$.data.driverAssigned").value(false));
  }

  @Test
  @DisplayName("GET /api/public/tracking/{orderReference}/history - Success")
  void getStatusHistory_withValidReference_returnsHistory() throws Exception {
    List<DispatchStatusHistory> history = new ArrayList<>();
    
    DispatchStatusHistory h1 = new DispatchStatusHistory();
    h1.setId(1L);
    h1.setDispatch(mockDispatch);
    h1.setStatus(DispatchStatus.ASSIGNED);
    h1.setUpdatedAt(LocalDateTime.of(2026, 1, 5, 7, 0));
    h1.setRemarks("Driver assigned");
    
    DispatchStatusHistory h2 = new DispatchStatusHistory();
    h2.setId(2L);
    h2.setDispatch(mockDispatch);
    h2.setStatus(DispatchStatus.IN_TRANSIT);
    h2.setUpdatedAt(LocalDateTime.of(2026, 1, 5, 8, 0));
    h2.setRemarks("Shipment picked up");
    
    history.add(h1);
    history.add(h2);

    when(transportOrderRepository.findByOrderReferenceIgnoreCase("BK-2026-00125"))
        .thenReturn(Optional.of(mockOrder));
    when(dispatchRepository.findByTransportOrderOrderByCreatedDateDesc(any(TransportOrder.class)))
        .thenReturn(List.of(mockDispatch));
    when(dispatchStatusHistoryRepository.findByDispatchOrderByUpdatedAtAsc(mockDispatch))
        .thenReturn(history);

    mockMvc.perform(get("/api/public/tracking/BK-2026-00125/history")
            .contentType(MediaType.APPLICATION_JSON))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.data").isArray())
        .andExpect(jsonPath("$.data", hasSize(2)))
        .andExpect(jsonPath("$.data[0].status").value("ASSIGNED"))
        .andExpect(jsonPath("$.data[0].notes").value("Driver assigned"))
        .andExpect(jsonPath("$.data[1].status").value("IN_TRANSIT"))
        .andExpect(jsonPath("$.data[1].notes").value("Shipment picked up"));
  }

  @Test
  @DisplayName("GET /api/public/tracking/{orderReference}/history - No Dispatch")
  void getStatusHistory_withNoDispatch_returnsEmptyHistory() throws Exception {
    when(transportOrderRepository.findByOrderReferenceIgnoreCase("BK-2026-00125"))
        .thenReturn(Optional.of(mockOrder));
    when(dispatchRepository.findByTransportOrderOrderByCreatedDateDesc(any(TransportOrder.class)))
        .thenReturn(List.of());

    mockMvc.perform(get("/api/public/tracking/BK-2026-00125/history")
            .contentType(MediaType.APPLICATION_JSON))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.data").isArray())
        .andExpect(jsonPath("$.data", hasSize(0)));
  }

  @Test
  @DisplayName("GET /api/public/tracking/{orderReference}/proof-of-delivery - Success")
  void getProofOfDelivery_withValidReference_returnsOk() throws Exception {
    UnloadProof unloadProof = new UnloadProof();
    unloadProof.setId(1L);
    mockDispatch.setUnloadProof(unloadProof);

    when(transportOrderRepository.findByOrderReferenceIgnoreCase("BK-2026-00125"))
        .thenReturn(Optional.of(mockOrder));
    when(dispatchRepository.findByTransportOrderOrderByCreatedDateDesc(any(TransportOrder.class)))
        .thenReturn(List.of(mockDispatch));

    mockMvc.perform(get("/api/public/tracking/BK-2026-00125/proof-of-delivery")
            .contentType(MediaType.APPLICATION_JSON))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.data.orderReference").value("BK-2026-00125"))
        .andExpect(jsonPath("$.data.isDelivered").value(true))
        .andExpect(jsonPath("$.data.availableForDownload").value(true));
  }

  @Test
  @DisplayName("GET /api/public/tracking/{orderReference}/proof-of-delivery - Not Yet Delivered")
  void getProofOfDelivery_withNoUnloadProof_returnsNotDelivered() throws Exception {
    mockDispatch.setUnloadProof(null);

    when(transportOrderRepository.findByOrderReferenceIgnoreCase("BK-2026-00125"))
        .thenReturn(Optional.of(mockOrder));
    when(dispatchRepository.findByTransportOrderOrderByCreatedDateDesc(any(TransportOrder.class)))
        .thenReturn(List.of(mockDispatch));

    mockMvc.perform(get("/api/public/tracking/BK-2026-00125/proof-of-delivery")
            .contentType(MediaType.APPLICATION_JSON))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.data.isDelivered").value(false))
        .andExpect(jsonPath("$.data.availableForDownload").value(false));
  }

  @Test
  @DisplayName("Tracking endpoints should not require authentication")
  void trackingEndpoints_withoutAuth_returnsOk() throws Exception {
    when(transportOrderRepository.findByOrderReferenceIgnoreCase("BK-2026-00125"))
        .thenReturn(Optional.of(mockOrder));
    when(dispatchRepository.findByTransportOrderOrderByCreatedDateDesc(any(TransportOrder.class)))
        .thenReturn(List.of(mockDispatch));

    // Test that endpoint works without authentication
    mockMvc.perform(get("/api/public/tracking/BK-2026-00125")
            .contentType(MediaType.APPLICATION_JSON))
        .andExpect(status().isOk());
  }
}
