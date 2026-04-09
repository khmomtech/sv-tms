package com.svtrucking.logistics.service;

import com.svtrucking.logistics.dto.CustomerAddressDto;
import com.svtrucking.logistics.model.Customer;
import com.svtrucking.logistics.model.CustomerAddress;
import com.svtrucking.logistics.repository.CustomerAddressRepository;
import java.io.InputStream;
import java.util.List;
import java.util.Optional;
import org.apache.poi.ss.usermodel.*;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

@Service
public class CustomerAddressService {

  private final CustomerAddressRepository customerAddressRepository;

  public CustomerAddressService(CustomerAddressRepository customerAddressRepository) {
    this.customerAddressRepository = customerAddressRepository;
  }

  /** Get a single customer address by ID */
  public Optional<CustomerAddress> getAddressById(Long id) {
    return customerAddressRepository.findById(id);
  }

  /** Create a new pickup/drop address */
  public CustomerAddress createAddress(CustomerAddress customerAddress) {
    return customerAddressRepository.save(customerAddress);
  }

  /** Update existing address */
  public CustomerAddress updateAddress(Long id, CustomerAddress newAddress) {
    return customerAddressRepository
        .findById(id)
        .map(
            existingAddress -> {
              existingAddress.setName(newAddress.getName());
              existingAddress.setAddress(newAddress.getAddress());
              existingAddress.setCity(newAddress.getCity());
              existingAddress.setCountry(newAddress.getCountry());
              existingAddress.setPostcode(newAddress.getPostcode());
              existingAddress.setScheduledTime(newAddress.getScheduledTime());
              existingAddress.setContactName(newAddress.getContactName());
              existingAddress.setContactPhone(newAddress.getContactPhone());
              existingAddress.setLongitude(newAddress.getLongitude());
              existingAddress.setLatitude(newAddress.getLatitude());
              existingAddress.setType(newAddress.getType());
              if (newAddress.getCustomer() != null) {
                existingAddress.setCustomer(newAddress.getCustomer());
              }
              return customerAddressRepository.save(existingAddress);
            })
        .orElseThrow(() -> new RuntimeException("Customer address not found with ID: " + id));
  }

  /** Delete an address */
  public void deleteAddress(Long id) {
    customerAddressRepository.deleteById(id);
  }

  /** Search customer addresses by name */
  public List<CustomerAddressDto> searchLocationsByName(String name) {
    List<CustomerAddress> addresses =
        customerAddressRepository.findByNameContainingIgnoreCase(name);
    return CustomerAddressDto.fromEntityList(addresses);
  }

  public Page<CustomerAddress> searchAddresses(
      Long customerId, String search, String type, Pageable pageable) {
    return customerAddressRepository.search(customerId, search, type, pageable);
  }

  public List<CustomerAddress> findByCustomerId(Long customerId) {
    return customerAddressRepository.findByCustomerId(customerId);
  }

  public List<CustomerAddress> findAll() {
    return customerAddressRepository.findAll();
  }

  @Transactional(rollbackFor = Exception.class)
  public int importAddresses(MultipartFile file, Long customerId) throws Exception {
    int totalRows = 0;
    int importedCount = 0;

    try (InputStream inputStream = file.getInputStream()) {
      Workbook workbook = WorkbookFactory.create(inputStream);
      Sheet sheet = workbook.getSheetAt(0);

      for (int i = 1; i <= sheet.getLastRowNum(); i++) {
        totalRows++;
        Row row = sheet.getRow(i);
        if (row == null
            || row.getCell(1) == null
            || row.getCell(1).getCellType() == CellType.BLANK) {
          throw new RuntimeException("Row " + (i + 1) + " is empty or missing required fields.");
        }

        String type = row.getCell(0).getStringCellValue().trim();
        String name = row.getCell(1).getStringCellValue().trim();
        String address = row.getCell(2).getStringCellValue().trim();
        String city = row.getCell(3).getStringCellValue().trim();
        String country = row.getCell(4).getStringCellValue().trim();
        double latitude = row.getCell(5).getNumericCellValue();
        double longitude = row.getCell(6).getNumericCellValue();

        if (latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) {
          throw new RuntimeException("Row " + (i + 1) + " has invalid coordinates.");
        }

        boolean exists =
            customerAddressRepository.existsByCustomer_IdAndNameIgnoreCase(customerId, name);
        if (exists) {
          throw new RuntimeException(
              "Duplicate name '" + name + "' for customer at row " + (i + 1));
        }

        CustomerAddress customerAddress = new CustomerAddress();
        Customer customer = new Customer();
        customer.setId(customerId);
        customerAddress.setCustomer(customer);
        customerAddress.setType(type);
        customerAddress.setName(name);
        customerAddress.setAddress(address);
        customerAddress.setCity(city);
        customerAddress.setCountry(country);
        customerAddress.setLatitude(latitude);
        customerAddress.setLongitude(longitude);

        customerAddressRepository.save(customerAddress);
        importedCount++;
      }

      workbook.close();
    } catch (Exception e) {
      throw new Exception("Failed to import addresses. Rolled back. Reason: " + e.getMessage(), e);
    }

    return importedCount;
  }
}
