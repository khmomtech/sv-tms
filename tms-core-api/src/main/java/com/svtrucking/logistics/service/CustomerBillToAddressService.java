package com.svtrucking.logistics.service;

import com.svtrucking.logistics.model.Customer;
import com.svtrucking.logistics.model.CustomerBillToAddress;
import com.svtrucking.logistics.model.CustomerAddress;
import com.svtrucking.logistics.repository.CustomerBillToAddressRepository;
import com.svtrucking.logistics.repository.CustomerAddressRepository;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class CustomerBillToAddressService {

  private final CustomerBillToAddressRepository repository;
  private final CustomerAddressRepository customerAddressRepository;
  private final CustomerService customerService;

  public CustomerBillToAddressService(
      CustomerBillToAddressRepository repository,
      CustomerAddressRepository customerAddressRepository,
      CustomerService customerService) {
    this.repository = repository;
    this.customerAddressRepository = customerAddressRepository;
    this.customerService = customerService;
  }

  public List<CustomerBillToAddress> list(Long customerId) {
    return repository.findByCustomerId(customerId);
  }

  public Page<CustomerBillToAddress> search(Long customerId, String search, Pageable pageable) {
    return repository.search(customerId, search == null ? null : search.trim(), pageable);
  }

  @Transactional
  public CustomerBillToAddress create(Long customerId, CustomerBillToAddress payload) {
    Customer customer = customerService.getCustomerById(customerId);
    payload.setId(null);
    payload.setCustomer(customer);
    if (payload.isPrimary()) {
      unsetPrimary(customerId);
    }
    return repository.save(payload);
  }

  @Transactional
  public CustomerBillToAddress update(Long customerId, Long billToId, CustomerBillToAddress payload) {
    CustomerBillToAddress existing = repository
        .findById(billToId)
        .orElseThrow(() -> new RuntimeException("Bill To Address not found with ID: " + billToId));
    if (existing.getCustomer() == null || !customerId.equals(existing.getCustomer().getId())) {
      throw new RuntimeException("Bill To Address does not belong to customer " + customerId);
    }

    existing.setName(payload.getName());
    existing.setAddress(payload.getAddress());
    existing.setCity(payload.getCity());
    existing.setState(payload.getState());
    existing.setZip(payload.getZip());
    existing.setCountry(payload.getCountry());
    existing.setContactName(payload.getContactName());
    existing.setContactPhone(payload.getContactPhone());
    existing.setEmail(payload.getEmail());
    existing.setTaxId(payload.getTaxId());
    existing.setNotes(payload.getNotes());

    if (payload.isPrimary() && !existing.isPrimary()) {
      unsetPrimary(customerId);
      existing.setPrimary(true);
    } else if (!payload.isPrimary() && existing.isPrimary()) {
      // allow unsetting primary if desired
      existing.setPrimary(false);
    }

    return repository.save(existing);
  }

  @Transactional
  public void delete(Long customerId, Long billToId) {
    CustomerBillToAddress existing = repository
        .findById(billToId)
        .orElseThrow(() -> new RuntimeException("Bill To Address not found with ID: " + billToId));
    if (existing.getCustomer() == null || !customerId.equals(existing.getCustomer().getId())) {
      throw new RuntimeException("Bill To Address does not belong to customer " + customerId);
    }
    repository.deleteById(billToId);
  }

  @Transactional
  public int migrateLegacyFromCustomerAddresses(Long customerId) {
    List<CustomerAddress> legacy = customerAddressRepository.findByCustomerId(customerId).stream()
        .filter(
            a -> {
              String t = a.getType() == null ? "" : a.getType().trim().toUpperCase();
              return t.startsWith("BILL");
            })
        .toList();
    if (legacy.isEmpty())
      return 0;

    List<CustomerBillToAddress> existing = repository.findByCustomerId(customerId);
    boolean hasPrimary = existing.stream().anyMatch(CustomerBillToAddress::isPrimary);
    Set<String> existingKeys = new HashSet<>();
    for (CustomerBillToAddress e : existing) {
      existingKeys.add(key(e.getName(), e.getAddress(), e.getCity(), e.getZip(), e.getCountry()));
    }

    Customer customer = customerService.getCustomerById(customerId);
    List<CustomerBillToAddress> toCreate = new ArrayList<>();
    List<CustomerAddress> toDelete = new ArrayList<>();
    for (int i = 0; i < legacy.size(); i++) {
      CustomerAddress a = legacy.get(i);
      String k = key(a.getName(), a.getAddress(), a.getCity(), a.getPostcode(), a.getCountry());
      if (existingKeys.contains(k)) {
        // Already present in bill-to table; delete legacy to avoid duplicates in UI.
        toDelete.add(a);
        continue;
      }
      CustomerBillToAddress b = new CustomerBillToAddress();
      b.setCustomer(customer);
      b.setName(a.getName());
      b.setAddress(a.getAddress());
      b.setCity(a.getCity());
      b.setCountry(a.getCountry());
      b.setZip(a.getPostcode());
      b.setContactName(a.getContactName());
      b.setContactPhone(a.getContactPhone());
      // If there is no existing primary, mark first migrated row as primary.
      b.setPrimary(!hasPrimary && toCreate.isEmpty());
      toCreate.add(b);
      toDelete.add(a);
      existingKeys.add(k);
    }

    if (!toCreate.isEmpty()) {
      repository.saveAll(toCreate);
    }
    if (!toDelete.isEmpty()) {
      customerAddressRepository.deleteAll(toDelete);
    }
    return toCreate.size();
  }

  private void unsetPrimary(Long customerId) {
    List<CustomerBillToAddress> list = repository.findByCustomerId(customerId);
    boolean changed = false;
    for (CustomerBillToAddress a : list) {
      if (a.isPrimary()) {
        a.setPrimary(false);
        changed = true;
      }
    }
    if (changed)
      repository.saveAll(list);
  }

  private String key(String name, String address, String city, String zip, String country) {
    return normalize(name)
        + "|"
        + normalize(address)
        + "|"
        + normalize(city)
        + "|"
        + normalize(zip)
        + "|"
        + normalize(country);
  }

  private String normalize(String v) {
    return v == null ? "" : v.trim().toLowerCase();
  }
}
