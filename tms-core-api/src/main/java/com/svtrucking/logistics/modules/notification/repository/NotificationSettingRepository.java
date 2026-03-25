package com.svtrucking.logistics.modules.notification.repository;

import com.svtrucking.logistics.modules.notification.model.NotificationChannel;
import com.svtrucking.logistics.modules.notification.model.NotificationSetting;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface NotificationSettingRepository extends JpaRepository<NotificationSetting, Long> {

  Optional<NotificationSetting> findByChannel(NotificationChannel channel);
}
