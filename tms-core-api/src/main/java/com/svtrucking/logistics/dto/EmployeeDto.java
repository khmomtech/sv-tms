package com.svtrucking.logistics.dto;

import com.svtrucking.logistics.model.Employee;
import java.time.LocalDate;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class EmployeeDto {
  private Long id;
  private String employeeCode;
  private String firstName;
  private String lastName;
  private String email;
  private String phoneNumber;
  private String department;
  private String position;
  private LocalDate hireDate;
  private String status;
  private Long userId;

  //  Convert `Employee` Entity to `EmployeeDto`
  public static EmployeeDto fromEntity(Employee employee) {
    return EmployeeDto.builder()
        .id(employee.getId())
        .employeeCode(employee.getEmployeeCode())
        .firstName(employee.getFirstName())
        .lastName(employee.getLastName())
        .email(employee.getEmail())
        .phoneNumber(employee.getPhoneNumber())
        .department(employee.getDepartment())
        .position(employee.getPosition())
        .hireDate(employee.getHireDate())
        .status(employee.getStatus())
        .userId(employee.getUser() != null ? employee.getUser().getId() : null)
        .build();
  }

  //  Convert `EmployeeDto` to `Employee` Entity
  public static Employee toEntity(EmployeeDto dto) {
    Employee employee = new Employee();
    employee.setId(dto.getId());
    employee.setEmployeeCode(dto.getEmployeeCode());
    employee.setFirstName(dto.getFirstName());
    employee.setLastName(dto.getLastName());
    employee.setEmail(dto.getEmail());
    employee.setPhoneNumber(dto.getPhoneNumber());
    employee.setDepartment(dto.getDepartment());
    employee.setPosition(dto.getPosition());
    employee.setHireDate(dto.getHireDate());
    employee.setStatus(dto.getStatus());
    return employee;
  }

  public EmployeeDto(Long id, String firstName) {
    this.id = id;
    this.firstName = firstName;
  }
}
