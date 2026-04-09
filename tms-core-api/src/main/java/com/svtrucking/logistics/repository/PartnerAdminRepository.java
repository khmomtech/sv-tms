package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.PartnerAdmin;
import com.svtrucking.logistics.model.PartnerCompany;
import com.svtrucking.logistics.model.User;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface PartnerAdminRepository extends JpaRepository<PartnerAdmin, Long> {

  List<PartnerAdmin> findByUser(User user);

  List<PartnerAdmin> findByPartnerCompany(PartnerCompany partnerCompany);

  Optional<PartnerAdmin> findByUserAndPartnerCompany(User user, PartnerCompany partnerCompany);

  @Query("SELECT pa FROM PartnerAdmin pa WHERE pa.user.id = :userId")
  List<PartnerAdmin> findByUserId(@Param("userId") Long userId);

  @Query("SELECT pa FROM PartnerAdmin pa WHERE pa.partnerCompany.id = :companyId")
  List<PartnerAdmin> findByCompanyId(@Param("companyId") Long companyId);

  @Query(
      "SELECT pa FROM PartnerAdmin pa WHERE pa.partnerCompany.id = :companyId AND pa.isPrimary = true")
  Optional<PartnerAdmin> findPrimaryAdminByCompanyId(@Param("companyId") Long companyId);

  boolean existsByUserAndPartnerCompany(User user, PartnerCompany partnerCompany);
}
