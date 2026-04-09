package com.svtrucking.logistics.service;

import com.svtrucking.logistics.dto.DriverLicenseDto;
import com.svtrucking.logistics.model.Driver;
import com.svtrucking.logistics.model.DriverLicense;
import com.svtrucking.logistics.repository.DriverLicenseRepository;
import com.svtrucking.logistics.repository.DriverRepository;

import jakarta.transaction.Transactional;

import java.util.List;
import java.util.UUID;

import org.springframework.dao.DataIntegrityViolationException;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class DriverLicenseService {

  private static final Logger LOG = LoggerFactory.getLogger(DriverLicenseService.class);

  private final DriverLicenseRepository licenseRepository;
  private final DriverRepository driverRepository;

  /**
   * Creates or updates a driver's license record.
   *
   * @param driverId The driver's ID.
   * @param dto The driver license DTO.
   * @return The saved or updated license as a DTO.
   */
  @Transactional
  public DriverLicenseDto createOrUpdateLicense(Long driverId, DriverLicenseDto dto) {
    if (dto == null) {
      throw new IllegalArgumentException("license DTO must not be null");
    }
    Driver driver =
        driverRepository
            .findById(driverId)
            .orElseThrow(
                () -> new IllegalArgumentException("Driver not found with ID: " + driverId));
    // Ensure licenseNumber exists and is trimmed. If client omitted it, generate a unique one.
    if (dto.getLicenseNumber() == null || dto.getLicenseNumber().isBlank()) {
      String generated = generateLicenseNumber();
      dto.setLicenseNumber(generated);
      LOG.info("No licenseNumber provided, generated: {} for driverId={}", generated, driverId);
    } else {
      dto.setLicenseNumber(dto.getLicenseNumber().trim());
    }

    // Validate licenseNumber length against DB column (length = 50)
    if (dto.getLicenseNumber().length() > 50) {
      throw new IllegalArgumentException("licenseNumber too long (max 50 chars)");
    }

    // Validate licenseClass length against DB column (length = 3)
    if (dto.getLicenseClass() != null && dto.getLicenseClass().length() > 3) {
      throw new IllegalArgumentException("licenseClass too long (max 3 chars)");
    }

    DriverLicense license = null;

    // Find any existing record with the same license number, including soft-deleted
    var byNumber = licenseRepository.findByLicenseNumberIncludingDeleted(dto.getLicenseNumber());
    if (byNumber.isPresent()) {
      DriverLicense existing = byNumber.get();
      if (existing.getDriver() != null && !existing.getDriver().getId().equals(driverId)) {
        throw new IllegalArgumentException(
            "License number already in use by another driver: " + dto.getLicenseNumber());
      }
      // Reuse/restore the existing record for the same driver
      existing.setDeleted(false);
      existing.setDriver(driver);
      license = existing;
    }

    if (license == null) {
      license = licenseRepository.findByDriverId(driverId).stream().findFirst().orElse(new DriverLicense());
    }

    license.setDriver(driver);
    license.setLicenseNumber(dto.getLicenseNumber());
    license.setLicenseClass(dto.getLicenseClass()); // Store in license record
    license.setIssuedDate(dto.getIssuedDate());
    license.setExpiryDate(dto.getExpiryDate());
    license.setIssuingAuthority(dto.getIssuingAuthority());
    license.setLicenseImageUrl(dto.getLicenseImageUrl());
    license.setLicenseFrontImage(dto.getLicenseFrontImage());
    license.setLicenseBackImage(dto.getLicenseBackImage());
    license.setNotes(dto.getNotes());

    // Try saving with retry logic to handle unique constraint races (driver_id or license_number)
    int attempts = 0;
    DriverLicense saved = null;
    while (true) {
      try {
        saved = licenseRepository.save(license);
        break;
      } catch (DataIntegrityViolationException ex) {
        attempts++;
        try {
          var existingOpt = licenseRepository.findByDriverId(driverId).stream().findFirst();
          if (existingOpt.isPresent()) {
            DriverLicense existing = existingOpt.get();
            existing.setLicenseNumber(license.getLicenseNumber());
            existing.setLicenseClass(license.getLicenseClass());
            existing.setIssuedDate(license.getIssuedDate());
            existing.setExpiryDate(license.getExpiryDate());
            existing.setIssuingAuthority(license.getIssuingAuthority());
            existing.setLicenseImageUrl(license.getLicenseImageUrl());
            existing.setLicenseFrontImage(license.getLicenseFrontImage());
            existing.setLicenseBackImage(license.getLicenseBackImage());
            existing.setNotes(license.getNotes());
            existing.setDeleted(false);
            saved = licenseRepository.save(existing);
            LOG.info("Concurrent insert detected - updated existing license for driverId={}", driverId);
            break;
          }
        } catch (Exception e) {
          LOG.warn("While handling DataIntegrityViolationException re-fetch failed for driverId={}", driverId, e);
        }

        if (attempts >= 3) {
          LOG.error("Failed to save license after {} attempts for driverId={}", attempts, driverId, ex);
          throw ex;
        }

        // If collision likely due to license_number uniqueness, regenerate and retry
        String newNumber = generateLicenseNumber();
        license.setLicenseNumber(newNumber);
        LOG.warn("Unique constraint collision while saving license, retrying with new licenseNumber: {} (attempt={})", newNumber, attempts);
      }
    }

    // 🇰🇭 Sync license class to driver (Cambodia: A1, A, B1, B, C, C1, D, E)
    if (dto.getLicenseClass() != null && !dto.getLicenseClass().isEmpty()) {
      driver.setLicenseClass(dto.getLicenseClass());
      driverRepository.save(driver);
      LOG.info("License class synced: driverId={} | licenseClass={}", driverId, dto.getLicenseClass());
    }

    LOG.info("License saved for driverId={} | licenseId={}", driverId, saved.getId());

    return DriverLicenseDto.fromEntity(saved);
  }

  /**
   * Gets a driver's license by driver ID.
   *
   * @param driverId The driver's ID.
   * @return The driver license DTO or null if not found.
   */
  @Transactional
  public DriverLicenseDto getLicenseByDriverId(Long driverId) {
    // Use join-fetch to ensure related Driver is initialized within the transaction
    return licenseRepository.findByDriverIdWithDriver(driverId)
        .map(DriverLicenseDto::fromEntity)
        .orElse(null);
  }

  /**
   * Deletes a license by its ID.
   *
   * @param licenseId The license ID.
   */
  public void deleteLicenseById(Long licenseId) {
    if (!licenseRepository.existsById(licenseId)) {
      throw new IllegalArgumentException("License not found with ID: " + licenseId);
    }
    licenseRepository.deleteById(licenseId);
    LOG.info("🗑️ License deleted: {}", licenseId);
  }

  /**
   * Updates only the front or back license image URL.
   *
   * @param driverId Driver ID.
   * @param isFront true if front image, false if back image.
   * @param imageUrl Image URL to set.
   */
  public void updateLicenseImage(Long driverId, boolean isFront, String imageUrl) {
    // Try to find existing license; if missing, create a new one bound to the driver
    DriverLicense license = licenseRepository.findByDriverId(driverId).stream().findFirst().orElse(null);

    if (license == null) {
      Driver driver =
          driverRepository
              .findById(driverId)
              .orElseThrow(() -> new RuntimeException("Driver not found with ID: " + driverId));
      license = new DriverLicense();
      license.setDriver(driver);
      // license_number is NOT NULL in DB; generate a UUID-based value to satisfy constraint
      license.setLicenseNumber(generateLicenseNumber());
    }

    if (isFront) {
      license.setLicenseFrontImage(imageUrl);
    } else {
      license.setLicenseBackImage(imageUrl);
    }

    // Try to save; if unique constraint collides, retry with a new generated license number.
    int attempts = 0;
    while (true) {
      try {
        licenseRepository.save(license);
        break;
      } catch (DataIntegrityViolationException ex) {
        attempts++;
        // If another transaction inserted a license for this driver concurrently,
        // re-fetch and update that existing record instead of trying to insert again.
        try {
          var existingOpt = licenseRepository.findByDriverId(driverId).stream().findFirst();
          if (existingOpt.isPresent()) {
            DriverLicense existing = existingOpt.get();
            if (isFront) {
              existing.setLicenseFrontImage(imageUrl);
            } else {
              existing.setLicenseBackImage(imageUrl);
            }
            licenseRepository.save(existing);
            LOG.info("Concurrent insert detected - updated existing license for driverId={}", driverId);
            return;
          }
        } catch (Exception e) {
          LOG.warn("While handling DataIntegrityViolationException re-fetch failed for driverId={}", driverId, e);
        }

        if (attempts >= 3) {
          LOG.error("Failed to save license after {} attempts for driverId={}", attempts, driverId, ex);
          throw ex;
        }

        // Likely a collision on `license_number` value; regenerate and retry
        String newNumber = generateLicenseNumber();
        license.setLicenseNumber(newNumber);
        LOG.warn("Unique constraint collision on license_number, retrying with new value: {} (attempt={})", newNumber, attempts);
      }
    }

    LOG.info("License image {} updated for driverId={}", isFront ? "front" : "back", driverId);
  }

  private String generateLicenseNumber() {
    return "LN-" + UUID.randomUUID().toString();
  }

  /**
   * Gets all active licenses (non-deleted).
   *
   * @return A list of driver licenses as DTOs.
   */
  public List<DriverLicenseDto> getAllLicenses() {
    return licenseRepository.findAll().stream().map(DriverLicenseDto::fromEntity).toList();
  }

  /**
   * Gets all licenses including deleted ones (for admin).
   *
   * @return A list of all driver licenses as DTOs.
   */
  public List<DriverLicenseDto> getAllLicensesIncludingDeleted() {
    return licenseRepository.findAllByOrderByIdDesc().stream()
        .map(DriverLicenseDto::fromEntity)
        .toList();
  }
}
