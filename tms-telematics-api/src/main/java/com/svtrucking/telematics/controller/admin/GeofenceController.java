package com.svtrucking.telematics.controller.admin;

import com.svtrucking.telematics.dto.GeofenceDto;
import com.svtrucking.telematics.dto.requests.GeofenceRequest;
import com.svtrucking.telematics.service.GeofenceService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.security.Principal;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/**
 * Geofence CRUD — admin panel.
 * All endpoints require ROLE_API_USER (valid access-token JWT).
 */
@RestController
@RequestMapping("/api/admin/geofences")
@RequiredArgsConstructor
@Tag(name = "Geofences", description = "Geofence configuration endpoints")
public class GeofenceController {

    private final GeofenceService geofenceService;

    @GetMapping
    @Operation(summary = "List geofences for a company")
    public ResponseEntity<List<GeofenceDto>> list(
            @RequestParam Long companyId) {
        return ResponseEntity.ok(geofenceService.findByCompany(companyId));
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get a single geofence")
    public ResponseEntity<GeofenceDto> getById(@PathVariable Long id) {
        return ResponseEntity.ok(geofenceService.findById(id));
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Create a geofence")
    public ResponseEntity<GeofenceDto> create(
            @Valid @RequestBody GeofenceRequest request,
            Principal principal) {
        String actor = principal != null ? principal.getName() : "system";
        GeofenceDto created = geofenceService.create(request, actor);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }

    @PutMapping("/{id}")
    @Operation(summary = "Update a geofence")
    public ResponseEntity<GeofenceDto> update(
            @PathVariable Long id,
            @Valid @RequestBody GeofenceRequest request) {
        return ResponseEntity.ok(geofenceService.update(id, request));
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(summary = "Delete a geofence")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        geofenceService.delete(id);
        return ResponseEntity.noContent().build();
    }
}
