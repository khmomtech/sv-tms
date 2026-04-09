package com.svtrucking.logistics.service;

import com.svtrucking.logistics.model.DocumentAudit;
import com.svtrucking.logistics.model.DriverDocument;
import com.svtrucking.logistics.repository.DocumentAuditRepository;
import com.svtrucking.logistics.core.FileStorageProperties;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.DigestInputStream;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

@Service
@RequiredArgsConstructor
@Slf4j
public class DocumentAuditService {

    private final DocumentAuditRepository auditRepository;
    private final FileStorageProperties fileStorageProperties;

    /** Create or update audit metadata for a document after file storage. */
    @Transactional
    public DocumentAudit createAudit(DriverDocument doc) {
        if (doc.getFileUrl() == null) {
            throw new IllegalArgumentException("Document has no fileUrl to audit");
        }
        // Derive path similar to DriverDocumentService logic
        Path path = resolveStoredPath(doc.getFileUrl());
        if (!Files.exists(path)) {
            log.warn("Cannot create audit: file missing for document {} path={} url={}", doc.getId(), path, doc.getFileUrl());
            throw new IllegalStateException("File missing for audit creation");
        }
        long size = safeSize(path);
        String mime = safeProbeMime(path);
        String checksum = computeSha256(path);

        // Check if audit already exists and update it instead of creating new one
        DocumentAudit audit = auditRepository.findByDocumentId(doc.getId()).orElse(null);
        if (audit != null) {
            // Update existing audit
            audit.setSizeBytes(size);
            audit.setMimeType(mime);
            audit.setChecksumSha256(checksum);
            // Reset thumbnail info since file changed
            audit.setThumbnailUrl(null);
            audit.setThumbnailPath(null);
            audit.setThumbnailAttempted(false);
            audit = auditRepository.save(audit);
            log.info("Updated audit for document {} (size={}, mime={}, sha256={})", doc.getId(), size, mime, checksum);
        } else {
            // Create new audit
            audit = DocumentAudit.builder()
                    .document(doc)
                    .sizeBytes(size)
                    .mimeType(mime)
                    .checksumSha256(checksum)
                    .thumbnailAttempted(false)
                    .build();
            audit = auditRepository.save(audit);
            log.info("Created audit for document {} (size={}, mime={}, sha256={})", doc.getId(), size, mime, checksum);
        }
        return audit;
    }

    @Transactional(readOnly = true)
    public DocumentAudit getAudit(Long documentId) {
        return auditRepository.findByDocumentId(documentId).orElse(null);
    }

    @Transactional(readOnly = true)
    public boolean verifyIntegrity(DriverDocument doc) {
        DocumentAudit audit = getAudit(doc.getId());
        if (audit == null) return false; // treat missing audit as unverifiable
        Path path = resolveStoredPath(doc.getFileUrl());
        if (!Files.exists(path)) return false;
        String currentChecksum = computeSha256(path);
        long currentSize = safeSize(path);
        boolean ok = audit.getChecksumSha256().equalsIgnoreCase(currentChecksum) && audit.getSizeBytes() == currentSize;
        if (!ok) {
            log.error("Integrity mismatch for document {} expected(size={},sha256={}) actual(size={},sha256={})", doc.getId(), audit.getSizeBytes(), audit.getChecksumSha256(), currentSize, currentChecksum);
        }
        return ok;
    }

    private Path resolveStoredPath(String fileUrl) {
        String working = fileUrl.trim();
        if (working.startsWith("uploads/")) working = "/" + working; // normalize legacy
        if (working.startsWith("/uploads/")) {
            String relative = working.substring("/uploads/".length());
            return fileStorageProperties.getBasePath().resolve(relative).normalize();
        }
        return Path.of(working).normalize();
    }

    private long safeSize(Path path) {
        try { return Files.size(path); } catch (IOException e) { return -1L; }
    }

    private String safeProbeMime(Path path) {
        try {
            String mime = Files.probeContentType(path);
            return mime != null ? mime : "application/octet-stream";
        } catch (IOException e) {
            return "application/octet-stream";
        }
    }

    private String computeSha256(Path path) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            try (InputStream is = Files.newInputStream(path); DigestInputStream dis = new DigestInputStream(is, md)) {
                byte[] buffer = new byte[8192];
                while (dis.read(buffer) != -1) { /* stream to digest */ }
            }
            byte[] digest = md.digest();
            StringBuilder sb = new StringBuilder();
            for (byte b : digest) sb.append(String.format("%02x", b));
            return sb.toString();
        } catch (NoSuchAlgorithmException | IOException e) {
            throw new RuntimeException("Failed to compute SHA-256", e);
        }
    }
}
