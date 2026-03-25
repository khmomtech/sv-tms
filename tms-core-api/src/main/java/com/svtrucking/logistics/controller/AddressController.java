package com.svtrucking.logistics.controller;

import com.svtrucking.logistics.model.Address;
import com.svtrucking.logistics.service.AddressService;
import java.util.List;
import java.util.Optional;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/admin/addresses")
@CrossOrigin(origins = "*")
public class AddressController {

  @Autowired private AddressService addressService;

  @PostMapping("/save")
  public ResponseEntity<Address> saveAddress(@RequestBody Address address) {
    Address savedAddress = addressService.saveAddress(address);
    return ResponseEntity.ok(savedAddress);
  }

  @GetMapping("/list")
  public ResponseEntity<List<Address>> getAllAddresses() {
    return ResponseEntity.ok(addressService.getAllAddresses());
  }

  @GetMapping("/customer/{customerId}")
  public ResponseEntity<List<Address>> getAddressesByCustomer(@PathVariable Long customerId) {
    return ResponseEntity.ok(addressService.getAddressesByCustomer(customerId));
  }

  @GetMapping("/{id}")
  public ResponseEntity<Address> getAddressById(@PathVariable Long id) {
    Optional<Address> address = addressService.getAddressById(id);
    return address.map(ResponseEntity::ok).orElseGet(() -> ResponseEntity.notFound().build());
  }

  @PutMapping("/update/{id}")
  public ResponseEntity<Address> updateAddress(
      @PathVariable Long id, @RequestBody Address updatedAddress) {
    try {
      return ResponseEntity.ok(addressService.updateAddress(id, updatedAddress));
    } catch (RuntimeException e) {
      return ResponseEntity.notFound().build();
    }
  }

  @DeleteMapping("/delete/{id}")
  public ResponseEntity<Void> deleteAddress(@PathVariable Long id) {
    if (addressService.getAddressById(id).isPresent()) {
      addressService.deleteAddress(id);
      return ResponseEntity.ok().build();
    }
    return ResponseEntity.notFound().build();
  }
}
