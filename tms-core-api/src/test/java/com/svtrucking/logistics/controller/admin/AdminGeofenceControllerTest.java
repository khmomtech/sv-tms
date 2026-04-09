package com.svtrucking.logistics.controller.admin;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.svtrucking.logistics.model.Geofence;
import com.svtrucking.logistics.model.Geofence.AlertType;
import com.svtrucking.logistics.model.Geofence.GeofenceType;
import com.svtrucking.logistics.repository.GeofenceRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.dao.DataAccessResourceFailureException;
import org.springframework.http.MediaType;
import com.svtrucking.logistics.exception.GlobalExceptionHandler;
import org.springframework.security.web.method.annotation.AuthenticationPrincipalArgumentResolver;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * Unit tests for {@link AdminGeofenceController} using standalone MockMvc.
 * Security annotations (@PreAuthorize) are bypassed so tests focus on
 * HTTP status codes, request validation, and response structure.
 */
@ExtendWith(MockitoExtension.class)
class AdminGeofenceControllerTest {

    private MockMvc mockMvc;

    @Mock
    private GeofenceRepository geofenceRepository;

    private final ObjectMapper objectMapper = new ObjectMapper();

    private static final long COMPANY_ID = 1L;
    private static final long GEOFENCE_ID = 42L;

    @BeforeEach
    void setUp() {
        AdminGeofenceController controller = new AdminGeofenceController(geofenceRepository, objectMapper);
        mockMvc = MockMvcBuilders.standaloneSetup(controller)
                .setControllerAdvice(new GlobalExceptionHandler())
                .setCustomArgumentResolvers(new AuthenticationPrincipalArgumentResolver())
                .build();
    }

    // ─── Helper builders ──────────────────────────────────────────────────────

    private Geofence buildCircleGeofence() {
        return Geofence.builder()
                .id(GEOFENCE_ID)
                .companyId(COMPANY_ID)
                .name("Warehouse A")
                .description("Main depot")
                .type(GeofenceType.CIRCLE)
                .centerLatitude(11.5564)
                .centerLongitude(104.9282)
                .radiusMeters(500.0)
                .alertType(AlertType.BOTH)
                .active(true)
                .createdBy("admin")
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();
    }

    private String circleCreateJson() throws Exception {
        return objectMapper.writeValueAsString(new java.util.LinkedHashMap<String, Object>() {
            {
                put("partnerCompanyId", COMPANY_ID);
                put("name", "Warehouse A");
                put("description", "Main depot");
                put("type", "CIRCLE");
                put("centerLatitude", 11.5564);
                put("centerLongitude", 104.9282);
                put("radiusMeters", 500);
                put("alertType", "BOTH");
                put("active", true);
            }
        });
    }

    // ─── GET list ────────────────────────────────────────────────────────────

    @Test
    void listGeofences_returnsOk_withEmptyList() throws Exception {
        when(geofenceRepository.findByCompanyIdAndActiveTrue(COMPANY_ID))
                .thenReturn(List.of());

        mockMvc.perform(get("/api/admin/geofences").param("companyId", String.valueOf(COMPANY_ID)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray())
                .andExpect(jsonPath("$.length()").value(0));
    }

    @Test
    void listGeofences_returnsOk_withOneGeofence() throws Exception {
        Geofence geofence = buildCircleGeofence();
        when(geofenceRepository.findByCompanyIdAndActiveTrue(COMPANY_ID))
                .thenReturn(List.of(geofence));

        mockMvc.perform(get("/api/admin/geofences").param("companyId", String.valueOf(COMPANY_ID)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].id").value(GEOFENCE_ID))
                .andExpect(jsonPath("$[0].name").value("Warehouse A"))
                .andExpect(jsonPath("$[0].type").value("CIRCLE"))
                .andExpect(jsonPath("$[0].centerLatitude").value(11.5564))
                .andExpect(jsonPath("$[0].centerLongitude").value(104.9282))
                .andExpect(jsonPath("$[0].radiusMeters").value(500.0))
                .andExpect(jsonPath("$[0].active").value(true));
    }

    @Test
    void listGeofences_missingCompanyId_returnsBadRequest() throws Exception {
        mockMvc.perform(get("/api/admin/geofences"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.status").value(400))
                .andExpect(jsonPath("$.error").value("Missing Request Parameter"));
    }

    @Test
    void listGeofences_repositoryThrows_returnsInternalServerErrorAndErrorResponse() throws Exception {
        when(geofenceRepository.findByCompanyIdAndActiveTrue(COMPANY_ID))
                .thenThrow(new DataAccessResourceFailureException("DB timeout"));

        mockMvc.perform(get("/api/admin/geofences").param("companyId", String.valueOf(COMPANY_ID)))
                .andExpect(status().isServiceUnavailable())
                .andExpect(jsonPath("$.status").value(503))
                .andExpect(jsonPath("$.error").value("Service Unavailable"))
                .andExpect(jsonPath("$.message").value("Database is currently unavailable. Please try again later."));
    }

    // ─── GET single ─────────────────────────────────────────────────────────

    @Test
    void getGeofence_whenExists_returnsOk() throws Exception {
        Geofence geofence = buildCircleGeofence();
        when(geofenceRepository.findById(GEOFENCE_ID)).thenReturn(Optional.of(geofence));

        mockMvc.perform(get("/api/admin/geofences/{id}", GEOFENCE_ID))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(GEOFENCE_ID))
                .andExpect(jsonPath("$.name").value("Warehouse A"))
                .andExpect(jsonPath("$.companyId").value(COMPANY_ID));
    }

    @Test
    void getGeofence_whenNotFound_returns404() throws Exception {
        when(geofenceRepository.findById(999L)).thenReturn(Optional.empty());

        mockMvc.perform(get("/api/admin/geofences/{id}", 999L))
                .andExpect(status().isNotFound());
    }

    // ─── POST create ─────────────────────────────────────────────────────────

    @Test
    void createGeofence_circle_returnsOk_withSavedEntity() throws Exception {
        Geofence saved = buildCircleGeofence();
        when(geofenceRepository.save(any(Geofence.class))).thenReturn(saved);

        mockMvc.perform(post("/api/admin/geofences")
                .contentType(MediaType.APPLICATION_JSON)
                .content(circleCreateJson()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(GEOFENCE_ID))
                .andExpect(jsonPath("$.name").value("Warehouse A"))
                .andExpect(jsonPath("$.type").value("CIRCLE"))
                .andExpect(jsonPath("$.companyId").value(COMPANY_ID))
                .andExpect(jsonPath("$.active").value(true))
                .andExpect(jsonPath("$.alertType").value("BOTH"));

        verify(geofenceRepository, times(1)).save(any(Geofence.class));
    }

    @Test
    void createGeofence_polygon_returnsOk() throws Exception {
        String coordinates = "[[104.9, 11.5],[104.95, 11.5],[104.95, 11.55],[104.9, 11.5]]";
        Geofence saved = Geofence.builder()
                .id(43L)
                .companyId(COMPANY_ID)
                .name("Restricted Zone")
                .type(GeofenceType.POLYGON)
                .geoJsonCoordinates(coordinates)
                .alertType(AlertType.ENTER)
                .active(true)
                .createdBy("system")
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();
        when(geofenceRepository.save(any())).thenReturn(saved);

        String body = objectMapper.writeValueAsString(new java.util.LinkedHashMap<String, Object>() {
            {
                put("partnerCompanyId", COMPANY_ID);
                put("name", "Restricted Zone");
                put("type", "POLYGON");
                put("geoJsonCoordinates", coordinates);
                put("alertType", "ENTER");
            }
        });

        mockMvc.perform(post("/api/admin/geofences")
                .contentType(MediaType.APPLICATION_JSON)
                .content(body))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(43))
                .andExpect(jsonPath("$.type").value("POLYGON"))
                .andExpect(jsonPath("$.alertType").value("ENTER"));
    }

    @Test
    void createGeofence_missingRequiredName_returns400() throws Exception {
        String body = objectMapper.writeValueAsString(new java.util.LinkedHashMap<String, Object>() {
            {
                put("partnerCompanyId", COMPANY_ID);
                // name omitted — @NotBlank violation
                put("type", "CIRCLE");
            }
        });

        mockMvc.perform(post("/api/admin/geofences")
                .contentType(MediaType.APPLICATION_JSON)
                .content(body))
                .andExpect(status().isBadRequest());

        verify(geofenceRepository, never()).save(any());
    }

    @Test
    void createGeofence_missingPartnerCompanyId_returns400() throws Exception {
        String body = objectMapper.writeValueAsString(new java.util.LinkedHashMap<String, Object>() {
            {
                put("name", "New Zone");
                put("type", "CIRCLE");
                // partnerCompanyId omitted — @NotNull violation
            }
        });

        mockMvc.perform(post("/api/admin/geofences")
                .contentType(MediaType.APPLICATION_JSON)
                .content(body))
                .andExpect(status().isBadRequest());

        verify(geofenceRepository, never()).save(any());
    }

    @Test
    void createGeofence_defaultsActiveToTrue_whenNotProvided() throws Exception {
        // Capture what gets saved
        Geofence saved = buildCircleGeofence();
        when(geofenceRepository.save(any(Geofence.class))).thenReturn(saved);

        String body = objectMapper.writeValueAsString(new java.util.LinkedHashMap<String, Object>() {
            {
                put("partnerCompanyId", COMPANY_ID);
                put("name", "Auto Active Zone");
                put("type", "CIRCLE");
                put("centerLatitude", 11.5564);
                put("centerLongitude", 104.9282);
                put("radiusMeters", 500);
            }
        });

        mockMvc.perform(post("/api/admin/geofences")
                .contentType(MediaType.APPLICATION_JSON)
                .content(body))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.active").value(true));
    }

    // ─── PUT update ──────────────────────────────────────────────────────────

    @Test
    void updateGeofence_whenExists_returnsOkWithUpdatedFields() throws Exception {
        Geofence existing = buildCircleGeofence();
        Geofence updated = Geofence.builder()
                .id(GEOFENCE_ID)
                .companyId(COMPANY_ID)
                .name("Warehouse A — Updated")
                .type(GeofenceType.CIRCLE)
                .centerLatitude(11.5600)
                .centerLongitude(104.9300)
                .radiusMeters(750.0)
                .alertType(AlertType.EXIT)
                .active(true)
                .createdBy("admin")
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();

        when(geofenceRepository.findById(GEOFENCE_ID)).thenReturn(Optional.of(existing));
        when(geofenceRepository.save(any(Geofence.class))).thenReturn(updated);

        String body = objectMapper.writeValueAsString(new java.util.LinkedHashMap<String, Object>() {
            {
                put("partnerCompanyId", COMPANY_ID);
                put("name", "Warehouse A — Updated");
                put("type", "CIRCLE");
                put("centerLatitude", 11.5600);
                put("centerLongitude", 104.9300);
                put("radiusMeters", 750);
                put("alertType", "EXIT");
                put("active", true);
            }
        });

        mockMvc.perform(put("/api/admin/geofences/{id}", GEOFENCE_ID)
                .contentType(MediaType.APPLICATION_JSON)
                .content(body))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(GEOFENCE_ID))
                .andExpect(jsonPath("$.name").value("Warehouse A — Updated"))
                .andExpect(jsonPath("$.radiusMeters").value(750.0))
                .andExpect(jsonPath("$.alertType").value("EXIT"));

        verify(geofenceRepository, times(1)).findById(GEOFENCE_ID);
        verify(geofenceRepository, times(1)).save(any(Geofence.class));
    }

    @Test
    void updateGeofence_whenNotFound_returns404() throws Exception {
        when(geofenceRepository.findById(999L)).thenReturn(Optional.empty());

        mockMvc.perform(put("/api/admin/geofences/{id}", 999L)
                .contentType(MediaType.APPLICATION_JSON)
                .content(circleCreateJson()))
                .andExpect(status().isNotFound());

        verify(geofenceRepository, never()).save(any());
    }

    @Test
    void updateGeofence_withTags_serializesAndReturnsCorrectly() throws Exception {
        Geofence existing = buildCircleGeofence();
        Geofence withTags = Geofence.builder()
                .id(GEOFENCE_ID)
                .companyId(COMPANY_ID)
                .name("Tagged Zone")
                .type(GeofenceType.CIRCLE)
                .centerLatitude(11.5564)
                .centerLongitude(104.9282)
                .radiusMeters(500.0)
                .alertType(AlertType.NONE)
                .active(true)
                .tags("[\"warehouse\",\"restricted\"]")
                .createdBy("admin")
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();

        when(geofenceRepository.findById(GEOFENCE_ID)).thenReturn(Optional.of(existing));
        when(geofenceRepository.save(any())).thenReturn(withTags);

        String body = objectMapper.writeValueAsString(new java.util.LinkedHashMap<String, Object>() {
            {
                put("partnerCompanyId", COMPANY_ID);
                put("name", "Tagged Zone");
                put("type", "CIRCLE");
                put("centerLatitude", 11.5564);
                put("centerLongitude", 104.9282);
                put("radiusMeters", 500);
                put("tags", List.of("warehouse", "restricted"));
            }
        });

        mockMvc.perform(put("/api/admin/geofences/{id}", GEOFENCE_ID)
                .contentType(MediaType.APPLICATION_JSON)
                .content(body))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.tags").isArray())
                .andExpect(jsonPath("$.tags[0]").value("warehouse"))
                .andExpect(jsonPath("$.tags[1]").value("restricted"));
    }

    // ─── DELETE ──────────────────────────────────────────────────────────────

    @Test
    void deleteGeofence_whenExists_softDeletesAndReturns200() throws Exception {
        Geofence existing = buildCircleGeofence();
        when(geofenceRepository.findById(GEOFENCE_ID)).thenReturn(Optional.of(existing));
        when(geofenceRepository.save(any(Geofence.class))).thenReturn(existing);

        mockMvc.perform(delete("/api/admin/geofences/{id}", GEOFENCE_ID))
                .andExpect(status().isOk());

        verify(geofenceRepository, times(1)).save(argThat(g -> !g.getActive()));
    }

    @Test
    void deleteGeofence_whenNotFound_returns404() throws Exception {
        when(geofenceRepository.findById(999L)).thenReturn(Optional.empty());

        mockMvc.perform(delete("/api/admin/geofences/{id}", 999L))
                .andExpect(status().isNotFound());

        verify(geofenceRepository, never()).save(any());
    }
}
