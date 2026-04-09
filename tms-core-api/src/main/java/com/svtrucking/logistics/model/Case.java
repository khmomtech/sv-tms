package com.svtrucking.logistics.model;

import com.svtrucking.logistics.enums.CaseCategory;
import com.svtrucking.logistics.enums.CaseStatus;
import com.svtrucking.logistics.enums.IssueSeverity;
import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToMany;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "cases")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Case {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @Column(length = 50, nullable = false, unique = true)
  private String code; // CASE-2025-0041

  @Column(length = 300, nullable = false)
  private String title;

  @Column(columnDefinition = "TEXT")
  private String description;

  @Enumerated(EnumType.STRING)
  @Column(length = 30, nullable = false)
  private CaseCategory category;

  @Enumerated(EnumType.STRING)
  @Column(length = 20, nullable = false)
  @Builder.Default
  private IssueSeverity severity = IssueSeverity.MEDIUM;

  @Enumerated(EnumType.STRING)
  @Column(length = 30, nullable = false)
  @Builder.Default
  private CaseStatus status = CaseStatus.OPEN;

  // Assignment
  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "assigned_to_user_id")
  private User assignedToUser;

  @Column(length = 100)
  private String assignedTeam;

  // Related entities
  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "driver_id")
  private Driver driver;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "vehicle_id")
  private Vehicle vehicle;

  // SLA tracking
  @Column(name = "sla_target_at")
  private LocalDateTime slaTargetAt;

  // Audit fields
  @Column(nullable = false)
  @Builder.Default
  private LocalDateTime createdAt = LocalDateTime.now();

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "created_by_user_id")
  private User createdByUser;

  private LocalDateTime updatedAt;
  private LocalDateTime closedAt;

  @Column(nullable = false)
  @Builder.Default
  private Boolean isDeleted = false;

  // Relationships
  @OneToMany(mappedBy = "caseEntity", cascade = CascadeType.ALL, orphanRemoval = true)
  @Builder.Default
  private List<CaseIncident> caseIncidents = new ArrayList<>();

  @OneToMany(mappedBy = "caseEntity", cascade = CascadeType.ALL, orphanRemoval = true)
  @Builder.Default
  private List<CaseTask> tasks = new ArrayList<>();

  @OneToMany(mappedBy = "caseEntity", cascade = CascadeType.ALL, orphanRemoval = true)
  @Builder.Default
  private List<CaseTimeline> timeline = new ArrayList<>();

  @OneToMany(mappedBy = "caseEntity", cascade = CascadeType.ALL, orphanRemoval = true)
  @Builder.Default
  private List<CaseAttachment> attachments = new ArrayList<>();

  @PrePersist
  protected void onCreate() {
    if (createdAt == null) {
      createdAt = LocalDateTime.now();
    }
  }

  @PreUpdate
  protected void onUpdate() {
    updatedAt = LocalDateTime.now();
  }

  // Helper methods
  public void addIncident(DriverIssue incident, User linkedByUser, String notes) {
    CaseIncident caseIncident = CaseIncident.builder()
        .caseEntity(this)
        .incident(incident)
        .linkedByUser(linkedByUser)
        .notes(notes)
        .build();
    caseIncidents.add(caseIncident);
  }

  public void addTask(String title, String description, User owner, LocalDateTime dueAt, User createdBy) {
    CaseTask task = CaseTask.builder()
        .caseEntity(this)
        .title(title)
        .description(description)
        .ownerUser(owner)
        .dueAt(dueAt)
        .createdByUser(createdBy)
        .build();
    tasks.add(task);
  }

  public void addTimelineEntry(com.svtrucking.logistics.enums.TimelineEntryType type, String message, User createdBy) {
    CaseTimeline entry = CaseTimeline.builder()
        .caseEntity(this)
        .entryType(type)
        .message(message)
        .createdByUser(createdBy)
        .build();
    timeline.add(entry);
  }

  public void addAttachment(String fileName, String filePath, Long fileSize, String mimeType, String description, User uploadedBy) {
    CaseAttachment attachment = CaseAttachment.builder()
        .caseEntity(this)
        .fileName(fileName)
        .filePath(filePath)
        .fileSize(fileSize)
        .mimeType(mimeType)
        .description(description)
        .uploadedByUser(uploadedBy)
        .build();
    attachments.add(attachment);
  }
}
