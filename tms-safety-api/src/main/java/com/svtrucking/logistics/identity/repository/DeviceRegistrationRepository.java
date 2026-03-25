package com.svtrucking.logistics.identity.repository;

import com.svtrucking.logistics.enums.DeviceStatus;
import com.svtrucking.logistics.identity.domain.DeviceRegistration;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface DeviceRegistrationRepository extends JpaRepository<DeviceRegistration, Long> {
  Optional<DeviceRegistration> findByDriverIdAndDeviceId(Long driverId, String deviceId);

  boolean existsByDriverIdAndDeviceIdAndStatus(Long driverId, String deviceId, DeviceStatus status);

  List<DeviceRegistration> findByDriverId(Long driverId);
}

