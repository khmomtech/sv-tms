package com.svtrucking.logistics.integration;

import com.svtrucking.logistics.dto.DispatchDto;
import com.svtrucking.logistics.enums.DispatchStatus;
import com.svtrucking.logistics.enums.OrderStatus;
import com.svtrucking.logistics.model.*;
import com.svtrucking.logistics.enums.*;
import com.svtrucking.logistics.repository.*;
import com.svtrucking.logistics.service.DispatchService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Integration tests for Dispatch lifecycle scenarios.
 *
 * Tests verify:
 * - Eager loading of related entities through the repository layer
 * - Complete happy path status lifecycle with TransportOrder sync
 * - Safety retry path (SAFETY_FAILED → re-enter loading)
 * - Breakdown recovery (IN_TRANSIT_BREAKDOWN → resume)
 * - Safety bypass (ARRIVED_LOADING → IN_QUEUE direct)
 * - Dispatch reopen (DELIVERED → PENDING_INVESTIGATION)
 */
@SpringBootTest
@ActiveProfiles("test")
@Transactional
public class DispatchApiIntegrationTest {

    @Autowired
    private DispatchRepository dispatchRepository;

    @Autowired
    private DriverRepository driverRepository;

    @Autowired
    private VehicleRepository vehicleRepository;

    @Autowired
    private TransportOrderRepository transportOrderRepository;

    @Autowired
    private CustomerRepository customerRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private DispatchService dispatchService;

    private Driver testDriver;
    private Vehicle testVehicle;
    private TransportOrder testOrder;
    private Dispatch testDispatch;

    @BeforeEach
    void setUp() {
        Customer customer = new Customer();
        customer.setName("Test Customer");
        customer = customerRepository.save(customer);

        User user = new User();
        user.setUsername("testuser_" + System.nanoTime());
        user.setPassword("password");
        user.setEmail("test_" + System.nanoTime() + "@example.com");
        user = userRepository.save(user);

        testDriver = new Driver();
        testDriver.setFirstName("John");
        testDriver.setLastName("Doe");
        testDriver.setPhone("+1234567890");
        testDriver.setLicenseNumber("DL123456_" + System.nanoTime());
        testDriver = driverRepository.save(testDriver);

        testVehicle = new Vehicle();
        testVehicle.setLicensePlate("ABC-" + System.nanoTime());
        testVehicle.setManufacturer("Toyota");
        testVehicle.setModel("Hilux");
        testVehicle.setYearMade(2023);
        testVehicle.setMileage(new BigDecimal("50000"));
        testVehicle.setStatus(VehicleStatus.AVAILABLE);
        testVehicle.setType(VehicleType.TRUCK);
        testVehicle = vehicleRepository.save(testVehicle);

        testOrder = TransportOrder.builder()
                .orderReference("ORD-TEST-" + System.nanoTime())
                .customer(customer)
                .createdBy(user)
                .status(OrderStatus.PENDING)
                .build();
        testOrder = transportOrderRepository.save(testOrder);

        testDispatch = Dispatch.builder()
                .routeCode("ROUTE-TEST-" + System.nanoTime())
                .driver(testDriver)
                .vehicle(testVehicle)
                .transportOrder(testOrder)
                .status(DispatchStatus.ASSIGNED)
                .tripType("DELIVERY")
                .startTime(LocalDateTime.now())
                .estimatedArrival(LocalDateTime.now().plusHours(2))
                .createdBy(user)
                .build();
        testDispatch = dispatchRepository.save(testDispatch);
    }

    // ---- Original test (preserved) ----

    @Test
    @DisplayName("Eager load: findAllWithDetails should load Driver, Vehicle, TransportOrder")
    void testFindAllWithDetails_ShouldEagerLoadDriverAndVehicle() {
        Page<Dispatch> dispatches = dispatchRepository.findAllWithDetails(PageRequest.of(0, 10));

        assertThat(dispatches.getContent()).isNotEmpty();

        Dispatch dispatch = dispatches.getContent().stream()
                .filter(d -> d.getId().equals(testDispatch.getId()))
                .findFirst()
                .orElseThrow(() -> new AssertionError("Test dispatch not found"));

        assertThat(dispatch.getDriver()).isNotNull();
        assertThat(dispatch.getDriver().getId()).isEqualTo(testDriver.getId());
        assertThat(dispatch.getDriver().getFirstName()).isEqualTo("John");
        assertThat(dispatch.getDriver().getLastName()).isEqualTo("Doe");

        assertThat(dispatch.getVehicle()).isNotNull();
        assertThat(dispatch.getVehicle().getId()).isEqualTo(testVehicle.getId());
        assertThat(dispatch.getVehicle().getModel()).isEqualTo("Hilux");

        assertThat(dispatch.getTransportOrder()).isNotNull();
        assertThat(dispatch.getTransportOrder().getId()).isEqualTo(testOrder.getId());
    }

    // ---- Phase 5.2: Lifecycle scenarios ----

    /**
     * Scenario 1 — Happy path; assert TransportOrder.status syncs at each step.
     *
     * Transitions: ASSIGNED → DRIVER_CONFIRMED → ARRIVED_LOADING
     * → SAFETY_PASSED → IN_QUEUE → LOADING → LOADED
     * → IN_TRANSIT → ARRIVED_UNLOADING → UNLOADING → UNLOADED
     * → DELIVERED → COMPLETED
     */
    @Test
    @DisplayName("Lifecycle 1: complete happy path with TransportOrder status sync")
    void testCompleteHappyPathLifecycle() {
        Long dispatchId = testDispatch.getId();

        // ASSIGNED → DRIVER_CONFIRMED
        step(dispatchId, DispatchStatus.DRIVER_CONFIRMED);
        assertTransportOrderStatus(testOrder.getId(), OrderStatus.DRIVER_CONFIRMED);

        // DRIVER_CONFIRMED → ARRIVED_LOADING
        step(dispatchId, DispatchStatus.ARRIVED_LOADING);
        assertTransportOrderStatus(testOrder.getId(), OrderStatus.ARRIVED_LOADING);

        // ARRIVED_LOADING → SAFETY_PASSED (transport order stays at ARRIVED_LOADING:
        // safety events don't change it)
        step(dispatchId, DispatchStatus.SAFETY_PASSED);
        assertTransportOrderStatus(testOrder.getId(), OrderStatus.ARRIVED_LOADING);

        // SAFETY_PASSED → IN_QUEUE (maps to ARRIVED_LOADING in TransportOrder)
        step(dispatchId, DispatchStatus.IN_QUEUE);
        assertTransportOrderStatus(testOrder.getId(), OrderStatus.ARRIVED_LOADING);

        // IN_QUEUE → LOADING
        step(dispatchId, DispatchStatus.LOADING);
        assertTransportOrderStatus(testOrder.getId(), OrderStatus.LOADING);

        // LOADING → LOADED
        step(dispatchId, DispatchStatus.LOADED);
        assertTransportOrderStatus(testOrder.getId(), OrderStatus.LOADED);

        // LOADED → IN_TRANSIT
        step(dispatchId, DispatchStatus.IN_TRANSIT);
        assertTransportOrderStatus(testOrder.getId(), OrderStatus.IN_TRANSIT);

        // IN_TRANSIT → ARRIVED_UNLOADING
        step(dispatchId, DispatchStatus.ARRIVED_UNLOADING);
        assertTransportOrderStatus(testOrder.getId(), OrderStatus.ARRIVED_UNLOADING);

        // ARRIVED_UNLOADING → UNLOADING
        step(dispatchId, DispatchStatus.UNLOADING);
        assertTransportOrderStatus(testOrder.getId(), OrderStatus.UNLOADING);

        // UNLOADING → UNLOADED
        step(dispatchId, DispatchStatus.UNLOADED);
        assertTransportOrderStatus(testOrder.getId(), OrderStatus.UNLOADED);

        // UNLOADED → DELIVERED
        step(dispatchId, DispatchStatus.DELIVERED);
        assertTransportOrderStatus(testOrder.getId(), OrderStatus.DELIVERED);

        // DELIVERED → COMPLETED
        DispatchDto completed = step(dispatchId, DispatchStatus.COMPLETED);
        assertThat(completed.getStatus()).isEqualTo(DispatchStatus.COMPLETED);
        assertTransportOrderStatus(testOrder.getId(), OrderStatus.COMPLETED);
    }

    /**
     * Scenario 2 — Safety retry.
     *
     * ARRIVED_LOADING → SAFETY_FAILED → ARRIVED_LOADING → SAFETY_PASSED → IN_QUEUE
     */
    @Test
    @DisplayName("Lifecycle 2: safety retry — SAFETY_FAILED re-presents at loading")
    void testSafetyRetryPath() {
        Long dispatchId = testDispatch.getId();

        step(dispatchId, DispatchStatus.DRIVER_CONFIRMED);
        step(dispatchId, DispatchStatus.ARRIVED_LOADING);

        // Safety fails
        step(dispatchId, DispatchStatus.SAFETY_FAILED);
        assertThat(dispatchRepository.findById(dispatchId).orElseThrow().getStatus())
                .isEqualTo(DispatchStatus.SAFETY_FAILED);

        // Driver fixes vehicle and re-presents
        step(dispatchId, DispatchStatus.ARRIVED_LOADING);
        assertThat(dispatchRepository.findById(dispatchId).orElseThrow().getStatus())
                .isEqualTo(DispatchStatus.ARRIVED_LOADING);

        // Safety passes this time
        step(dispatchId, DispatchStatus.SAFETY_PASSED);
        step(dispatchId, DispatchStatus.IN_QUEUE);
        assertThat(dispatchRepository.findById(dispatchId).orElseThrow().getStatus())
                .isEqualTo(DispatchStatus.IN_QUEUE);
    }

    /**
     * Scenario 3 — Breakdown recovery.
     *
     * IN_TRANSIT → IN_TRANSIT_BREAKDOWN → IN_TRANSIT → ARRIVED_UNLOADING
     */
    @Test
    @DisplayName("Lifecycle 3: breakdown recovery — resumes IN_TRANSIT after repair")
    void testBreakdownRecovery() {
        Long dispatchId = testDispatch.getId();

        step(dispatchId, DispatchStatus.DRIVER_CONFIRMED);
        step(dispatchId, DispatchStatus.ARRIVED_LOADING);
        step(dispatchId, DispatchStatus.IN_QUEUE);
        step(dispatchId, DispatchStatus.LOADING);
        step(dispatchId, DispatchStatus.LOADED);
        step(dispatchId, DispatchStatus.IN_TRANSIT);

        // Breakdown occurs mid-transit
        step(dispatchId, DispatchStatus.IN_TRANSIT_BREAKDOWN);
        assertThat(dispatchRepository.findById(dispatchId).orElseThrow().getStatus())
                .isEqualTo(DispatchStatus.IN_TRANSIT_BREAKDOWN);

        // Breakdown resolved — resume transit
        step(dispatchId, DispatchStatus.IN_TRANSIT);
        assertThat(dispatchRepository.findById(dispatchId).orElseThrow().getStatus())
                .isEqualTo(DispatchStatus.IN_TRANSIT);

        // Continue to destination
        step(dispatchId, DispatchStatus.ARRIVED_UNLOADING);
        assertThat(dispatchRepository.findById(dispatchId).orElseThrow().getStatus())
                .isEqualTo(DispatchStatus.ARRIVED_UNLOADING);
    }

    /**
     * Scenario 4 — Safety bypass.
     *
     * ARRIVED_LOADING → IN_QUEUE direct (skipping SAFETY_PASSED).
     */
    @Test
    @DisplayName("Lifecycle 4: safety bypass — ARRIVED_LOADING goes directly to IN_QUEUE")
    void testSafetyBypassDirectToInQueue() {
        Long dispatchId = testDispatch.getId();

        step(dispatchId, DispatchStatus.DRIVER_CONFIRMED);
        step(dispatchId, DispatchStatus.ARRIVED_LOADING);

        // Bypass safety check entirely
        DispatchDto inQueue = step(dispatchId, DispatchStatus.IN_QUEUE);
        assertThat(inQueue.getStatus()).isEqualTo(DispatchStatus.IN_QUEUE);
        assertThat(dispatchRepository.findById(dispatchId).orElseThrow().getStatus())
                .isEqualTo(DispatchStatus.IN_QUEUE);
    }

    /**
     * Scenario 5 — Dispatch reopen.
     *
     * DELIVERED → PENDING_INVESTIGATION via reopenDispatch().
     */
    @Test
    @DisplayName("Lifecycle 5: reopen — DELIVERED dispatch moved to PENDING_INVESTIGATION")
    void testReopenDeliveredDispatch() {
        Long dispatchId = testDispatch.getId();

        // Advance to DELIVERED
        step(dispatchId, DispatchStatus.DRIVER_CONFIRMED);
        step(dispatchId, DispatchStatus.ARRIVED_LOADING);
        step(dispatchId, DispatchStatus.IN_QUEUE);
        step(dispatchId, DispatchStatus.LOADING);
        step(dispatchId, DispatchStatus.LOADED);
        step(dispatchId, DispatchStatus.IN_TRANSIT);
        step(dispatchId, DispatchStatus.ARRIVED_UNLOADING);
        step(dispatchId, DispatchStatus.UNLOADING);
        step(dispatchId, DispatchStatus.UNLOADED);
        step(dispatchId, DispatchStatus.DELIVERED);

        assertThat(dispatchRepository.findById(dispatchId).orElseThrow().getStatus())
                .isEqualTo(DispatchStatus.DELIVERED);

        // Reopen for investigation
        DispatchDto reopened = dispatchService.reopenDispatch(dispatchId, "Damage claim from customer");
        assertThat(reopened.getStatus()).isEqualTo(DispatchStatus.PENDING_INVESTIGATION);
        assertThat(dispatchRepository.findById(dispatchId).orElseThrow().getStatus())
                .isEqualTo(DispatchStatus.PENDING_INVESTIGATION);
    }

    // ---- Helpers ----

    /**
     * Advance dispatch to {@code newStatus} via updateDispatch(), which bypasses
     * workflow prerequisites so lifecycle tests can step through statuses without
     * needing to satisfy every business rule (POL, LoadingQueue, etc.).
     */
    private DispatchDto step(Long dispatchId, DispatchStatus newStatus) {
        DispatchDto request = new DispatchDto();
        request.setStatus(newStatus);
        DispatchDto result = dispatchService.updateDispatch(dispatchId, request);
        assertThat(result.getStatus())
                .as("Dispatch status after step to %s", newStatus)
                .isEqualTo(newStatus);
        return result;
    }

    private void assertTransportOrderStatus(Long orderId, OrderStatus expectedStatus) {
        TransportOrder order = transportOrderRepository.findById(orderId).orElseThrow();
        assertThat(order.getStatus())
                .as("TransportOrder.status after dispatch status change")
                .isEqualTo(expectedStatus);
    }
}
