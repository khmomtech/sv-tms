package com.svtrucking.logistics.model;

import com.svtrucking.logistics.enums.IncidentGroup;
import com.svtrucking.logistics.enums.IncidentSource;
import com.svtrucking.logistics.enums.IncidentStatus;
import com.svtrucking.logistics.enums.IncidentType;
import com.svtrucking.logistics.enums.IssueSeverity;
import com.svtrucking.logistics.enums.IssueStatus;
import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.ElementCollection;
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
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "driver_issues")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DriverIssue {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @Column(length = 50, unique = true)
  private String code;

  @Enumerated(EnumType.STRING)
  @Column(name = "incident_group", length = 20)
  private IncidentGroup incidentGroup;

  @Enumerated(EnumType.STRING)
  @Column(name = "incident_type", length = 50)
  private IncidentType incidentType;

  @Enumerated(EnumType.STRING)
  @Column(length = 20)
  @Builder.Default
  private IncidentSource source = IncidentSource.DRIVER_APP;

  @Enumerated(EnumType.STRING)
  @Column(name = "incident_status", length = 20)
  @Builder.Default
  private IncidentStatus incidentStatus = IncidentStatus.NEW;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "reported_by_user_id")
  private User reportedByUser;

  @Column(name = "sla_due_at")
  private LocalDateTime slaDueAt;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "driver_id", nullable = false)
  private Driver driver;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "vehicle_id")
  private Vehicle vehicle;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "dispatch_id")
  private Dispatch dispatch;

  @Column(nullable = false, length = 200)
  private String title;

  @Column(columnDefinition = "TEXT")
  private String description;

  @Enumerated(EnumType.STRING)
  @Column(length = 20)
  @Builder.Default
  private IssueSeverity severity = IssueSeverity.MEDIUM;

  @Column(length = 100)
  private String category;

  @Enumerated(EnumType.STRING)
  @Column(length = 20)
  @Builder.Default
  private IssueStatus status = IssueStatus.OPEN;

  @Column
  private Double latitude;

  @Column
  private Double longitude;

  @Column(length = 500)
  private String locationAddress;

  public String getLocation() {
    return locationAddress;
  }

  public void setLocation(String location) {
    this.locationAddress = location;
  }

  @Column
  private Double currentKm;

  @Column(columnDefinition = "TEXT")
  private String resolutionNotes;

  @Column(nullable = false)
  @Builder.Default
  private LocalDateTime reportedAt = LocalDateTime.now();

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "assigned_to")
  private User assignedTo;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "work_order_id")
  private WorkOrder workOrder;

  private LocalDateTime resolvedAt;
  private LocalDateTime createdAt;
  private LocalDateTime updatedAt;

  @Column(nullable = false)
  @Builder.Default
  private Boolean isDeleted = false;

  @ElementCollection(fetch = FetchType.EAGER)
  @Builder.Default
  private Set<String> images = new LinkedHashSet<>();

  @OneToMany(mappedBy = "driverIssue", cascade = CascadeType.ALL, orphanRemoval = true)
  @Builder.Default
  private List<DriverIssuePhoto> photos = new ArrayList<>();

  @PrePersist
  protected void onCreate() {
    if (createdAt == null) {
      createdAt = LocalDateTime.now();
    }
    if (reportedAt == null) {
      reportedAt = LocalDateTime.now();
    }
  }

  @PreUpdate
  protected void onUpdate() {
    updatedAt = LocalDateTime.now();
  }

  public void addPhoto(String photoUrl) {
    DriverIssuePhoto photo = new DriverIssuePhoto();
    photo.setDriverIssue(this);
    photo.setPhotoUrl(photoUrl);
    photos.add(photo);
  }
}
