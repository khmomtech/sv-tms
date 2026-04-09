package com.svtrucking.logistics.service;

import com.svtrucking.logistics.enums.PartnershipType;
import com.svtrucking.logistics.enums.Status;
import com.svtrucking.logistics.model.PartnerCompany;
import com.svtrucking.logistics.repository.PartnerCompanyRepository;
import com.svtrucking.logistics.exception.BusinessConflictException;
import java.time.LocalDateTime;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class PartnerCompanyService {

  private final PartnerCompanyRepository partnerCompanyRepository;

  @Transactional(readOnly = true)
  public List<PartnerCompany> getAllPartners() {
    return partnerCompanyRepository.findAll();
  }

  @Transactional(readOnly = true)
  public List<PartnerCompany> getActivePartners() {
    return partnerCompanyRepository.findByStatus(Status.ACTIVE);
  }

  @Transactional(readOnly = true)
  public List<PartnerCompany> getPartnersByType(PartnershipType type) {
    return partnerCompanyRepository.findByPartnershipType(type);
  }

  @Transactional(readOnly = true)
  public PartnerCompany getPartnerById(Long id) {
    return partnerCompanyRepository
        .findById(id)
        .orElseThrow(() -> new RuntimeException("Partner company not found with ID: " + id));
  }

  @Transactional(readOnly = true)
  public PartnerCompany getPartnerByCode(String code) {
    return partnerCompanyRepository
        .findByCompanyCode(code)
        .orElseThrow(() -> new RuntimeException("Partner company not found with code: " + code));
  }

  @Transactional
  public PartnerCompany createPartner(PartnerCompany partner) {
    // Validate unique constraints
    if (partner.getCompanyCode() != null
        && partnerCompanyRepository.existsByCompanyCode(partner.getCompanyCode())) {
      throw new BusinessConflictException("Company code already exists: " + partner.getCompanyCode());
    }

    if (partner.getBusinessLicense() != null
        && partnerCompanyRepository.existsByBusinessLicenseIgnoreCase(partner.getBusinessLicense())) {
      throw new BusinessConflictException(
          "Business license already exists: " + partner.getBusinessLicense());
    }

    // Set defaults
    if (partner.getStatus() == null) {
      partner.setStatus(Status.ACTIVE);
    }

    partner.setCreatedAt(LocalDateTime.now());
    partner.setUpdatedAt(LocalDateTime.now());

    return partnerCompanyRepository.save(partner);
  }

  @Transactional
  public PartnerCompany updatePartner(Long id, PartnerCompany updates) {
    PartnerCompany existing = getPartnerById(id);

    // Update fields
    if (updates.getCompanyName() != null) {
      existing.setCompanyName(updates.getCompanyName());
    }
    if (updates.getBusinessLicense() != null) {
      existing.setBusinessLicense(updates.getBusinessLicense());
    }
    if (updates.getContactPerson() != null) {
      existing.setContactPerson(updates.getContactPerson());
    }
    if (updates.getEmail() != null) {
      existing.setEmail(updates.getEmail());
    }
    if (updates.getPhone() != null) {
      existing.setPhone(updates.getPhone());
    }
    if (updates.getAddress() != null) {
      existing.setAddress(updates.getAddress());
    }
    if (updates.getPartnershipType() != null) {
      existing.setPartnershipType(updates.getPartnershipType());
    }
    if (updates.getStatus() != null) {
      existing.setStatus(updates.getStatus());
    }
    if (updates.getContractStartDate() != null) {
      existing.setContractStartDate(updates.getContractStartDate());
    }
    if (updates.getContractEndDate() != null) {
      existing.setContractEndDate(updates.getContractEndDate());
    }
    if (updates.getCommissionRate() != null) {
      existing.setCommissionRate(updates.getCommissionRate());
    }
    if (updates.getCreditLimit() != null) {
      existing.setCreditLimit(updates.getCreditLimit());
    }
    if (updates.getNotes() != null) {
      existing.setNotes(updates.getNotes());
    }
    if (updates.getLogoUrl() != null) {
      existing.setLogoUrl(updates.getLogoUrl());
    }
    if (updates.getWebsite() != null) {
      existing.setWebsite(updates.getWebsite());
    }

    existing.setUpdatedAt(LocalDateTime.now());
    existing.setUpdatedBy(updates.getUpdatedBy());

    return partnerCompanyRepository.save(existing);
  }

  @Transactional
  public void deletePartner(Long id) {
    PartnerCompany partner = getPartnerById(id);
    partnerCompanyRepository.delete(partner);
  }

  @Transactional
  public void deactivatePartner(Long id) {
    PartnerCompany partner = getPartnerById(id);
    partner.setStatus(Status.INACTIVE);
    partner.setUpdatedAt(LocalDateTime.now());
    partnerCompanyRepository.save(partner);
  }

  @Transactional(readOnly = true)
  public List<PartnerCompany> searchPartners(String search) {
    return partnerCompanyRepository.searchPartners(search);
  }

  /**
   * Generate next company code (e.g., PART-001, PART-002)
   */
  public String generateCompanyCode() {
    List<PartnerCompany> all = partnerCompanyRepository.findAll();
    int maxNumber = 0;

    for (PartnerCompany p : all) {
      String code = p.getCompanyCode();
      if (code != null && code.startsWith("PART-")) {
        try {
          int num = Integer.parseInt(code.substring(5));
          if (num > maxNumber) {
            maxNumber = num;
          }
        } catch (NumberFormatException ignored) {
          // Skip invalid codes
        }
      }
    }

    return String.format("PART-%03d", maxNumber + 1);
  }
}
