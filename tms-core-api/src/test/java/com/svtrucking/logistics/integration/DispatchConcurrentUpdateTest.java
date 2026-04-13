package com.svtrucking.logistics.integration;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.svtrucking.logistics.dto.DispatchDto;
import com.svtrucking.logistics.enums.DispatchStatus;
import com.svtrucking.logistics.enums.OrderStatus;
import com.svtrucking.logistics.enums.VehicleStatus;
import com.svtrucking.logistics.enums.VehicleType;
import com.svtrucking.logistics.idempotency.IdempotentResponse;
import com.svtrucking.logistics.idempotency.IdempotencyService;
import com.svtrucking.logistics.model.*;
import com.svtrucking.logistics.repository.*;
import com.svtrucking.logistics.security.AuthenticatedUserUtil;
import com.svtrucking.logistics.service.DispatchService;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.orm.ObjectOptimisticLockingFailureException;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicReference;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Integration tests for concurrent dispatch update safety and idempotency
 * replay.
 *
 * <p>
 * Tests verify:
 * <ul>
 * <li>Optimistic locking: two threads racing to update the same dispatch — at
 * most one
 * {@link ObjectOptimisticLockingFailureException} propagates; final DB state is
 * always
 * consistent.
 * <li>Idempotency replay: the {@code IdempotencyFilter} returns a cached
 * response with
 * {@code X-Idempotency-Replay: true} when the same {@code X-Idempotency-Key} is
 * sent
 * twice.
 * </ul>
 *
 * <p>
 * <b>Why no class-level {@code @Transactional}?</b>
 * The concurrent scenario requires each service call to run in its own real
 * database
 * transaction. A single class-level transaction would prevent Hibernate's
 * {@code @Version}
 * check from ever detecting a conflict because both threads would share the
 * same
 * uncommitted view.
 *
 * <p>
 * <b>Why {@code @MockBean IdempotencyService}?</b>
 * The test profile disables Redis ({@code spring.data.redis.host=disabled}) and
 * excludes
 * {@code RedisAutoConfiguration}. {@code IdempotencyService} requires
 * {@code RedisTemplate},
 * so the real bean cannot be created. The mock prevents context-startup failure
 * while still
 * allowing the real {@code IdempotencyFilter} to execute through the MockMvc
 * filter chain.
 *
 * <p>
 * <b>Why {@code @MockBean AuthenticatedUserUtil}?</b>
 * The PATCH endpoint routes through {@code updateDispatchStatusWithResponse()},
 * which calls
 * {@code validateDriverOwnershipForMutation()}. That method checks the
 * authenticated driver
 * ID against the dispatch's assigned driver via
 * {@code authUtil.getCurrentDriverId()}.
 * Stubbing the mock to return the test driver's ID satisfies the ownership
 * check without
 * requiring a real JWT.
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT, properties = "idempotency.enabled=true")
@AutoConfigureMockMvc
@ActiveProfiles("test")
public class DispatchConcurrentUpdateTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

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
    private DispatchStatusHistoryRepository dispatchStatusHistoryRepository;

    @Autowired
    private DispatchService dispatchService;

    /**
     * Replaces the Redis-backed bean so the context starts without a Redis
     * connection.
     */
    @MockBean
    private IdempotencyService idempotencyService;

    /**
     * Replaces the JWT-reading utility so driver ownership checks can be satisfied
     * in tests without a real JWT token.
     */
    @MockBean
    private AuthenticatedUserUtil authUtil;

    private Long dispatchId;
    private Long transportOrderId;
    private Driver testDriver;
    private User testUser;

    @BeforeEach
    void setUp() throws Exception {
        long nonce = System.nanoTime();

        Customer customer = new Customer();
        customer.setName("Concurrent Customer " + nonce);
        customer = customerRepository.save(customer);

        testUser = new User();
        testUser.setUsername("concurrent_user_" + nonce);
        testUser.setPassword("password");
        testUser.setEmail("concurrent_" + nonce + "@test.com");
        testUser = userRepository.save(testUser);

        testDriver = new Driver();
        testDriver.setFirstName("Concurrent");
        testDriver.setLastName("Driver");
        testDriver.setPhone("+1200000000");
        testDriver.setLicenseNumber("CONC_" + nonce);
        testDriver = driverRepository.save(testDriver);

        Vehicle testVehicle = new Vehicle();
        testVehicle.setLicensePlate("CONC-" + nonce);
        testVehicle.setManufacturer("Toyota");
        testVehicle.setModel("Hilux");
        testVehicle.setYearMade(2023);
        testVehicle.setMileage(new BigDecimal("10000"));
        testVehicle.setStatus(VehicleStatus.AVAILABLE);
        testVehicle.setType(VehicleType.TRUCK);
        testVehicle = vehicleRepository.save(testVehicle);

        TransportOrder order = TransportOrder.builder()
                .orderReference("ORD-CONC-" + nonce)
                .customer(customer)
                .createdBy(testUser)
                .status(OrderStatus.PENDING)
                .build();
        order = transportOrderRepository.save(order);
        transportOrderId = order.getId();

        Dispatch dispatch = Dispatch.builder()
                .routeCode("RT-CONC-" + nonce)
                .driver(testDriver)
                .vehicle(testVehicle)
                .transportOrder(order)
                .status(DispatchStatus.ASSIGNED)
                .tripType("DELIVERY")
                .startTime(LocalDateTime.now())
                .estimatedArrival(LocalDateTime.now().plusHours(2))
                .createdBy(testUser)
                .build();
        dispatch = dispatchRepository.save(dispatch);
        dispatchId = dispatch.getId();

        // Stub driver ownership so the HTTP endpoint's
        // validateDriverOwnershipForMutation()
        // accepts requests as if the authenticated user owns this dispatch.
        doReturn(testDriver.getId()).when(authUtil).getCurrentDriverId();
        doReturn(testUser).when(authUtil).getCurrentUser();

        // By default, idempotency service reports no cached response.
        when(idempotencyService.get(any(), any())).thenReturn(Optional.empty());
        doNothing().when(idempotencyService).store(any(), any(), any());
    }

    @AfterEach
    void tearDown() {
        if (dispatchId != null) {
            dispatchStatusHistoryRepository.deleteByDispatchId(dispatchId);
            dispatchRepository.deleteById(dispatchId);
        }
        if (transportOrderId != null) {
            transportOrderRepository.deleteById(transportOrderId);
        }
    }

    @Test
    @DisplayName("Driver accept persists dispatch status and read-after-write returns DRIVER_CONFIRMED")
    @WithMockUser(authorities = {"ROLE_DRIVER"})
    void driverAccept_persistsStatusAndImmediateReadSeesUpdatedState() throws Exception {
        mockMvc.perform(post("/api/driver/dispatches/" + dispatchId + "/accept"))
                .andExpect(status().isOk());

        Dispatch persisted = dispatchRepository.findById(dispatchId).orElseThrow();
        assertThat(persisted.getStatus()).isEqualTo(DispatchStatus.DRIVER_CONFIRMED);

        mockMvc.perform(get("/api/driver/dispatches/" + dispatchId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value("DRIVER_CONFIRMED"));

        mockMvc.perform(get("/api/driver/dispatches/" + dispatchId + "/available-actions"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.currentStatus").value("DRIVER_CONFIRMED"));
    }

    // ── Scenario 1: Optimistic Lock Race ─────────────────────────────────────────

    /**
     * Two threads simultaneously attempt {@code ASSIGNED → DRIVER_CONFIRMED} on the
     * same
     * dispatch. Because the dispatch entity uses {@code @Version} optimistic
     * locking, exactly
     * one of the following outcomes must occur:
     *
     * <ol>
     * <li><b>Race detected:</b> one thread wins; the other throws
     * {@link ObjectOptimisticLockingFailureException}. Final status =
     * {@code DRIVER_CONFIRMED}.
     * <li><b>Sequential execution:</b> the first thread commits before the second
     * reads. The
     * second thread finds the dispatch already at {@code DRIVER_CONFIRMED} and
     * returns
     * without a version conflict (service no-op path). Final status =
     * {@code DRIVER_CONFIRMED}.
     * </ol>
     *
     * In both outcomes the DB state converges to {@code DRIVER_CONFIRMED} and no
     * unexpected
     * exception type is thrown.
     */
    @Test
    @DisplayName("Concurrent race: optimistic lock ensures consistent DRIVER_CONFIRMED state")
    void testConcurrentStatusUpdate_finalStateIsConsistent() throws InterruptedException {
        int threadCount = 2;
        CountDownLatch ready = new CountDownLatch(threadCount);
        CountDownLatch go = new CountDownLatch(1);
        ExecutorService executor = Executors.newFixedThreadPool(threadCount);

        AtomicReference<DispatchDto> result1 = new AtomicReference<>();
        AtomicReference<DispatchDto> result2 = new AtomicReference<>();
        AtomicReference<Throwable> error1 = new AtomicReference<>();
        AtomicReference<Throwable> error2 = new AtomicReference<>();

        executor.submit(() -> {
            ready.countDown();
            try {
                go.await();
                result1.set(dispatchService.updateDispatchStatus(dispatchId, DispatchStatus.DRIVER_CONFIRMED));
            } catch (Throwable t) {
                error1.set(t);
            }
        });

        executor.submit(() -> {
            ready.countDown();
            try {
                go.await();
                result2.set(dispatchService.updateDispatchStatus(dispatchId, DispatchStatus.DRIVER_CONFIRMED));
            } catch (Throwable t) {
                error2.set(t);
            }
        });

        // Gate: wait until both threads are parked at the CountDownLatch, then release.
        assertThat(ready.await(5, TimeUnit.SECONDS))
                .as("Both threads must reach the start gate within 5 s")
                .isTrue();
        go.countDown();

        executor.shutdown();
        assertThat(executor.awaitTermination(10, TimeUnit.SECONDS))
                .as("Both threads must complete within 10 s")
                .isTrue();

        // At least one thread must have returned a successful DTO.
        boolean anySuccess = result1.get() != null || result2.get() != null;
        assertThat(anySuccess)
                .as("At least one thread must have successfully updated the dispatch")
                .isTrue();

        // Any exception must be an optimistic-lock conflict — not a programming error.
        if (error1.get() != null) {
            assertThat(error1.get())
                    .as("Thread 1 may only fail with an optimistic lock exception")
                    .isInstanceOf(ObjectOptimisticLockingFailureException.class);
        }
        if (error2.get() != null) {
            assertThat(error2.get())
                    .as("Thread 2 may only fail with an optimistic lock exception")
                    .isInstanceOf(ObjectOptimisticLockingFailureException.class);
        }

        // Most important: the final persisted state is unambiguously DRIVER_CONFIRMED.
        Dispatch finalDispatch = dispatchRepository.findById(dispatchId)
                .orElseThrow(() -> new AssertionError("Dispatch not found after concurrent update"));
        assertThat(finalDispatch.getStatus())
                .as("Dispatch must be in DRIVER_CONFIRMED state after concurrent updates")
                .isEqualTo(DispatchStatus.DRIVER_CONFIRMED);
    }

    // ── Scenario 2: Idempotency Replay via HTTP Filter ───────────────────────────

    /**
     * Sending the same {@code PATCH /status} request twice with an identical
     * {@code X-Idempotency-Key} header must:
     *
     * <ol>
     * <li>Return HTTP 200 on the first call with no {@code X-Idempotency-Replay}
     * header.
     * <li>Return HTTP 200 on the second call with
     * {@code X-Idempotency-Replay: true},
     * proving the response came from the filter's cache.
     * </ol>
     *
     * <p>
     * The {@link IdempotencyService} is mocked with an in-process
     * {@link AtomicReference}
     * that simulates the Redis read/write contract without requiring a real Redis
     * connection.
     */
    @Test
    @WithMockUser(roles = "DRIVER")
    @DisplayName("Idempotency replay: X-Idempotency-Replay: true on second request with same key")
    void testIdempotencyReplay_sameKeySentTwice_secondResponseIsReplay() throws Exception {
        // Use an AtomicReference as an in-process substitute for Redis.
        AtomicReference<IdempotentResponse> inMemoryCache = new AtomicReference<>();

        doAnswer(inv -> {
            inMemoryCache.set(inv.getArgument(2));
            return null;
        }).when(idempotencyService).store(any(), any(), any());

        when(idempotencyService.get(any(), any()))
                .thenAnswer(inv -> Optional.ofNullable(inMemoryCache.get()));

        String idempotencyKey = "test-idem-key-" + dispatchId;
        String requestBody = objectMapper.writeValueAsString(
                Map.of("status", "DRIVER_CONFIRMED"));

        // ── First request: cache is empty → filter processes the request normally ──
        MvcResult firstResponse = mockMvc.perform(
                patch("/api/driver/dispatches/" + dispatchId + "/status")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(requestBody)
                        .header("X-Idempotency-Key", idempotencyKey))
                .andExpect(status().isOk())
                .andReturn();

        String firstReplayHeader = firstResponse.getResponse().getHeader("X-Idempotency-Replay");
        assertThat(firstReplayHeader)
                .as("First request must not carry the replay header")
                .isNotEqualTo("true");

        // The filter must have stored the response for future replays.
        verify(idempotencyService, atLeastOnce()).store(
                any(),
                argThat(key -> key != null && key.endsWith(":" + idempotencyKey)),
                any());
        assertThat(inMemoryCache.get())
                .as("IdempotencyService.store() must have been called with a non-null response")
                .isNotNull();

        // ── Second request: cache is populated → filter short-circuits and replays ──
        MvcResult secondResponse = mockMvc.perform(
                patch("/api/driver/dispatches/" + dispatchId + "/status")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(requestBody)
                        .header("X-Idempotency-Key", idempotencyKey))
                .andExpect(status().isOk())
                .andReturn();

        assertThat(secondResponse.getResponse().getHeader("X-Idempotency-Replay"))
                .as("Second request with the same idempotency key must be flagged as a replay")
                .isEqualTo("true");
    }
}
