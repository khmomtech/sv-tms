package com.svtrucking.logistics.controller;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.dto.IncidentDto;
import com.svtrucking.logistics.dto.IncidentStatisticsDto;
import com.svtrucking.logistics.enums.*;
import com.svtrucking.logistics.security.AuthenticatedUserUtil;
import com.svtrucking.logistics.service.IncidentService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.util.UriComponentsBuilder;

import java.net.URI;
import java.time.LocalDateTime;
import java.util.List;

@RestController
@RequestMapping("/api/incidents")
@RequiredArgsConstructor
@Validated
@CrossOrigin(origins = "*")
@Slf4j
public class IncidentController {

  private final IncidentService incidentService;
  private final AuthenticatedUserUtil authUtil;

  /**
   * Create a new incident
   */
  @PostMapping(produces = MediaType.APPLICATION_JSON_VALUE)
  @PreAuthorize("@authorizationService.hasPermission('incident:create')")
  public ResponseEntity<ApiResponse<IncidentDto>> createIncident(
      @Valid @RequestBody IncidentDto incidentDto,
      UriComponentsBuilder uriBuilder) {
    
    Long currentUserId = authUtil.getCurrentUserId();
    IncidentDto created = incidentService.createIncident(incidentDto, currentUserId);
    
    URI location = uriBuilder.path("/api/incidents/{id}")
        .buildAndExpand(created.getId())
        .toUri();
    
    return ResponseEntity.created(location)
        .body(new ApiResponse<>(true, "Incident created successfully", created));
  }

  /**
   * Get incident by ID
   */
  @GetMapping(value = "/{id}", produces = MediaType.APPLICATION_JSON_VALUE)
  @PreAuthorize("@authorizationService.hasPermission('incident:view')")
  public ResponseEntity<ApiResponse<IncidentDto>> getIncidentById(@PathVariable Long id) {
    IncidentDto incident = incidentService.getIncidentById(id);
    return ResponseEntity.ok(new ApiResponse<>(true, "Incident retrieved", incident));
  }

  /**
   * Get incident by code
   */
  @GetMapping(value = "/code/{code}", produces = MediaType.APPLICATION_JSON_VALUE)
  @PreAuthorize("@authorizationService.hasPermission('incident:view')")
  public ResponseEntity<ApiResponse<IncidentDto>> getIncidentByCode(@PathVariable String code) {
    IncidentDto incident = incidentService.getIncidentByCode(code);
    return ResponseEntity.ok(new ApiResponse<>(true, "Incident retrieved", incident));
  }

  /**
   * List incidents with filtering and pagination
   */
  @GetMapping(produces = MediaType.APPLICATION_JSON_VALUE)
  @PreAuthorize("@authorizationService.hasPermission('incident:list')")
  public ResponseEntity<ApiResponse<Page<IncidentDto>>> listIncidents(
      @RequestParam(required = false) IncidentStatus status,
      @RequestParam(required = false) IncidentGroup group,
      @RequestParam(required = false) IssueSeverity severity,
      @RequestParam(required = false) Long driverId,
      @RequestParam(required = false) Long vehicleId,
      @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) 
          LocalDateTime reportedAfter,
      @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) 
          LocalDateTime reportedBefore,
      @PageableDefault(size = 20, sort = "reportedAt", direction = Sort.Direction.DESC) Pageable pageable) {
    
    Page<IncidentDto> incidents = incidentService.listIncidents(
        status, group, severity, driverId, vehicleId, 
        reportedAfter, reportedBefore, pageable);
    
    return ResponseEntity.ok(new ApiResponse<>(true, "Incidents retrieved", incidents));
  }

  /**
   * Update incident
   */
  @PutMapping(value = "/{id}", produces = MediaType.APPLICATION_JSON_VALUE)
  @PreAuthorize("@authorizationService.hasPermission('incident:update')")
  public ResponseEntity<ApiResponse<IncidentDto>> updateIncident(
      @PathVariable Long id,
      @Valid @RequestBody IncidentDto incidentDto) {
    
    IncidentDto updated = incidentService.updateIncident(id, incidentDto);
    return ResponseEntity.ok(new ApiResponse<>(true, "Incident updated", updated));
  }

  /**
   * Validate incident
   */
  @PostMapping(value = "/{id}/validate", produces = MediaType.APPLICATION_JSON_VALUE)
  @PreAuthorize("@authorizationService.hasPermission('incident:validate')")
  public ResponseEntity<ApiResponse<IncidentDto>> validateIncident(@PathVariable Long id) {
    IncidentDto validated = incidentService.validateIncident(id);
    return ResponseEntity.ok(new ApiResponse<>(true, "Incident validated", validated));
  }

  /**
   * Close incident
   */
  @PostMapping(value = "/{id}/close", produces = MediaType.APPLICATION_JSON_VALUE)
  @PreAuthorize("@authorizationService.hasPermission('incident:manage')")
  public ResponseEntity<ApiResponse<IncidentDto>> closeIncident(
      @PathVariable Long id,
      @RequestBody(required = false) String resolutionNotes) {
    
    IncidentDto closed = incidentService.closeIncident(id, resolutionNotes);
    return ResponseEntity.ok(new ApiResponse<>(true, "Incident closed", closed));
  }

  /**
   * Delete incident
   */
  @DeleteMapping("/{id}")
  @PreAuthorize("@authorizationService.hasPermission('incident:delete')")
  public ResponseEntity<ApiResponse<Void>> deleteIncident(@PathVariable Long id) {
    incidentService.deleteIncident(id);
    return ResponseEntity.ok(new ApiResponse<>(true, "Incident deleted", null));
  }

  /**
   * Get incident statistics
   */
  @GetMapping(value = "/statistics", produces = MediaType.APPLICATION_JSON_VALUE)
  @PreAuthorize("@authorizationService.hasPermission('incident:view')")
  public ResponseEntity<ApiResponse<IncidentStatisticsDto>> getStatistics(
      @RequestParam(required = false) IncidentStatus status,
      @RequestParam(required = false) IncidentGroup group,
      @RequestParam(required = false) IssueSeverity severity,
      @RequestParam(required = false) Long driverId,
      @RequestParam(required = false) Long vehicleId,
      @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) 
          LocalDateTime reportedAfter,
      @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) 
          LocalDateTime reportedBefore) {
    
    IncidentStatisticsDto stats = incidentService.calculateStatistics(
        status, group, severity, driverId, vehicleId, 
        reportedAfter, reportedBefore);
    
    return ResponseEntity.ok(new ApiResponse<>(true, "Statistics calculated", stats));
  }

  /**
   * Upload photos to incident
   */
  @PostMapping(value = "/{id}/upload-photos", 
      consumes = MediaType.MULTIPART_FORM_DATA_VALUE,
      produces = MediaType.APPLICATION_JSON_VALUE)
  @PreAuthorize("@authorizationService.hasPermission('incident:update')")
  public ResponseEntity<ApiResponse<IncidentDto>> uploadPhotos(
      @PathVariable Long id,
      @RequestPart("files") List<MultipartFile> files) {
    
    IncidentDto updated = incidentService.uploadPhotos(id, files);
    return ResponseEntity.ok(new ApiResponse<>(true, "Photos uploaded successfully", updated));
  }
}
