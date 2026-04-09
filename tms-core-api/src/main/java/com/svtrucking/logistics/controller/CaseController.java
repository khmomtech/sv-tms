package com.svtrucking.logistics.controller;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.dto.CaseDto;
import com.svtrucking.logistics.dto.CaseTaskDto;
import com.svtrucking.logistics.dto.CaseTaskRequest;
import com.svtrucking.logistics.enums.*;
import com.svtrucking.logistics.security.AuthenticatedUserUtil;
import com.svtrucking.logistics.service.CaseService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
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
import org.springframework.web.util.UriComponentsBuilder;

import java.net.URI;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/cases")
@RequiredArgsConstructor
@Validated
@CrossOrigin(origins = "*")
@Slf4j
public class CaseController {

  private final CaseService caseService;
  private final AuthenticatedUserUtil authUtil;

  // Request DTOs
  public record LinkIncidentRequest(@NotBlank String notes) {}

  /**
   * Create a new case
   */
  @PostMapping(produces = MediaType.APPLICATION_JSON_VALUE)
  @PreAuthorize("@authorizationService.hasPermission('case:create')")
  public ResponseEntity<ApiResponse<CaseDto>> createCase(
      @Valid @RequestBody CaseDto caseDto,
      UriComponentsBuilder uriBuilder) {
    
    Long currentUserId = authUtil.getCurrentUserId();
    CaseDto created = caseService.createCase(caseDto, currentUserId);
    
    URI location = uriBuilder.path("/api/cases/{id}")
        .buildAndExpand(created.getId())
        .toUri();
    
    return ResponseEntity.created(location)
        .body(new ApiResponse<>(true, "Case created successfully", created));
  }

  /**
   * Get case by ID
   */
  @GetMapping(value = "/{id}", produces = MediaType.APPLICATION_JSON_VALUE)
  @PreAuthorize("@authorizationService.hasPermission('case:view')")
  public ResponseEntity<ApiResponse<CaseDto>> getCaseById(
      @PathVariable Long id,
      @RequestParam(defaultValue = "false") boolean includeRelatedData) {
    
    CaseDto caseDto = caseService.getCaseById(id, includeRelatedData);
    return ResponseEntity.ok(new ApiResponse<>(true, "Case retrieved", caseDto));
  }

  /**
   * Get case by code
   */
  @GetMapping(value = "/code/{code}", produces = MediaType.APPLICATION_JSON_VALUE)
  @PreAuthorize("@authorizationService.hasPermission('case:view')")
  public ResponseEntity<ApiResponse<CaseDto>> getCaseByCode(
      @PathVariable String code,
      @RequestParam(defaultValue = "false") boolean includeRelatedData) {
    
    CaseDto caseDto = caseService.getCaseByCode(code, includeRelatedData);
    return ResponseEntity.ok(new ApiResponse<>(true, "Case retrieved", caseDto));
  }

  /**
   * List cases with filtering and pagination
   */
  @GetMapping(produces = MediaType.APPLICATION_JSON_VALUE)
  @PreAuthorize("@authorizationService.hasPermission('case:list')")
  public ResponseEntity<ApiResponse<Page<CaseDto>>> listCases(
      @RequestParam(required = false) CaseStatus status,
      @RequestParam(required = false) CaseCategory category,
      @RequestParam(required = false) IssueSeverity severity,
      @RequestParam(required = false) Long assignedToUserId,
      @RequestParam(required = false) Long driverId,
      @RequestParam(required = false) Long vehicleId,
      @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) 
          LocalDateTime createdAfter,
      @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) 
          LocalDateTime createdBefore,
      @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
    
    Page<CaseDto> cases = caseService.listCases(
        status, category, severity, assignedToUserId, driverId, vehicleId,
        createdAfter, createdBefore, pageable);
    
    return ResponseEntity.ok(new ApiResponse<>(true, "Cases retrieved", cases));
  }

  /**
   * Search cases by text
   */
  @GetMapping(value = "/search", produces = MediaType.APPLICATION_JSON_VALUE)
  @PreAuthorize("@authorizationService.hasPermission('case:list')")
  public ResponseEntity<ApiResponse<Page<CaseDto>>> searchCases(
      @RequestParam String q,
      @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
    
    Page<CaseDto> cases = caseService.searchCases(q, pageable);
    return ResponseEntity.ok(new ApiResponse<>(true, "Search results", cases));
  }

  /**
   * Update case
   */
  @PutMapping(value = "/{id}", produces = MediaType.APPLICATION_JSON_VALUE)
  @PreAuthorize("@authorizationService.hasPermission('case:update')")
  public ResponseEntity<ApiResponse<CaseDto>> updateCase(
      @PathVariable Long id,
      @Valid @RequestBody CaseDto caseDto) {
    
    Long currentUserId = authUtil.getCurrentUserId();
    CaseDto updated = caseService.updateCase(id, caseDto, currentUserId);
    return ResponseEntity.ok(new ApiResponse<>(true, "Case updated", updated));
  }

  /**
   * Update case status
   */
  @PostMapping(value = "/{id}/status", produces = MediaType.APPLICATION_JSON_VALUE)
  @PreAuthorize("@authorizationService.hasPermission('case:update')")
  public ResponseEntity<ApiResponse<CaseDto>> updateCaseStatus(
      @PathVariable Long id,
      @RequestParam CaseStatus status) {
    
    CaseDto caseDto = new CaseDto();
    caseDto.setStatus(status);
    
    Long currentUserId = authUtil.getCurrentUserId();
    CaseDto updated = caseService.updateCase(id, caseDto, currentUserId);
    return ResponseEntity.ok(new ApiResponse<>(true, "Case status updated", updated));
  }

  /**
   * Link incident to case (escalate)
   */
  @PostMapping(value = "/{id}/incidents", produces = MediaType.APPLICATION_JSON_VALUE)
  @PreAuthorize("@authorizationService.hasPermission('incident:escalate')")
  public ResponseEntity<ApiResponse<CaseDto>> linkIncidentToCase(
      @PathVariable Long id,
      @RequestParam Long incidentId,
      @RequestBody(required = false) LinkIncidentRequest request) {
    
    Long currentUserId = authUtil.getCurrentUserId();
    String notes = request != null ? request.notes() : null;
    
    CaseDto updated = caseService.linkIncidentToCase(id, incidentId, notes, currentUserId);
    return ResponseEntity.ok(new ApiResponse<>(true, "Incident linked to case", updated));
  }

  /**
   * Unlink incident from case
   */
  @DeleteMapping(value = "/{id}/incidents/{incidentId}")
  @PreAuthorize("@authorizationService.hasPermission('case:manage')")
  public ResponseEntity<ApiResponse<Void>> unlinkIncidentFromCase(
      @PathVariable Long id,
      @PathVariable Long incidentId) {
    
    caseService.unlinkIncidentFromCase(id, incidentId);
    return ResponseEntity.ok(new ApiResponse<>(true, "Incident unlinked from case", null));
  }

  /**
   * Close case
   */
  @PostMapping(value = "/{id}/close", produces = MediaType.APPLICATION_JSON_VALUE)
  @PreAuthorize("@authorizationService.hasPermission('case:close')")
  public ResponseEntity<ApiResponse<CaseDto>> closeCase(@PathVariable Long id) {
    Long currentUserId = authUtil.getCurrentUserId();
    CaseDto closed = caseService.closeCase(id, currentUserId);
    return ResponseEntity.ok(new ApiResponse<>(true, "Case closed", closed));
  }

  /**
   * Delete case
   */
  @DeleteMapping("/{id}")
  @PreAuthorize("@authorizationService.hasPermission('case:delete')")
  public ResponseEntity<ApiResponse<Void>> deleteCase(@PathVariable Long id) {
    caseService.deleteCase(id);
    return ResponseEntity.ok(new ApiResponse<>(true, "Case deleted", null));
  }

  /**
   * Get case statistics
   */
  @GetMapping(value = "/statistics", produces = MediaType.APPLICATION_JSON_VALUE)
  @PreAuthorize("@authorizationService.hasPermission('case:list')")
  public ResponseEntity<ApiResponse<Map<String, Long>>> getCaseStatistics() {
    Map<String, Long> stats = caseService.getCaseStatistics();
    return ResponseEntity.ok(new ApiResponse<>(true, "Statistics retrieved", stats));
  }

  // ---------------------------------------------------------------------------
  // Case Tasks (lightweight CRUD for case-specific tasks)
  // ---------------------------------------------------------------------------

  @GetMapping(value = "/{id}/tasks", produces = MediaType.APPLICATION_JSON_VALUE)
  @PreAuthorize("@authorizationService.hasPermission('case:view')")
  public ResponseEntity<ApiResponse<List<CaseTaskDto>>> getCaseTasks(@PathVariable Long id) {
    List<CaseTaskDto> tasks = caseService.getCaseTasks(id);
    return ResponseEntity.ok(new ApiResponse<>(true, "Case tasks retrieved", tasks));
  }

  @PostMapping(value = "/{id}/tasks", produces = MediaType.APPLICATION_JSON_VALUE)
  @PreAuthorize("@authorizationService.hasPermission('case:update')")
  public ResponseEntity<ApiResponse<CaseTaskDto>> createCaseTask(
      @PathVariable Long id, @Valid @RequestBody CaseTaskRequest request) {
    Long currentUserId = authUtil.getCurrentUserId();
    CaseTaskDto created = caseService.createCaseTask(id, request, currentUserId);
    return ResponseEntity.ok(new ApiResponse<>(true, "Case task created", created));
  }

  @PutMapping(value = "/{id}/tasks/{taskId}", produces = MediaType.APPLICATION_JSON_VALUE)
  @PreAuthorize("@authorizationService.hasPermission('case:update')")
  public ResponseEntity<ApiResponse<CaseTaskDto>> updateCaseTask(
      @PathVariable Long id,
      @PathVariable Long taskId,
      @Valid @RequestBody CaseTaskRequest request) {
    Long currentUserId = authUtil.getCurrentUserId();
    CaseTaskDto updated = caseService.updateCaseTask(id, taskId, request, currentUserId);
    return ResponseEntity.ok(new ApiResponse<>(true, "Case task updated", updated));
  }

  @DeleteMapping(value = "/{id}/tasks/{taskId}", produces = MediaType.APPLICATION_JSON_VALUE)
  @PreAuthorize("@authorizationService.hasPermission('case:update')")
  public ResponseEntity<ApiResponse<Void>> deleteCaseTask(
      @PathVariable Long id, @PathVariable Long taskId) {
    caseService.deleteCaseTask(id, taskId);
    return ResponseEntity.ok(new ApiResponse<>(true, "Case task deleted", null));
  }

  /**
   * Get overdue cases
   */
  @GetMapping(value = "/overdue", produces = MediaType.APPLICATION_JSON_VALUE)
  @PreAuthorize("@authorizationService.hasPermission('case:list')")
  public ResponseEntity<ApiResponse<List<CaseDto>>> getOverdueCases() {
    List<CaseDto> overdue = caseService.getOverdueCases();
    return ResponseEntity.ok(new ApiResponse<>(true, "Overdue cases retrieved", overdue));
  }
}
