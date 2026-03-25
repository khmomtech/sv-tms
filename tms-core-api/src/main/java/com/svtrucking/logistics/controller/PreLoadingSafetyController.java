package com.svtrucking.logistics.controller;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.dto.PreLoadingSafetyCheckRequest;
import com.svtrucking.logistics.dto.PreLoadingSafetyCheckResponse;
import com.svtrucking.logistics.repository.PreLoadingSafetyCheckRepository;
import com.svtrucking.logistics.service.FileStorageService;
import com.svtrucking.logistics.service.PreLoadingSafetyCheckService;
import com.svtrucking.logistics.service.SafetyChecklistPdfService;
import jakarta.validation.Valid;
import java.util.List;
import java.util.NoSuchElementException;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/pre-loading-safety")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class PreLoadingSafetyController {

  private static final String SAFETY_WRITE_AUTH =
      "hasAnyAuthority('ROLE_SAFETY','ROLE_LOADING','ROLE_DISPATCH_MONITOR','dispatch:write','ROLE_ADMIN','ROLE_SUPERADMIN','all_functions')";
  private static final String SAFETY_READ_AUTH =
      "hasAnyAuthority('ROLE_SAFETY','ROLE_LOADING','ROLE_DISPATCH_MONITOR','ROLE_ADMIN','ROLE_SUPERADMIN','dispatch:view','dispatch:read','dispatch:monitor','all_functions')";

  private final PreLoadingSafetyCheckService safetyService;
  private final SafetyChecklistPdfService pdfService;
  private final FileStorageService fileStorageService;
  private final PreLoadingSafetyCheckRepository safetyRepository;

  @PostMapping(produces = MediaType.APPLICATION_JSON_VALUE)
  @PreAuthorize(SAFETY_WRITE_AUTH)
  public ResponseEntity<ApiResponse<PreLoadingSafetyCheckResponse>> submit(
      @Valid @RequestBody PreLoadingSafetyCheckRequest request) {
    PreLoadingSafetyCheckResponse response = safetyService.submitSafetyCheck(request);
    return ResponseEntity.ok(new ApiResponse<>(true, "Pre-entry safety check saved", response));
  }

  @GetMapping(value = "/latest/{dispatchId}", produces = MediaType.APPLICATION_JSON_VALUE)
  @PreAuthorize(SAFETY_READ_AUTH)
  public ResponseEntity<ApiResponse<PreLoadingSafetyCheckResponse>> latest(
      @PathVariable Long dispatchId) {
    PreLoadingSafetyCheckResponse response = safetyService.getLatestByDispatch(dispatchId);
    return ResponseEntity.ok(new ApiResponse<>(true, "Latest safety check", response));
  }

  @GetMapping(value = "/dispatch/{dispatchId}", produces = MediaType.APPLICATION_JSON_VALUE)
  @PreAuthorize(SAFETY_READ_AUTH)
  public ResponseEntity<ApiResponse<List<PreLoadingSafetyCheckResponse>>> history(
      @PathVariable Long dispatchId) {
    List<PreLoadingSafetyCheckResponse> history = safetyService.getHistory(dispatchId);
    return ResponseEntity.ok(new ApiResponse<>(true, "Safety check history", history));
  }

  @PostMapping(
      value = "/{id}/proof",
      consumes = MediaType.MULTIPART_FORM_DATA_VALUE,
      produces = MediaType.APPLICATION_JSON_VALUE)
  @PreAuthorize(SAFETY_WRITE_AUTH)
  public ResponseEntity<ApiResponse<String>> uploadProof(
      @PathVariable Long id, @org.springframework.web.bind.annotation.RequestPart("file") MultipartFile file) {
    safetyRepository
        .findById(id)
        .orElseThrow(() -> new NoSuchElementException("Safety check not found: " + id));
    String url = fileStorageService.storeFileInSubfolder(file, "safety-proof/" + id);
    return ResponseEntity.ok(new ApiResponse<>(true, "Proof uploaded", url));
  }

  @GetMapping(
      value = "/pdf/{dispatchId}",
      produces = MediaType.APPLICATION_PDF_VALUE)
  @PreAuthorize(SAFETY_READ_AUTH)
  public ResponseEntity<byte[]> checklistPdf(@PathVariable Long dispatchId) {
    try {
      byte[] pdf = pdfService.generate(dispatchId);
      return ResponseEntity.ok()
          .header(HttpHeaders.CONTENT_DISPOSITION, "inline; filename=safety-check-" + dispatchId + ".pdf")
          .body(pdf);
    } catch (NoSuchElementException e) {
      // Return 404 if dispatch or safety check not found
      return ResponseEntity.status(404)
          .header(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_JSON_VALUE)
          .body(("{\"error\":\"" + e.getMessage() + "\"}").getBytes());
    } catch (Exception e) {
      // Return 500 for other errors
      return ResponseEntity.status(500)
          .header(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_JSON_VALUE)
          .body(("{\"error\":\"Failed to generate PDF: " + e.getMessage() + "\"}").getBytes());
    }
  }
}
