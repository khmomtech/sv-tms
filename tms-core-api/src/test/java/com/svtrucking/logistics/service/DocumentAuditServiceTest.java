package com.svtrucking.logistics.service;

import com.svtrucking.logistics.model.DocumentAudit;
import com.svtrucking.logistics.model.DriverDocument;
import com.svtrucking.logistics.repository.DocumentAuditRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.mockito.Mockito;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

/**
 * Unit tests for {@link DocumentAuditService} focusing on checksum, size capture and integrity
 * verification logic. Uses a real temporary file and a mocked repository to avoid DB dependency.
 */
class DocumentAuditServiceTest {

    private DocumentAuditRepository auditRepository;
    private DocumentAuditService auditService;

    // We bypass FileStorageProperties path resolution by using absolute file paths in fileUrl.
    private final com.svtrucking.logistics.core.FileStorageProperties fileStorageProperties = new com.svtrucking.logistics.core.FileStorageProperties();

    @BeforeEach
    void setUp() {
        auditRepository = Mockito.mock(DocumentAuditRepository.class);
        auditService = new DocumentAuditService(auditRepository, fileStorageProperties);
    }

    @Test
    void createAudit_capturesSizeMimeAndChecksum() throws Exception {
        Path tempFile = Files.createTempFile("audit-test-", ".txt");
        Files.writeString(tempFile, "abc"); // content length 3 bytes

        DriverDocument doc = DriverDocument.builder()
                .id(1L)
                .fileUrl(tempFile.toString()) // absolute path so service uses direct resolution
                .name("test.txt")
                .category("other")
                .isRequired(false)
                .build();

        // Mock save to return entity with id
        when(auditRepository.save(any(DocumentAudit.class))).thenAnswer(invocation -> {
            DocumentAudit a = invocation.getArgument(0);
            a.setId(10L);
            return a;
        });

        DocumentAudit created = auditService.createAudit(doc);

        assertNotNull(created.getId(), "Audit id should be set by repository");
        assertEquals(3L, created.getSizeBytes(), "Size bytes mismatch");
        assertEquals("text/plain", created.getMimeType(), "Mime type should be probed as text/plain");

        // Expected SHA-256 for 'abc'
        String expectedSha256 = sha256Hex("abc".getBytes());
        assertEquals(expectedSha256, created.getChecksumSha256(), "Checksum mismatch");

        // Verify repository save was called once
        ArgumentCaptor<DocumentAudit> captor = ArgumentCaptor.forClass(DocumentAudit.class);
        verify(auditRepository, times(1)).save(captor.capture());
        assertEquals(expectedSha256, captor.getValue().getChecksumSha256());
    }

    @Test
    void verifyIntegrity_detectsTamper() throws Exception {
        Path tempFile = Files.createTempFile("audit-tamper-", ".bin");
        Files.write(tempFile, new byte[]{1,2,3,4,5});

        DriverDocument doc = DriverDocument.builder()
                .id(2L)
                .fileUrl(tempFile.toString())
                .name("sample.bin")
                .category("other")
                .isRequired(false)
                .build();

        // First create audit (mock save assigns id)
        when(auditRepository.save(any(DocumentAudit.class))).thenAnswer(invocation -> {
            DocumentAudit a = invocation.getArgument(0);
            a.setId(20L);
            return a;
        });
        DocumentAudit audit = auditService.createAudit(doc);

        // Mock repository findByDocumentId
        when(auditRepository.findByDocumentId(doc.getId())).thenReturn(Optional.of(audit));

        // Integrity should be OK initially
        assertTrue(auditService.verifyIntegrity(doc), "Integrity should pass before tampering");

        // Tamper with file content
        Files.write(tempFile, new byte[]{9,9,9,9}); // different size & checksum
        assertFalse(auditService.verifyIntegrity(doc), "Integrity should fail after tampering");
    }

    @Test
    void verifyIntegrity_returnsFalseWhenAuditMissingOrFileMissing() throws IOException {
        Path tempFile = Files.createTempFile("audit-missing-", ".dat");
        Files.writeString(tempFile, "hello");

        DriverDocument doc = DriverDocument.builder()
                .id(3L)
                .fileUrl(tempFile.toString())
                .name("missing.dat")
                .category("other")
                .isRequired(false)
                .build();

        // No audit present
        when(auditRepository.findByDocumentId(doc.getId())).thenReturn(Optional.empty());
        assertFalse(auditService.verifyIntegrity(doc), "Integrity should be false when audit missing");

        // Delete file to simulate missing disk file
        Files.deleteIfExists(tempFile);
        // Provide a stub audit now
        DocumentAudit stubAudit = DocumentAudit.builder()
                .id(30L)
                .document(doc)
                .checksumSha256("deadbeef")
                .sizeBytes(999L)
                .mimeType("application/octet-stream")
                .thumbnailAttempted(false)
                .build();
        when(auditRepository.findByDocumentId(doc.getId())).thenReturn(Optional.of(stubAudit));
        assertFalse(auditService.verifyIntegrity(doc), "Integrity should be false when file missing even if audit exists");
    }

    private static String sha256Hex(byte[] data) throws Exception {
        MessageDigest md = MessageDigest.getInstance("SHA-256");
        byte[] digest = md.digest(data);
        StringBuilder sb = new StringBuilder();
        for (byte b : digest) sb.append(String.format("%02x", b));
        return sb.toString();
    }
}
