package com.svtrucking.logistics.safety.service;

import com.svtrucking.logistics.dto.SafetyCheckAttachmentDto;
import com.svtrucking.logistics.dto.SafetyCheckDto;
import com.svtrucking.logistics.dto.requests.PublicSafetyCheckRequest;
import com.svtrucking.logistics.enums.SafetyRiskLevel;
import org.springframework.web.multipart.MultipartFile;

/**
 * Fineract-style "WritePlatformService" facade.
 *
 * <p>All state-changing operations go here.
 */
public interface SafetyCheckWritePlatformService {

  SafetyCheckDto submitPublic(PublicSafetyCheckRequest request);

  SafetyCheckDto saveDraft(SafetyCheckDto payload, Long driverId, Long actorId, String actorRole);

  SafetyCheckAttachmentDto addAttachment(
      Long safetyCheckId,
      Long itemId,
      MultipartFile file,
      Long actorId,
      String actorRole,
      Long driverId);

  SafetyCheckDto submit(Long safetyCheckId, Long driverId, Long actorId, String actorRole);

  SafetyCheckDto approve(
      Long safetyCheckId, Long actorId, String actorRole, SafetyRiskLevel riskOverride);

  SafetyCheckDto reject(Long safetyCheckId, Long actorId, String actorRole, String reason);
}

