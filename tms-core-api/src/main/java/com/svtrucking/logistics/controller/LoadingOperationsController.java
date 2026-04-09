package com.svtrucking.logistics.controller;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.dto.*;
import com.svtrucking.logistics.enums.LoadingDocumentType;
import com.svtrucking.logistics.enums.WarehouseCode;
import com.svtrucking.logistics.service.LoadingWorkflowService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.stream.Stream;

@RestController
@RequestMapping("/api/loading-ops")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
@Slf4j
public class LoadingOperationsController {

  private final LoadingWorkflowService loadingWorkflowService;

  @PostMapping(value = "/queue", produces = MediaType.APPLICATION_JSON_VALUE)
  @PreAuthorize("hasAnyAuthority('ROLE_LOADING','ROLE_DISPATCH_MONITOR','ROLE_ADMIN','ROLE_SUPERADMIN','all_functions')")
  public ResponseEntity<ApiResponse<LoadingQueueResponse>> enqueue(
      @Valid @RequestBody LoadingQueueRequest request) {
    return ResponseEntity.ok(
        new ApiResponse<>(true, "Dispatch queued", loadingWorkflowService.enqueue(request)));
  }

  @PutMapping(value = "/queue/{id}/call", produces = MediaType.APPLICATION_JSON_VALUE)
  @PreAuthorize("hasAnyAuthority('ROLE_LOADING','ROLE_DISPATCH_MONITOR','ROLE_ADMIN','ROLE_SUPERADMIN','all_functions')")
  public ResponseEntity<ApiResponse<LoadingQueueResponse>> callToBay(
      @PathVariable Long id,
      @RequestParam(required = false) String bay,
      @RequestParam(required = false) String remarks) {
    return ResponseEntity.ok(
        new ApiResponse<>(true, "Queue entry called", loadingWorkflowService.callToBay(id, bay, remarks)));
  }

  @PutMapping(value = "/queue/{id}/gate", produces = MediaType.APPLICATION_JSON_VALUE)
  @PreAuthorize("hasAnyAuthority('ROLE_LOADING','ROLE_DISPATCH_MONITOR','ROLE_ADMIN','ROLE_SUPERADMIN','all_functions')")
  public ResponseEntity<ApiResponse<LoadingQueueResponse>> updateGateInfo(
      @PathVariable Long id,
      @RequestBody(required = false) LoadingGateUpdateRequest request) {
    return ResponseEntity.ok(
        new ApiResponse<>(true, "Loading gate updated", loadingWorkflowService.updateGateInfo(id, request)));
  }

  @PostMapping(value = "/sessions/start", produces = MediaType.APPLICATION_JSON_VALUE)
  @PreAuthorize("hasAnyAuthority('ROLE_LOADING','ROLE_DISPATCH_MONITOR','ROLE_ADMIN','ROLE_SUPERADMIN','all_functions')")
  public ResponseEntity<ApiResponse<LoadingSessionResponse>> startLoading(
      @Valid @RequestBody LoadingSessionStartRequest request) {
    return ResponseEntity.ok(
        new ApiResponse<>(true, "Loading started", loadingWorkflowService.startLoading(request)));
  }

  @PutMapping(value = "/sessions/complete", produces = MediaType.APPLICATION_JSON_VALUE)
  @PreAuthorize("hasAnyAuthority('ROLE_LOADING','ROLE_ADMIN','ROLE_SUPERADMIN','all_functions')")
  public ResponseEntity<ApiResponse<LoadingSessionResponse>> completeLoading(
      @Valid @RequestBody LoadingSessionCompleteRequest request) {
    return ResponseEntity.ok(
        new ApiResponse<>(
            true, "Loading completed", loadingWorkflowService.completeLoading(request)));
  }

  @GetMapping(value = "/queue", produces = MediaType.APPLICATION_JSON_VALUE)
  @PreAuthorize("hasAnyAuthority('ROLE_LOADING','ROLE_SAFETY','ROLE_DISPATCH_MONITOR','ROLE_ADMIN','ROLE_SUPERADMIN','all_functions')")
  public ResponseEntity<ApiResponse<List<LoadingQueueResponse>>> queueByWarehouse(
      @RequestParam String warehouse) {
    final String normalizedWarehouse = warehouse == null ? "" : warehouse.trim().toUpperCase();

    try {
      if ("ALL".equals(normalizedWarehouse)) {
        List<LoadingQueueResponse> allRows = Stream
            .of(WarehouseCode.KHB, WarehouseCode.W2, WarehouseCode.W3)
            .flatMap(code -> loadingWorkflowService.getQueueByWarehouse(code).stream())
            .toList();
        return ResponseEntity.ok(new ApiResponse<>(true, "Queue", allRows));
      }

      WarehouseCode warehouseCode = WarehouseCode.from(normalizedWarehouse);
      if (warehouseCode == null) {
        return ResponseEntity.badRequest()
            .body(new ApiResponse<>(false, "Invalid warehouse code.", List.of()));
      }

      return ResponseEntity.ok(
          new ApiResponse<>(true, "Queue", loadingWorkflowService.getQueueByWarehouse(warehouseCode)));
    } catch (Exception ex) {
      log.error("Failed to get queue for warehouse {}", normalizedWarehouse, ex);
      return ResponseEntity.ok(new ApiResponse<>(false, "Queue temporarily unavailable.", List.of()));
    }
  }

  @GetMapping(value = "/queue/dispatch/{dispatchId}", produces = MediaType.APPLICATION_JSON_VALUE)
  @PreAuthorize("hasAnyAuthority('ROLE_LOADING','ROLE_SAFETY','ROLE_DISPATCH_MONITOR','ROLE_ADMIN','ROLE_SUPERADMIN','all_functions')")
  public ResponseEntity<ApiResponse<LoadingQueueResponse>> queueForDispatch(
      @PathVariable Long dispatchId) {
    return ResponseEntity.ok(
        new ApiResponse<>(
            true, "Queue entry", loadingWorkflowService.getQueueForDispatch(dispatchId)));
  }

  @GetMapping(value = "/sessions/dispatch/{dispatchId}", produces = MediaType.APPLICATION_JSON_VALUE)
  @PreAuthorize("hasAnyAuthority('ROLE_LOADING','ROLE_SAFETY','ROLE_DISPATCH_MONITOR','ROLE_ADMIN','ROLE_SUPERADMIN','all_functions')")
  public ResponseEntity<ApiResponse<LoadingSessionResponse>> sessionForDispatch(
      @PathVariable Long dispatchId) {
    return ResponseEntity.ok(
        new ApiResponse<>(
            true, "Loading session", loadingWorkflowService.getSessionForDispatch(dispatchId)));
  }

  @GetMapping(value = "/dispatch/{dispatchId}/detail", produces = MediaType.APPLICATION_JSON_VALUE)
  @PreAuthorize("hasAnyAuthority('ROLE_LOADING','ROLE_SAFETY','ROLE_DISPATCH_MONITOR','ROLE_ADMIN','ROLE_SUPERADMIN','all_functions')")
  public ResponseEntity<ApiResponse<LoadingDispatchDetailResponse>> dispatchDetail(
      @PathVariable Long dispatchId) {
    return ResponseEntity.ok(
        new ApiResponse<>(
            true, "Loading dispatch detail", loadingWorkflowService.getDispatchDetail(dispatchId)));
  }

  @PostMapping(
      value = "/sessions/{sessionId}/documents",
      consumes = MediaType.MULTIPART_FORM_DATA_VALUE,
      produces = MediaType.APPLICATION_JSON_VALUE)
  @PreAuthorize("hasAnyAuthority('ROLE_LOADING','ROLE_ADMIN','ROLE_SUPERADMIN','all_functions')")
  public ResponseEntity<ApiResponse<LoadingDocumentDto>> uploadDocument(
      @PathVariable Long sessionId,
      @RequestParam(required = false, defaultValue = "OTHER") String documentType,
      @RequestPart("file") MultipartFile file) {
    final LoadingDocumentType type;
    try {
      type =
          documentType != null
              ? LoadingDocumentType.valueOf(documentType.trim().toUpperCase())
              : LoadingDocumentType.OTHER;
    } catch (IllegalArgumentException ex) {
      return ResponseEntity.badRequest()
          .body(new ApiResponse<>(false, "Invalid documentType: " + documentType, null));
    }
    return ResponseEntity.ok(
        new ApiResponse<>(
            true, "Document uploaded", loadingWorkflowService.uploadDocument(sessionId, type, file)));
  }
}
