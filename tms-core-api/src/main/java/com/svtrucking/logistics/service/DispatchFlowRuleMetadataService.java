package com.svtrucking.logistics.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.svtrucking.logistics.dto.dispatchflow.DispatchFlowProofPolicyDto;
import com.svtrucking.logistics.enums.DispatchStatus;
import com.svtrucking.logistics.model.DispatchFlowTransitionRule;
import java.util.EnumSet;
import java.util.List;
import java.util.Set;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
@Slf4j
public class DispatchFlowRuleMetadataService {

  private static final Set<String> ROOT_PROOF_POLICY_FIELDS =
      Set.of(
          "proofRequired",
          "requiredInputType",
          "proofType",
          "proofSubmissionAllowedStatuses",
          "proofSubmissionMode",
          "autoAdvanceStatusAfterProof",
          "proofReviewRequired",
          "allowLateProofRecovery",
          "blockMessage",
          "blockCode",
          "minImages",
          "maxImages",
          "signatureRequired",
          "locationRequired",
          "remarksRequired",
          "maxFileSizeBytes",
          "mimeTypes");

  private final ObjectMapper objectMapper;

  public DispatchFlowProofPolicyDto parseProofPolicy(String metadataJson) {
    if (metadataJson == null || metadataJson.isBlank()) {
      return null;
    }

    try {
      JsonNode root = objectMapper.readTree(metadataJson);
      if (root == null || root.isNull() || !root.isObject()) {
        return null;
      }
      if (root.has("proofPolicy") && root.get("proofPolicy").isObject()) {
        return objectMapper.treeToValue(root.get("proofPolicy"), DispatchFlowProofPolicyDto.class);
      }
      for (String field : ROOT_PROOF_POLICY_FIELDS) {
        if (root.has(field)) {
          return objectMapper.treeToValue(root, DispatchFlowProofPolicyDto.class);
        }
      }
      return null;
    } catch (Exception ex) {
      log.warn("Failed to parse dispatch flow metadata_json proofPolicy: {}", ex.getMessage());
      return null;
    }
  }

  public String mergeProofPolicy(String metadataJson, DispatchFlowProofPolicyDto proofPolicy) {
    ObjectNode root = objectNode(metadataJson);
    ROOT_PROOF_POLICY_FIELDS.forEach(root::remove);
    if (proofPolicy == null) {
      root.remove("proofPolicy");
    } else {
      root.set("proofPolicy", objectMapper.valueToTree(proofPolicy));
    }

    if (root.isEmpty()) {
      return null;
    }

    try {
      return objectMapper.writeValueAsString(root);
    } catch (JsonProcessingException ex) {
      throw new IllegalArgumentException("Invalid dispatch flow metadata", ex);
    }
  }

  public DispatchFlowProofPolicyDto resolveProofPolicyForRule(DispatchFlowTransitionRule rule) {
    if (rule == null) {
      return null;
    }

    DispatchFlowProofPolicyDto configured = parseProofPolicy(rule.getMetadataJson());
    if (configured != null) {
      normalize(configured, rule.getToStatus());
      if (Boolean.TRUE.equals(configured.getProofRequired())
          || !"NONE".equalsIgnoreCase(safeRequiredInput(configured.getRequiredInputType()))) {
        return configured;
      }
    }

    return defaultProofPolicy(rule.getToStatus());
  }

  public DispatchFlowProofPolicyDto defaultProofPolicy(DispatchStatus toStatus) {
    if (toStatus == DispatchStatus.LOADED) {
      return DispatchFlowProofPolicyDto.builder()
          .proofRequired(Boolean.TRUE)
          .requiredInputType("POL")
          .proofType("POL")
          .proofSubmissionMode("DURING_STAGE")
          .proofSubmissionAllowedStatuses(List.of(DispatchStatus.LOADING, DispatchStatus.LOADED))
          .autoAdvanceStatusAfterProof(DispatchStatus.LOADED)
          .allowLateProofRecovery(Boolean.TRUE)
          .blockCode("POL_REQUIRED")
          .blockMessage("Submit POL (proof of loading) to mark as loaded.")
          .minImages(1)
          .build();
    }

    if (toStatus == DispatchStatus.UNLOADED) {
      return DispatchFlowProofPolicyDto.builder()
          .proofRequired(Boolean.TRUE)
          .requiredInputType("POD")
          .proofType("POD")
          .proofSubmissionMode("DURING_STAGE")
          .proofSubmissionAllowedStatuses(
              List.of(
                  DispatchStatus.ARRIVED_UNLOADING,
                  DispatchStatus.UNLOADING,
                  DispatchStatus.UNLOADED,
                  DispatchStatus.DELIVERED,
                  DispatchStatus.FINANCIAL_LOCKED,
                  DispatchStatus.CLOSED,
                  DispatchStatus.COMPLETED))
          .autoAdvanceStatusAfterProof(DispatchStatus.UNLOADED)
          .allowLateProofRecovery(Boolean.TRUE)
          .blockCode("POD_REQUIRED")
          .blockMessage("Submit POD before completing delivery.")
          .minImages(1)
          .build();
    }

    return null;
  }

  public DispatchFlowProofPolicyDto defaultProofPolicyForType(String proofType) {
    if ("POL".equalsIgnoreCase(proofType)) {
      return defaultProofPolicy(DispatchStatus.LOADED);
    }
    if ("POD".equalsIgnoreCase(proofType)) {
      return defaultProofPolicy(DispatchStatus.UNLOADED);
    }
    return null;
  }

  private void normalize(DispatchFlowProofPolicyDto proofPolicy, DispatchStatus toStatus) {
    if (proofPolicy.getRequiredInputType() == null || proofPolicy.getRequiredInputType().isBlank()) {
      proofPolicy.setRequiredInputType(proofPolicy.getProofType() != null ? proofPolicy.getProofType() : "NONE");
    }
    if (proofPolicy.getProofType() == null || proofPolicy.getProofType().isBlank()) {
      proofPolicy.setProofType(proofPolicy.getRequiredInputType());
    }
    if (proofPolicy.getProofRequired() == null) {
      proofPolicy.setProofRequired(!"NONE".equalsIgnoreCase(safeRequiredInput(proofPolicy.getRequiredInputType())));
    }
    if (proofPolicy.getAllowLateProofRecovery() == null) {
      proofPolicy.setAllowLateProofRecovery(Boolean.FALSE);
    }
    if (proofPolicy.getProofReviewRequired() == null) {
      proofPolicy.setProofReviewRequired(Boolean.FALSE);
    }
    if (proofPolicy.getSignatureRequired() == null) {
      proofPolicy.setSignatureRequired(Boolean.FALSE);
    }
    if (proofPolicy.getLocationRequired() == null) {
      proofPolicy.setLocationRequired(Boolean.FALSE);
    }
    if (proofPolicy.getRemarksRequired() == null) {
      proofPolicy.setRemarksRequired(Boolean.FALSE);
    }
    if ((proofPolicy.getProofSubmissionAllowedStatuses() == null
            || proofPolicy.getProofSubmissionAllowedStatuses().isEmpty())
        && toStatus != null) {
      DispatchFlowProofPolicyDto defaults = defaultProofPolicy(toStatus);
      if (defaults != null) {
        proofPolicy.setProofSubmissionAllowedStatuses(defaults.getProofSubmissionAllowedStatuses());
      }
    }
    if (proofPolicy.getAutoAdvanceStatusAfterProof() == null && toStatus != null) {
      proofPolicy.setAutoAdvanceStatusAfterProof(toStatus);
    }
  }

  private ObjectNode objectNode(String metadataJson) {
    if (metadataJson == null || metadataJson.isBlank()) {
      return objectMapper.createObjectNode();
    }
    try {
      JsonNode node = objectMapper.readTree(metadataJson);
      if (node != null && node.isObject()) {
        return (ObjectNode) node.deepCopy();
      }
    } catch (JsonProcessingException ex) {
      log.warn("Unable to preserve existing metadata_json, replacing it: {}", ex.getMessage());
    }
    return objectMapper.createObjectNode();
  }

  private String safeRequiredInput(String value) {
    return value == null ? "NONE" : value;
  }
}
