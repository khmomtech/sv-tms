package com.svtrucking.logistics.domain.driver;

import com.svtrucking.logistics.dto.requests.DriverCreateRequest;
import com.svtrucking.logistics.dto.requests.DriverUpdateRequest;
import com.svtrucking.logistics.enums.RoleType;
import com.svtrucking.logistics.model.Driver;
import com.svtrucking.logistics.model.Role;
import com.svtrucking.logistics.model.User;
import com.svtrucking.logistics.repository.EmployeeRepository;
import com.svtrucking.logistics.repository.DriverGroupRepository;
import com.svtrucking.logistics.repository.RoleRepository;
import com.svtrucking.logistics.repository.UserRepository;
import com.svtrucking.logistics.repository.VehicleRepository;
import java.util.HashSet;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

/**
 * Encapsulates driver specific business rules such as assembling the aggregate from incoming
 * requests and validating partner/company constraints.
 */
@Component
@RequiredArgsConstructor
public class DriverDomainService {

  private final EmployeeRepository employeeRepository;
  private final VehicleRepository vehicleRepository;
  private final UserRepository userRepository;
  private final RoleRepository roleRepository;
  private final PasswordEncoder passwordEncoder;
  private final DriverGroupRepository driverGroupRepository;

  /** Build a new {@link Driver} aggregate from a validated request. */
  public Driver buildNewDriver(DriverCreateRequest request) {
    Driver driver = new Driver();

    if (request.getUser() != null) {
      User user = new User();
      user.setUsername(request.getUser().getUsername());
      user.setPassword(passwordEncoder.encode(request.getUser().getPassword()));
      user.setEmail(request.getUser().getEmail());

      Set<String> roleNames = new HashSet<>();
      if (request.getUser().getRoles() != null) {
        roleNames.addAll(request.getUser().getRoles());
      }
      roleNames.add("DRIVER"); // Ensure DRIVER role is always present

      Set<Role> roles = roleNames.stream()
          .map(roleName -> {
            try {
              return RoleType.valueOf(roleName.toUpperCase());
            } catch (IllegalArgumentException e) {
              throw new RuntimeException("Invalid role: " + roleName);
            }
          })
          .map(roleType -> roleRepository.findByName(roleType)
              .orElseThrow(() -> new RuntimeException("Role not found: " + roleType)))
          .collect(Collectors.toSet());
      user.setRoles(roles);

      userRepository.save(user);
      driver.setUser(user);
    }

    driver.setFirstName(request.getFirstName());
    driver.setLastName(request.getLastName());
    driver.setName(
        resolveDisplayName(request.getName(), request.getFirstName(), request.getLastName()));
    driver.setLicenseNumber(request.getLicenseNumber());
    driver.setPhone(request.getPhone());
    driver.setRating(request.getRating());
    driver.setIsActive(request.getIsActive());
    driver.setZone(request.getZone());
    driver.setVehicleType(request.getVehicleType());
    driver.setStatus(request.getStatus());
    driver.setIdCardExpiry(request.getIdCardExpiry());
    // Location now managed via DriverLatestLocation table
    driver.setDeviceToken(request.getDeviceToken());
    driver.setProfilePicture(request.getProfilePicture());
    driver.setPartner(request.isPartner());
    mapDriverGroup(driver, request.getDriverGroupId());
    // Partner company now managed via partnerCompanyEntity FK

    mapEmployee(driver, request.getEmployeeId());
    mapVehicle(driver, request.getAssignedVehicleId());

    // Partner company validation now via partnerCompanyEntity FK constraint

    return driver;
  }

  /** Update mutable attributes from {@link DriverUpdateRequest}. */
  public void applyUpdate(Driver driver, DriverUpdateRequest request) {
    Optional.ofNullable(request.getFirstName()).ifPresent(driver::setFirstName);
    Optional.ofNullable(request.getLastName()).ifPresent(driver::setLastName);
    driver.setName(
        resolveDisplayName(request.getName(), driver.getFirstName(), driver.getLastName()));

    Optional.ofNullable(request.getLicenseNumber()).ifPresent(driver::setLicenseNumber);
    Optional.ofNullable(request.getPhone()).ifPresent(driver::setPhone);
    Optional.ofNullable(request.getRating()).ifPresent(driver::setRating);
    Optional.ofNullable(request.getIsActive()).ifPresent(driver::setIsActive);
    Optional.ofNullable(request.getZone()).ifPresent(driver::setZone);
    Optional.ofNullable(request.getVehicleType()).ifPresent(driver::setVehicleType);
    Optional.ofNullable(request.getStatus()).ifPresent(driver::setStatus);
    Optional.ofNullable(request.getIdCardExpiry()).ifPresent(driver::setIdCardExpiry);
    Optional.ofNullable(request.getProfilePicture()).ifPresent(driver::setProfilePicture);
    // Location now managed via DriverLatestLocation table
    Optional.ofNullable(request.getDeviceToken()).ifPresent(driver::setDeviceToken);

    Optional.ofNullable(request.getIsPartner())
        .ifPresent(
            partner -> {
              driver.setPartner(partner);
              // Partner company now managed via partnerCompanyEntity FK relationship
            });

    Optional.ofNullable(request.getEmployeeId()).ifPresent(id -> mapEmployee(driver, id));
    if (request.getVehicleId() != null) {
      mapVehicle(driver, request.getVehicleId());
    } else {
      driver.setAssignedVehicle(null);
    }
    mapDriverGroup(driver, request.getDriverGroupId());

    // Partner company validation now via partnerCompanyEntity FK constraint
  }

  private void mapEmployee(Driver driver, Long employeeId) {
    Optional.ofNullable(employeeId)
        .flatMap(employeeRepository::findById)
        .ifPresent(driver::setEmployee);
  }

  private void mapVehicle(Driver driver, Long vehicleId) {
    Optional.ofNullable(vehicleId)
        .flatMap(vehicleRepository::findById)
        .ifPresent(driver::setAssignedVehicle);
  }

  private void mapDriverGroup(Driver driver, Long groupId) {
    if (groupId == null) {
      driver.setDriverGroup(null);
      return;
    }
    Optional.ofNullable(groupId)
        .flatMap(driverGroupRepository::findById)
        .ifPresent(driver::setDriverGroup);
  }

  private String resolveDisplayName(String explicitName, String firstName, String lastName) {
    if (explicitName != null && !explicitName.isBlank()) {
      return explicitName;
    }
    String first = firstName != null ? firstName : "";
    String last = lastName != null ? lastName : "";
    return (first + " " + last).trim();
  }

  private void validatePartnerCompany(boolean partner, String company) {
    if (partner && (company == null || company.isBlank())) {
      throw new IllegalArgumentException("Partner driver must have a valid company name.");
    }
  }
}
