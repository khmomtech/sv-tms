package com.svtrucking.logistics.model;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import java.time.LocalDateTime;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Links users with PARTNER_ADMIN role to their partner companies.
 * Defines what permissions they have within their company.
 */
@Entity
@Table(
    name = "partner_admins",
    uniqueConstraints = {
      @UniqueConstraint(
          name = "uk_user_company",
          columnNames = {"user_id", "partner_company_id"})
    })
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
public class PartnerAdmin {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "user_id", nullable = false)
  private User user;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "partner_company_id", nullable = false)
  private PartnerCompany partnerCompany;

  /** Can view and manage drivers from this partner company */
  @Column(name = "can_manage_drivers", nullable = false)
  @Builder.Default
  private Boolean canManageDrivers = true;

  /** Can view and manage customers from this partner company */
  @Column(name = "can_manage_customers", nullable = false)
  @Builder.Default
  private Boolean canManageCustomers = false;

  /** Can view financial reports for this partner */
  @Column(name = "can_view_reports", nullable = false)
  @Builder.Default
  private Boolean canViewReports = true;

  /** Can manage partner company settings */
  @Column(name = "can_manage_settings", nullable = false)
  @Builder.Default
  private Boolean canManageSettings = false;

  /** Is primary admin for this partner company */
  @Column(name = "is_primary", nullable = false)
  @Builder.Default
  private Boolean isPrimary = false;

  @Column(name = "created_at", updatable = false)
  @Builder.Default
  private LocalDateTime createdAt = LocalDateTime.now();

  @Column(name = "created_by", length = 100)
  private String createdBy;
}
