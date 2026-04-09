package com.svtrucking.logistics.service;

import com.svtrucking.logistics.dto.DeviceRegisterDto;
import com.svtrucking.logistics.dto.requests.DeviceApprovalRequest;
import com.svtrucking.logistics.enums.DeviceStatus;
import com.svtrucking.logistics.model.DeviceRegister;
import com.svtrucking.logistics.model.Driver;
import com.svtrucking.logistics.repository.DeviceRegisterRepository;
import com.svtrucking.logistics.repository.DriverRepository;
import java.time.LocalDateTime;
import java.util.Optional;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnWebApplication;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Slf4j
@ConditionalOnWebApplication(type = ConditionalOnWebApplication.Type.SERVLET)
public class DeviceRegistrationService {

  private final DeviceRegisterRepository deviceRepo;
  private final DriverRepository driverRepo;
  private final AuthenticationManager authenticationManager;

  @Transactional
  public void requestApprovalViaLogin(DeviceApprovalRequest request) {
    try {
      // Validate input fields
      if (request.getUsername() == null || request.getUsername().isBlank()) {
        throw new IllegalArgumentException("Username is required");
      }
      if (request.getPassword() == null || request.getPassword().isBlank()) {
        throw new IllegalArgumentException("Password is required");
      }
      if (request.getDeviceId() == null || request.getDeviceId().isBlank()) {
        throw new IllegalArgumentException("Device ID is required");
      }

      // Authenticate driver
      authenticationManager.authenticate(
              new UsernamePasswordAuthenticationToken(
                  request.getUsername(), request.getPassword()));

      Driver driver =
          driverRepo
              .findByUsername(request.getUsername())
              .orElseThrow(
                  () ->
                      new RuntimeException(
                          "Driver not found with username: " + request.getUsername()));

      Optional<DeviceRegister> existing =
          deviceRepo.findByDriverIdAndDeviceId(driver.getId(), request.getDeviceId());

      if (existing.isPresent()) {
        DeviceRegister device = existing.get();
        device.setStatus(DeviceStatus.PENDING);
        device.setDeviceName(request.getDeviceName());
        device.setOs(request.getOs());
        device.setVersion(request.getVersion());
        device.setManufacturer(request.getManufacturer());
        device.setModel(request.getModel());
        device.setAppVersion(request.getAppVersion());
        device.setIpAddress(request.getIpAddress());
        device.setLocation(request.getLocation());
        if (device.getRegisteredAt() == null) {
          device.setRegisteredAt(LocalDateTime.now());
        }
        device.setStatusUpdatedAt(LocalDateTime.now());
        deviceRepo.save(device);
        log.info("Approval re-requested via login: {}", request.getDeviceId());
      } else {
        DeviceRegister newDevice =
            DeviceRegister.builder()
                .driver(driver)
                .deviceId(request.getDeviceId())
                .deviceName(request.getDeviceName())
                .os(request.getOs())
                .version(request.getVersion())
                .manufacturer(request.getManufacturer())
                .model(request.getModel())
                .appVersion(request.getAppVersion())
                .ipAddress(request.getIpAddress())
                .location(request.getLocation())
                .status(DeviceStatus.PENDING)
                .registeredAt(LocalDateTime.now())
                .statusUpdatedAt(LocalDateTime.now())
                .build();
        deviceRepo.save(newDevice);
        log.info("Approval requested via login for new device: {}", request.getDeviceId());
      }

    } catch (BadCredentialsException ex) {
      log.warn("Invalid login for user '{}': {}", request.getUsername(), ex.getMessage());
      throw new BadCredentialsException("Invalid username or password", ex);
    } catch (IllegalArgumentException ex) {
      log.warn("Validation error in approval request: {}", ex.getMessage());
      throw ex;
    } catch (Exception e) {
      log.error(" Unexpected error during device approval via login", e);
      throw new RuntimeException("Authentication failed or internal error", e);
    }
  }

  // --- other methods below remain unchanged ---

  @Transactional
  public DeviceStatus registerOrVerifyDevice(DeviceRegisterDto dto) {
    validateInput(dto);
    Driver driver = getDriver(dto.getDriverId());
    Optional<DeviceRegister> existing =
        deviceRepo.findByDriverIdAndDeviceId(driver.getId(), dto.getDeviceId());

    if (existing.isPresent()) {
      log.info(
          "🔁 Device already registered: {}, Status: {}",
          dto.getDeviceId(),
          existing.get().getStatus());
      return existing.get().getStatus();
    }

    DeviceRegister newDevice =
        DeviceRegister.builder()
            .driver(driver)
            .deviceId(dto.getDeviceId())
            .deviceName(dto.getDeviceName())
            .os(dto.getOs())
            .version(dto.getVersion())
            .status(DeviceStatus.PENDING)
            .registeredAt(LocalDateTime.now())
            .build();

    deviceRepo.save(newDevice);
    log.info(
        "📌 New device registered for driver {} - Device ID: {}",
        driver.getId(),
        dto.getDeviceId());
    return DeviceStatus.PENDING;
  }

  @Transactional
  public void requestDeviceApproval(DeviceRegisterDto dto) {
    validateInput(dto);
    Driver driver = getDriver(dto.getDriverId());
    Optional<DeviceRegister> existing =
        deviceRepo.findByDriverIdAndDeviceId(driver.getId(), dto.getDeviceId());

    if (existing.isPresent()) {
      DeviceRegister device = existing.get();
      device.setStatus(DeviceStatus.PENDING);
      if (device.getRegisteredAt() == null) {
        device.setRegisteredAt(LocalDateTime.now());
      }
      device.setStatusUpdatedAt(LocalDateTime.now());
      deviceRepo.save(device);
      log.info(
          "Approval re-requested for existing device ID={} (Driver: {})",
          dto.getDeviceId(),
          driver.getId());
    } else {
      DeviceRegister newDevice =
          DeviceRegister.builder()
              .driver(driver)
              .deviceId(dto.getDeviceId())
              .deviceName(dto.getDeviceName())
              .os(dto.getOs())
              .version(dto.getVersion())
              .status(DeviceStatus.PENDING)
              .registeredAt(LocalDateTime.now())
              .statusUpdatedAt(LocalDateTime.now())
              .build();
      deviceRepo.save(newDevice);
      log.info(
          "Approval requested for new device ID={} (Driver: {})",
          dto.getDeviceId(),
          driver.getId());
    }
  }

  public boolean isDeviceApproved(Long driverId, String deviceId) {
    if (driverId == null || deviceId == null) return false;
    boolean approved =
        deviceRepo.existsByDriverIdAndDeviceIdAndStatus(driverId, deviceId, DeviceStatus.APPROVED);
    log.debug(
        "🔍 Device approval check - Driver ID: {}, Device ID: {}, Approved: {}",
        driverId,
        deviceId,
        approved);
    return approved;
  }

  @Transactional
  public String resolveLoginDeviceStatus(Long driverId, String deviceId) {
    return resolveLoginDeviceStatus(
        DeviceRegisterDto.builder().driverId(driverId).deviceId(deviceId).build());
  }

  @Transactional
  public void updateDeviceStatus(Long deviceId, DeviceStatus status) {
    DeviceRegister device =
        deviceRepo
            .findById(deviceId)
            .orElseThrow(() -> new RuntimeException("Device not found for ID: " + deviceId));

    device.setStatus(status);
    if (device.getRegisteredAt() == null) {
      device.setRegisteredAt(LocalDateTime.now());
    }
    device.setStatusUpdatedAt(LocalDateTime.now());
    deviceRepo.save(device);
    log.info(" Device status updated: ID={}, New Status={}", deviceId, status);
  }

  @Transactional
  public DeviceRegister createDevice(DeviceRegisterDto dto) {
    Driver driver = getDriver(dto.getDriverId());

    deviceRepo
        .findByDriverIdAndDeviceId(driver.getId(), dto.getDeviceId())
        .ifPresent(
            existing -> {
              throw new RuntimeException("Device already registered for this driver.");
            });

    DeviceRegister device =
        DeviceRegister.builder()
            .driver(driver)
            .deviceId(dto.getDeviceId())
            .deviceName(dto.getDeviceName())
            .os(dto.getOs())
            .version(dto.getVersion())
            .status(dto.getStatus() != null ? dto.getStatus() : DeviceStatus.PENDING)
            .registeredAt(LocalDateTime.now())
            .build();

    log.info("🆕 Device created manually: {}", dto.getDeviceId());
    return deviceRepo.save(device);
  }

  @Transactional
  public DeviceRegister updateDevice(Long id, DeviceRegisterDto dto) {
    DeviceRegister device =
        deviceRepo
            .findById(id)
            .orElseThrow(() -> new RuntimeException("Device not found for ID: " + id));

    if (dto.getDeviceName() != null) device.setDeviceName(dto.getDeviceName());
    if (dto.getDeviceId() != null) device.setDeviceId(dto.getDeviceId());
    if (dto.getOs() != null) device.setOs(dto.getOs());
    if (dto.getVersion() != null) device.setVersion(dto.getVersion());
    if (dto.getStatus() != null) device.setStatus(dto.getStatus());

    if (device.getRegisteredAt() == null) {
      device.setRegisteredAt(LocalDateTime.now());
    }

    log.info("✏️ Device updated: ID={}, New Data={}", id, dto);
    return deviceRepo.save(device);
  }

  @Transactional
  public void deleteDevice(Long id) {
    if (!deviceRepo.existsById(id)) {
      throw new RuntimeException("Device not found for ID: " + id);
    }
    deviceRepo.deleteById(id);
    log.warn(" Device deleted: ID={}", id);
  }

  private void validateInput(DeviceRegisterDto dto) {
    if (dto.getDriverId() == null || dto.getDeviceId() == null || dto.getDeviceId().isBlank()) {
      throw new IllegalArgumentException("Driver ID and Device ID are required");
    }
  }

  private Driver getDriver(Long driverId) {
    return driverRepo
        .findById(driverId)
        .orElseThrow(() -> new RuntimeException("Driver not found for ID: " + driverId));
  }

  @Transactional
  public String resolveLoginDeviceStatus(DeviceRegisterDto dto) {
    log.info("resolveLoginDeviceStatus called with dto={}", dto);
    if (dto == null
        || dto.getDriverId() == null
        || dto.getDeviceId() == null
        || dto.getDeviceId().isBlank()) {
      log.debug("resolveLoginDeviceStatus: invalid dto, returning NOT_REGISTERED");
      return "NOT_REGISTERED";
    }

    Long driverId = dto.getDriverId();
    String deviceId = dto.getDeviceId().trim();
    Optional<DeviceRegister> deviceOpt = deviceRepo.findByDriverIdAndDeviceId(driverId, deviceId);

    if (deviceOpt.isPresent()) {
      DeviceRegister device = deviceOpt.get();
      applyDeviceMetadata(device, dto);
      deviceRepo.save(device);

      DeviceStatus status = device.getStatus();
      if (status == DeviceStatus.APPROVED) {
        return "APPROVED";
      }
      if (status == DeviceStatus.PENDING) {
        return "PENDING";
      }
      if (status == DeviceStatus.REJECTED) {
        return "REJECTED";
      }
      if (status == DeviceStatus.BLOCKED) {
        return "BLOCKED";
      }
      return "UNKNOWN";
    }

    if (!deviceRepo.existsByDriverIdAndStatus(driverId, DeviceStatus.APPROVED)) {
      Driver driver = getDriver(driverId);
      DeviceRegister autoApproved =
          DeviceRegister.builder()
              .driver(driver)
              .deviceId(deviceId)
              .deviceName(dto.getDeviceName())
              .os(dto.getOs())
              .version(dto.getVersion())
              .appVersion(dto.getAppVersion())
              .manufacturer(dto.getManufacturer())
              .model(dto.getModel())
              .ipAddress(dto.getIpAddress())
              .location(dto.getLocation())
              .status(DeviceStatus.APPROVED)
              .approvedBy("SYSTEM_AUTO_FIRST_DEVICE")
              .registeredAt(LocalDateTime.now())
              .statusUpdatedAt(LocalDateTime.now())
              .build();
      deviceRepo.save(autoApproved);
      log.info(
          "Auto-approved first login device for driver {} with deviceId={}",
          driverId,
          deviceId);
      return "APPROVED";
    }

    return "ACTIVE_ON_OTHER_PHONE";
  }

  private void applyDeviceMetadata(DeviceRegister device, DeviceRegisterDto dto) {
    if (dto.getDeviceName() != null && !dto.getDeviceName().isBlank()) {
      device.setDeviceName(dto.getDeviceName().trim());
    }
    if (dto.getOs() != null && !dto.getOs().isBlank()) {
      device.setOs(dto.getOs().trim());
    }
    if (dto.getVersion() != null && !dto.getVersion().isBlank()) {
      device.setVersion(dto.getVersion().trim());
    }
    if (dto.getAppVersion() != null && !dto.getAppVersion().isBlank()) {
      device.setAppVersion(dto.getAppVersion().trim());
    }
    if (dto.getManufacturer() != null && !dto.getManufacturer().isBlank()) {
      device.setManufacturer(dto.getManufacturer().trim());
    }
    if (dto.getModel() != null && !dto.getModel().isBlank()) {
      device.setModel(dto.getModel().trim());
    }
    if (dto.getIpAddress() != null && !dto.getIpAddress().isBlank()) {
      device.setIpAddress(dto.getIpAddress().trim());
    }
    if (dto.getLocation() != null && !dto.getLocation().isBlank()) {
      device.setLocation(dto.getLocation().trim());
    }
  }

  public String getDeviceStatus(Long driverId, String deviceId) {
    if (driverId == null || deviceId == null || deviceId.isBlank()) {
      return "NOT_REGISTERED";
    }

    Optional<DeviceRegister> deviceOpt = deviceRepo.findByDriverIdAndDeviceId(driverId, deviceId);

    if (deviceOpt.isEmpty()) {
      return "NOT_REGISTERED";
    }

    DeviceStatus status = deviceOpt.get().getStatus();
    if (status == DeviceStatus.APPROVED) {
      return "APPROVED";
    }
    if (status == DeviceStatus.PENDING) {
      return "PENDING";
    }
    if (status == DeviceStatus.REJECTED) {
      return "REJECTED";
    }
    return "UNKNOWN";
  }
}
