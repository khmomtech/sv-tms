package com.svtrucking.logistics.model;

import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import java.util.StringJoiner;
import lombok.Getter;
import lombok.Setter;

@Setter
@Getter
@Entity
@Table(name = "customer_addresses")
public class CustomerAddress {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  private String name;
  private String address;
  private String city;
  private String country;
  private String postcode;
  private String scheduledTime;
  @jakarta.persistence.Column(name = "contact_name")
  private String contactName;
  @jakarta.persistence.Column(name = "contact_phone")
  private String contactPhone;
  private double longitude;
  private double latitude;
  private String type; //  "WAREHOUSE" or "DEPO"

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "customer_id")
  private Customer customer;

  public String getFullAddress() {
    StringJoiner joiner = new StringJoiner(", ");
    if (this.address != null && !this.address.isBlank()) joiner.add(this.address.trim());
    if (this.city != null && !this.city.isBlank()) joiner.add(this.city.trim());
    if (this.country != null && !this.country.isBlank()) joiner.add(this.country.trim());
    return joiner.toString();
  }
}
