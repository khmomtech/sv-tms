package com.svtrucking.logistics.model;

import jakarta.persistence.CollectionTable;
import jakarta.persistence.Column;
import jakarta.persistence.ElementCollection;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
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
@Entity
public class UnloadProof {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  private String remarks;
  private String address;
  private Double latitude;
  private Double longitude;

  @ElementCollection
  @CollectionTable(
      name = "unload_proof_images",
      joinColumns = @JoinColumn(name = "unload_proof_id"))
  @Column(name = "image_path")
  private List<String> proofImagePaths;

  private String signaturePath;
  private LocalDateTime submittedAt;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "unload_detail_id")
  private UnloadDetail unloadDetail;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "dispatch_id")
  private Dispatch dispatch;
}
