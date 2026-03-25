package com.svtrucking.logistics.service;

import com.svtrucking.logistics.model.Customer;
import com.svtrucking.logistics.model.CustomerAddress;
import com.svtrucking.logistics.repository.CustomerRepository;
import com.svtrucking.logistics.repository.CustomerAddressRepository;
import java.io.*;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.Optional;
import org.apache.poi.ss.usermodel.*;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

@Service
public class OrderAddressExcelService {

  private final CustomerAddressRepository orderAddressRepository;
  private final CustomerRepository customerRepository;

  public OrderAddressExcelService(
      CustomerAddressRepository orderAddressRepository, CustomerRepository customerRepository) {
    this.orderAddressRepository = orderAddressRepository;
    this.customerRepository = customerRepository;
  }

  public ByteArrayInputStream exportToExcel(List<CustomerAddress> addresses) throws IOException {
    try (Workbook workbook = new XSSFWorkbook();
        ByteArrayOutputStream out = new ByteArrayOutputStream()) {
      Sheet sheet = workbook.createSheet("Customer Addresses");

      Row headerRow = sheet.createRow(0);
      String[] headers = {
        "ID",
        "Customer ID",
        "Customer Name",
        "Name",
        "Address",
        "City",
        "Country",
        "Type",
        "Latitude",
        "Longitude"
      };
      for (int i = 0; i < headers.length; i++) {
        headerRow.createCell(i).setCellValue(headers[i]);
      }

      int rowIdx = 1;
      for (CustomerAddress address : addresses) {
        Row row = sheet.createRow(rowIdx++);
        row.createCell(0).setCellValue(address.getId());
        row.createCell(1).setCellValue(address.getCustomer().getId());
        row.createCell(2).setCellValue(address.getCustomer().getName());
        row.createCell(3).setCellValue(address.getName());
        row.createCell(4).setCellValue(address.getAddress());
        row.createCell(5).setCellValue(address.getCity());
        row.createCell(6).setCellValue(address.getCountry());
        row.createCell(7).setCellValue(address.getType());
        row.createCell(8).setCellValue(address.getLatitude());
        row.createCell(9).setCellValue(address.getLongitude());
      }

      workbook.write(out);
      return new ByteArrayInputStream(out.toByteArray());
    }
  }

  public List<CustomerAddress> importFromExcel(MultipartFile file) throws IOException {
    List<CustomerAddress> addressList = new ArrayList<>();

    try (InputStream is = file.getInputStream();
        Workbook workbook = new XSSFWorkbook(is)) {
      Sheet sheet = workbook.getSheetAt(0);
      Iterator<Row> rows = sheet.iterator();
      if (rows.hasNext()) rows.next(); // skip header

      while (rows.hasNext()) {
        Row row = rows.next();
        long customerId = (long) row.getCell(1).getNumericCellValue();
        Optional<Customer> customerOpt = customerRepository.findById(customerId);
        if (customerOpt.isEmpty()) continue;

        CustomerAddress addr = new CustomerAddress();
        addr.setCustomer(customerOpt.get());
        addr.setName(row.getCell(3).getStringCellValue());
        addr.setAddress(row.getCell(4).getStringCellValue());
        addr.setCity(row.getCell(5).getStringCellValue());
        addr.setCountry(row.getCell(6).getStringCellValue());
        addr.setType(row.getCell(7).getStringCellValue());
        addr.setLatitude(row.getCell(8).getNumericCellValue());
        addr.setLongitude(row.getCell(9).getNumericCellValue());

        addressList.add(addr);
      }

      orderAddressRepository.saveAll(addressList);
      return addressList;
    }
  }
}
