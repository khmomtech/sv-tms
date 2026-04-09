package com.svtrucking.logistics.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.svtrucking.logistics.model.UnloadProof;
import java.time.LocalDateTime;
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
public class UnloadProofDto {

  private Long id;
  private Long dispatchId;

  private String remarks;
  private String address;

  private Double latitude;
  private Double longitude;

  private List<String> proofImagePaths;
  private String signaturePath;

  private LocalDateTime submittedAt;

  public static UnloadProofDto fromEntity(UnloadProof proof) {
    return UnloadProofDto.builder()
        .id(proof.getId())
        .dispatchId(proof.getDispatch().getId())
        .remarks(proof.getRemarks())
        .address(proof.getAddress())
        .latitude(proof.getLatitude())
        .longitude(proof.getLongitude())
        .proofImagePaths(
            proof.getProofImagePaths() != null
                ? List.copyOf(proof.getProofImagePaths())
                : List.of())
        .signaturePath(proof.getSignaturePath())
        .submittedAt(proof.getSubmittedAt())
        .build();
  }

  //  Added helper getters to access image and signature
  public List<String> getImageUrls() {
    return this.proofImagePaths;
  }

  public String getSignatureUrl() {
    return this.signaturePath;
  }
}
