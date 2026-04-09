package com.svtrucking.logistics.modules.notification.service;

import com.svtrucking.logistics.modules.notification.model.NotificationChannel;
import com.svtrucking.logistics.modules.notification.model.NotificationSetting;
import com.svtrucking.logistics.modules.notification.repository.NotificationSettingRepository;
import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class NotificationSettingService {

  private final NotificationSettingRepository repository;

  public NotificationSettingService(NotificationSettingRepository repository) {
    this.repository = repository;
  }

  public List<NotificationSetting> listAll() {
    return repository.findAll();
  }

  @Transactional
  public NotificationSetting updateByChannel(NotificationChannel channel, NotificationSetting payload) {
    NotificationSetting setting = repository.findByChannel(channel).orElseGet(() -> {
      NotificationSetting newSetting = new NotificationSetting();
      newSetting.setChannel(channel);
      return newSetting;
    });

    setting.setEnabled(payload.isEnabled());
    setting.setThresholdDays(payload.getThresholdDays());
    setting.setThresholdKm(payload.getThresholdKm());
    setting.setRecipientsJson(payload.getRecipientsJson());

    return repository.save(setting);
  }
}
