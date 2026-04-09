package com.svtrucking.logistics.service;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

import com.svtrucking.logistics.model.Driver;
import com.svtrucking.logistics.model.DriverLicense;
import com.svtrucking.logistics.repository.DriverLicenseRepository;
import com.svtrucking.logistics.repository.DriverRepository;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.dao.DataIntegrityViolationException;

@ExtendWith(MockitoExtension.class)
public class DriverLicenseServiceTest {

  @Mock private DriverLicenseRepository licenseRepository;
  @Mock private DriverRepository driverRepository;

  @InjectMocks private DriverLicenseService service;

  @Test
  void updateLicenseImage_retriesOnUniqueConstraint() {
    Long driverId = 123L;

    Driver driver = new Driver();
    driver.setId(driverId);

    when(licenseRepository.findByDriverId(driverId)).thenReturn(Optional.empty());
    when(driverRepository.findById(driverId)).thenReturn(Optional.of(driver));

    // First save throws unique constraint, second returns saved entity
    when(licenseRepository.save(any(DriverLicense.class)))
        .thenThrow(new DataIntegrityViolationException("duplicate key"))
        .thenAnswer(invocation -> invocation.getArgument(0));

    service.updateLicenseImage(driverId, true, "http://files.example.com/x.jpg");

    ArgumentCaptor<DriverLicense> captor = ArgumentCaptor.forClass(DriverLicense.class);
    verify(licenseRepository, atLeast(2)).save(captor.capture());

    // Last saved license should have a generated license number
    DriverLicense last = captor.getAllValues().get(captor.getAllValues().size() - 1);
    assertNotNull(last.getLicenseNumber());
    assertTrue(last.getLicenseNumber().startsWith("LN-"));
    assertEquals("http://files.example.com/x.jpg", last.getLicenseFrontImage());
  }
}
