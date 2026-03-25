package com.svtrucking.logistics.model;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.svtrucking.logistics.enums.PartnershipType;
import com.svtrucking.logistics.enums.Status;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.LocalDate;
import java.time.LocalDateTime;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Represents a partner company in the TMS system.
 * Partners can provide drivers, be customers, or both.
 */
@Entity
@Table(name = "partner_companies")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
public class PartnerCompany {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @Column(nullable = false, unique = true, length = 50)
  private String companyCode; // e.g., "PART-001"

  @Column(nullable = false, length = 255)
  private String companyName;

  @Column(unique = true, length = 100)
  private String businessLicense; // Tax ID or Business Registration Number

  @Column(length = 255)
  private String contactPerson;

  @Column(nullable = false, length = 255)
  private String email;

  @Column(nullable = false, length = 50)
  private String phone;

  @Column(columnDefinition = "TEXT")
  private String address;

  @Enumerated(EnumType.STRING)
  @Column(nullable = false, length = 30)
  private PartnershipType partnershipType;

  @Enumerated(EnumType.STRING)
  @Column(nullable = false, length = 20)
  @Builder.Default
  private Status status = Status.ACTIVE;

  @Column(name = "contract_start_date")
  private LocalDate contractStartDate;

  @Column(name = "contract_end_date")
  private LocalDate contractEndDate;

  /** Revenue sharing percentage (0-100) */
  @Column(name = "commission_rate")
  private Double commissionRate; // e.g., 15.5 means 15.5%

  /** Credit limit for corporate customers (in USD or local currency) */
  @Column(name = "credit_limit")
  private Double creditLimit;

  @Column(columnDefinition = "TEXT")
  private String notes;

  @Column(name = "logo_url", length = 500)
  private String logoUrl;

  @Column(name = "website", length = 255)
  private String website;

  @Column(name = "created_at", updatable = false)
  @Builder.Default
  private LocalDateTime createdAt = LocalDateTime.now();

  @Column(name = "updated_at")
  @Builder.Default
  private LocalDateTime updatedAt = LocalDateTime.now();

  @Column(name = "created_by", length = 100)
  private String createdBy;

  @Column(name = "updated_by", length = 100)
  private String updatedBy;
}
