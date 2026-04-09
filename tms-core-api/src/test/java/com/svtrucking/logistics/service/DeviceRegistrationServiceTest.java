package com.svtrucking.logistics.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.svtrucking.logistics.dto.DeviceRegisterDto;
import com.svtrucking.logistics.enums.DeviceStatus;
import com.svtrucking.logistics.model.DeviceRegister;
import com.svtrucking.logistics.model.Driver;
import com.svtrucking.logistics.repository.DeviceRegisterRepository;
import com.svtrucking.logistics.repository.DriverRepository;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.AuthenticationManager;

@ExtendWith(MockitoExtension.class)
class DeviceRegistrationServiceTest {

  @Mock private DeviceRegisterRepository deviceRepo;
  @Mock private DriverRepository driverRepo;
  @Mock private AuthenticationManager authenticationManager;

  private DeviceRegistrationService service;

  @BeforeEach
  void setUp() {
    service = new DeviceRegistrationService(deviceRepo, driverRepo, authenticationManager);
  }

  @Test
  void resolveLoginDeviceStatus_autoApprovesFirstDevice() {
    Driver driver = new Driver();
    driver.setId(200L);

    when(deviceRepo.findByDriverIdAndDeviceId(200L, "phone-a")).thenReturn(Optional.empty());
    when(deviceRepo.existsByDriverIdAndStatus(200L, DeviceStatus.APPROVED)).thenReturn(false);
    when(driverRepo.findById(200L)).thenReturn(Optional.of(driver));

    String status =
        service.resolveLoginDeviceStatus(
            DeviceRegisterDto.builder()
                .driverId(200L)
                .deviceId(" phone-a ")
                .deviceName("Samsung A54")
                .os("Android")
                .version("14")
                .appVersion("1.0.0")
                .manufacturer("Samsung")
                .model("SM-A546E")
                .build());

    assertThat(status).isEqualTo("APPROVED");
    ArgumentCaptor<DeviceRegister> captor = ArgumentCaptor.forClass(DeviceRegister.class);
    verify(deviceRepo).save(captor.capture());
    assertThat(captor.getValue().getStatus()).isEqualTo(DeviceStatus.APPROVED);
    assertThat(captor.getValue().getApprovedBy()).isEqualTo("SYSTEM_AUTO_FIRST_DEVICE");
    assertThat(captor.getValue().getDeviceId()).isEqualTo("phone-a");
    assertThat(captor.getValue().getDeviceName()).isEqualTo("Samsung A54");
    assertThat(captor.getValue().getOs()).isEqualTo("Android");
  }

  @Test
  void resolveLoginDeviceStatus_rejectsDifferentDeviceWhenApprovedOneAlreadyExists() {
    when(deviceRepo.findByDriverIdAndDeviceId(200L, "phone-b")).thenReturn(Optional.empty());
    when(deviceRepo.existsByDriverIdAndStatus(200L, DeviceStatus.APPROVED)).thenReturn(true);

    String status =
        service.resolveLoginDeviceStatus(
            DeviceRegisterDto.builder().driverId(200L).deviceId("phone-b").build());

    assertThat(status).isEqualTo("ACTIVE_ON_OTHER_PHONE");
    verify(deviceRepo, never()).save(org.mockito.ArgumentMatchers.any(DeviceRegister.class));
  }

  @Test
  void resolveLoginDeviceStatus_allowsKnownApprovedDevice() {
    DeviceRegister approved = DeviceRegister.builder().deviceId("phone-a").status(DeviceStatus.APPROVED).build();
    when(deviceRepo.findByDriverIdAndDeviceId(200L, "phone-a")).thenReturn(Optional.of(approved));

    String status =
        service.resolveLoginDeviceStatus(
            DeviceRegisterDto.builder()
                .driverId(200L)
                .deviceId("phone-a")
                .deviceName("Pixel 8")
                .appVersion("2.0.0")
                .build());

    assertThat(status).isEqualTo("APPROVED");
    assertThat(approved.getDeviceName()).isEqualTo("Pixel 8");
    assertThat(approved.getAppVersion()).isEqualTo("2.0.0");
  }
}
