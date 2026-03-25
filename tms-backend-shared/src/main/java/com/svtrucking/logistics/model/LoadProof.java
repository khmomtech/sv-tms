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
import jakarta.persistence.OneToOne;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
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
@Table(
    name = "load_proof",
    uniqueConstraints = {@UniqueConstraint(columnNames = "dispatch_id")})
public class LoadProof {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  private String remarks;

  @ElementCollection
  @CollectionTable(name = "load_proof_images", joinColumns = @JoinColumn(name = "load_proof_id"))
  @Column(name = "image_path")
  private List<String> proofImagePaths;

  private String signaturePath;
  private LocalDateTime uploadedAt;

  @OneToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "dispatch_id", unique = true)
  private Dispatch dispatch;

  @PrePersist
  public void onCreate() {
    if (uploadedAt == null) {
      uploadedAt = LocalDateTime.now();
    }
  }
}
