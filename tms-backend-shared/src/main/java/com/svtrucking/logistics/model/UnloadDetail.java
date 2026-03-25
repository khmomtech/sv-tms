package com.svtrucking.logistics.model;

import jakarta.persistence.CascadeType;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToMany;
import jakarta.persistence.Table;
import java.time.LocalDateTime;
import java.util.List;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
@Table(name = "unload_details")
public class UnloadDetail {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  private LocalDateTime startTime;
  private LocalDateTime endTime;

  @OneToMany(mappedBy = "unloadDetail", cascade = CascadeType.ALL, orphanRemoval = true)
  private List<UnloadProof> proofs;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "dispatch_id")
  private Dispatch dispatch;
}
