package com.svtrucking.logistics.service;

import java.util.List;
import java.util.stream.Collectors;

import com.svtrucking.logistics.dto.CustomerContactDto;
import com.svtrucking.logistics.dto.request.CustomerContactRequest;
import com.svtrucking.logistics.exception.CustomerNotFoundException;
import com.svtrucking.logistics.model.Customer;
import com.svtrucking.logistics.model.CustomerContact;
import com.svtrucking.logistics.repository.CustomerContactRepository;
import com.svtrucking.logistics.repository.CustomerRepository;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
@Transactional
public class CustomerContactService {

    private final CustomerContactRepository contactRepository;
    private final CustomerRepository customerRepository;

    /**
     * Get all contacts for a customer
     */
    @Transactional(readOnly = true)
    public List<CustomerContactDto> getContactsByCustomerId(Long customerId) {
        return contactRepository.findByCustomerId(customerId).stream()
            .map(CustomerContactDto::fromEntity)
            .collect(Collectors.toList());
    }

    /**
     * Get active contacts only
     */
    @Transactional(readOnly = true)
    public List<CustomerContactDto> getActiveContactsByCustomerId(Long customerId) {
        return contactRepository.findByCustomerIdAndIsActiveTrue(customerId).stream()
            .map(CustomerContactDto::fromEntity)
            .collect(Collectors.toList());
    }

    /**
     * Get primary contact for a customer
     */
    @Transactional(readOnly = true)
    public CustomerContactDto getPrimaryContact(Long customerId) {
        CustomerContact contact = contactRepository.findPrimaryContactByCustomerId(customerId);
        return CustomerContactDto.fromEntity(contact);
    }

    /**
     * Get contact by ID
     */
    @Transactional(readOnly = true)
    public CustomerContactDto getContactById(Long id) {
        CustomerContact contact = contactRepository.findById(id)
            .orElseThrow(() -> new RuntimeException("Contact not found with id: " + id));
        return CustomerContactDto.fromEntity(contact);
    }

    /**
     * Create new contact
     */
    public CustomerContactDto createContact(CustomerContactRequest request) {
        Customer customer = customerRepository.findById(request.getCustomerId())
            .orElseThrow(() -> new CustomerNotFoundException("Customer not found with id: " + request.getCustomerId()));

        // If setting as primary, unset other primary contacts
        if (Boolean.TRUE.equals(request.getIsPrimary())) {
            unsetPrimaryContacts(request.getCustomerId());
        }

        CustomerContact contact = new CustomerContact();
        contact.setCustomer(customer);
        contact.setFullName(request.getFullName());
        contact.setEmail(request.getEmail());
        contact.setPhone(request.getPhone());
        contact.setPosition(request.getPosition());
        contact.setIsPrimary(request.getIsPrimary() != null ? request.getIsPrimary() : false);
        contact.setIsActive(request.getIsActive() != null ? request.getIsActive() : true);
        contact.setNotes(request.getNotes());

        CustomerContact saved = contactRepository.save(contact);
        return CustomerContactDto.fromEntity(saved);
    }

    /**
     * Update existing contact
     */
    public CustomerContactDto updateContact(Long id, CustomerContactRequest request) {
        CustomerContact contact = contactRepository.findById(id)
            .orElseThrow(() -> new RuntimeException("Contact not found with id: " + id));

        // If setting as primary, unset other primary contacts
        if (Boolean.TRUE.equals(request.getIsPrimary()) && !Boolean.TRUE.equals(contact.getIsPrimary())) {
            unsetPrimaryContacts(contact.getCustomer().getId());
        }

        contact.setFullName(request.getFullName());
        contact.setEmail(request.getEmail());
        contact.setPhone(request.getPhone());
        contact.setPosition(request.getPosition());
        contact.setIsPrimary(request.getIsPrimary() != null ? request.getIsPrimary() : false);
        contact.setIsActive(request.getIsActive() != null ? request.getIsActive() : true);
        contact.setNotes(request.getNotes());

        CustomerContact updated = contactRepository.save(contact);
        return CustomerContactDto.fromEntity(updated);
    }

    /**
     * Delete contact
     */
    public void deleteContact(Long id) {
        if (!contactRepository.existsById(id)) {
            throw new RuntimeException("Contact not found with id: " + id);
        }
        contactRepository.deleteById(id);
    }

    /**
     * Search contacts
     */
    @Transactional(readOnly = true)
    public List<CustomerContactDto> searchContacts(Long customerId, String query) {
        return contactRepository.searchByCustomerIdAndQuery(customerId, query).stream()
            .map(CustomerContactDto::fromEntity)
            .collect(Collectors.toList());
    }

    /**
     * Count contacts for a customer
     */
    @Transactional(readOnly = true)
    public long countContacts(Long customerId) {
        return contactRepository.countByCustomerId(customerId);
    }

    /**
     * Helper: Unset all primary contacts for a customer
     */
    private void unsetPrimaryContacts(Long customerId) {
        List<CustomerContact> contacts = contactRepository.findByCustomerId(customerId);
        contacts.forEach(c -> c.setIsPrimary(false));
        contactRepository.saveAll(contacts);
    }
}
