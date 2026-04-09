package com.svtrucking.logistics.controller.drivers;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.dto.DocumentAuditDto;
import com.svtrucking.logistics.model.DriverDocument;
import com.svtrucking.logistics.dto.DriverDocumentCreateDto;
import com.svtrucking.logistics.dto.DriverDocumentUpdateDto;
import com.svtrucking.logistics.service.DriverDocumentService;
import com.svtrucking.logistics.service.DocumentAuditService;
import java.util.List;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.io.Resource;
import org.springframework.core.io.FileSystemResource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

/**
 * Controller for driver document operations.
 * Separated from DriverController to follow Single Responsibility Principle.
 */
@RestController
@RequestMapping("/api/admin/drivers")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
@Slf4j
public class DriverDocumentController {

  private final DriverDocumentService driverDocumentService;
  private final DocumentAuditService documentAuditService;

  /**
   * Get all documents for a driver.
   */
  @GetMapping("/{driverId}/documents")
  @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_VIEW_ALL) " +
                "or @authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
  public ResponseEntity<ApiResponse<List<DriverDocument>>> getDriverDocuments(@PathVariable Long driverId) {
    try {
      log.info("Getting all documents for driver: {}", driverId);
      List<DriverDocument> documents = driverDocumentService.getDocumentsByDriver(driverId);
      log.debug("Retrieved {} documents for driver {}", documents.size(), driverId);
      return ResponseEntity.ok(ApiResponse.success("Documents retrieved successfully", documents));
    } catch (com.svtrucking.logistics.exception.ResourceNotFoundException e) {
      log.warn("Driver not found when fetching documents for driver {}: {}", driverId, e.getMessage());
      return ResponseEntity.status(HttpStatus.NOT_FOUND)
          .body(ApiResponse.fail("Driver not found: " + e.getMessage()));
    } catch (Exception e) {
      log.error("Error retrieving documents for driver {}: {}", driverId, e.getMessage(), e);
      return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
          .body(ApiResponse.fail("Failed to retrieve documents: " + e.getMessage()));
    }
  }

  /**
   * Get a specific document.
   */
  @GetMapping("/documents/{documentId}")
  @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_VIEW_ALL) " +
                "or @authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
  public ResponseEntity<ApiResponse<DriverDocument>> getDocument(@PathVariable Long documentId) {
    try {
      log.info("Getting document: {}", documentId);
      DriverDocument document = driverDocumentService.getDocument(documentId, null);
      return ResponseEntity.ok(ApiResponse.success("Document retrieved successfully", document));
    } catch (Exception e) {
      log.error("Error retrieving document {}: {}", documentId, e.getMessage(), e);
      return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
          .body(ApiResponse.fail("Failed to retrieve document: " + e.getMessage()));
    }
  }

  /**
   * Create a new document for a driver.
   */
  @PostMapping(value = "/{driverId}/documents", produces = MediaType.APPLICATION_JSON_VALUE)
  @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
  public ResponseEntity<ApiResponse<DriverDocument>> createDocument(
      @PathVariable Long driverId, @RequestBody DriverDocumentCreateDto documentDto) {
    try {
      log.info("Creating document for driver: {}", driverId);

      DriverDocument document = DriverDocument.builder()
          .name(documentDto.getName())
          .category(documentDto.getCategory())
          .expiryDate(documentDto.getExpiryDate())
          .description(documentDto.getDescription())
          .isRequired(documentDto.getIsRequired() != null ? documentDto.getIsRequired() : false)
          .fileUrl(documentDto.getFileUrl())
          .build();

      DriverDocument createdDocument = driverDocumentService.createDocument(driverId, document);
      return ResponseEntity.status(HttpStatus.CREATED)
          .body(ApiResponse.success("Document created successfully", createdDocument));
    } catch (IllegalArgumentException e) {
      log.error("Validation error creating document for driver {}: {}", driverId, e.getMessage());
      // Map the simple service validation message into the structured errors map expected by tests
      java.util.Map<String, String> errors = new java.util.HashMap<>();
      String msg = e.getMessage();
      if (msg != null && msg.toLowerCase().contains("name")) {
        errors.put("name", msg);
      } else if (msg != null && msg.toLowerCase().contains("category")) {
        errors.put("category", msg);
      } else {
        errors.put("general", msg != null ? msg : "Validation error");
      }
      return ResponseEntity.badRequest()
          .body(ApiResponse.fail("Validation failed.", errors));
    } catch (Exception e) {
      log.error("Error creating document for driver {}: {}", driverId, e.getMessage(), e);
      return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
          .body(ApiResponse.fail("Failed to create document: " + e.getMessage()));
    }
  }

  /**
   * Update a document.
   */
  @PutMapping("/{driverId}/documents/{documentId}")
  @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
  public ResponseEntity<ApiResponse<DriverDocument>> updateDocument(
      @PathVariable Long driverId, @PathVariable Long documentId, @RequestBody DriverDocumentUpdateDto documentUpdate) {
    try {
      log.info("Updating document {} for driver {}", documentId, driverId);
      DriverDocument updatedDocument = driverDocumentService.updateDocument(documentId, null, documentUpdate);
      return ResponseEntity.ok(ApiResponse.success("Document updated successfully", updatedDocument));
    } catch (Exception e) {
      log.error("Error updating document {} for driver {}: {}", documentId, driverId, e.getMessage(), e);
      return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
          .body(ApiResponse.fail("Failed to update document: " + e.getMessage()));
    }
  }

  /**
   * Update a document with a new file.
   */
  @PutMapping("/{driverId}/documents/{documentId}/file")
  @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
  public ResponseEntity<ApiResponse<DriverDocument>> updateDocumentFile(
      @PathVariable Long driverId,
      @PathVariable Long documentId,
      @RequestPart("file") MultipartFile file,
      @RequestParam(required = false) String name,
      @RequestParam(required = false) String category,
      @RequestParam(required = false) String expiryDate,
      @RequestParam(required = false) String description,
      @RequestParam(required = false) Boolean isRequired) {
    try {
      log.info("Updating file for document {} for driver {}", documentId, driverId);

      // Validate file type
      String contentType = file.getContentType();
      if (contentType == null ||
          (!contentType.equals("application/pdf") && !contentType.startsWith("image/"))) {
        return ResponseEntity.badRequest()
            .body(ApiResponse.fail("Invalid file type. Only PDF and image files are allowed."));
      }

      // Build update DTO
      DriverDocumentUpdateDto updateDto = DriverDocumentUpdateDto.builder()
          .name(name != null && !name.isEmpty() ? name : null)
          .category(category != null && !category.isEmpty() ? category : null)
          .description(description != null && !description.isEmpty() ? description : null)
          .isRequired(isRequired)
          .build();

      // Parse expiry date if provided
      if (expiryDate != null && !expiryDate.isEmpty()) {
        try {
          updateDto.setExpiryDate(java.time.LocalDate.parse(expiryDate));
        } catch (Exception e) {
          log.warn("Invalid expiry date format: {} - expected YYYY-MM-DD", expiryDate);
          return ResponseEntity.badRequest()
              .body(ApiResponse.fail("Invalid expiry date format. Use YYYY-MM-DD"));
        }
      }

      // Update document with new file
      DriverDocument updatedDocument = driverDocumentService.updateDocumentFile(documentId, file, updateDto);

      return ResponseEntity.ok(ApiResponse.success("Document file updated successfully", updatedDocument));

    } catch (IllegalArgumentException e) {
      log.error("Validation error updating file for document {} for driver {}: {}", documentId, driverId, e.getMessage());
      return ResponseEntity.badRequest()
          .body(ApiResponse.fail("Validation error: " + e.getMessage()));
    } catch (Exception e) {
      log.error("Error updating file for document {} for driver {}: {}", documentId, driverId, e.getMessage(), e);
      return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
          .body(ApiResponse.fail("Error updating document file: " + e.getMessage()));
    }
  }

  /**
   * Delete a document.
   */
  @DeleteMapping("/{driverId}/documents/{documentId}")
  @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
  public ResponseEntity<ApiResponse<String>> deleteDocument(
      @PathVariable Long driverId, @PathVariable Long documentId) {
    try {
      log.info("Deleting document {} for driver {}", documentId, driverId);
      driverDocumentService.deleteDocument(documentId, null);
      return ResponseEntity.ok(ApiResponse.success("Document deleted successfully"));
    } catch (Exception e) {
      log.error("Error deleting document {} for driver {}: {}", documentId, driverId, e.getMessage(), e);
      return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
          .body(ApiResponse.fail("Failed to delete document: " + e.getMessage()));
    }
  }

  /**
   * Get documents by category.
   */
  @GetMapping("/{driverId}/documents/category/{category}")
  @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_VIEW_ALL) " +
                "or @authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
  public ResponseEntity<ApiResponse<List<DriverDocument>>> getDocumentsByCategory(
      @PathVariable Long driverId, @PathVariable String category) {
    try {
      log.info("Getting documents for driver: {} with category: {}", driverId, category);
      List<DriverDocument> documents = driverDocumentService.getDocumentsByCategory(driverId, category);
      return ResponseEntity.ok(ApiResponse.success("Documents retrieved successfully", documents));
    } catch (Exception e) {
      log.error("Error retrieving documents by category '{}' for driver {}: {}", category, driverId, e.getMessage(), e);
      return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
          .body(ApiResponse.fail("Failed to retrieve documents by category: " + e.getMessage()));
    }
  }

  /**
   * Get expired documents for a driver.
   */
  @GetMapping("/{driverId}/documents/expired")
  @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_VIEW_ALL) " +
                "or @authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
  public ResponseEntity<ApiResponse<List<DriverDocument>>> getExpiredDocuments(@PathVariable Long driverId) {
    try {
      log.info("Getting expired documents for driver: {}", driverId);
      List<DriverDocument> documents = driverDocumentService.getExpiredDocuments(driverId);
      return ResponseEntity.ok(ApiResponse.success("Expired documents retrieved successfully", documents));
    } catch (Exception e) {
      log.error("Error retrieving expired documents for driver {}: {}", driverId, e.getMessage(), e);
      return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
          .body(ApiResponse.fail("Failed to retrieve expired documents: " + e.getMessage()));
    }
  }

  /**
   * Get expiring documents for a driver (within 30 days).
   */
  @GetMapping("/{driverId}/documents/expiring")
  @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_VIEW_ALL) " +
                "or @authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
  public ResponseEntity<ApiResponse<List<DriverDocument>>> getExpiringDocuments(@PathVariable Long driverId) {
    try {
      log.info("Getting expiring documents for driver: {}", driverId);
      List<DriverDocument> documents = driverDocumentService.getExpiringDocuments(driverId);
      return ResponseEntity.ok(ApiResponse.success("Expiring documents retrieved successfully", documents));
    } catch (Exception e) {
      log.error("Error retrieving expiring documents for driver {}: {}", driverId, e.getMessage(), e);
      return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
          .body(ApiResponse.fail("Failed to retrieve expiring documents: " + e.getMessage()));
    }
  }

  /**
   * Get required documents for a driver.
   */
  @GetMapping("/{driverId}/documents/required")
  @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_VIEW_ALL) " +
                "or @authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
  public ResponseEntity<ApiResponse<List<DriverDocument>>> getRequiredDocuments(@PathVariable Long driverId) {
    try {
      log.info("Getting required documents for driver: {}", driverId);
      List<DriverDocument> documents = driverDocumentService.getRequiredDocuments(driverId);
      return ResponseEntity.ok(ApiResponse.success("Required documents retrieved successfully", documents));
    } catch (Exception e) {
      log.error("Error retrieving required documents for driver {}: {}", driverId, e.getMessage(), e);
      return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
          .body(ApiResponse.fail("Failed to retrieve required documents: " + e.getMessage()));
    }
  }

  /**
   * Upload a document file for a driver.
   */
  @PostMapping("/{driverId}/documents/upload")
  @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
  public ResponseEntity<ApiResponse<DriverDocument>> uploadDocument(
      @PathVariable Long driverId,
      @RequestPart("file") MultipartFile file,
      @RequestParam(required = false) String name,
      @RequestParam(required = false) String category,
      @RequestParam(required = false) String expiryDate,
      @RequestParam(required = false) String description,
      @RequestParam(required = false) Boolean isRequired) {

    try {
      log.info("Uploading document for driver: {}", driverId);
      log.debug("Upload request - file: {}, name: {}, category: {}",
                file.getOriginalFilename(), name, category);

      // Validate file type
      String contentType = file.getContentType();
      if (contentType == null ||
          (!contentType.equals("application/pdf") && !contentType.startsWith("image/"))) {
        return ResponseEntity.badRequest()
            .body(ApiResponse.fail("Invalid file type. Only PDF and image files are allowed."));
      }

      // Create document object from request parameters
      DriverDocument document = new DriverDocument();
      if (name != null && !name.isEmpty()) {
        document.setName(name);
      } else {
        String originalFilename = file.getOriginalFilename();
        if (originalFilename != null && !originalFilename.isEmpty()) {
          document.setName(originalFilename);
        } else {
          document.setName("uploaded_document_" + System.currentTimeMillis());
        }
      }
      if (category != null && !category.isEmpty()) {
        document.setCategory(category);
      }
      if (description != null && !description.isEmpty()) {
        document.setDescription(description);
      }
      if (isRequired != null) {
        document.setIsRequired(isRequired);
      }

      // Parse expiry date if provided
      if (expiryDate != null && !expiryDate.isEmpty()) {
        try {
          document.setExpiryDate(java.time.LocalDate.parse(expiryDate));
        } catch (Exception e) {
          log.warn("Invalid expiry date format: {} - expected YYYY-MM-DD", expiryDate);
          return ResponseEntity.badRequest()
              .body(ApiResponse.fail("Invalid expiry date format. Use YYYY-MM-DD"));
        }
      }

      // Upload file and save document
      DriverDocument savedDocument = driverDocumentService.uploadDocument(driverId, file, document);

      return ResponseEntity.status(HttpStatus.CREATED)
          .body(ApiResponse.success("Document uploaded successfully", savedDocument));

    } catch (IllegalArgumentException e) {
      log.error("Validation error uploading document for driver {}: {}", driverId, e.getMessage());
      return ResponseEntity.badRequest()
          .body(ApiResponse.fail("Validation error: " + e.getMessage()));
    } catch (Exception e) {
      log.error("Error uploading document for driver: {}", driverId, e);
      return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
          .body(ApiResponse.fail("Error uploading document: " + e.getMessage()));
    }
  }

  /**
   * Download the binary content for a driver document.
   */
  @GetMapping("/{driverId}/documents/{documentId}/download")
  @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_VIEW_ALL) " +
                "or @authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
  public ResponseEntity<Resource> downloadDriverDocument(
      @PathVariable Long driverId,
      @PathVariable Long documentId,
      @RequestParam(name = "disposition", defaultValue = "inline") String disposition) {
    try {
      FileSystemResource resource = driverDocumentService.loadDocumentFile(documentId, driverId);

      // Attempt integrity verification if audit exists
      boolean integrityOk = false;
      try {
        DriverDocument doc = driverDocumentService.getDocument(documentId, driverId);
        integrityOk = documentAuditService.verifyIntegrity(doc);
      } catch (Exception e) {
        log.debug("Integrity verification skipped for document {}: {}", documentId, e.getMessage());
      }

      // Determine content type
      String contentType = null;
      try {
        contentType = java.nio.file.Files.probeContentType(resource.getFile().toPath());
      } catch (Exception ignored) {
      }
      if (contentType == null) {
        contentType = MediaType.APPLICATION_OCTET_STREAM_VALUE;
      }

      String filename = resource.getFilename();
      // If stored filename is UUID_prefixed (uuid_originalname.ext), strip UUID prefix for Content-Disposition
      if (filename != null && filename.contains("_")) {
        String[] parts = filename.split("_", 2);
        if (parts.length == 2) {
          filename = parts[1];
        }
      }
      HttpHeaders headers = new HttpHeaders();
      headers.add(HttpHeaders.CONTENT_TYPE, contentType);
      headers.add(HttpHeaders.CONTENT_DISPOSITION,
          ("attachment".equalsIgnoreCase(disposition) ? "attachment" : "inline") + "; filename=\"" + filename + "\"");

      if (!integrityOk) {
        headers.add("X-Document-Integrity", "mismatch-or-unverified");
      } else {
        headers.add("X-Document-Integrity", "ok");
      }
      return ResponseEntity.ok().headers(headers).body(resource);
    } catch (com.svtrucking.logistics.exception.ResourceNotFoundException e) {
      log.warn("Requested document/file not found {} for driver {}: {}", documentId, driverId, e.getMessage());
      return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
    } catch (Exception e) {
      log.error("Error downloading document {} for driver {}: {}", documentId, driverId, e.getMessage(), e);
      return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
    }
  }

  /**
   * Fetch audit metadata + integrity status for a document.
   */
  @GetMapping("/{driverId}/documents/{documentId}/audit")
  @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_VIEW_ALL) " +
                "or @authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
  public ResponseEntity<ApiResponse<DocumentAuditDto>> getDocumentAudit(
      @PathVariable Long driverId,
      @PathVariable Long documentId) {
    try {
      DriverDocument doc = driverDocumentService.getDocument(documentId, driverId);
      var audit = documentAuditService.getAudit(documentId);
      if (audit == null) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
            .body(ApiResponse.fail("Audit not found"));
      }
      boolean integrityOk = documentAuditService.verifyIntegrity(doc);
      var dto = DocumentAuditDto.builder()
          .documentId(doc.getId())
          .auditId(audit.getId())
          .sizeBytes(audit.getSizeBytes())
          .mimeType(audit.getMimeType())
          .checksumSha256(audit.getChecksumSha256())
          .integrityOk(integrityOk)
          .thumbnailUrl(audit.getThumbnailUrl())
          .thumbnailAttempted(audit.isThumbnailAttempted())
          .build();
      return ResponseEntity.ok(ApiResponse.success("Audit fetched", dto));
    } catch (Exception e) {
      log.error("Error fetching audit for document {} driver {}: {}", documentId, driverId, e.getMessage(), e);
      return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
          .body(ApiResponse.fail("Server error"));
    }
  }
}
