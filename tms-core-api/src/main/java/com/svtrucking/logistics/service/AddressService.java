package com.svtrucking.logistics.service;

import com.svtrucking.logistics.model.Address;
import com.svtrucking.logistics.repository.AddressRepository;
import java.util.List;
import java.util.Optional;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class AddressService {

  @Autowired private AddressRepository addressRepository;

  public Address saveAddress(Address address) {
    return addressRepository.save(address);
  }

  public List<Address> getAllAddresses() {
    return addressRepository.findAll();
  }

  public List<Address> getAddressesByCustomer(Long customerId) {
    return addressRepository.findByCustomerId(customerId);
  }

  public Optional<Address> getAddressById(Long id) {
    return addressRepository.findById(id);
  }

  public Address updateAddress(Long id, Address updatedAddress) {
    return addressRepository
        .findById(id)
        .map(
            existingAddress -> {
              existingAddress.setName(updatedAddress.getName());
              existingAddress.setAddress(updatedAddress.getAddress());
              existingAddress.setPostcode(updatedAddress.getPostcode());
              existingAddress.setCity(updatedAddress.getCity());
              existingAddress.setCountry(updatedAddress.getCountry());
              existingAddress.setPhone(updatedAddress.getPhone());
              existingAddress.setLatitude(updatedAddress.getLatitude());
              existingAddress.setLongitude(updatedAddress.getLongitude());
              return addressRepository.save(existingAddress);
            })
        .orElseThrow(() -> new RuntimeException("Address not found"));
  }

  public void deleteAddress(Long id) {
    addressRepository.deleteById(id);
  }
}
