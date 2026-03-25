package com.svtrucking.logistics.identity.device;

import com.svtrucking.logistics.dto.DeviceRegisterDto;
import com.svtrucking.logistics.dto.requests.DeviceApprovalRequest;
import com.svtrucking.logistics.enums.DeviceStatus;
import com.svtrucking.logistics.identity.domain.DeviceRegistration;
import com.svtrucking.logistics.identity.domain.DriverProfile;
import com.svtrucking.logistics.identity.domain.User;
import com.svtrucking.logistics.identity.repository.DeviceRegistrationRepository;
import com.svtrucking.logistics.identity.repository.DriverProfileRepository;
import com.svtrucking.logistics.identity.repository.UserRepository;
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

  private final DeviceRegistrationRepository deviceRepo;
  private final DriverProfileRepository driverRepo;
  private final UserRepository userRepository;
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

      User user =
          userRepository
              .findByUsername(request.getUsername())
              .orElseThrow(
                  () ->
                      new RuntimeException(
                          "User not found with username: " + request.getUsername()));

      DriverProfile driver =
          driverRepo
              .findByUserId(user.getId())
              .orElseThrow(
                  () ->
                      new RuntimeException(
                          "Driver not found for user: " + request.getUsername()));

      Optional<DeviceRegistration> existing =
          deviceRepo.findByDriverIdAndDeviceId(driver.getId(), request.getDeviceId());

      if (existing.isPresent()) {
        DeviceRegistration device = existing.get();
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
        DeviceRegistration newDevice =
            DeviceRegistration.builder()
                .driverId(driver.getId())
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
    DriverProfile driver = getDriver(dto.getDriverId());
    Optional<DeviceRegistration> existing =
        deviceRepo.findByDriverIdAndDeviceId(driver.getId(), dto.getDeviceId());

    if (existing.isPresent()) {
      log.info(
          "🔁 Device already registered: {}, Status: {}",
          dto.getDeviceId(),
          existing.get().getStatus());
      return existing.get().getStatus();
    }

    DeviceRegistration newDevice =
        DeviceRegistration.builder()
            .driverId(driver.getId())
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
    DriverProfile driver = getDriver(dto.getDriverId());
    Optional<DeviceRegistration> existing =
        deviceRepo.findByDriverIdAndDeviceId(driver.getId(), dto.getDeviceId());

    if (existing.isPresent()) {
      DeviceRegistration device = existing.get();
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
      DeviceRegistration newDevice =
          DeviceRegistration.builder()
              .driverId(driver.getId())
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
  public void updateDeviceStatus(Long deviceId, DeviceStatus status) {
    DeviceRegistration device =
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
  public DeviceRegistration createDevice(DeviceRegisterDto dto) {
    DriverProfile driver = getDriver(dto.getDriverId());

    deviceRepo
        .findByDriverIdAndDeviceId(driver.getId(), dto.getDeviceId())
        .ifPresent(
            existing -> {
              throw new RuntimeException("Device already registered for this driver.");
            });

    DeviceRegistration device =
        DeviceRegistration.builder()
            .driverId(driver.getId())
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
  public DeviceRegistration updateDevice(Long id, DeviceRegisterDto dto) {
    DeviceRegistration device =
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

  private DriverProfile getDriver(Long driverId) {
    return driverRepo
        .findById(driverId)
        .orElseThrow(() -> new RuntimeException("Driver not found for ID: " + driverId));
  }

  public String getDeviceStatus(Long driverId, String deviceId) {
    if (driverId == null || deviceId == null || deviceId.isBlank()) {
      return "NOT_REGISTERED";
    }

    Optional<DeviceRegistration> deviceOpt = deviceRepo.findByDriverIdAndDeviceId(driverId, deviceId);

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
