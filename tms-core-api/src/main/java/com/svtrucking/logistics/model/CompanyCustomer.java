package com.svtrucking.logistics.model;

import jakarta.persistence.Entity;
import jakarta.persistence.PrimaryKeyJoinColumn;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

// Company Customer
@Data
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "company_customers")
@PrimaryKeyJoinColumn(name = "customer_id")
public class CompanyCustomer extends Customer {
  private String companyName;
  private String registrationNumber;
  private String taxId;
  private String industry;
  private String contactPerson;
  private String contactPersonPhone;
  private String contactPersonEmail;
}
