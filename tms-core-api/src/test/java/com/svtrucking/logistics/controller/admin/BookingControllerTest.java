package com.svtrucking.logistics.controller.admin;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.dto.BookingDto;
import com.svtrucking.logistics.dto.CreateBookingRequest;
import com.svtrucking.logistics.service.BookingService;
import java.math.BigDecimal;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.ResponseEntity;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

@ExtendWith(MockitoExtension.class)
class BookingControllerTest {

    private MockMvc mockMvc;

    @Mock
    private BookingService bookingService;

    @InjectMocks
    private BookingController bookingController;

    private final ObjectMapper objectMapper = new ObjectMapper();

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.standaloneSetup(bookingController).build();
    }

    @Test
    void updateBooking_returnsOk() throws Exception {
        CreateBookingRequest req = CreateBookingRequest.builder()
                .customerId(1L)
                .serviceType("FTL")
                .paymentType("COD")
                .estimatedCost(BigDecimal.valueOf(100))
                .build();

        BookingDto updated = BookingDto.builder().id(1L).customerId(1L).serviceType("FTL").build();

        when(bookingService.update(eq(1L), any(CreateBookingRequest.class)))
                .thenReturn(ResponseEntity.ok(ApiResponse.ok("Booking updated", updated)));

        mockMvc
                .perform(
                        put("/api/admin/bookings/{id}", 1L)
                                .contentType("application/json")
                                .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk());
    }
}
