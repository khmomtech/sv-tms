package com.svtrucking.logistics.service;

import com.svtrucking.logistics.enums.CustomerType;
import com.svtrucking.logistics.enums.RoleType;
import com.svtrucking.logistics.enums.Status;
import com.svtrucking.logistics.exception.CustomerNotFoundException;
import com.svtrucking.logistics.exception.InvalidCustomerDataException;
import com.svtrucking.logistics.exception.DuplicateCustomerException;
import com.svtrucking.logistics.model.Customer;
import com.svtrucking.logistics.model.CustomerAudit;
import com.svtrucking.logistics.model.Role;
import com.svtrucking.logistics.model.User;
import com.svtrucking.logistics.repository.CustomerRepository;
import com.svtrucking.logistics.repository.CustomerAuditRepository;
import com.svtrucking.logistics.repository.RoleRepository;
import com.svtrucking.logistics.repository.UserRepository;
import com.svtrucking.logistics.validator.CustomerValidator;
import jakarta.persistence.criteria.Predicate;
import java.io.InputStream;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.poi.ss.usermodel.*;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

/**
 * Service layer for Customer management.
 * Handles business logic, validation, and data persistence for customers.
 * 
 * @author TMS Team
 * @version 2.0
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class CustomerService {
    private final CustomerRepository customerRepository;
    private final CustomerAuditRepository customerAuditRepository;
    private final UserRepository userRepository;
    private final RoleRepository roleRepository;
    private final PasswordEncoder passwordEncoder;
    private final CustomerValidator customerValidator;

    /**
     * Retrieves all customers with pagination and sorting.
     * Only returns non-deleted customers (soft delete support).
     * 
     * @param page Page number (0-indexed)
     * @param size Number of items per page
     * @return Page of customers sorted by creation date (newest first)
     */
    @Transactional(readOnly = true)
    public Page<Customer> getAllCustomers(int page, int size) {
        log.debug("Fetching active customers: page={}, size={}", page, size);

        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        Page<Customer> customers = customerRepository.findAllActive(pageable);

        log.info("Retrieved {} active customers (page {}/{})",
                customers.getNumberOfElements(), page + 1, customers.getTotalPages());

        return customers;
    }

    /**
     * Searches customers by name, phone, or email.
     * 
     * @param name  Name search keyword
     * @param phone Phone search keyword
     * @param email Email search keyword
     * @return List of matching customers
     */
    @Transactional(readOnly = true)
    public List<Customer> searchCustomers(String name, String phone, String email) {
        log.debug("Searching customers: name={}, phone={}, email={}", name, phone, email);

        List<Customer> customers = customerRepository
                .findByNameContainingIgnoreCaseOrPhoneContainingIgnoreCaseOrEmailContainingIgnoreCase(
                        name, phone, email);

        log.info("Found {} customers matching search criteria", customers.size());

        return customers;
    }

    /**
     * Retrieves a customer by ID.
     * 
     * @param id Customer ID
     * @return Customer entity
     * @throws CustomerNotFoundException if customer not found
     */
    @Transactional(readOnly = true)
    public Customer getCustomerById(Long id) {
        log.debug("Fetching customer by ID: {}", id);

        return customerRepository.findById(id)
                .orElseThrow(() -> {
                    log.error("Customer not found with ID: {}", id);
                    return new CustomerNotFoundException(id);
                });
    }

    @Transactional(readOnly = true)
    public List<Customer> getAllActiveForExport() {
        return customerRepository.findAllActive(Pageable.unpaged()).getContent();
    }

    /**
     * Generate the next sequential customer code
     * Finds the highest existing code and increments it
     * Format: CUSTXXXX where XXXX is a 4-digit sequential number
     * Examples: CUST0001, CUST0002, ..., CUST9999
     * 
     * @return Next sequential customer code
     * @throws InvalidCustomerDataException if code limit exceeded (CUST9999)
     */
    @Transactional(readOnly = true)
    public String generateNextCustomerCode() {
        log.debug("Generating next sequential customer code");

        Set<String> allCodes = customerRepository.findAllCodes();
        int nextNumber = 1;

        if (allCodes != null && !allCodes.isEmpty()) {
            // Extract numbers from existing codes (e.g., "CUST0001" → 1)
            int maxNumber = allCodes.stream()
                    .filter(code -> code.matches("CUST\\d{4,}")) // Match CUST followed by 4+ digits
                    .map(code -> {
                        try {
                            // Remove "CUST" prefix and parse as integer
                            return Integer.parseInt(code.substring(4));
                        } catch (NumberFormatException e) {
                            return 0;
                        }
                    })
                    .max(Integer::compareTo)
                    .orElse(0);

            nextNumber = maxNumber + 1;
        }

        // Check if we've exceeded 4-digit limit (CUST9999)
        if (nextNumber > 9999) {
            log.error("Customer code limit reached: attempted to generate CUST{}", nextNumber);
            throw new InvalidCustomerDataException("Customer code limit reached (CUST9999 max)");
        }

        String nextCode = String.format("CUST%04d", nextNumber);
        log.info("Generated next sequential customer code: {}", nextCode);

        return nextCode;
    }

    /**
     * Creates a new customer.
     * 
     * @param customer Customer entity to create
     * @return Saved customer entity
     * @throws InvalidCustomerDataException if validation fails
     * @throws DuplicateCustomerException   if duplicate customer exists
     */
    @Transactional
    public Customer saveCustomer(Customer customer) {
        String normalizedCode = normalizeCustomerCode(customer.getCustomerCode());
        customer.setCustomerCode(normalizedCode);

        log.debug("Creating new customer: code={}, name={}", normalizedCode, customer.getName());

        // Validate before create
        customerValidator.validateForCreate(customer);

        // Check for duplicates
        validateNoDuplicates(customer, null);

        // Normalize data
        // Email normalization only needed if provided
        if (customer.getEmail() != null) {
            customer.setEmail(customer.getEmail().toLowerCase());
        }

        Customer saved = customerRepository.save(customer);

        // Create audit record
        CustomerAudit audit = CustomerAudit.forCreate(saved.getId(), getCurrentUsername());
        customerAuditRepository.save(audit);

        log.info("Created customer: id={}, code={}, name={}",
                saved.getId(), saved.getCustomerCode(), saved.getName());

        return saved;
    }

    /**
     * Updates an existing customer.
     * 
     * @param id       Customer ID to update
     * @param customer Updated customer data
     * @return Updated customer entity
     * @throws CustomerNotFoundException    if customer not found
     * @throws InvalidCustomerDataException if validation fails
     * @throws DuplicateCustomerException   if duplicate customer exists
     */
    @Transactional
    public Customer updateCustomer(Long id, Customer customer) {
        log.debug("Updating customer: id={}", id);

        // Check existence
        Customer existing = getCustomerById(id);

        // Validate before update
        customer.setId(id);
        String normalizedCode = normalizeCustomerCode(customer.getCustomerCode());
        customer.setCustomerCode(normalizedCode);
        customerValidator.validateForUpdate(customer, id);

        // Check for duplicates (excluding current customer)
        validateNoDuplicates(customer, id);

        // Update fields
        existing.setCustomerCode(normalizedCode);
        existing.setName(customer.getName());
        existing.setType(customer.getType());
        existing.setPhone(customer.getPhone());
        existing.setEmail(customer.getEmail() != null ? customer.getEmail().toLowerCase() : null);
        existing.setAddress(customer.getAddress());
        existing.setStatus(customer.getStatus());

        // Update new fields if provided
        if (customer.getCreditLimit() != null) {
            existing.setCreditLimit(customer.getCreditLimit());
        }
        if (customer.getPaymentTerms() != null) {
            existing.setPaymentTerms(customer.getPaymentTerms());
        }
        if (customer.getCurrency() != null) {
            existing.setCurrency(customer.getCurrency());
        }
        if (customer.getLifecycleStage() != null) {
            existing.setLifecycleStage(customer.getLifecycleStage());
        }
        if (customer.getSegment() != null) {
            existing.setSegment(customer.getSegment());
        }
        if (customer.getAccountManager() != null) {
            existing.setAccountManager(customer.getAccountManager());
        }

        Customer updated = customerRepository.save(existing);

        // Create audit trail for update
        CustomerAudit audit = CustomerAudit.forUpdate(updated.getId(), getCurrentUsername(), "customer_updated", null,
                null);
        customerAuditRepository.save(audit);

        log.info("Updated customer: id={}, code={}", updated.getId(), updated.getCustomerCode());

        return updated;
    }

    /**
     * Deletes a customer by ID (soft delete).
     * Sets deletedAt timestamp instead of actually removing the record.
     * 
     * @param id Customer ID to delete
     * @throws CustomerNotFoundException    if customer not found
     * @throws InvalidCustomerDataException if customer has active orders
     */
    @Transactional
    public void deleteCustomer(Long id) {
        log.debug("Soft deleting customer: id={}", id);

        Customer customer = getCustomerById(id);

        // Validate deletion is allowed
        customerValidator.validateForDelete(id);

        // Soft delete: set timestamp and user
        customer.setDeletedAt(LocalDateTime.now());
        customer.setDeletedBy(getCurrentUsername());

        Customer deleted = customerRepository.save(customer);

        // Create audit trail for delete
        CustomerAudit audit = CustomerAudit.forDelete(deleted.getId(), getCurrentUsername());
        customerAuditRepository.save(audit);

        log.warn("Soft deleted customer: id={}, code={}, deletedBy={}",
                id, customer.getCustomerCode(), customer.getDeletedBy());
    }

    /**
     * Filters customers based on multiple criteria with pagination.
     * 
     * @param customerCode Customer code filter (partial match)
     * @param name         Name filter (partial match)
     * @param phone        Phone filter (partial match)
     * @param email        Email filter (partial match)
     * @param type         Customer type filter (exact match)
     * @param status       Status filter (exact match)
     * @param page         Page number
     * @param size         Page size
     * @return Page of filtered customers
     */
    @Transactional(readOnly = true)
    public Page<Customer> filterCustomers(
            String customerCode,
            String name,
            String phone,
            String email,
            String type,
            String status,
            int page,
            int size) {

        log.debug("Filtering customers with criteria: code={}, name={}, phone={}, email={}, type={}, status={}",
                customerCode, name, phone, email, type, status);

        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));

        Page<Customer> filteredCustomers = customerRepository.findAll(
                (root, query, cb) -> {
                    List<Predicate> predicates = new ArrayList<>();

                    if (customerCode != null && !customerCode.trim().isEmpty()) {
                        predicates.add(
                                cb.like(
                                        cb.lower(root.get("customerCode")), "%" + customerCode.toLowerCase() + "%"));
                    }
                    if (name != null && !name.trim().isEmpty()) {
                        predicates.add(cb.like(cb.lower(root.get("name")), "%" + name.toLowerCase() + "%"));
                    }
                    if (phone != null && !phone.trim().isEmpty()) {
                        predicates.add(cb.like(cb.lower(root.get("phone")), "%" + phone.toLowerCase() + "%"));
                    }
                    if (email != null && !email.trim().isEmpty()) {
                        predicates.add(cb.like(cb.lower(root.get("email")), "%" + email.toLowerCase() + "%"));
                    }
                    if (type != null && !type.trim().isEmpty()) {
                        try {
                            predicates.add(cb.equal(root.get("type"), CustomerType.valueOf(type.toUpperCase())));
                        } catch (IllegalArgumentException e) {
                            log.warn("Invalid customer type filter: {}", type);
                        }
                    }
                    if (status != null && !status.trim().isEmpty()) {
                        try {
                            predicates.add(cb.equal(root.get("status"), Status.valueOf(status.toUpperCase())));
                        } catch (IllegalArgumentException e) {
                            log.warn("Invalid status filter: {}", status);
                        }
                    }

                    return cb.and(predicates.toArray(new Predicate[0]));
                },
                pageable);

        log.info("Filtered customers: found {} results (page {}/{})",
                filteredCustomers.getNumberOfElements(), page + 1, filteredCustomers.getTotalPages());

        return filteredCustomers;
    }

    /**
     * Imports customers from spreadsheet or CSV file.
     * 
     * @param file Excel file containing customer data
     * @return Summary of the import attempt, including saved customers, counts, and
     *         failure details
     * @throws InvalidCustomerDataException if file format is invalid or data
     *                                      validation fails
     */
    public CustomerImportResult importCustomersFromExcel(MultipartFile file) {
        log.info("Starting customer import from Excel file: {}", file.getOriginalFilename());

        if (file.isEmpty()) {
            throw new InvalidCustomerDataException("file", "Excel file is empty");
        }

        List<Customer> customers = new ArrayList<>();
        int successCount = 0;
        int failureCount = 0;
        List<String> failureMessages = new ArrayList<>();

        String filename = file.getOriginalFilename() != null ? file.getOriginalFilename().toLowerCase() : "";
        String contentType = file.getContentType() != null ? file.getContentType().toLowerCase() : "";
        boolean looksCsv = filename.endsWith(".csv") || contentType.contains("csv");
        // Browsers often send CSV as "application/vnd.ms-excel"; allow that to try CSV
        // first
        boolean looksExcel = filename.endsWith(".xlsx") || filename.endsWith(".xls")
                || (contentType.contains("excel") && !looksCsv);

        // --- CSV path ---
        if (looksCsv) {
            try (BufferedReader reader = new BufferedReader(
                    new InputStreamReader(file.getInputStream(), StandardCharsets.UTF_8))) {
                String line;
                int rowIndex = 0;
                String[] expectedHeaders = { "customerCode", "name", "type", "phone", "email", "address", "status" };

                while ((line = reader.readLine()) != null) {
                    rowIndex++;
                    // Skip header
                    if (rowIndex == 1) {
                        String[] headers = line.split(",");
                        if (headers.length < expectedHeaders.length) {
                            throw new InvalidCustomerDataException("file", "Invalid CSV header");
                        }
                        for (int i = 0; i < expectedHeaders.length; i++) {
                            if (!expectedHeaders[i].equalsIgnoreCase(headers[i].trim())) {
                                throw new InvalidCustomerDataException(
                                        "file",
                                        "Invalid header at column "
                                                + (i + 1)
                                                + ". Expected '"
                                                + expectedHeaders[i]
                                                + "' but found '"
                                                + headers[i]
                                                + "'");
                            }
                        }
                        continue;
                    }

                    String[] cols = line.split(",", -1);
                    if (cols.length < expectedHeaders.length) {
                        failureCount++;
                        log.error("Failed to import customer from CSV row {}: insufficient columns", rowIndex);
                        continue;
                    }
                    try {
                        Customer customer = new Customer();
                        customer.setCustomerCode(cols[0].trim());
                        customer.setName(cols[1].trim());
                        customer.setType(
                                "COMPANY".equalsIgnoreCase(cols[2].trim())
                                        ? CustomerType.COMPANY
                                        : CustomerType.INDIVIDUAL);
                        customer.setPhone(cols[3].trim());
                        customer.setEmail(cols[4].trim());
                        customer.setAddress(cols[5].trim());
                        customer.setStatus(
                                "INACTIVE".equalsIgnoreCase(cols[6].trim()) ? Status.INACTIVE : Status.ACTIVE);

                        customerValidator.validateForCreate(customer);
                        customers.add(saveCustomer(customer));
                        successCount++;
                    } catch (Exception e) {
                        failureCount++;
                        log.error("Failed to import customer from CSV row {}: {}", rowIndex, e.getMessage());
                        failureMessages.add("CSV row " + rowIndex + ": " + e.getMessage());
                    }
                }
            } catch (Exception e) {
                log.error("Failed to import customers from CSV: {}", e.getMessage(), e);
                throw new InvalidCustomerDataException(
                        "file",
                        "Failed to process CSV file: " + e.getMessage());
            }
            log.info("Customer import completed from CSV: {} succeeded, {} failed", successCount, failureCount);
            return new CustomerImportResult(customers, successCount, failureCount, failureMessages);
        }

        // --- Excel path ---
        try (InputStream inputStream = file.getInputStream();
                Workbook workbook = new XSSFWorkbook(inputStream)) {

            Sheet sheet = workbook.getSheetAt(0);
            log.debug("Processing {} rows from Excel sheet", sheet.getLastRowNum());

            // Validate header row to match template (0-based indices)
            String[] expectedHeaders = { "customerCode", "name", "type", "phone", "email", "address", "status" };
            Row headerRow = sheet.getRow(0);
            for (int i = 0; i < expectedHeaders.length; i++) {
                String headerVal = headerRow != null ? getCellValue(headerRow.getCell(i)).toLowerCase() : "";
                if (!expectedHeaders[i].equalsIgnoreCase(headerVal)) {
                    throw new InvalidCustomerDataException(
                            "file",
                            "Invalid header at column " + (i + 1) + ". Expected '" + expectedHeaders[i]
                                    + "' but found '" + headerVal + "'");
                }
            }

            for (int rowIndex = 1; rowIndex <= sheet.getLastRowNum(); rowIndex++) {
                Row row = sheet.getRow(rowIndex);
                if (row == null) {
                    log.debug("Skipping empty row {}", rowIndex);
                    continue;
                }

                try {
                    Customer customer = new Customer();
                    customer.setCustomerCode(getCellValue(row.getCell(0)));
                    customer.setName(getCellValue(row.getCell(1)));
                    customer.setType(
                            "COMPANY".equalsIgnoreCase(getCellValue(row.getCell(2)))
                                    ? CustomerType.COMPANY
                                    : CustomerType.INDIVIDUAL);
                    customer.setPhone(getCellValue(row.getCell(3)));
                    customer.setEmail(getCellValue(row.getCell(4)));
                    customer.setAddress(getCellValue(row.getCell(5)));
                    customer.setStatus(
                            "INACTIVE".equalsIgnoreCase(getCellValue(row.getCell(6)))
                                    ? Status.INACTIVE
                                    : Status.ACTIVE);

                    // Validate and save
                    customerValidator.validateForCreate(customer);
                    customers.add(saveCustomer(customer));
                    successCount++;
                } catch (Exception e) {
                    failureCount++;
                    log.error("Failed to import customer from row {}: {}", rowIndex, e.getMessage());
                    failureMessages.add("Row " + rowIndex + ": " + e.getMessage());
                }
            }

        } catch (Exception e) {
            log.warn("Excel parsing failed ({}). Attempting CSV fallback.", e.getMessage());
            // Fallback: try to parse as CSV in case the file was a CSV with an Excel
            // mime-type
            try (BufferedReader reader = new BufferedReader(
                    new InputStreamReader(file.getInputStream(), StandardCharsets.UTF_8))) {
                String line;
                int rowIndex = 0;
                String[] expectedHeaders = { "customerCode", "name", "type", "phone", "email", "address", "status" };

                while ((line = reader.readLine()) != null) {
                    rowIndex++;
                    if (rowIndex == 1) {
                        String[] headers = line.split(",");
                        if (headers.length < expectedHeaders.length) {
                            throw new InvalidCustomerDataException("file", "Invalid CSV header");
                        }
                        for (int i = 0; i < expectedHeaders.length; i++) {
                            if (!expectedHeaders[i].equalsIgnoreCase(headers[i].trim())) {
                                throw new InvalidCustomerDataException(
                                        "file",
                                        "Invalid header at column "
                                                + (i + 1)
                                                + ". Expected '"
                                                + expectedHeaders[i]
                                                + "' but found '"
                                                + headers[i]
                                                + "'");
                            }
                        }
                        continue;
                    }

                    String[] cols = line.split(",", -1);
                    if (cols.length < expectedHeaders.length) {
                        failureCount++;
                        log.error("Failed to import customer from CSV row {}: insufficient columns", rowIndex);
                        continue;
                    }
                    try {
                        Customer customer = new Customer();
                        customer.setCustomerCode(cols[0].trim());
                        customer.setName(cols[1].trim());
                        customer.setType(
                                "COMPANY".equalsIgnoreCase(cols[2].trim())
                                        ? CustomerType.COMPANY
                                        : CustomerType.INDIVIDUAL);
                        customer.setPhone(cols[3].trim());
                        customer.setEmail(cols[4].trim());
                        customer.setAddress(cols[5].trim());
                        customer.setStatus(
                                "INACTIVE".equalsIgnoreCase(cols[6].trim()) ? Status.INACTIVE : Status.ACTIVE);

                        customerValidator.validateForCreate(customer);
                        customers.add(saveCustomer(customer));
                        successCount++;
                    } catch (Exception csvErr) {
                        failureCount++;
                        log.error("Failed to import customer from CSV row {}: {}", rowIndex, csvErr.getMessage());
                        failureMessages.add("CSV fallback row " + rowIndex + ": " + csvErr.getMessage());
                    }
                }
                log.info("Customer import completed from CSV fallback: {} succeeded, {} failed", successCount,
                        failureCount);
                return new CustomerImportResult(customers, successCount, failureCount, failureMessages);
            } catch (Exception csvFallbackErr) {
                log.error("Failed to import customers; both Excel and CSV parsing failed: {}",
                        csvFallbackErr.getMessage(), csvFallbackErr);
                throw new InvalidCustomerDataException(
                        "file",
                        "Failed to process file. Supported formats: .csv, .xlsx, .xls. Details: "
                                + csvFallbackErr.getMessage());
            }
        }

        log.info("Customer import completed: {} succeeded, {} failed", successCount, failureCount);

        return new CustomerImportResult(customers, successCount, failureCount, failureMessages);
    }

    public static record CustomerImportResult(
            List<Customer> customers,
            int successCount,
            int failureCount,
            List<String> failureMessages) {
    }

    /**
     * Extracts cell value as string, handling different cell types.
     * 
     * @param cell Excel cell
     * @return Cell value as string
     */
    private String getCellValue(Cell cell) {
        if (cell == null)
            return "";
        DataFormatter formatter = new DataFormatter();
        String value = formatter.formatCellValue(cell);
        return value != null ? value.trim() : "";
    }

    /**
     * Creates a login account for an existing customer.
     * 
     * @param customer Customer entity to create account for
     * @param username Desired username
     * @param password Password (will be encrypted)
     * @param email    Email for the account
     * @return Updated customer with linked user account
     * @throws InvalidCustomerDataException if username/email already exists or
     *                                      validation fails
     */
    @Transactional
    public Customer createCustomerAccount(Customer customer, String username, String password, String email) {
        log.info("Creating customer account: customerId={}, username={}", customer.getId(), username);

        if (customer.getId() == null) {
            throw new InvalidCustomerDataException("customer", "Customer must be persisted before creating account");
        }

        // Validate username is unique
        if (userRepository.findByUsername(username).isPresent()) {
            log.error("Username already exists: {}", username);
            throw new InvalidCustomerDataException("username", "Username already exists: " + username);
        }

        // Validate email is unique (if provided)
        if (email != null && !email.isEmpty() && userRepository.findByEmail(email).isPresent()) {
            log.error("Email already exists: {}", email);
            throw new InvalidCustomerDataException("email", "Email already exists: " + email);
        }

        // Get CUSTOMER role
        Role customerRole = roleRepository.findByName(RoleType.CUSTOMER)
                .orElseThrow(() -> {
                    log.error("CUSTOMER role not found in database");
                    return new InvalidCustomerDataException("role", "CUSTOMER role not found");
                });

        // Create user account
        User user = new User();
        user.setUsername(username);
        user.setPassword(passwordEncoder.encode(password));
        user.setEmail(email != null && !email.isEmpty() ? email : customer.getEmail());
        user.setEnabled(true);
        user.setAccountNonLocked(true);
        user.setAccountNonExpired(true);
        user.setCredentialsNonExpired(true);
        user.addRole(customerRole);

        User savedUser = userRepository.save(user);
        log.debug("Created user account: id={}, username={}", savedUser.getId(), savedUser.getUsername());

        // Link user to customer
        customer.setUser(savedUser);
        Customer updated = customerRepository.save(customer);

        log.info("Successfully created customer account: customerId={}, userId={}",
                updated.getId(), savedUser.getId());

        return updated;
    }

    private String normalizeCustomerCode(String customerCode) {
        if (customerCode == null) {
            return null;
        }
        return customerCode.trim().toUpperCase();
    }

    // ==================== Duplicate Detection Helper ====================

    /**
     * Validates that customer data doesn't duplicate existing customers.
     * Checks customer code, phone, and email for uniqueness.
     * 
     * @param customer  Customer to validate
     * @param excludeId ID to exclude from check (for updates)
     * @throws DuplicateCustomerException if duplicate found
     */
    private void validateNoDuplicates(Customer customer, Long excludeId) {
        // Check customer code
        if (excludeId == null) {
            if (customerRepository.existsByCustomerCode(customer.getCustomerCode())) {
                log.error("Duplicate customer code: {}", customer.getCustomerCode());
                throw new DuplicateCustomerException("customer code", customer.getCustomerCode());
            }
        } else {
            if (customerRepository.existsByCustomerCodeAndIdNot(customer.getCustomerCode(), excludeId)) {
                log.error("Duplicate customer code: {}", customer.getCustomerCode());
                throw new DuplicateCustomerException("customer code", customer.getCustomerCode());
            }
        }

        // Check phone if provided
        if (customer.getPhone() != null && !customer.getPhone().trim().isEmpty()) {
            if (excludeId == null) {
                if (customerRepository.existsByPhone(customer.getPhone())) {
                    log.error("Duplicate phone number: {}", customer.getPhone());
                    throw new DuplicateCustomerException("phone number", customer.getPhone());
                }
            } else {
                if (customerRepository.existsByPhoneAndIdNot(customer.getPhone(), excludeId)) {
                    log.error("Duplicate phone number: {}", customer.getPhone());
                    throw new DuplicateCustomerException("phone number", customer.getPhone());
                }
            }
        }

        // Check email if provided
        if (customer.getEmail() != null && !customer.getEmail().trim().isEmpty()) {
            String normalizedEmail = customer.getEmail().toLowerCase();
            if (excludeId == null) {
                if (customerRepository.existsByEmail(normalizedEmail)) {
                    log.error("Duplicate email: {}", normalizedEmail);
                    throw new DuplicateCustomerException("email", normalizedEmail);
                }
            } else {
                if (customerRepository.existsByEmailAndIdNot(normalizedEmail, excludeId)) {
                    log.error("Duplicate email: {}", normalizedEmail);
                    throw new DuplicateCustomerException("email", normalizedEmail);
                }
            }
        }
    }

    /**
     * Updates the FCM device token for a customer for push notification delivery.
     *
     * @param customerId  Customer ID
     * @param deviceToken FCM device token from the mobile app
     * @throws CustomerNotFoundException if customer not found
     */
    @Transactional
    public void updateCustomerDeviceToken(Long customerId, String deviceToken) {
        Customer customer = customerRepository.findById(customerId)
                .orElseThrow(() -> new CustomerNotFoundException(customerId));
        customer.setDeviceToken(deviceToken);
        customerRepository.save(customer);
        log.debug("Updated FCM device token for customer id={}", customerId);
    }

    /**
     * Gets current authenticated username for audit trails.
     *
     * @return Current username or "system" if not authenticated
     */
    private String getCurrentUsername() {
        try {
            Authentication auth = SecurityContextHolder.getContext().getAuthentication();
            if (auth != null && auth.isAuthenticated() && !"anonymousUser".equals(auth.getName())) {
                return auth.getName();
            }
        } catch (Exception e) {
            log.warn("Failed to get current username: {}", e.getMessage());
        }
        return "system";
    }
}
