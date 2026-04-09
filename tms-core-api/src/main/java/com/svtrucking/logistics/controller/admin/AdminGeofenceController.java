package com.svtrucking.logistics.controller.admin;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.svtrucking.logistics.model.Geofence;
import com.svtrucking.logistics.model.Geofence.AlertType;
import com.svtrucking.logistics.model.Geofence.GeofenceType;
import com.svtrucking.logistics.repository.GeofenceRepository;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Optional;

/**
 * CRUD endpoints for geofence management.
 * Used by the live-map UI on the frontend to load, create, update, and delete
 * geographic zones (circles, polygons, route corridors).
 */
@RestController
@RequestMapping("/api/admin/geofences")
@RequiredArgsConstructor
@Slf4j
public class AdminGeofenceController {

    private final GeofenceRepository geofenceRepository;
    private final ObjectMapper objectMapper;

    // ─── Request / Response DTOs ──────────────────────────────────────────────

    public record GeofenceDto(
            Long id,
            Long companyId,
            String name,
            String description,
            String type,
            Double centerLatitude,
            Double centerLongitude,
            Double radiusMeters,
            String geoJsonCoordinates,
            String alertType,
            Integer speedLimitKmh,
            Boolean active,
            List<String> tags,
            String createdBy,
            String createdAt,
            String updatedAt) {
    }

    public record GeofenceCreateRequest(
            @NotNull Long partnerCompanyId,
            @NotBlank String name,
            String description,
            @NotNull String type,
            Double centerLatitude,
            Double centerLongitude,
            Double radiusMeters,
            String geoJsonCoordinates,
            String alertType,
            Integer speedLimitKmh,
            Boolean active,
            List<String> tags) {
    }

    // ─── Endpoints ────────────────────────────────────────────────────────────

    /**
     * GET /api/admin/geofences?companyId={id}
     * Returns all active geofences for the given company.
     * Frontend live-map calls this on startup to render zones on the map.
     */
    @GetMapping
    @PreAuthorize("hasAnyAuthority('ROLE_ADMIN','ROLE_SUPERADMIN','ROLE_MANAGER','all_functions')")
    public ResponseEntity<List<GeofenceDto>> listGeofences(
            @RequestParam Long companyId) {
        List<Geofence> geofences = Optional.ofNullable(geofenceRepository.findByCompanyIdAndActiveTrue(companyId))
                .orElse(List.of());
        List<GeofenceDto> dtos = geofences.stream().map(this::toDto).toList();
        return ResponseEntity.ok(dtos);
    }

    /**
     * GET /api/admin/geofences/{id}
     */
    @GetMapping("/{id}")
    @PreAuthorize("hasAnyAuthority('ROLE_ADMIN','ROLE_SUPERADMIN','ROLE_MANAGER','all_functions')")
    public ResponseEntity<GeofenceDto> getGeofence(@PathVariable Long id) {
        return geofenceRepository.findById(id)
                .map(g -> ResponseEntity.ok(toDto(g)))
                .orElse(ResponseEntity.notFound().build());
    }

    /**
     * POST /api/admin/geofences
     */
    @PostMapping
    @PreAuthorize("hasAnyAuthority('ROLE_ADMIN','ROLE_SUPERADMIN','all_functions')")
    public ResponseEntity<GeofenceDto> createGeofence(
            @Valid @RequestBody GeofenceCreateRequest req,
            @AuthenticationPrincipal UserDetails principal) {

        Geofence geofence = Geofence.builder()
                .companyId(req.partnerCompanyId())
                .name(req.name())
                .description(req.description())
                .type(parseType(req.type()))
                .centerLatitude(req.centerLatitude())
                .centerLongitude(req.centerLongitude())
                .radiusMeters(req.radiusMeters())
                .geoJsonCoordinates(req.geoJsonCoordinates())
                .alertType(parseAlertType(req.alertType()))
                .speedLimitKmh(req.speedLimitKmh())
                .active(req.active() != null ? req.active() : true)
                .tags(serializeTags(req.tags()))
                .createdBy(principal != null ? principal.getUsername() : "system")
                .build();

        Geofence saved = geofenceRepository.save(geofence);
        log.info("Geofence created: id={} name={} company={}", saved.getId(), saved.getName(), saved.getCompanyId());
        return ResponseEntity.ok(toDto(saved));
    }

    /**
     * PUT /api/admin/geofences/{id}
     */
    @PutMapping("/{id}")
    @PreAuthorize("hasAnyAuthority('ROLE_ADMIN','ROLE_SUPERADMIN','all_functions')")
    public ResponseEntity<GeofenceDto> updateGeofence(
            @PathVariable Long id,
            @Valid @RequestBody GeofenceCreateRequest req) {

        return geofenceRepository.findById(id).map(geofence -> {
            geofence.setName(req.name());
            geofence.setDescription(req.description());
            geofence.setType(parseType(req.type()));
            geofence.setCenterLatitude(req.centerLatitude());
            geofence.setCenterLongitude(req.centerLongitude());
            geofence.setRadiusMeters(req.radiusMeters());
            geofence.setGeoJsonCoordinates(req.geoJsonCoordinates());
            geofence.setAlertType(parseAlertType(req.alertType()));
            geofence.setSpeedLimitKmh(req.speedLimitKmh());
            if (req.active() != null)
                geofence.setActive(req.active());
            geofence.setTags(serializeTags(req.tags()));
            Geofence saved = geofenceRepository.save(geofence);
            log.info("Geofence updated: id={} name={}", saved.getId(), saved.getName());
            return ResponseEntity.ok(toDto(saved));
        }).orElse(ResponseEntity.notFound().build());
    }

    /**
     * DELETE /api/admin/geofences/{id}
     * Soft-delete by setting active = false.
     */
    @DeleteMapping("/{id}")
    @PreAuthorize("hasAnyAuthority('ROLE_ADMIN','ROLE_SUPERADMIN','all_functions')")
    public ResponseEntity<Void> deleteGeofence(@PathVariable Long id) {
        return geofenceRepository.findById(id).map(geofence -> {
            geofence.setActive(false);
            geofenceRepository.save(geofence);
            log.info("Geofence soft-deleted: id={}", id);
            return ResponseEntity.ok().<Void>build();
        }).orElse(ResponseEntity.notFound().build());
    }

    // ─── Helpers ──────────────────────────────────────────────────────────────

    private GeofenceDto toDto(Geofence g) {
        return new GeofenceDto(
                g != null ? g.getId() : null,
                g != null ? g.getCompanyId() : null,
                g != null ? g.getName() : null,
                g != null ? g.getDescription() : null,
                g != null && g.getType() != null ? g.getType().name() : Geofence.GeofenceType.POLYGON.name(),
                g != null ? g.getCenterLatitude() : null,
                g != null ? g.getCenterLongitude() : null,
                g != null ? g.getRadiusMeters() : null,
                g != null ? g.getGeoJsonCoordinates() : null,
                g != null && g.getAlertType() != null ? g.getAlertType().name() : Geofence.AlertType.NONE.name(),
                g != null ? g.getSpeedLimitKmh() : null,
                g != null ? g.getActive() : false,
                g != null ? deserializeTags(g.getTags()) : List.of(),
                g != null ? g.getCreatedBy() : null,
                g != null && g.getCreatedAt() != null ? g.getCreatedAt().toString() : null,
                g != null && g.getUpdatedAt() != null ? g.getUpdatedAt().toString() : null);
    }

    private GeofenceType parseType(String type) {
        try {
            return GeofenceType.valueOf(type.toUpperCase());
        } catch (Exception e) {
            return GeofenceType.POLYGON;
        }
    }

    private AlertType parseAlertType(String alertType) {
        if (alertType == null)
            return AlertType.NONE;
        try {
            return AlertType.valueOf(alertType.toUpperCase());
        } catch (Exception e) {
            return AlertType.NONE;
        }
    }

    private String serializeTags(List<String> tags) {
        if (tags == null || tags.isEmpty())
            return null;
        try {
            return objectMapper.writeValueAsString(tags);
        } catch (Exception e) {
            return null;
        }
    }

    private List<String> deserializeTags(String tags) {
        if (tags == null || tags.isBlank())
            return List.of();
        try {
            return objectMapper.readValue(tags, new TypeReference<List<String>>() {
            });
        } catch (Exception e) {
            return List.of();
        }
    }
}
