package com.svtrucking.logistics.controller;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.dto.DriverIssueDto;
import com.svtrucking.logistics.security.AuthenticatedUserUtil;
import com.svtrucking.logistics.service.DriverIssueService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.net.URI;
import java.time.LocalDate;
import java.util.List;
import java.util.NoSuchElementException;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.util.UriComponentsBuilder;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;

@RestController
@RequestMapping("/api/driver/issues")
@RequiredArgsConstructor
@Validated
// Narrow CORS in prod or remove and configure globally
@CrossOrigin(origins = "*")
public class DriverIssueController {

  private final DriverIssueService driverIssueService;
  private final AuthenticatedUserUtil authUtil;

  // ---------- Request DTOs ----------
  public record SubmitIssueRequest(
      Long dispatchId,
      @NotBlank @Size(max = 120) String title,
      @NotBlank @Size(max = 5000) String description) {}

  public record UpdateIssueRequest(
      @NotBlank @Size(max = 120) String title, @NotBlank @Size(max = 5000) String description) {}

  public record UpdateStatusRequest(
      @NotBlank String status // validate allowed values in service or with a custom validator
      ) {}

  // ---------- Create (multipart: JSON + images) ----------
  // @PreAuthorize("hasRole('DRIVER')")
  @PostMapping(
      consumes = {MediaType.MULTIPART_FORM_DATA_VALUE},
      produces = MediaType.APPLICATION_JSON_VALUE)
  public ResponseEntity<ApiResponse<DriverIssueDto>> submitIssue(
      @Valid @RequestPart("payload") SubmitIssueRequest payload,
      @RequestPart(name = "images", required = false) List<MultipartFile> images,
      UriComponentsBuilder uriBuilder) {
    Long driverId = authUtil.getCurrentDriverId();
    DriverIssueDto dto =
        driverIssueService.submitIssue(
            driverId, payload.dispatchId(), payload.title(), payload.description(), images);

    // 201 + Location: /api/driver/issues/{id}
    URI location = uriBuilder.path("/api/driver/issues/{id}").buildAndExpand(dto.getId()).toUri();

    return ResponseEntity.created(location)
        .body(new ApiResponse<>(true, "Issue submitted successfully", dto));
  }

  // ---------- List (paged + optional filters) ----------
  // @PreAuthorize("hasRole('DRIVER')")
  @GetMapping(value = "/paged", produces = MediaType.APPLICATION_JSON_VALUE)
  public ResponseEntity<ApiResponse<Page<DriverIssueDto>>> getIssuesByDriverPaged(
      @RequestParam(required = false) String status,
      @RequestParam(required = false) String type, // if you support types
      @RequestParam(required = false) LocalDate fromDate, // optional date filters
      @RequestParam(required = false) LocalDate toDate,
      @PageableDefault(size = 10, sort = "createdAt") Pageable pageable) {
    Long driverId = authUtil.getCurrentDriverId();
    if (type != null && type.equalsIgnoreCase("incident")) {
      type = null;
    }
    Page<DriverIssueDto> page =
        driverIssueService.getDriverIssues(driverId, status, type, fromDate, toDate, pageable);

    return ResponseEntity.ok(new ApiResponse<>(true, "Fetched issue list", page));
  }

  // ---------- List (paged) by explicit driverId (admin/support use) ----------
  // NOTE: This endpoint is useful when an admin needs to see issues for a specific driver.
  // It mirrors /paged but the driver is provided in the path.
  @GetMapping(value = "/{driverId:\\d+}/paged", produces = MediaType.APPLICATION_JSON_VALUE)
  public ResponseEntity<ApiResponse<Page<DriverIssueDto>>> getIssuesByDriverIdPaged(
      @PathVariable Long driverId,
      @RequestParam(required = false) String status,
      @RequestParam(required = false) String type,
      @RequestParam(required = false) LocalDate fromDate,
      @RequestParam(required = false) LocalDate toDate,
      @PageableDefault(size = 10, sort = "createdAt") Pageable pageable) {
    if (type != null && type.equalsIgnoreCase("incident")) {
      type = null;
    }
    Page<DriverIssueDto> page =
        driverIssueService.getDriverIssues(driverId, status, type, fromDate, toDate, pageable);

    return ResponseEntity.ok(new ApiResponse<>(true, "Fetched issue list", page));
  }

  // ---------- Get by id ----------
  // @PreAuthorize("hasRole('DRIVER')")
  @GetMapping(value = "/{id:\\d+}", produces = MediaType.APPLICATION_JSON_VALUE)
  public ResponseEntity<ApiResponse<DriverIssueDto>> getById(@PathVariable Long id) {
    DriverIssueDto dto =
        driverIssueService.getByIdOwnedByCurrentDriver(id, authUtil.getCurrentDriverId());
    return ResponseEntity.ok(new ApiResponse<>(true, "Fetched issue details", dto));
  }

  // ---------- Update text fields (JSON) ----------
  // @PreAuthorize("hasRole('DRIVER')")
  @PutMapping(
      value = "/{id:\\d+}",
      consumes = MediaType.APPLICATION_JSON_VALUE,
      produces = MediaType.APPLICATION_JSON_VALUE)
  public ResponseEntity<ApiResponse<DriverIssueDto>> updateIssue(
      @PathVariable Long id, @Valid @RequestBody UpdateIssueRequest update) {
    Long driverId = authUtil.getCurrentDriverId();
    DriverIssueDto updated =
        driverIssueService.updateIssueOwnedByDriver(
            id, driverId, update.title(), update.description());
    return ResponseEntity.ok(new ApiResponse<>(true, "Issue updated successfully", updated));
  }

  // ---------- Update status (JSON) ----------
  // @PreAuthorize("hasRole('DRIVER')")
  @PatchMapping(
      value = "/{id:\\d+}/status",
      consumes = MediaType.APPLICATION_JSON_VALUE,
      produces = MediaType.APPLICATION_JSON_VALUE)
  public ResponseEntity<ApiResponse<DriverIssueDto>> updateStatus(
      @PathVariable Long id, @Valid @RequestBody UpdateStatusRequest body) {
    Long driverId = authUtil.getCurrentDriverId();
    DriverIssueDto updated =
        driverIssueService.updateStatusOwnedByDriver(id, driverId, body.status());
    return ResponseEntity.ok(new ApiResponse<>(true, "Status updated successfully", updated));
  }

  // ---------- Delete ----------
  // @PreAuthorize("hasRole('DRIVER')")
  @DeleteMapping("/{id:\\d+}")
  public ResponseEntity<ApiResponse<Void>> deleteIssue(@PathVariable Long id) {
    Long driverId = authUtil.getCurrentDriverId();
    driverIssueService.deleteIssueOwnedByDriver(id, driverId);
    return ResponseEntity.status(HttpStatus.NO_CONTENT)
        .header(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_JSON_VALUE)
        .body(new ApiResponse<>(true, "Issue deleted successfully", null));
  }

  // ---------- Local exception handlers for safer client responses ----------
  @ExceptionHandler(IllegalArgumentException.class)
  public ResponseEntity<ApiResponse<Void>> handleBadRequest(IllegalArgumentException ex) {
    return ResponseEntity.badRequest()
        .body(new ApiResponse<>(false, ex.getMessage(), null));
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

  @ExceptionHandler(MethodArgumentTypeMismatchException.class)
  public ResponseEntity<ApiResponse<Void>> handleTypeMismatch(MethodArgumentTypeMismatchException ex) {
    String msg = "Invalid path parameter: " + ex.getName();
    return ResponseEntity.badRequest()
        .body(new ApiResponse<>(false, msg, null));
  }
}
