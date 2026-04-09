package com.svtrucking.logistics.service;

import com.svtrucking.logistics.enums.PartnershipType;
import com.svtrucking.logistics.enums.Status;
import com.svtrucking.logistics.exception.BusinessConflictException;
import com.svtrucking.logistics.model.PartnerCompany;
import com.svtrucking.logistics.repository.PartnerCompanyRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.annotation.Transactional;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@Transactional
class PartnerCompanyServiceTest {

  @Autowired
  private PartnerCompanyService service;

  @Autowired
  private PartnerCompanyRepository repository;

  private PartnerCompany basePartner(String code, String license) {
    return PartnerCompany.builder()
        .companyCode(code)
        .companyName("Test Vendor " + code)
        .businessLicense(license)
        .contactPerson("Alice")
        .email(code.toLowerCase() + "@example.com")
        .phone("+1555000" + code.substring(code.length() - 3))
        .address("123 Street")
        .partnershipType(PartnershipType.DRIVER_FLEET)
        .status(Status.ACTIVE)
        .commissionRate(10.0)
        .creditLimit(1000.0)
        .build();
  }

  @Test
  @DisplayName("createPartner persists entity and sets timestamps")
  void createPartner_ok() {
    PartnerCompany created = service.createPartner(basePartner("PART-900", "LIC-900"));
    assertNotNull(created.getId());
    assertNotNull(created.getCreatedAt());
    assertNotNull(created.getUpdatedAt());
    assertEquals("PART-900", created.getCompanyCode());
  }

  @Test
  @DisplayName("createPartner throws conflict on duplicate company code")
  void createPartner_duplicateCompanyCode() {
    service.createPartner(basePartner("PART-901", "LIC-901"));
    BusinessConflictException ex = assertThrows(BusinessConflictException.class, () ->
        service.createPartner(basePartner("PART-901", "LIC-902"))
    );
    assertTrue(ex.getMessage().contains("Company code already exists"));
  }

  @Test
  @DisplayName("createPartner throws conflict on duplicate business license case-insensitive")
  void createPartner_duplicateBusinessLicense_caseInsensitive() {
    service.createPartner(basePartner("PART-902", "ABC-123"));
    BusinessConflictException ex = assertThrows(BusinessConflictException.class, () ->
        service.createPartner(basePartner("PART-903", "abc-123"))
    );
    assertTrue(ex.getMessage().contains("Business license already exists"));
  }
}
