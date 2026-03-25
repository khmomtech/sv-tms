package com.svtrucking.logistics.model;

import com.svtrucking.logistics.enums.TimelineEntryType;
import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "case_timeline")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CaseTimeline {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "case_id", nullable = false)
  private Case caseEntity;

  @Enumerated(EnumType.STRING)
  @Column(name = "entry_type", length = 30, nullable = false)
  private TimelineEntryType entryType;

  @Column(columnDefinition = "TEXT", nullable = false)
  private String message;

  @Column(nullable = false)
  @Builder.Default
  private LocalDateTime createdAt = LocalDateTime.now();

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "created_by_user_id")
  private User createdByUser;

  @Column(columnDefinition = "JSON")
  private String metadata; // JSON string for additional data

  @PrePersist
  protected void onCreate() {
    if (createdAt == null) {
      createdAt = LocalDateTime.now();
    }
  }
}
