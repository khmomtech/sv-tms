package com.svtrucking.logistics.service;

import com.svtrucking.logistics.model.Employee;
import com.svtrucking.logistics.repository.EmployeeRepository;
import java.util.List;
import java.util.Optional;
import java.util.concurrent.atomic.AtomicLong;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class EmployeeService {

  private final EmployeeRepository employeeRepository;
  private static final AtomicLong employeeCounter =
      new AtomicLong(1000); //  Auto-generate EMP codes

  public EmployeeService(EmployeeRepository employeeRepository) {
    this.employeeRepository = employeeRepository;
  }

  /** Add a New Employee */
  @Transactional
  public Employee addEmployee(Employee employee) {
    employee.setEmployeeCode("EMP-" + employeeCounter.incrementAndGet());
    return employeeRepository.save(employee);
  }

  /** Get All Employees */
  public List<Employee> getAllEmployees() {
    return employeeRepository.findAll();
  }

  public Page<Employee> search(String search, Pageable pageable) {
    String q = (search == null || search.isBlank()) ? null : search.trim();
    return employeeRepository.search(q, pageable);
  }

  /** Get Employee by ID */
  public Optional<Employee> getEmployeeById(Long id) {
    return employeeRepository.findById(id);
  }

  /** Update Employee */
  @Transactional
  public Employee updateEmployee(Long id, Employee updatedEmployee) {
    Employee employee =
        employeeRepository
            .findById(id)
            .orElseThrow(() -> new RuntimeException("Employee not found"));

    employee.setFirstName(updatedEmployee.getFirstName());
    employee.setLastName(updatedEmployee.getLastName());
    employee.setEmail(updatedEmployee.getEmail());
    employee.setPhoneNumber(updatedEmployee.getPhoneNumber());
    employee.setDepartment(updatedEmployee.getDepartment());
    employee.setPosition(updatedEmployee.getPosition());
    employee.setHireDate(updatedEmployee.getHireDate());
    employee.setStatus(updatedEmployee.getStatus());

    return employeeRepository.save(employee);
  }

  /** Delete Employee */
  @Transactional
  public void deleteEmployee(Long id) {
    employeeRepository.deleteById(id);
  }
}
