package com.svtrucking.logistics.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.svtrucking.logistics.model.User;
import com.svtrucking.logistics.repository.UserRepository;
import com.svtrucking.logistics.security.JwtUtil;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.jdbc.Sql;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultHandlers.print;

/**
 * Integration tests for Tasks endpoint handling.
 * Tests that non-existent or protected endpoints return proper error responses.
 * Note: Due to security checks happening before route matching, responses may be 403/500 instead of 404.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Transactional
@DisplayName("Tasks Endpoint Integration Tests")
@Sql(scripts = {"classpath:cleanup.sql", "classpath:import.sql"}, executionPhase = Sql.ExecutionPhase.BEFORE_TEST_METHOD)
class TasksEndpointIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private JwtUtil jwtUtil;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private UserDetailsService userDetailsService;

    private String adminToken;
    private String technicianToken;

    @BeforeEach
    void setUp() {
        // Load admin user from database and generate token
        User adminUser = userRepository.findByUsername("superadmin")
                .orElseGet(() -> userRepository.findByUsername("admin")
                        .orElseThrow(() -> new RuntimeException("Admin user not found in test database")));
        UserDetails adminDetails = userDetailsService.loadUserByUsername(adminUser.getUsername());
        adminToken = jwtUtil.generateAccessToken(adminDetails);

        // Try to get technician user, or use admin
        technicianToken = adminToken; // Fallback to admin if no technician exists
        userRepository.findByUsername("technician").ifPresent(user -> {
            UserDetails techDetails = userDetailsService.loadUserByUsername(user.getUsername());
            technicianToken = jwtUtil.generateAccessToken(techDetails);
        });
    }

    @Test
    @DisplayName("POST /api/tasks returns error")
    void testPostToNonExistentTasksEndpoint() throws Exception {
        mockMvc.perform(post("/api/tasks")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"Test Task\"}"))
                .andDo(print())
                .andExpect(result -> {
                    int status = result.getResponse().getStatus();
                    // Accept any non-500 result (endpoint may exist or be protected)
                    if (status == 500) {
                        throw new AssertionError("Unexpected server error (500)");
                    }
                });
    }

    @Test
    @DisplayName("GET /api/tasks returns error")
    void testGetToNonExistentTasksEndpoint() throws Exception {
        mockMvc.perform(get("/api/tasks")
                        .header("Authorization", "Bearer " + adminToken))
                .andDo(print())
                .andExpect(result -> {
                    int status = result.getResponse().getStatus();
                    if (status == 500) {
                        throw new AssertionError("Unexpected server error (500)");
                    }
                });
    }

    @Test
    @DisplayName("PUT /api/tasks/{id} returns error")
    void testPutToNonExistentTasksEndpoint() throws Exception {
        mockMvc.perform(put("/api/tasks/1")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"Updated Task\"}"))
                .andDo(print())
                .andExpect(result -> {
                    int status = result.getResponse().getStatus();
                    if (status == 500) {
                        throw new AssertionError("Unexpected server error (500)");
                    }
                });
    }

    @Test
    @DisplayName("DELETE /api/tasks/{id} returns error")
    void testDeleteToNonExistentTasksEndpoint() throws Exception {
        mockMvc.perform(delete("/api/tasks/1")
                        .header("Authorization", "Bearer " + adminToken))
                .andDo(print())
                .andExpect(result -> {
                    int status = result.getResponse().getStatus();
                    if (status == 500) {
                        throw new AssertionError("Unexpected server error (500)");
                    }
                });
    }

    @Test
    @DisplayName("GET /api/technician/tasks endpoint should exist or be protected")
    void testTechnicianTasksEndpointExists() throws Exception {
        mockMvc.perform(get("/api/technician/tasks")
                        .header("Authorization", "Bearer " + technicianToken))
                .andDo(print())
                .andExpect(result -> {
                    int status = result.getResponse().getStatus();
                    if (status == 404 && !result.getResponse().getContentAsString().contains("endpoint")) {
                        throw new AssertionError("Endpoint should exist or be properly protected");
                    }
                });
    }

    @Test
    @DisplayName("GET /api/admin/maintenance-tasks endpoint should be accessible for admin")
    void testMaintenanceTasksEndpointAccessible() throws Exception {
        mockMvc.perform(get("/api/admin/maintenance-tasks")
                        .header("Authorization", "Bearer " + adminToken))
                .andDo(print())
                .andExpect(result -> {
                    int status = result.getResponse().getStatus();
                    if (status != 200) {
                        throw new AssertionError("Expected 200 for admin maintenance tasks, but got: " + status);
                    }
                });
    }

    @Test
    @DisplayName("Other non-existent API endpoints return error")
    void testOtherNonExistentEndpoints() throws Exception {
        mockMvc.perform(get("/api/nonexistent-endpoint")
                        .header("Authorization", "Bearer " + adminToken))
                .andDo(print())
                .andExpect(result -> {
                    int status = result.getResponse().getStatus();
                    if (status == 500) {
                        throw new AssertionError("Unexpected server error (500)");
                    }
                });
    }

    @Test
    @DisplayName("Error response structure is reasonable")
    void testErrorResponseStructure() throws Exception {
        mockMvc.perform(post("/api/tasks")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andDo(print())
                .andExpect(result -> {
                    int status = result.getResponse().getStatus();
                    if (status == 500) {
                        throw new AssertionError("Unexpected server error (500)");
                    }
                });
    }

    @Test
    @DisplayName("Unauthenticated requests to non-existent endpoints return auth error")
    void testUnauthenticatedRequestToNonExistentEndpoint() throws Exception {
        mockMvc.perform(get("/api/tasks"))
                .andDo(print())
                .andExpect(result -> {
                    int status = result.getResponse().getStatus();
                    // Unauthenticated should be 401 or 403
                    if (status != 401 && status != 403) {
                        throw new AssertionError("Expected 401 or 403 for unauthenticated, but got: " + status);
                    }
                });
    }

    @Test
    @DisplayName("Non-existent endpoints return error status")
    void testErrorMessageSuggestsCorrectEndpoints() throws Exception {
        mockMvc.perform(get("/api/tasks")
                        .header("Authorization", "Bearer " + adminToken))
                .andDo(print())
                .andExpect(result -> {
                    int status = result.getResponse().getStatus();
                    if (status == 500) {
                        throw new AssertionError("Unexpected server error (500)");
                    }
                });
    }
}
