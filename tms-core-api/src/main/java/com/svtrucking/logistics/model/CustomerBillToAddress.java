package com.svtrucking.logistics.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import java.time.Instant;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.EqualsAndHashCode;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.ToString;

@Setter
@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@ToString
@EqualsAndHashCode(onlyExplicitlyIncluded = true)
@Entity
@Table(name = "customer_bill_to_addresses")
public class CustomerBillToAddress {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  @EqualsAndHashCode.Include
  private Long id;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "customer_id", nullable = false)
  private Customer customer;

  @Column(nullable = false, length = 150)
  private String name;

  @Column(nullable = false, length = 250)
  private String address;

  @Column(length = 150)
  private String city;

  @Column(length = 120)
  private String state;

  @Column(name = "zip", length = 30)
  private String zip;

  @Column(length = 120)
  private String country;

  @Column(name = "contact_name", length = 120)
  private String contactName;

  @Column(name = "contact_phone", length = 40)
  private String contactPhone;

  @Column(length = 150)
  private String email;

  @Column(name = "tax_id", length = 80)
  private String taxId;

  @Column(columnDefinition = "TEXT")
  private String notes;

  @Column(name = "is_primary", nullable = false)
  private boolean primary;

  @Column(name = "created_at", insertable = false, updatable = false)
  private Instant createdAt;

  @Column(name = "updated_at", insertable = false, updatable = false)
  private Instant updatedAt;

  @PrePersist
  void ensureDefaults() {
    if (this.name != null) this.name = this.name.trim();
    if (this.address != null) this.address = this.address.trim();
  }

  public String getDisplayAddress() {
    StringBuilder joiner = new StringBuilder();
    if (name != null && !name.isBlank()) {
      joiner.append(name.trim());
    }
    if (address != null && !address.isBlank()) {
      if (joiner.length() > 0) joiner.append(", ");
      joiner.append(address.trim());
    }
    if (city != null && !city.isBlank()) {
      if (joiner.length() > 0) joiner.append(", ");
      joiner.append(city.trim());
    }
    if (country != null && !country.isBlank()) {
      if (joiner.length() > 0) joiner.append(", ");
      joiner.append(country.trim());
    }
    return joiner.toString();
  }

  public boolean matches(CustomerBillToAddress other) {
    if (other == null) return false;
    return getDisplayAddress().equalsIgnoreCase(other.getDisplayAddress());
  }
}
