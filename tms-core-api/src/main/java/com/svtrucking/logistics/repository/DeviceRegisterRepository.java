package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.enums.DeviceStatus;
import com.svtrucking.logistics.model.DeviceRegister;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;

public interface DeviceRegisterRepository extends JpaRepository<DeviceRegister, Long>, JpaSpecificationExecutor<DeviceRegister> {

  Optional<DeviceRegister> findByDriverIdAndDeviceId(Long driverId, String deviceId);

  Optional<DeviceRegister> findByDeviceId(
      String deviceId); //  Needed for login-based device approval

  boolean existsByDriverIdAndDeviceIdAndStatus(Long driverId, String deviceId, DeviceStatus status);

  boolean existsByDriverIdAndStatus(Long driverId, DeviceStatus status);

  Optional<DeviceRegister> findFirstByDriverIdAndStatusOrderByRegisteredAtAsc(
      Long driverId, DeviceStatus status);
}
