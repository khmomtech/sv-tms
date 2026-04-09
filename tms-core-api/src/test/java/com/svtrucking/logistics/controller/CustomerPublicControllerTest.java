package com.svtrucking.logistics.controller;

import com.svtrucking.logistics.service.CustomerAddressService;
import com.svtrucking.logistics.service.CustomerService;
import com.svtrucking.logistics.service.IncidentService;
import com.svtrucking.logistics.service.TransportOrderService;
import com.svtrucking.logistics.security.AuthenticatedUserUtil;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.web.PageableHandlerMethodArgumentResolver;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.util.Collections;
import java.util.Optional;

import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.any;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.mockito.Mockito.when;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.svtrucking.logistics.core.ApiResponse;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

public class CustomerPublicControllerTest {

    private MockMvc mockMvc;

    private TransportOrderService transportOrderService;
    private CustomerAddressService customerAddressService;
    private AuthenticatedUserUtil authenticatedUserUtil;
    private CustomerService customerService;
    private IncidentService incidentService;

    @BeforeEach
    void setUp() {
        transportOrderService = org.mockito.Mockito.mock(TransportOrderService.class);
        customerAddressService = org.mockito.Mockito.mock(CustomerAddressService.class);
        authenticatedUserUtil = org.mockito.Mockito.mock(AuthenticatedUserUtil.class);
        customerService = org.mockito.Mockito.mock(CustomerService.class);
        incidentService = org.mockito.Mockito.mock(IncidentService.class);

        CustomerPublicController controller = new CustomerPublicController(
                transportOrderService, customerAddressService, customerService,
                authenticatedUserUtil, incidentService);

        mockMvc = MockMvcBuilders.standaloneSetup(controller)
                .setCustomArgumentResolvers(new PageableHandlerMethodArgumentResolver())
                .build();
    }

    // ── Orders ────────────────────────────────────────────────────────────────

    @Test
    void listOrders_whenOwner_returnsOk() throws Exception {
        when(authenticatedUserUtil.getCurrentCustomerId()).thenReturn(Optional.of(123L));
        when(transportOrderService.findByCustomerId(123L)).thenReturn(Collections.emptyList());

        Authentication auth = new UsernamePasswordAuthenticationToken("user", "n/a",
                java.util.List.of(new SimpleGrantedAuthority("ROLE_USER")));
        org.springframework.security.core.context.SecurityContextHolder.getContext().setAuthentication(auth);

        mockMvc.perform(get("/api/customer/123/orders")).andExpect(status().isOk());
    }

    @Test
    void listOrders_whenDifferentCustomer_returnsForbidden() throws Exception {
        when(authenticatedUserUtil.getCurrentCustomerId()).thenReturn(Optional.of(456L));

        Authentication auth = new UsernamePasswordAuthenticationToken("user", "n/a",
                java.util.List.of(new SimpleGrantedAuthority("ROLE_USER")));
        org.springframework.security.core.context.SecurityContextHolder.getContext().setAuthentication(auth);

        mockMvc.perform(get("/api/customer/123/orders")).andExpect(status().isForbidden());
    }

    @Test
    void listOrders_whenUnauthenticated_returnsForbidden() throws Exception {
        org.springframework.security.core.context.SecurityContextHolder.clearContext();
        mockMvc.perform(get("/api/customer/123/orders")).andExpect(status().isForbidden());
    }

    // ── Incidents ─────────────────────────────────────────────────────────────

    @Test
    void getIncidents_whenOwner_returnsOk() throws Exception {
        when(authenticatedUserUtil.getCurrentCustomerId()).thenReturn(Optional.of(123L));
        when(incidentService.getIncidentsByCustomerId(anyLong(), any())).thenReturn(new PageImpl<>(Collections.emptyList(), PageRequest.of(0, 50), 0));

        Authentication auth = new UsernamePasswordAuthenticationToken("user", "n/a",
                java.util.List.of(new SimpleGrantedAuthority("ROLE_USER")));
        org.springframework.security.core.context.SecurityContextHolder.getContext().setAuthentication(auth);

        mockMvc.perform(get("/api/customer/123/incidents"))
                .andExpect(status().isOk());
    }

    @Test
    void getIncidents_whenDifferentCustomer_returnsForbidden() throws Exception {
        when(authenticatedUserUtil.getCurrentCustomerId()).thenReturn(Optional.of(456L));

        Authentication auth = new UsernamePasswordAuthenticationToken("user", "n/a",
                java.util.List.of(new SimpleGrantedAuthority("ROLE_USER")));
        org.springframework.security.core.context.SecurityContextHolder.getContext().setAuthentication(auth);

        mockMvc.perform(get("/api/customer/123/incidents"))
                .andExpect(status().isForbidden());
    }

    @Test
    void getIncidents_whenUnauthenticated_returnsForbidden() throws Exception {
        org.springframework.security.core.context.SecurityContextHolder.clearContext();
        mockMvc.perform(get("/api/customer/123/incidents"))
                .andExpect(status().isForbidden());
    }

  @Test
  void jackson_canSerializeApiResponseWithPage() throws Exception {
    ObjectMapper mapper = new ObjectMapper();
    // Ensure Jackson can serialize Spring Data Page when using a fresh ObjectMapper.
    // PageImpl contains a pageable field (Unpaged) which may throw UnsupportedOperationException
    // if not ignored/handled.
    mapper.registerModule(new com.fasterxml.jackson.datatype.jsr310.JavaTimeModule());
    mapper.disable(com.fasterxml.jackson.databind.SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);
    mapper.addMixIn(org.springframework.data.domain.PageImpl.class, PageMixin.class);

    String json = mapper.writeValueAsString(
        new ApiResponse<>(true, "ok", new org.springframework.data.domain.PageImpl<>(Collections.emptyList())));
    assertNotNull(json);
  }

  private abstract static class PageMixin {
    @com.fasterxml.jackson.annotation.JsonIgnore
    abstract Object getPageable();
  }
}
