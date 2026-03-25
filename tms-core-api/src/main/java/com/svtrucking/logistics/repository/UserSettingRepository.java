package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.UserSetting;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserSettingRepository extends JpaRepository<UserSetting, Long> {
  List<UserSetting> findByUserId(Long userId);

  Optional<UserSetting> findByUserIdAndKey(Long userId, String key);
}
