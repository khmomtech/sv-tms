package com.svtrucking.logistics.dto;

import lombok.Builder;
import lombok.Value;

@Value
@Builder
public class DocumentAuditDto {
    Long documentId;
    Long auditId;
    Long sizeBytes;
    String mimeType;
    String checksumSha256;
    boolean integrityOk;
    String thumbnailUrl;
    boolean thumbnailAttempted;
}
