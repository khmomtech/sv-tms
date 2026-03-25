package com.svtrucking.logistics.model;

import com.svtrucking.logistics.enums.VehicleDocumentType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.FetchType;
import jakarta.persistence.Table;
import java.time.LocalDateTime;
import java.util.Date;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
@Table(name = "vehicle_documents")
public class VehicleDocument {
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "vehicle_id")
  @com.fasterxml.jackson.annotation.JsonIgnore
  private Vehicle vehicle;

  @Enumerated(EnumType.STRING)
  @Column(name = "document_type", nullable = false, length = 32)
  private VehicleDocumentType documentType;

  @Column(name = "document_url")
  private String documentUrl;

  @Column(name = "document_number", length = 80)
  private String documentNumber;

  @Column(name = "issue_date")
  private Date issueDate;

  @Column(name = "expiry_date")
  private Date expiryDate;

  @Column(name = "is_approved")
  private boolean isApproved;

  @Column(name = "notes", length = 2000)
  private String notes;

  @Column(name = "created_at", updatable = false)
  private LocalDateTime createdAt;

  @Column(name = "updated_at")
  private LocalDateTime updatedAt;

  @Column(name = "updated_by", length = 100)
  private String updatedBy;

  @Column(name = "deleted")
  private Boolean deleted;
}
