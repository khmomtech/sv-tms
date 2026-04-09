package com.svtrucking.logistics.validator;

import com.svtrucking.logistics.enums.CustomerType;
import com.svtrucking.logistics.enums.Status;
import com.svtrucking.logistics.exception.InvalidCustomerDataException;
import com.svtrucking.logistics.model.Customer;
import com.svtrucking.logistics.repository.CustomerRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.regex.Pattern;

/**
 * Validator for Customer entity with comprehensive business rule validation.
 * Follows Single Responsibility Principle - only validates customer data.
 */
@Component
@RequiredArgsConstructor
public class CustomerValidator {

    private final CustomerRepository customerRepository;

    // Email validation pattern (RFC 5322 simplified)
    private static final Pattern EMAIL_PATTERN = Pattern.compile(
            "^[a-zA-Z0-9_+&*-]+(?:\\.[a-zA-Z0-9_+&*-]+)*@(?:[a-zA-Z0-9-]+\\.)+[a-zA-Z]{2,7}$"
    );

    // Phone validation pattern (supports international formats)
    private static final Pattern PHONE_PATTERN = Pattern.compile(
            "^[+]?[(]?[0-9]{1,4}[)]?[-\\s.]?[(]?[0-9]{1,4}[)]?[-\\s.]?[0-9]{1,9}$"
    );

    // Customer code pattern (uppercase alphanumeric with optional hyphen/underscore, 3-20 characters)
    private static final Pattern CUSTOMER_CODE_PATTERN = Pattern.compile("^[A-Z0-9_-]{3,20}$");

    /**
     * Validates customer data before creation.
     * 
     * @param customer Customer entity to validate
     * @throws InvalidCustomerDataException if validation fails
     */
    public void validateForCreate(Customer customer) {
        validateRequiredFields(customer);
        validateCustomerCode(customer.getCustomerCode(), null);
        validateEmail(customer.getEmail());
        validatePhone(customer.getPhone());
        validateCustomerType(customer.getType());
        validateStatus(customer.getStatus());
        validateBusinessRules(customer);
    }

    /**
     * Validates customer data before update.
     * 
     * @param customer Customer entity to validate
     * @param customerId ID of customer being updated
     * @throws InvalidCustomerDataException if validation fails
     */
    public void validateForUpdate(Customer customer, Long customerId) {
        if (customerId == null) {
            throw new InvalidCustomerDataException("id", "Customer ID is required for update");
        }

        validateRequiredFields(customer);
        validateCustomerCode(customer.getCustomerCode(), customerId);
        validateEmail(customer.getEmail());
        validatePhone(customer.getPhone());
        validateCustomerType(customer.getType());
        validateStatus(customer.getStatus());
        validateBusinessRules(customer);
    }

    /**
     * Validates required fields are not null or empty.
     */
    private void validateRequiredFields(Customer customer) {
        if (customer == null) {
            throw new InvalidCustomerDataException("customer", "Customer object cannot be null");
        }

        if (isNullOrEmpty(customer.getCustomerCode())) {
            throw new InvalidCustomerDataException("customerCode", "Customer code is required");
        }

        if (isNullOrEmpty(customer.getName())) {
            throw new InvalidCustomerDataException("name", "Customer name is required");
        }

        if (customer.getType() == null) {
            throw new InvalidCustomerDataException("type", "Customer type is required");
        }

        if (customer.getStatus() == null) {
            throw new InvalidCustomerDataException("status", "Customer status is required");
        }
    }

    /**
     * Validates customer code format and uniqueness.
     */
    private void validateCustomerCode(String customerCode, Long excludeCustomerId) {
        String normalizedCode = customerCode.trim().toUpperCase();

        if (!CUSTOMER_CODE_PATTERN.matcher(normalizedCode).matches()) {
            throw new InvalidCustomerDataException(
                    "customerCode",
                    "Customer code must be 3-20 characters using uppercase letters, digits, hyphen, or underscore"
            );
        }

        // Check uniqueness
        boolean exists =
                excludeCustomerId == null
                        ? customerRepository.existsByCustomerCode(normalizedCode)
                        : customerRepository.existsByCustomerCodeAndIdNot(normalizedCode, excludeCustomerId);

        if (exists) {
            throw new InvalidCustomerDataException(
                    "customerCode",
                    "Customer code '" + normalizedCode + "' already exists"
            );
        }
    }

    /**
     * Validates email format if provided.
     */
    private void validateEmail(String email) {
        if (isNullOrEmpty(email)) {
            return; // Email is optional
        }

        if (!EMAIL_PATTERN.matcher(email).matches()) {
            throw new InvalidCustomerDataException("email", "Invalid email format");
        }

        // Email should be lowercase
        if (!email.equals(email.toLowerCase())) {
            throw new InvalidCustomerDataException("email", "Email must be lowercase");
        }
    }

    /**
     * Validates phone number format if provided.
     */
    private void validatePhone(String phone) {
        if (isNullOrEmpty(phone)) {
            return; // Phone is optional
        }

        if (!PHONE_PATTERN.matcher(phone).matches()) {
            throw new InvalidCustomerDataException(
                    "phone",
                    "Invalid phone number format (must be 10-15 digits, may include +, -, spaces, parentheses)"
            );
        }

        // Phone length validation
        String digitsOnly = phone.replaceAll("[^0-9]", "");
        if (digitsOnly.length() < 8 || digitsOnly.length() > 15) {
            throw new InvalidCustomerDataException(
                    "phone",
                    "Phone number must contain 8-15 digits"
            );
        }
    }

    /**
     * Validates customer type is valid enum value.
     */
    private void validateCustomerType(CustomerType type) {
        if (type == null) {
            throw new InvalidCustomerDataException("type", "Customer type cannot be null");
        }

        // Enum validation is implicit, but we can add custom logic here
        if (type != CustomerType.INDIVIDUAL && type != CustomerType.COMPANY) {
            throw new InvalidCustomerDataException(
                    "type",
                    "Customer type must be either INDIVIDUAL or COMPANY"
            );
        }
    }

    /**
     * Validates status is valid enum value.
     */
    private void validateStatus(Status status) {
        if (status == null) {
            throw new InvalidCustomerDataException("status", "Status cannot be null");
        }

        // Enum validation is implicit, but we can add custom logic here
        if (status != Status.ACTIVE && status != Status.INACTIVE) {
            throw new InvalidCustomerDataException(
                    "status",
                    "Status must be either ACTIVE or INACTIVE"
            );
        }
    }

    /**
     * Validates business rules specific to customer type.
     */
    private void validateBusinessRules(Customer customer) {
        // Company customers should have company-specific data
        if (customer.getType() == CustomerType.COMPANY) {
            if (isNullOrEmpty(customer.getName())) {
                throw new InvalidCustomerDataException(
                        "name",
                        "Company name is required for COMPANY type customers"
                );
            }

            // Company names should be at least 2 characters
            if (customer.getName().trim().length() < 2) {
                throw new InvalidCustomerDataException(
                        "name",
                        "Company name must be at least 2 characters"
                );
            }
        }

        // Individual customers validation
        if (customer.getType() == CustomerType.INDIVIDUAL) {
            if (isNullOrEmpty(customer.getName())) {
                throw new InvalidCustomerDataException(
                        "name",
                        "Individual name is required for INDIVIDUAL type customers"
                );
            }

            // Individual names should be at least 2 characters
            if (customer.getName().trim().length() < 2) {
                throw new InvalidCustomerDataException(
                        "name",
                        "Individual name must be at least 2 characters"
                );
            }
        }

        // Name length validation
        if (customer.getName() != null && customer.getName().length() > 200) {
            throw new InvalidCustomerDataException(
                    "name",
                    "Customer name cannot exceed 200 characters"
            );
        }

        // Address length validation
        if (customer.getAddress() != null && customer.getAddress().length() > 500) {
            throw new InvalidCustomerDataException(
                    "address",
                    "Address cannot exceed 500 characters"
            );
        }
    }

    /**
     * Validates customer deletion is allowed.
     * 
     * @param customerId ID of customer to delete
     * @throws InvalidCustomerDataException if customer has active orders
     */
    public void validateForDelete(Long customerId) {
        if (customerId == null) {
            throw new InvalidCustomerDataException("id", "Customer ID is required for deletion");
        }

        Customer customer = customerRepository.findById(customerId)
                .orElseThrow(() -> new InvalidCustomerDataException(
                        "id",
                        "Customer with ID " + customerId + " not found"
                ));

        // Check if customer has active orders
        // This would require OrderRepository injection - implementing a basic check
        if (customer.getStatus() == Status.ACTIVE) {
            // Soft delete recommendation
            throw new InvalidCustomerDataException(
                    "status",
                    "Cannot delete active customer. Please deactivate first."
            );
        }
    }

    /**
     * Utility method to check if string is null or empty after trimming.
     */
    private boolean isNullOrEmpty(String value) {
        return value == null || value.trim().isEmpty();
    }
}
