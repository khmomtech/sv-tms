package com.svtrucking.logistics.controller;

import com.svtrucking.logistics.dto.VehicleDto;
import com.svtrucking.logistics.dto.VehicleStatisticsDto;
import com.svtrucking.logistics.service.VehicleService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.data.domain.Page;
import org.springframework.data.web.PageableHandlerMethodArgumentResolver;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.util.Collections;
import java.util.Optional;

import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Unit tests for {@link FleetController} using standalone MockMvc.
 *
 * Security annotations (@PreAuthorize) are bypassed in standalone mode so each
 * test focuses on HTTP status codes and response structure, not authorization.
 */
class FleetControllerTest {

    private MockMvc mockMvc;
    private VehicleService vehicleService;

    @BeforeEach
    void setUp() {
        vehicleService = mock(VehicleService.class);
        FleetController controller = new FleetController(vehicleService);

        var objectMapper = org.springframework.http.converter.json.Jackson2ObjectMapperBuilder.json().build();
        objectMapper.registerModule(new com.fasterxml.jackson.datatype.jsr310.JavaTimeModule());
        objectMapper.disable(com.fasterxml.jackson.databind.SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);
        objectMapper.addMixIn(org.springframework.data.domain.PageImpl.class, PageMixin.class);

        var converter = new org.springframework.http.converter.json.MappingJackson2HttpMessageConverter(objectMapper);

        mockMvc = MockMvcBuilders.standaloneSetup(controller)
                .setMessageConverters(converter)
                .setCustomArgumentResolvers(new PageableHandlerMethodArgumentResolver())
                .build();
    }

    private abstract static class PageMixin {
        @com.fasterxml.jackson.annotation.JsonIgnore
        abstract Object getPageable();
    }

    @Test
    void overview_returnsOk_withStatisticsPayload() throws Exception {
        VehicleStatisticsDto stats = new VehicleStatisticsDto();
        when(vehicleService.getFleetStatistics()).thenReturn(stats);

        mockMvc.perform(get("/api/fleet/overview"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));
    }

    @Test
    void listVehicles_returnsOk_withEmptyPage() throws Exception {
        when(vehicleService.advancedSearch(any(), any(), any(), any(), any(), any(), any()))
                .thenReturn(Page.empty());

        mockMvc.perform(get("/api/fleet/vehicles"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));
    }

    @Test
    void vehiclesRequiringService_returnsOk_withEmptyList() throws Exception {
        when(vehicleService.getVehiclesRequiringService()).thenReturn(Collections.emptyList());

        mockMvc.perform(get("/api/fleet/vehicles/requiring-service"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));
    }

    @Test
    void getVehicle_whenExists_returnsOk() throws Exception {
        VehicleDto dto = new VehicleDto();
        when(vehicleService.getVehicleDtoById(1L)).thenReturn(Optional.of(dto));

        mockMvc.perform(get("/api/fleet/vehicles/1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));
    }

    @Test
    void getVehicle_whenNotFound_returns404() throws Exception {
        when(vehicleService.getVehicleDtoById(99L)).thenReturn(Optional.empty());

        mockMvc.perform(get("/api/fleet/vehicles/99"))
                .andExpect(status().isNotFound());
    }
}
