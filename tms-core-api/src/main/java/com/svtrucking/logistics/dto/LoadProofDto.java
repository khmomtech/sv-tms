package com.svtrucking.logistics.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.svtrucking.logistics.model.LoadProof;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Collections;
import java.util.List;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class LoadProofDto {

  private Long id;
  private Long dispatchId;
  private String routeCode;
  private String driverName;
  private String remarks;
  private List<String> proofImagePaths;
  private String signaturePath;
  private String uploadedAt;

  public static LoadProofDto fromEntity(LoadProof proof) {
    LocalDateTime uploadedTime =
        proof.getUploadedAt() != null ? proof.getUploadedAt() : LocalDateTime.now(); // fallback

    return LoadProofDto.builder()
        .id(proof.getId())
        .dispatchId(proof.getDispatch() != null ? proof.getDispatch().getId() : null)
        .routeCode(proof.getDispatch() != null ? proof.getDispatch().getRouteCode() : null)
        .driverName(
            proof.getDispatch() != null && proof.getDispatch().getDriver() != null
                ? proof.getDispatch().getDriver().getName()
                : "Unknown")
        .remarks(proof.getRemarks())
        .proofImagePaths(
            proof.getProofImagePaths() != null
                ? List.copyOf(proof.getProofImagePaths())
                : Collections.emptyList())
        .signaturePath(proof.getSignaturePath())
        .uploadedAt(uploadedTime.format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm")))
        .build();
  }

  public List<String> getImageUrls() {
    return proofImagePaths;
  }

  public String getSignatureUrl() {
    return signaturePath;
  }
}
