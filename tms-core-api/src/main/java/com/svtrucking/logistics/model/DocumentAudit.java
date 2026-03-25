package com.svtrucking.logistics.model;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;

/**
 * Audit metadata for a stored driver document. Captures immutable file attributes
 * (size, checksum, original mime type) at upload time plus optional derived assets
 * like a generated thumbnail. Used later to validate download integrity and to
 * accelerate preview rendering.
 */
@Entity
@Table(name = "driver_document_audit")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DocumentAudit {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "document_id", nullable = false, unique = true)
    private DriverDocument document;

    /** SHA-256 hex checksum of the stored file content at upload time */
    @Column(name = "checksum_sha256", length = 64, nullable = false)
    private String checksumSha256;

    /** File size in bytes at upload time */
    @Column(name = "size_bytes", nullable = false)
    private Long sizeBytes;

    /** Detected MIME type (from MultipartFile contentType or probe) */
    @Column(name = "mime_type", length = 128, nullable = false)
    private String mimeType;

    /** Public URL to generated thumbnail asset (if created) */
    @Column(name = "thumbnail_url", length = 500)
    private String thumbnailUrl;

    /** Path on disk to thumbnail (for maintenance / regeneration) */
    @Column(name = "thumbnail_path", length = 500)
    private String thumbnailPath;

    /** True if thumbnail generation attempted (prevents repeated failures spam) */
    @Column(name = "thumbnail_attempted", nullable = false)
    private boolean thumbnailAttempted;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}
