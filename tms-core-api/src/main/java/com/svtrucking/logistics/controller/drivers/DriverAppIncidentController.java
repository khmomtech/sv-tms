package com.svtrucking.logistics.controller.drivers;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.dto.DriverIssuePhotoDto;
import com.svtrucking.logistics.dto.IncidentDto;
import com.svtrucking.logistics.enums.IncidentGroup;
import com.svtrucking.logistics.enums.IncidentSource;
import com.svtrucking.logistics.enums.IncidentStatus;
import com.svtrucking.logistics.enums.IncidentType;
import com.svtrucking.logistics.enums.IssueSeverity;
import com.svtrucking.logistics.security.AuthenticatedUserUtil;
import com.svtrucking.logistics.service.IncidentService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.net.URI;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.NoSuchElementException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.util.UriComponentsBuilder;

/**
 * Driver-facing controller to let the driver_app create and view incidents using the new incident
 * domain model. It mirrors the driver issue flow (multipart payload + optional photos) but writes
 * to the IncidentService so the data appears in the incident/case workflows.
 */
@RestController
@RequestMapping("/api/driver-app/incidents")
@RequiredArgsConstructor
@Validated
@CrossOrigin(origins = "*")
@Slf4j
public class DriverAppIncidentController {

  private final IncidentService incidentService;
  private final AuthenticatedUserUtil authUtil;

  /**
   * Payload expected from driver_app (sent as JSON part named "payload" in multipart requests).
   * Fields for group/type/severity are optional; sensible defaults are derived to keep the app
   * backward compatible.
   */
  public record DriverIncidentCreateRequest(
      @NotBlank @Size(max = 200) String title,
      @NotBlank @Size(max = 5000) String description,
      IncidentGroup incidentGroup,
      IncidentType incidentType,
      IssueSeverity severity,
      Double latitude,
      Double longitude,
      String location,
      Long vehicleId,
      Long dispatchId) {}

  public record UpdateStatusRequest(@NotBlank String status) {}
  public record UpdateIncidentRequest(
      @NotBlank @Size(max = 200) String title, @NotBlank @Size(max = 5000) String description) {}

  /**
   * Response tailored for the driver_app model (keeps "images" + "createdAt" keys the app already
   * consumes).
   */
  public record DriverIncidentResponse(
      Long id,
      String code,
      String title,
      String description,
      String status,
      IssueSeverity severity,
      LocalDateTime createdAt,
      List<String> images) {

    public static DriverIncidentResponse fromIncident(IncidentDto dto) {
      if (dto == null) return null;

      List<String> photoUrls = new ArrayList<>();
      if (dto.getPhotoUrls() != null) {
        photoUrls.addAll(dto.getPhotoUrls());
      }
      if (dto.getPhotos() != null) {
        for (DriverIssuePhotoDto p : dto.getPhotos()) {
          if (p != null && p.getPhotoUrl() != null) {
            photoUrls.add(p.getPhotoUrl());
          }
        }
      }

      IssueSeverity sev = dto.getSeverity() != null ? dto.getSeverity() : IssueSeverity.MEDIUM;
      String status =
          dto.getIncidentStatus() != null
              ? dto.getIncidentStatus().name()
              : IncidentStatus.NEW.name();
      LocalDateTime created =
          dto.getReportedAt() != null
              ? dto.getReportedAt()
              : (dto.getCreatedAt() != null ? dto.getCreatedAt() : LocalDateTime.now());

      return new DriverIncidentResponse(
          dto.getId(), dto.getCode(), dto.getTitle(), dto.getDescription(), status, sev, created,
          photoUrls);
    }
  }

  /**
   * Create incident from driver_app (supports multipart upload with JSON "payload" + optional
   * "images").
   */
  @PostMapping(
      consumes = MediaType.MULTIPART_FORM_DATA_VALUE,
      produces = MediaType.APPLICATION_JSON_VALUE)
  public ResponseEntity<ApiResponse<DriverIncidentResponse>> createFromDriverApp(
      @Valid @RequestPart("payload") DriverIncidentCreateRequest payload,
      @RequestPart(value = "images", required = false) List<MultipartFile> images,
      UriComponentsBuilder uriBuilder) {

    Long driverId = authUtil.getCurrentDriverId();
    Long currentUserId = authUtil.getCurrentUserId();

    IncidentDto request =
        IncidentDto.builder()
            .incidentGroup(resolveGroup(payload))
            .incidentType(resolveType(payload))
            .severity(payload.severity() != null ? payload.severity() : IssueSeverity.MEDIUM)
            .source(IncidentSource.DRIVER_APP)
            .title(payload.title())
            .description(payload.description())
            .driverId(driverId)
            .vehicleId(payload.vehicleId())
            .tripId(payload.dispatchId())
            .locationText(payload.location())
            .locationLat(payload.latitude())
            .locationLng(payload.longitude())
            .build();

    IncidentDto created = incidentService.createIncident(request, currentUserId);

    if (images != null && !images.isEmpty()) {
      created = incidentService.uploadPhotos(created.getId(), images);
    }

    URI location =
        uriBuilder.path("/api/driver-app/incidents/{id}").buildAndExpand(created.getId()).toUri();

    return ResponseEntity.created(location)
        .body(
            new ApiResponse<>(
                true, "Incident submitted successfully", DriverIncidentResponse.fromIncident(created)));
  }

  /**
   * List incidents belonging to the authenticated driver. Accepts legacy status/severity strings so
   * the driver_app can keep its current filters without blowing up on enum mismatch.
   */
  @GetMapping(produces = MediaType.APPLICATION_JSON_VALUE)
  public ResponseEntity<ApiResponse<Page<DriverIncidentResponse>>> listMyIncidents(
      @RequestParam(required = false) String status,
      @RequestParam(required = false) String severity,
      @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
          LocalDate fromDate,
      @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate toDate,
      @PageableDefault(size = 10, sort = "reportedAt", direction = Sort.Direction.DESC)
          Pageable pageable) {

    Long driverId = authUtil.getCurrentDriverId();

    IncidentStatus statusFilter = parseStatus(status);
    IssueSeverity severityFilter = parseSeverity(severity);
    LocalDateTime from = fromDate != null ? fromDate.atStartOfDay() : null;
    LocalDateTime to = toDate != null ? toDate.atTime(23, 59, 59) : null;

    Page<IncidentDto> incidents =
        incidentService.listIncidents(
            statusFilter, null, severityFilter, driverId, null, from, to, pageable);

    Page<DriverIncidentResponse> mapped = incidents.map(DriverIncidentResponse::fromIncident);
    return ResponseEntity.ok(new ApiResponse<>(true, "Incidents retrieved", mapped));
  }

  /**
   * Get a single incident (driver ownership enforced).
   */
  @GetMapping(value = "/{id}", produces = MediaType.APPLICATION_JSON_VALUE)
  public ResponseEntity<ApiResponse<DriverIncidentResponse>> getMyIncident(@PathVariable Long id) {
    Long driverId = authUtil.getCurrentDriverId();
    IncidentDto incident = incidentService.getIncidentById(id);
    if (incident.getDriverId() != null && !incident.getDriverId().equals(driverId)) {
      throw new SecurityException("Incident does not belong to the current driver");
    }
    return ResponseEntity.ok(
        new ApiResponse<>(true, "Incident retrieved", DriverIncidentResponse.fromIncident(incident)));
  }

  /**
   * Upload additional photos for an incident the driver owns.
   */
  @PostMapping(
      value = "/{id}/photos",
      consumes = MediaType.MULTIPART_FORM_DATA_VALUE,
      produces = MediaType.APPLICATION_JSON_VALUE)
  public ResponseEntity<ApiResponse<DriverIncidentResponse>> uploadPhotos(
      @PathVariable Long id, @RequestPart("images") List<MultipartFile> images) {
    Long driverId = authUtil.getCurrentDriverId();
    IncidentDto incident = incidentService.getIncidentById(id);
    if (incident.getDriverId() != null && !incident.getDriverId().equals(driverId)) {
      throw new SecurityException("Incident does not belong to the current driver");
    }
    IncidentDto updated = incidentService.uploadPhotos(id, images);
    return ResponseEntity.ok(
        new ApiResponse<>(true, "Photos uploaded successfully", DriverIncidentResponse.fromIncident(updated)));
  }

  /**
   * Update status for an incident owned by the current driver (maps driver-app labels to incident enums).
   */
  @PatchMapping(
      value = "/{id}/status",
      consumes = MediaType.APPLICATION_JSON_VALUE,
      produces = MediaType.APPLICATION_JSON_VALUE)
  public ResponseEntity<ApiResponse<DriverIncidentResponse>> updateStatus(
      @PathVariable Long id, @Valid @RequestBody UpdateStatusRequest body) {
    Long driverId = authUtil.getCurrentDriverId();
    IncidentStatus status = parseStatus(body.status());
    if (status == null) {
      throw new IllegalArgumentException("Unsupported status: " + body.status());
    }
    IncidentDto updated =
        incidentService.updateIncidentStatusOwnedByDriver(id, driverId, status);
    return ResponseEntity.ok(
        new ApiResponse<>(true, "Status updated", DriverIncidentResponse.fromIncident(updated)));
  }

  /**
   * Update title/description for an incident owned by the current driver.
   */
  @PutMapping(
      value = "/{id}",
      consumes = MediaType.APPLICATION_JSON_VALUE,
      produces = MediaType.APPLICATION_JSON_VALUE)
  public ResponseEntity<ApiResponse<DriverIncidentResponse>> updateIncident(
      @PathVariable Long id, @Valid @RequestBody UpdateIncidentRequest body) {
    Long driverId = authUtil.getCurrentDriverId();
    IncidentDto updated =
        incidentService.updateIncidentOwnedByDriver(id, driverId, body.title(), body.description());
    return ResponseEntity.ok(
        new ApiResponse<>(true, "Incident updated", DriverIncidentResponse.fromIncident(updated)));
  }

  /**
   * Delete an incident owned by the current driver.
   */
  @DeleteMapping("/{id}")
  public ResponseEntity<ApiResponse<Void>> deleteIncident(@PathVariable Long id) {
    Long driverId = authUtil.getCurrentDriverId();
    incidentService.deleteIncidentOwnedByDriver(id, driverId);
    return ResponseEntity.status(HttpStatus.NO_CONTENT)
        .body(new ApiResponse<>(true, "Incident deleted", null));
  }

  // ---- helpers ----

  private IncidentGroup resolveGroup(DriverIncidentCreateRequest payload) {
    if (payload.incidentGroup() != null) return payload.incidentGroup();

    String text =
        (payload.title() + " " + payload.description())
            .toLowerCase(Locale.ROOT)
            .replace("_", " ");

    if (text.contains("customer") || text.contains("delivery")) return IncidentGroup.CUSTOMER;
    if (text.contains("accident")
        || text.contains("collision")
        || text.contains("hit")
        || text.contains("damage")
        || text.contains("theft")
        || text.contains("vandalism")) return IncidentGroup.ACCIDENT;
    if (text.contains("speed") || text.contains("route") || text.contains("block"))
      return IncidentGroup.TRAFFIC;
    return IncidentGroup.VEHICLE;
  }

  private IncidentType resolveType(DriverIncidentCreateRequest payload) {
    if (payload.incidentType() != null) return payload.incidentType();

    String text =
        (payload.title() + " " + payload.description())
            .toLowerCase(Locale.ROOT)
            .replace("_", " ");

    if (text.contains("tire")) return IncidentType.BREAKDOWN;
    if (text.contains("engine") || text.contains("mechanical") || text.contains("maintenance"))
      return IncidentType.MECHANICAL_FAILURE;
    if (text.contains("collision") || text.contains("accident") || text.contains("hit"))
      return IncidentType.COLLISION;
    if (text.contains("damage") || text.contains("theft") || text.contains("vandalism"))
      return IncidentType.PROPERTY_DAMAGE;
    if (text.contains("late") || text.contains("delay")) return IncidentType.MISSED_SCHEDULE;
    if (text.contains("route") || text.contains("block")) return IncidentType.WRONG_ROUTE;
    return IncidentType.OTHER;
  }

  private IncidentStatus parseStatus(String status) {
    if (status == null || status.isBlank()) return null;
    String normalized = status.trim().toUpperCase(Locale.ROOT);
    switch (normalized) {
      case "OPEN":
        return IncidentStatus.NEW;
      case "IN_PROGRESS":
      case "VALIDATED":
        return IncidentStatus.VALIDATED;
      case "CLOSED":
        return IncidentStatus.CLOSED;
      default:
        try {
          return IncidentStatus.valueOf(normalized);
        } catch (IllegalArgumentException ex) {
          log.warn("Ignoring unknown incident status filter from driver app: {}", status);
          return null;
        }
    }
  }

  private IssueSeverity parseSeverity(String severity) {
    if (severity == null || severity.isBlank()) return null;
    try {
      return IssueSeverity.valueOf(severity.trim().toUpperCase(Locale.ROOT));
    } catch (IllegalArgumentException ex) {
      log.warn("Ignoring unknown severity filter from driver app: {}", severity);
      return null;
    }
  }

  // ---- local exception responses for the driver app ----

  @ExceptionHandler(IllegalArgumentException.class)
  public ResponseEntity<ApiResponse<Void>> handleBadRequest(IllegalArgumentException ex) {
    return ResponseEntity.badRequest().body(new ApiResponse<>(false, ex.getMessage(), null));
  }

  @ExceptionHandler(SecurityException.class)
  public ResponseEntity<ApiResponse<Void>> handleForbidden(SecurityException ex) {
    return ResponseEntity.status(HttpStatus.FORBIDDEN)
        .body(new ApiResponse<>(false, ex.getMessage(), null));
  }

  @ExceptionHandler(NoSuchElementException.class)
  public ResponseEntity<ApiResponse<Void>> handleNotFound(NoSuchElementException ex) {
    return ResponseEntity.status(HttpStatus.NOT_FOUND)
        .body(new ApiResponse<>(false, ex.getMessage(), null));
  }
}
