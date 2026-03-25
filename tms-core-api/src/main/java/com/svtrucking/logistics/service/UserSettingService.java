package com.svtrucking.logistics.service;

import com.svtrucking.logistics.model.UserSetting;
import com.svtrucking.logistics.repository.UserSettingRepository;
import java.util.List;
import java.util.Optional;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

@Slf4j
@Service
@RequiredArgsConstructor
public class UserSettingService {

  private final UserSettingRepository userSettingRepository;

  /** Get all settings for a given user. */
  public List<UserSetting> getSettingsByUserId(Long userId) {
    return userSettingRepository.findByUserId(userId);
  }

  /** Get a specific setting by user and key. */
  public Optional<UserSetting> getSettingByUserIdAndKey(Long userId, String key) {
    return userSettingRepository.findByUserIdAndKey(userId, key);
  }

  /** Create or update a setting for the user. */
  public UserSetting updateSetting(Long userId, String key, String value) {
    Optional<UserSetting> existing = userSettingRepository.findByUserIdAndKey(userId, key);
    UserSetting setting;

    if (existing.isPresent()) {
      setting = existing.get();
      setting.setValue(value);
    } else {
      setting = UserSetting.builder().userId(userId).key(key).value(value).build();
    }

    UserSetting saved = userSettingRepository.save(setting);
    log.info("User setting saved: userId={}, key={}, value={}", userId, key, value);
    return saved;
  }
}
