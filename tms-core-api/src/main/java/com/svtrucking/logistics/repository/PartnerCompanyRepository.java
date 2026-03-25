package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.enums.PartnershipType;
import com.svtrucking.logistics.enums.Status;
import com.svtrucking.logistics.model.PartnerCompany;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface PartnerCompanyRepository extends JpaRepository<PartnerCompany, Long> {

  Optional<PartnerCompany> findByCompanyCode(String companyCode);

  Optional<PartnerCompany> findByBusinessLicense(String businessLicense);

  List<PartnerCompany> findByStatus(Status status);

  List<PartnerCompany> findByPartnershipType(PartnershipType partnershipType);

  @Query(
      "SELECT p FROM PartnerCompany p WHERE p.status = :status AND p.partnershipType = :type ORDER BY p.companyName")
  List<PartnerCompany> findActiveByType(
      @Param("status") Status status, @Param("type") PartnershipType type);

  @Query(
      "SELECT p FROM PartnerCompany p WHERE "
          + "LOWER(p.companyName) LIKE LOWER(CONCAT('%', :search, '%')) OR "
          + "LOWER(p.companyCode) LIKE LOWER(CONCAT('%', :search, '%')) OR "
          + "LOWER(p.email) LIKE LOWER(CONCAT('%', :search, '%'))")
  List<PartnerCompany> searchPartners(@Param("search") String search);

  boolean existsByCompanyCode(String companyCode);

  boolean existsByBusinessLicense(String businessLicense);

    boolean existsByBusinessLicenseIgnoreCase(String businessLicense);
}
