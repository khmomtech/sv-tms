package com.svtrucking.logistics.service;

import com.svtrucking.logistics.dto.DriverDocumentUpdateDto;
import com.svtrucking.logistics.exception.ResourceNotFoundException;
import com.svtrucking.logistics.model.Driver;
import com.svtrucking.logistics.model.DriverDocument;
import com.svtrucking.logistics.repository.DriverDocumentRepository;
import com.svtrucking.logistics.repository.DriverRepository;
import com.svtrucking.logistics.core.FileStorageProperties;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.time.LocalDate;
import java.util.List;
import java.util.Objects;

@Service
@Slf4j
public class DriverDocumentService {

    @Autowired
    private DriverDocumentRepository driverDocumentRepository;

    @Autowired
    private DriverRepository driverRepository;

    @Autowired
    private FileStorageProperties fileStorageProperties;

    /**
     * Get all documents for a driver
     */
    @Transactional(readOnly = true)
    public List<DriverDocument> getDocumentsByDriver(Long driverId) {
        log.info("Fetching documents for driver: {}", driverId);
        // Verify driver exists
        driverRepository.findById(driverId)
                .orElseThrow(() -> new ResourceNotFoundException("Driver not found with id: " + driverId));
        return driverDocumentRepository.findByDriverId(driverId);
    }

    /**
     * Get a specific document
     */
    @Transactional(readOnly = true)
    public DriverDocument getDocument(Long documentId, Long driverId) {
        log.info("Fetching document: {} for driver: {}", documentId, driverId);
        return driverDocumentRepository.findByIdAndDriverId(documentId, driverId)
                .orElseThrow(() -> new ResourceNotFoundException("Document not found with id: " + documentId));
    }

    /**
     * Load the underlying file as a Resource for download/preview.
     * Validates that the document belongs to the given driver.
     */
    @Transactional(readOnly = true)
    public org.springframework.core.io.FileSystemResource loadDocumentFile(Long documentId, Long driverId) {
        log.info("Loading file resource for document {} (driver={})", documentId, driverId);
        DriverDocument doc = driverDocumentRepository.findById(documentId)
                .orElseThrow(() -> new ResourceNotFoundException("Document not found with id: " + documentId));

        if (driverId != null && (doc.getDriver() == null || !driverId.equals(doc.getDriver().getId()))) {
            throw new ResourceNotFoundException("Document " + documentId + " does not belong to driver " + driverId);
        }

        String fileUrl = doc.getFileUrl();
        if (fileUrl == null || fileUrl.isBlank()) {
            throw new ResourceNotFoundException("Document " + documentId + " has no stored file.");
        }

        // Expected patterns:
        //  1) /uploads/documents/<driverId>/uuid_filename.ext (preferred)
        //  2) uploads/documents/<driverId>/uuid_filename.ext (legacy w/out leading slash)
        //  3) Absolute path on disk (fallback) e.g. /app/uploads/documents/4/uuid_filename.ext
        final String prefixed = "/uploads/";
        String working = fileUrl.trim();

        // Normalize legacy pattern missing leading slash
        if (working.startsWith("uploads/")) {
            working = "/" + working; // ensure leading slash for consistent prefix handling
        }

        java.nio.file.Path resolvedPath = null;
        if (working.startsWith(prefixed)) {
            String relative = working.substring(prefixed.length()); // documents/driverId/uuid_filename.ext
            java.nio.file.Path base = fileStorageProperties.getBasePath();
            resolvedPath = base.resolve(relative).normalize();
            log.debug("Resolved document {} path under baseDir: base='{}', relative='{}', full='{}'", documentId, base, relative, resolvedPath);
        } else {
            // Attempt direct resolution for absolute or previously stored full path
            java.nio.file.Path direct = java.nio.file.Paths.get(working).normalize();
            log.debug("Attempting direct path resolution for document {}: {}", documentId, direct);
            resolvedPath = direct;
        }

        // Final existence check with extra diagnostic logging
        if (resolvedPath == null || !java.nio.file.Files.exists(resolvedPath)) {
            log.warn("File missing for document {}. fileUrl='{}', resolved='{}'", documentId, working, resolvedPath);
            // Emit distinct message so controller can optionally map to 410 later if desired
            throw new ResourceNotFoundException("Stored file not found for document " + documentId);
        }

        return new org.springframework.core.io.FileSystemResource(resolvedPath);
    }

    /**
     * Create a new document
     */
    @Transactional
    public DriverDocument createDocument(Long driverId, DriverDocument document) {
        log.info("Creating document for driver: {}", driverId);

        Driver driver = driverRepository.findById(driverId)
                .orElseThrow(() -> new ResourceNotFoundException("Driver not found with id: " + driverId));

        // Validate required fields
        if (document.getName() == null || document.getName().trim().isEmpty()) {
            throw new IllegalArgumentException("Document name is required");
        }
        if (document.getCategory() == null || document.getCategory().trim().isEmpty()) {
            throw new IllegalArgumentException("Document category is required");
        }

        document.setDriver(driver);
        document.setIsRequired(Objects.requireNonNullElse(document.getIsRequired(), false));

        DriverDocument savedDocument = driverDocumentRepository.save(document);
        log.info("Document created with id: {}", savedDocument.getId());
        return savedDocument;
    }

    /**
     * Update an existing document
     */
    @Transactional
    public DriverDocument updateDocument(Long documentId, Long driverId, DriverDocumentUpdateDto documentDetails) {
        log.info("Updating document: {} for driver: {}", documentId, driverId);

        // If driverId is null, just fetch by documentId
        DriverDocument document = driverDocumentRepository.findById(documentId)
                .orElseThrow(() -> new ResourceNotFoundException("Document not found with id: " + documentId));

        // Update only the fields that are provided
        if (documentDetails.getName() != null) {
            document.setName(documentDetails.getName());
        }
        if (documentDetails.getCategory() != null) {
            document.setCategory(documentDetails.getCategory());
        }
        if (documentDetails.getExpiryDate() != null) {
            document.setExpiryDate(documentDetails.getExpiryDate());
        }
        if (documentDetails.getDescription() != null) {
            document.setDescription(documentDetails.getDescription());
        }
        if (documentDetails.getIsRequired() != null) {
            document.setIsRequired(documentDetails.getIsRequired());
        }
        if (documentDetails.getFileUrl() != null) {
            document.setFileUrl(documentDetails.getFileUrl());
        }

        DriverDocument updatedDocument = driverDocumentRepository.save(document);
        log.info("Document updated: {}", documentId);
        return updatedDocument;
    }

    /**
     * Update a document with a new file while preserving the document ID
     */
    @Transactional
    public DriverDocument updateDocumentFile(Long documentId, MultipartFile file, DriverDocumentUpdateDto documentDetails) throws IOException {
        log.info("Updating document file: {}", documentId);

        // Fetch the existing document
        DriverDocument document = driverDocumentRepository.findById(documentId)
                .orElseThrow(() -> new ResourceNotFoundException("Document not found with id: " + documentId));

        // Get the driver for file storage path
        Driver driver = document.getDriver();
        if (driver == null) {
            throw new IllegalStateException("Document " + documentId + " has no associated driver");
        }

        // Validate the new file
        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("File is empty");
        }

        log.info("New file name: {}, Size: {} bytes", file.getOriginalFilename(), file.getSize());

        // Delete the old file from disk if it exists
        String oldFileUrl = document.getFileUrl();
        if (oldFileUrl != null && !oldFileUrl.isBlank()) {
            try {
                deleteFileFromDisk(oldFileUrl);
                log.info("Old file deleted successfully: {}", oldFileUrl);
            } catch (Exception e) {
                log.warn("Failed to delete old file {}: {}", oldFileUrl, e.getMessage());
                // Continue with update even if old file deletion fails
            }
        }

        // Store the new file
        String newFileUrl = null;
        if (fileStorageService != null) {
            try {
                newFileUrl = fileStorageService.storeFileInSubfolder(file, "documents/" + driver.getId());
                log.info("New file stored successfully at: {}", newFileUrl);
            } catch (Exception e) {
                log.error("Error storing new file: {}", e.getMessage(), e);
                throw new RuntimeException("Error storing file: " + e.getMessage(), e);
            }
        } else {
            log.warn("FileStorageService is null, file will not be stored");
        }

        // Update document properties
        document.setFileUrl(newFileUrl);

        // Update metadata fields if provided
        if (documentDetails.getName() != null) {
            document.setName(documentDetails.getName());
        }
        if (documentDetails.getCategory() != null) {
            document.setCategory(documentDetails.getCategory());
        }
        if (documentDetails.getExpiryDate() != null) {
            document.setExpiryDate(documentDetails.getExpiryDate());
        }
        if (documentDetails.getDescription() != null) {
            document.setDescription(documentDetails.getDescription());
        }
        if (documentDetails.getIsRequired() != null) {
            document.setIsRequired(documentDetails.getIsRequired());
        }

        // Validate required fields
        if (document.getName() == null || document.getName().trim().isEmpty()) {
            throw new IllegalArgumentException("Document name is required");
        }
        if (document.getCategory() == null || document.getCategory().trim().isEmpty()) {
            throw new IllegalArgumentException("Document category is required");
        }

        // Save updated document
        DriverDocument updatedDocument = driverDocumentRepository.save(document);
        log.info("Document file updated successfully with id: {}", documentId);

        // Update audit metadata
        try {
            documentAuditService.createAudit(updatedDocument);
        } catch (Exception e) {
            log.warn("Failed to update audit for document {}: {}", documentId, e.getMessage());
        }

        return updatedDocument;
    }

    /**
     * Helper method to delete a file from disk
     */
    private void deleteFileFromDisk(String fileUrl) throws IOException {
        if (fileUrl == null || fileUrl.isBlank()) {
            return;
        }

        String prefixed = "/uploads/";
        String working = fileUrl.trim();

        // Normalize legacy pattern missing leading slash
        if (working.startsWith("uploads/")) {
            working = "/" + working;
        }

        java.nio.file.Path resolvedPath = null;
        if (working.startsWith(prefixed)) {
            String relative = working.substring(prefixed.length());
            java.nio.file.Path base = fileStorageProperties.getBasePath();
            resolvedPath = base.resolve(relative).normalize();
        } else {
            resolvedPath = java.nio.file.Paths.get(working).normalize();
        }

        if (resolvedPath != null && java.nio.file.Files.exists(resolvedPath)) {
            java.nio.file.Files.delete(resolvedPath);
            log.debug("Deleted file from disk: {}", resolvedPath);
        } else {
            log.warn("File not found for deletion: {}", fileUrl);
        }
    }

    /**
     * Delete a document
     */
    @Transactional
    public void deleteDocument(Long documentId, Long driverId) {
        log.info("Deleting document: {} for driver: {}", documentId, driverId);

        // If driverId is null, just check by documentId
        if (!driverDocumentRepository.existsById(documentId)) {
            throw new ResourceNotFoundException("Document not found with id: " + documentId);
        }

        driverDocumentRepository.deleteById(documentId);
        log.info("Document deleted: {}", documentId);
    }

    /**
     * Get documents by category
     */
    @Transactional(readOnly = true)
    public List<DriverDocument> getDocumentsByCategory(Long driverId, String category) {
        log.info("Fetching documents for driver: {} with category: {}", driverId, category);
        driverRepository.findById(driverId)
                .orElseThrow(() -> new ResourceNotFoundException("Driver not found with id: " + driverId));
        return driverDocumentRepository.findByDriverIdAndCategory(driverId, category);
    }

    /**
     * Get expired documents
     */
    @Transactional(readOnly = true)
    public List<DriverDocument> getExpiredDocuments(Long driverId) {
        log.info("Fetching expired documents for driver: {}", driverId);
        driverRepository.findById(driverId)
                .orElseThrow(() -> new ResourceNotFoundException("Driver not found with id: " + driverId));
        return driverDocumentRepository.findExpiredDocuments(driverId, LocalDate.now());
    }

    /**
     * Get documents expiring soon (within 30 days)
     */
    @Transactional(readOnly = true)
    public List<DriverDocument> getExpiringDocuments(Long driverId) {
        log.info("Fetching expiring documents for driver: {}", driverId);
        driverRepository.findById(driverId)
                .orElseThrow(() -> new ResourceNotFoundException("Driver not found with id: " + driverId));
        LocalDate today = LocalDate.now();
        LocalDate thirtyDaysFromNow = today.plusDays(30);
        return driverDocumentRepository.findExpiringDocuments(driverId, today, thirtyDaysFromNow);
    }

    /**
     * Get required documents
     */
    @Transactional(readOnly = true)
    public List<DriverDocument> getRequiredDocuments(Long driverId) {
        log.info("Fetching required documents for driver: {}", driverId);
        driverRepository.findById(driverId)
                .orElseThrow(() -> new ResourceNotFoundException("Driver not found with id: " + driverId));
        return driverDocumentRepository.findRequiredDocuments(driverId);
    }

    /**
     * Delete all documents for a driver (used when deleting driver)
     */
    @Transactional
    public void deleteAllDocumentsForDriver(Long driverId) {
        log.info("Deleting all documents for driver: {}", driverId);
        driverDocumentRepository.deleteByDriverId(driverId);
    }

    /**
     * Upload a document file and save document record
     */
    @Autowired
    private FileStorageService fileStorageService;

    @Autowired
    private DocumentAuditService documentAuditService;

    @Transactional
    public DriverDocument uploadDocument(Long driverId, MultipartFile file, DriverDocument document) throws IOException {
        log.info("Uploading document for driver: {}", driverId);

        // Verify driver exists
        Driver driver = driverRepository.findById(driverId)
                .orElseThrow(() -> new ResourceNotFoundException("Driver not found with id: " + driverId));

        // Validate file
        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("File is empty");
        }

        log.info("File name: {}, Size: {} bytes", file.getOriginalFilename(), file.getSize());

        // Save file to storage
        String fileUrl = null;
        if (fileStorageService != null) {
            try {
                fileUrl = fileStorageService.storeFileInSubfolder(file, "documents/" + driverId);
                log.info("File stored successfully at: {}", fileUrl);
            } catch (Exception e) {
                log.error("Error storing file: {}", e.getMessage(), e);
                throw new RuntimeException("Error storing file: " + e.getMessage(), e);
            }
        } else {
            log.warn("FileStorageService is null, file will not be stored");
        }

        // Set document properties
        document.setDriver(driver);
        document.setFileUrl(fileUrl);
        document.setIsRequired(Objects.requireNonNullElse(document.getIsRequired(), false));

        // Validate required fields before saving
        if (document.getName() == null || document.getName().trim().isEmpty()) {
            throw new IllegalArgumentException("Document name is required");
        }
        if (document.getCategory() == null || document.getCategory().trim().isEmpty()) {
            throw new IllegalArgumentException("Document category is required");
        }

        // Save document record
        DriverDocument savedDocument = driverDocumentRepository.save(document);
        log.info("Document uploaded and saved with id: {}", savedDocument.getId());

        // Create audit metadata (size, mime, checksum) post-persist
        try {
            documentAuditService.createAudit(savedDocument);
        } catch (Exception e) {
            log.warn("Failed to create audit for document {}: {}", savedDocument.getId(), e.getMessage());
        }
        return savedDocument;
    }
}
