package com.svtrucking.logistics.service;

import com.svtrucking.logistics.enums.RoleType;
import com.svtrucking.logistics.model.PartnerAdmin;
import com.svtrucking.logistics.model.PartnerCompany;
import com.svtrucking.logistics.model.User;
import com.svtrucking.logistics.repository.PartnerAdminRepository;
import java.time.LocalDateTime;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class PartnerAdminService {

  private final PartnerAdminRepository partnerAdminRepository;
  private final UserService userService;
  private final PartnerCompanyService partnerCompanyService;

  @Transactional(readOnly = true)
  public List<PartnerAdmin> getAdminsByCompany(Long companyId) {
    return partnerAdminRepository.findByCompanyId(companyId);
  }

  @Transactional(readOnly = true)
  public List<PartnerAdmin> getCompaniesByUser(Long userId) {
    return partnerAdminRepository.findByUserId(userId);
  }

  @Transactional(readOnly = true)
  public PartnerAdmin getPrimaryAdmin(Long companyId) {
    return partnerAdminRepository
        .findPrimaryAdminByCompanyId(companyId)
        .orElseThrow(
            () -> new RuntimeException("No primary admin found for company ID: " + companyId));
  }

  @Transactional
  public PartnerAdmin assignAdminToCompany(
      Long userId, Long companyId, Boolean isPrimary, String createdBy) {
    User user = userService.getUserById(userId).orElseThrow(
        () -> new RuntimeException("User not found with ID: " + userId));
    PartnerCompany company = partnerCompanyService.getPartnerById(companyId);

    // Check if user has PARTNER_ADMIN role
    boolean hasRole =
        user.getRoles().stream().anyMatch(role -> role.getName() == RoleType.PARTNER_ADMIN);
    if (!hasRole) {
      throw new RuntimeException("User must have PARTNER_ADMIN role");
    }

    // Check if already assigned
    if (partnerAdminRepository.existsByUserAndPartnerCompany(user, company)) {
      throw new RuntimeException("User is already an admin for this company");
    }

    // If setting as primary, unset other primary admins
    if (isPrimary != null && isPrimary) {
      PartnerAdmin currentPrimary =
          partnerAdminRepository.findPrimaryAdminByCompanyId(companyId).orElse(null);
      if (currentPrimary != null) {
        currentPrimary.setIsPrimary(false);
        partnerAdminRepository.save(currentPrimary);
      }
    }

    PartnerAdmin admin =
        PartnerAdmin.builder()
            .user(user)
            .partnerCompany(company)
            .isPrimary(isPrimary != null ? isPrimary : false)
            .canManageDrivers(true)
            .canManageCustomers(false)
            .canViewReports(true)
            .canManageSettings(false)
            .createdAt(LocalDateTime.now())
            .createdBy(createdBy)
            .build();

    return partnerAdminRepository.save(admin);
  }

  @Transactional
  public PartnerAdmin updatePermissions(
      Long adminId,
      Boolean canManageDrivers,
      Boolean canManageCustomers,
      Boolean canViewReports,
      Boolean canManageSettings,
      Boolean isPrimary) {
    PartnerAdmin admin =
        partnerAdminRepository
            .findById(adminId)
            .orElseThrow(() -> new RuntimeException("Partner admin not found with ID: " + adminId));

    if (canManageDrivers != null) {
      admin.setCanManageDrivers(canManageDrivers);
    }
    if (canManageCustomers != null) {
      admin.setCanManageCustomers(canManageCustomers);
    }
    if (canViewReports != null) {
      admin.setCanViewReports(canViewReports);
    }
    if (canManageSettings != null) {
      admin.setCanManageSettings(canManageSettings);
    }
    if (isPrimary != null && isPrimary) {
      // Unset other primary admins for this company
      PartnerAdmin currentPrimary =
          partnerAdminRepository
              .findPrimaryAdminByCompanyId(admin.getPartnerCompany().getId())
              .orElse(null);
      if (currentPrimary != null && !currentPrimary.getId().equals(adminId)) {
        currentPrimary.setIsPrimary(false);
        partnerAdminRepository.save(currentPrimary);
      }
      admin.setIsPrimary(true);
    } else if (isPrimary != null) {
      admin.setIsPrimary(false);
    }

    return partnerAdminRepository.save(admin);
  }

  @Transactional
  public void removeAdminFromCompany(Long adminId) {
    PartnerAdmin admin =
        partnerAdminRepository
            .findById(adminId)
            .orElseThrow(() -> new RuntimeException("Partner admin not found with ID: " + adminId));

    partnerAdminRepository.delete(admin);
  }

  /**
   * Check if user can manage drivers for a specific partner company
   */
  @Transactional(readOnly = true)
  public boolean canManageDrivers(Long userId, Long companyId) {
    List<PartnerAdmin> admins = partnerAdminRepository.findByUserId(userId);
    return admins.stream()
        .anyMatch(
            pa ->
                pa.getPartnerCompany().getId().equals(companyId)
                    && Boolean.TRUE.equals(pa.getCanManageDrivers()));
  }

  /**
   * Check if user can manage customers for a specific partner company
   */
  @Transactional(readOnly = true)
  public boolean canManageCustomers(Long userId, Long companyId) {
    List<PartnerAdmin> admins = partnerAdminRepository.findByUserId(userId);
    return admins.stream()
        .anyMatch(
            pa ->
                pa.getPartnerCompany().getId().equals(companyId)
                    && Boolean.TRUE.equals(pa.getCanManageCustomers()));
  }

  /**
   * Get all company IDs that a user can manage
   */
  @Transactional(readOnly = true)
  public List<Long> getManagedCompanyIds(Long userId) {
    return partnerAdminRepository.findByUserId(userId).stream()
        .map(pa -> pa.getPartnerCompany().getId())
        .toList();
  }
}
