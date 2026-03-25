package com.svtrucking.logistics.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.Table;
import java.time.LocalDate;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.SQLDelete;
import org.hibernate.annotations.Where;
import jakarta.persistence.FetchType;
import jakarta.persistence.OneToOne;
import jakarta.persistence.PrePersist;
import jakarta.persistence.UniqueConstraint;

@Entity
@Table(
    name = "driver_licenses",
    uniqueConstraints = {@UniqueConstraint(columnNames = "license_number")})
@SQLDelete(sql = "UPDATE driver_licenses SET deleted = true WHERE id = ?")
@Where(clause = "deleted = false")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DriverLicense {
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @OneToOne(fetch = FetchType.LAZY, optional = false)
  @JoinColumn(name = "driver_id", nullable = false)
  private Driver driver;

  @Column(name = "license_number", nullable = false, unique = true, length = 50)
  private String licenseNumber;

  @Column(name = "license_class", length = 3)
  private String licenseClass; // Cambodia: A1, A, B1, B, C, C1, D, E

  @Column(name = "issued_date")
  private LocalDate issuedDate;

  @Column(name = "expiry_date")
  private LocalDate expiryDate;

  @Column(name = "issuing_authority", length = 100)
  private String issuingAuthority;

  @Column(name = "license_image_url", length = 255)
  private String licenseImageUrl;

  @Column(name = "license_front_image", length = 255)
  private String licenseFrontImage;

  @Column(name = "license_back_image", length = 255)
  private String licenseBackImage;

  @Column(name = "notes", length = 255)
  private String notes;

  @SQLDelete(sql = "UPDATE driver_licenses SET deleted = true WHERE id = ?")
  @Where(clause = "deleted = false")
  @Column(name = "deleted", nullable = false)
  private boolean deleted = false;

  @PrePersist
  public void onCreate() {
    if (this.issuedDate == null) {
      this.issuedDate = LocalDate.now();
    }
  }

  public boolean isExpired() {
    return expiryDate != null && expiryDate.isBefore(LocalDate.now());
  }
}
