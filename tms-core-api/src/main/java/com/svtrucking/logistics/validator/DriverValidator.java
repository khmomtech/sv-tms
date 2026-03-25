package com.svtrucking.logistics.validator;

import com.svtrucking.logistics.dto.requests.DriverCreateRequest;
import com.svtrucking.logistics.dto.requests.DriverUpdateRequest;
import com.svtrucking.logistics.exception.DriverValidationException;
import com.svtrucking.logistics.exception.InvalidDriverDataException;
import com.svtrucking.logistics.model.Driver;
import com.svtrucking.logistics.repository.DriverRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.web.multipart.MultipartFile;

import java.util.Set;
import java.util.regex.Pattern;

/**
 * Validator for driver business rules and data integrity.
 * Centralizes all validation logic for driver operations.
 * 
 * Validation Categories:
 * - Required field validation
 * - Format validation (phone, license)
 * - Business rule validation (partner company, employee references)
 * - File upload validation
 * - Uniqueness constraints
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class DriverValidator {

    private final DriverRepository driverRepository;

    // Validation constants
    private static final Pattern PHONE_PATTERN = Pattern.compile("^[+]?[0-9]{8,15}$");
    private static final Pattern LICENSE_PATTERN = Pattern.compile("^[A-Z0-9]{5,20}$");
    private static final Set<String> ALLOWED_IMAGE_EXTENSIONS = Set.of(".jpg", ".jpeg", ".png", ".webp");
    private static final long MAX_FILE_SIZE = 5 * 1024 * 1024; // 5MB

    /**
     * Validates driver creation request.
     * 
     * @param request The driver creation request
     * @throws InvalidDriverDataException if required fields are missing or invalid
     * @throws DriverValidationException  if business rules are violated
     */
    public void validateDriverCreation(DriverCreateRequest request) {
        log.debug("Validating driver creation request");

        // Required fields
        validateRequiredFieldsForCreation(request);

        // Format validation
        if (request.getPhone() != null) {
            validatePhoneFormat(request.getPhone());
        }

        if (request.getLicenseNumber() != null && !request.getLicenseNumber().isBlank()) {
            validateLicenseFormat(request.getLicenseNumber());
            // License uniqueness check removed — license docs live in driver_documents
        }

        // Business rules
        validatePartnerRequirements(request.isPartner(), request.getPartnerCompany());

        // Rating validation
        if (request.getRating() != null) {
            validateRating(request.getRating());
        }

        log.debug("Driver creation request validation passed");
    }

    /**
     * Validates driver update request.
     * 
     * @param driver  Existing driver entity
     * @param request Update request
     * @throws InvalidDriverDataException if data is invalid
     * @throws DriverValidationException  if business rules are violated
     */
    public void validateDriverUpdate(Driver driver, DriverUpdateRequest request) {
        log.debug("Validating driver update for ID: {}", driver.getId());

        // Required fields
        validateRequiredFieldsForUpdate(request);

        // Format validation
        if (request.getPhone() != null) {
            validatePhoneFormat(request.getPhone());
        }

        if (request.getLicenseNumber() != null && !request.getLicenseNumber().isBlank()) {
            validateLicenseFormat(request.getLicenseNumber());
            // License uniqueness check removed — license docs live in driver_documents
        }

        // Business rules
        if (request.getIsPartner() != null) {
            validatePartnerRequirements(request.getIsPartner(), request.getPartnerCompany());
        }

        // Rating validation
        if (request.getRating() != null) {
            validateRating(request.getRating());
        }

        log.debug("Driver update validation passed for ID: {}", driver.getId());
    }

    /**
     * Validates driver entity before persistence.
     * 
     * @param driver The driver entity
     * @throws InvalidDriverDataException if data is invalid
     */
    public void validateDriver(Driver driver) {
        log.debug("Validating driver entity: {}", driver.getId());

        if (driver.getId() != null && driver.getId() <= 0) {
            throw new InvalidDriverDataException("id", "must be positive if provided");
        }

        // Phone validation
        if (driver.getPhone() != null && !driver.getPhone().isBlank()) {
            validatePhoneFormat(driver.getPhone());
        }

        // License validation
        if (driver.getLicenseNumber() != null && !driver.getLicenseNumber().isBlank()) {
            validateLicenseFormat(driver.getLicenseNumber());
        }

        // Partner validation - check partnerCompanyEntity instead of partnerCompany
        // string
        if (driver.isPartner() && driver.getPartnerCompanyEntity() == null) {
            throw new DriverValidationException("partner company",
                    "partner driver must have a valid partner company");
        }

        // Rating validation
        if (driver.getRating() != null) {
            validateRating(driver.getRating());
        }

        log.debug("Driver entity validation passed");
    }

    /**
     * Validates profile picture file upload.
     * 
     * @param file The uploaded file
     * @throws InvalidDriverDataException if file is invalid
     */
    public void validateProfilePicture(MultipartFile file) {
        log.debug("Validating profile picture upload");

        if (file == null || file.isEmpty()) {
            throw new InvalidDriverDataException("profilePicture", "file must not be empty");
        }

        // Check file size
        if (file.getSize() > MAX_FILE_SIZE) {
            throw new InvalidDriverDataException("profilePicture",
                    String.format("file size must not exceed %d MB", MAX_FILE_SIZE / 1024 / 1024));
        }

        // Check file extension
        String filename = file.getOriginalFilename();
        if (filename == null || filename.isBlank()) {
            throw new InvalidDriverDataException("profilePicture", "filename is required");
        }

        String extension = getFileExtension(filename);
        if (!ALLOWED_IMAGE_EXTENSIONS.contains(extension.toLowerCase())) {
            throw new InvalidDriverDataException("profilePicture",
                    "unsupported file type. Allowed: " + ALLOWED_IMAGE_EXTENSIONS);
        }

        log.debug("Profile picture validation passed");
    }

    // ==================== Private Helper Methods ====================

    private void validateRequiredFieldsForCreation(DriverCreateRequest request) {
        if (request.getFirstName() == null || request.getFirstName().isBlank()) {
            throw new InvalidDriverDataException("firstName", "is required");
        }

        if (request.getLastName() == null || request.getLastName().isBlank()) {
            throw new InvalidDriverDataException("lastName", "is required");
        }

        if (request.getPhone() == null || request.getPhone().isBlank()) {
            throw new InvalidDriverDataException("phone", "is required");
        }
    }

    private void validateRequiredFieldsForUpdate(DriverUpdateRequest request) {
        if (request.getFirstName() != null && request.getFirstName().isBlank()) {
            throw new InvalidDriverDataException("firstName", "must not be blank if provided");
        }

        if (request.getLastName() != null && request.getLastName().isBlank()) {
            throw new InvalidDriverDataException("lastName", "must not be blank if provided");
        }

        if (request.getPhone() != null && request.getPhone().isBlank()) {
            throw new InvalidDriverDataException("phone", "must not be blank if provided");
        }
    }

    private void validatePhoneFormat(String phone) {
        if (!PHONE_PATTERN.matcher(phone).matches()) {
            throw new InvalidDriverDataException("phone",
                    "invalid format. Expected: 8-15 digits, optional + prefix");
        }
    }

    private void validateLicenseFormat(String licenseNumber) {
        if (!LICENSE_PATTERN.matcher(licenseNumber.toUpperCase()).matches()) {
            throw new InvalidDriverDataException("licenseNumber",
                    "invalid format. Expected: 5-20 alphanumeric characters");
        }
    }

    // validateLicenseUniqueness removed — license docs live in driver_documents
    // (category='license'),
    // not in the legacy driver_licenses table.

    private void validatePartnerRequirements(boolean isPartner, String partnerCompany) {
        if (isPartner && (partnerCompany == null || partnerCompany.isBlank())) {
            throw new DriverValidationException("partner company",
                    "partner driver must have a valid company name");
        }
    }

    private void validateRating(Double rating) {
        if (rating < 0.0 || rating > 5.0) {
            throw new InvalidDriverDataException("rating",
                    "must be between 0.0 and 5.0");
        }
    }

    private String getFileExtension(String filename) {
        int dotIndex = filename.lastIndexOf('.');
        if (dotIndex > 0 && dotIndex < filename.length() - 1) {
            return filename.substring(dotIndex);
        }
        return "";
    }
}
